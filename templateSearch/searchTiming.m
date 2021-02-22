% PRESENT-ABSENT SEARCH TRIAL for MonkeyLogic - Vision Lab, IISc
%{
Presents present-absent visual search array at screen center. Provides two touch button
on the right side (from subjects' POV) as responses:
  - Top button for 'same/absent' response, and
  - Bottom button for 'diff/present' response.

VERSION HISTORY
- 06-Feb-2021 - Thomas  - First implementation
%}
% HEADER start ---------------------------------------------------------------------------

% CHECK if touch and eyesignal are present to continue
if ~ML_touchpresent, error('This task requires touch signal input!'); end
if ~ML_eyepresent,   error('This task requires eye signal input!');   end

% REMOVE the joystick cursor
showcursor(false);

% POINTER to trial number
trialNum = TrialRecord.CurrentTrialNumber;

% ITI (set to 0 to measure true ITI in ML Dashboard)
set_iti(200);

% EDITABLE variables that can be changed during the task
editable(...
    'goodPause',    'badPause',         'taskFixRadius',    'taskStimRadius',...
    'taskStimScale','spatialSDFlag',...
    'calFixRadius', 'calFixInitPeriod', 'calFixHoldPeriod', 'calFixRandFlag',...
    'rewardVol',    'rewardLine',       'rewardReps',       'rewardRepsGap');
goodPause        = 200;
badPause         = 1000;
taskFixRadius    = 10;
taskStimRadius   = 5;
taskStimScale    = 1;
spatialSDFlag    = 0;
calFixRadius     = 6;
calFixInitPeriod = 500;
calFixHoldPeriod = 200;
calFixRandFlag   = 1;
rewardVol        = 0.2;
rewardLine       = 1;
rewardReps       = 1;
rewardRepsGap    = 500;

% PARAMETERS relevant for task timing and hold/fix control
holdInitPeriod   = Info.holdInitPeriod;
fixInitPeriod    = Info.fixInitPeriod;
fixHoldPeriod    = 500;
holdRadius       = TrialData.TaskObject.Attribute{1, 2}{1, 2};
holdRadiusBuffer = 2;
searchPeriod     = Info.searchPeriod;
respPeriod       = Info.respPeriod;
reward           = ml_rewardVol2Time(rewardVol);

% ASSIGN event codes from TrialRecord.User
err = TrialRecord.User.err;
pic = TrialRecord.User.pic;
aud = TrialRecord.User.aud;
bhv = TrialRecord.User.bhv;
rew = TrialRecord.User.rew;
exp = TrialRecord.User.exp;
trl = TrialRecord.User.trl;
chk = TrialRecord.User.chk;

% POINTERS to TaskObjects
ptd         = 1; 
hold        = 2;
fix         = 3; 
calib       = 4; 
audCorr     = 5; 
audWrong    = 6; 
same        = 7;
diff        = 8; 
target      = 9; 
distractor1 = 10;
distractor2 = 11;
distractor3 = 12;
distractor4 = 13;
distractor5 = 14;
distractor6 = 15;
distractor7 = 16;
distractor8 = 17;

searchArray = [target distractor1 distractor2 distractor3 distractor4...
        distractor5 distractor6 distractor7 distractor8];

% REPOSITION target and distractor to random locations
arrayLocs   = [...
    0,               0,...
    0,               taskStimRadius,...
    0,              -taskStimRadius,...
    taskStimRadius,  0,...
    -taskStimRadius, 0,...
    taskStimRadius,  taskStimRadius,...
    taskStimRadius, -taskStimRadius,...
    -taskStimRadius,  taskStimRadius,...
    -taskStimRadius, -taskStimRadius];

normJitter  = rand(18,1)*2;
arrayLocs   = reshape((arrayLocs + normJitter'), 2, 9)';
arrayLocs   = arrayLocs(randperm(size(arrayLocs, 1)), :);

reposition_object(target,      arrayLocs(1,:));
reposition_object(distractor1, arrayLocs(2,:));
reposition_object(distractor2, arrayLocs(3,:));
reposition_object(distractor3, arrayLocs(4,:));
reposition_object(distractor4, arrayLocs(5,:));
reposition_object(distractor5, arrayLocs(6,:));
reposition_object(distractor6, arrayLocs(7,:));
reposition_object(distractor7, arrayLocs(8,:));
reposition_object(distractor8, arrayLocs(9,:));

% SCALE objects
if taskStimScale ~= 1
    rescale_object(searchArray, taskStimScale);
end
        
% SET response button order for SD task
if ~isfield(TrialRecord.User, 'respOrder')
    TrialRecord.User.respOrder = [same diff];
end
respOrder = TrialRecord.User.respOrder;

% DECLARE select timing and reward variables as NaN
tHoldButtonOn   = NaN;
tTrialInit      = NaN;
tFixAcqCueOn    = NaN;
tFixAcq         = NaN;
tFixAcqCueOff   = NaN;
tSearchRespOn   = NaN;
tBhvResp        = NaN;
tSearchOff      = NaN;
tAllOff         = NaN;
juiceConsumed   = NaN;

% HEADER end -----------------------------------------------------------------------------
% TRIAL start ----------------------------------------------------------------------------

% CHECK and proceed only if screen is not being touched
while istouching(), end
outcome = -1;

% SEND check even lines
eventmarker(chk.linesEven);

% TRIAL start
eventmarker(trl.start);
TrialRecord.User.TrialStart(trialNum,:) = datevec(now);

% RUN trial sequence till outcome registered
while outcome < 0
    % PRESENT hold button
    tHoldButtonOn = toggleobject([hold ptd], 'eventmarker', pic.holdOn);
    
    % WAIT for touch in INIT period
    [ontarget, ~, tTrialInit] = eyejoytrack(...
        'touchtarget',  hold, holdRadius,...
        '~touchtarget', hold, holdRadius + holdRadiusBuffer,...
        holdInitPeriod);
    
    if(sum(ontarget) == 0)
        % Error if there's no touch anywhere
        event   = [pic.holdOff bhv.holdNotInit];
        outcome = err.holdNil; break
    elseif ontarget(2) == 1
        % Error if any touch outside hold button
        event   = [pic.holdOff bhv.holdOutside];
        outcome = err.holdOutside; break
    else
        % Correctly initiated hold
        eventmarker(bhv.holdInit);
    end
    
    % PRESENT fixation cue
    tFixAcqCueOn = toggleobject([fix ptd], 'eventmarker', pic.fixOn);
    
    % WAIT for fixation and CHECK for hold in HOLD period
    [ontarget, ~, tFixAcq] = eyejoytrack(...
        'releasetarget', hold, holdRadius,...
        '~touchtarget',  hold, holdRadius + holdRadiusBuffer,...
        'acquirefix',    fix,  taskFixRadius,...
        fixInitPeriod);
    
    if ontarget(1) == 0
        % Error if monkey has released hold
        event   = [pic.holdOff pic.fixOff bhv.holdNotMaint];
        outcome = err.holdBreak; break
    elseif ontarget(2) == 1
        % Error if monkey touched outside
        event   = [pic.holdOff pic.fixOff bhv.holdOutside];
        outcome = err.holdOutside; break
    elseif ontarget(3) == 0
        % Error if monkey never looked inside fixRadius
        event   = [pic.holdOff pic.fixOff bhv.fixNotInit ];
        outcome = err.fixNil; break
    else
        % Correctly acquired fixation and held hold
        eventmarker([bhv.holdMaint bhv.fixInit]);
    end
    
    % CHECK hold and fixation in HOLD period (200ms to stabilize eye gaze)
    ontarget = eyejoytrack(...
        'releasetarget', hold, holdRadius,...
        '~touchtarget',  hold, holdRadius + holdRadiusBuffer,...
        'holdfix',       fix,  taskFixRadius,...
        fixHoldPeriod); 
    
    if ontarget(1) == 0
        % Error if monkey has released hold 
        event   = [pic.holdOff pic.fixOff bhv.holdNotMaint]; 
        outcome = err.holdBreak; break
    elseif ontarget(2) == 1
        % Error if monkey touched outside
        event   = [pic.holdOff pic.fixOff bhv.holdOutside]; 
        outcome = err.holdOutside; break
    elseif ontarget(3) == 0
        % Error if monkey went outside fixRadius
        event   = [pic.holdOff pic.sampleOff bhv.fixNotMaint]; 
        outcome = err.fixBreak; break
    else
        % Correctly held fixation & hold
        eventmarker([bhv.holdMaint bhv.fixMaint]);
    end    
    
    % REMOVE fixation cue and PRESENT search array
    tFixAcqCueOff = toggleobject([fix hold respOrder searchArray ptd],...
        'eventmarker', [pic.fixOff pic.sampleOn]);
    tSearchRespOn = tFixAcqCueOff;
    
    % WAIT for response in SEARCH period
    [chosenResp, ~, tBhvResp] = eyejoytrack(...
        'touchtarget',  respOrder, holdRadius,...
        '~touchtarget', hold,      holdRadius + holdRadiusBuffer,...
        searchPeriod);
    
    % REMOVE search array
    tSearchOff = toggleobject([searchArray ptd],...
        'eventmarker', pic.sampleOff);
    
    % WAIT for response if TEST period < RESP period
    if searchPeriod < respPeriod
        [chosenResp, ~, tBhvResp] = eyejoytrack(...
            'touchtarget',  respOrder, holdRadius,...
            '~touchtarget', hold,      holdRadius + holdRadiusBuffer,...
            (respPeriod - searchPeriod));
    end
    
    % RECORD reaction time
    rt = tBhvResp - tSearchRespOn;
    
    if chosenResp(1) == 0 && chosenResp(2) == 0
        % Error if no response from monkey
        event   = [pic.choiceOff bhv.respNil];
        outcome = err.respNil; break
    elseif chosenResp(1) == 0 && chosenResp(2) == 1
        % Error if monkey touched outside
        event   = [pic.choiceOff bhv.holdOutside];
        outcome = err.holdOutside; break
    elseif Info.expectedResponse == 0
        % Correct response by monkey on ambigous/free-choice trial
        event   = [pic.choiceOff bhv.respCorr rew.juice];
        outcome = err.respCorr; break
    elseif chosenResp(1) == Info.expectedResponse
        % Correct response by monkey
        event   = [pic.choiceOff bhv.respCorr rew.juice];
        outcome = err.respCorr; break   
    else
        % Wrong response by monkey
        event   = [pic.choiceOff bhv.respWrong];
        outcome = err.respWrong; break
    end
end

% SET trial outcome and remove all stimuli
trialerror(outcome);
tAllOff = toggleobject(1:12, 'status', 'off', 'eventmarker', event);

% TRIAL end
eventmarker(trl.stop);
TrialRecord.User.TrialStop(trialNum,:) = datevec(now);

% TRIAL end ------------------------------------------------------------------------------ 
% FOOTER start --------------------------------------------------------------------------- 

% REWARD monkey if correct response given
if outcome == err.holdNil
    % TRIAL not initiated; give good pause
    idle(goodPause);
elseif outcome == err.respCorr
    % CORRECT response; give reward, audCorr & good pause
    juiceConsumed = TrialRecord.Editable.rewardVol;
    goodmonkey(reward,...
        'juiceline',   rewardLine,...
        'numreward',   rewardReps,...
        'pausetime',   rewardRepsGap,...
        'nonblocking', 1);
    toggleobject(audCorr);
    idle(goodPause);
else
    % WRONG response; give audWrong & badpause
    toggleobject(audWrong);
    idle(badPause);
end

% ASSIGN trial footer eventmarkers
cTrial       = trl.trialShift       + TrialRecord.CurrentTrialNumber;
cBlock       = trl.blockShift       + TrialRecord.CurrentBlock;
cTrialWBlock = trl.trialWBlockShift + TrialRecord.CurrentTrialWithinBlock;
cCondition   = trl.conditionShift   + TrialRecord.CurrentCondition;
cTrialError  = trl.outcomeShift     + outcome;
cExpResponse = trl.expRespFree      + Info.expectedResponse;
cTrialFlag   = trl.typeShift;

if isfield(Info, 'trialFlag')
    cTrialFlag = cTrialFlag + Info.trialFlag;
end

% ASSIGN trial footer editable
cGoodPause        = trl.edtShift + TrialRecord.Editable.goodPause;
cBadPause         = trl.edtShift + TrialRecord.Editable.badPause;
cTaskFixRadius    = trl.edtShift + TrialRecord.Editable.taskFixRadius;
cCalFixRadius     = trl.edtShift + TrialRecord.Editable.calFixRadius;
cCalFixInitPeriod = trl.edtShift + TrialRecord.Editable.calFixInitPeriod;
cCalFixHoldPeriod = trl.edtShift + TrialRecord.Editable.calFixHoldPeriod;
cRewardVol        = trl.edtShift + TrialRecord.Editable.rewardVol*1000;

% FOOTER start marker
eventmarker(trl.footerStart);

% SEND footers
eventmarker(cTrial);      
eventmarker(cBlock);       
eventmarker(cTrialWBlock);
eventmarker(cCondition);  
eventmarker(cTrialError); 
eventmarker(cExpResponse);
eventmarker(cTrialFlag);

% EDITABLE start marker
eventmarker(trl.edtStart);

% SEND editable in following order
eventmarker(cGoodPause); 
eventmarker(cBadPause); 
eventmarker(cTaskFixRadius);
eventmarker(cCalFixRadius);
eventmarker(cCalFixInitPeriod); 
eventmarker(cCalFixHoldPeriod);
eventmarker(cRewardVol);

% EDITABLE stop marker
eventmarker(trl.edtStop);

% FOOTER end marker
eventmarker(trl.footerStop);

% SAVE to TrialRecord.user
TrialRecord.User.juiceConsumed(trialNum)      = juiceConsumed;
TrialRecord.User.responseCorrect(trialNum)    = outcome;
TrialRecord.User.expectedResponse(trialNum)   = Info.expectedResponse;
if exist('chosenResp','var')
    TrialRecord.User.chosenResponse(trialNum) = chosenResp(1);
else
    TrialRecord.User.chosenResponse(trialNum) = NaN;
end
TrialRecord.User.trialFlag(trialNum)          = Info.trialFlag;

% SAVE to Data.UserVars
bhv_variable(...
    'juiceConsumed',  juiceConsumed,  'tHoldButtonOn',   tHoldButtonOn,...
    'tTrialInit',     tTrialInit,     'tFixAcqCueOn',    tFixAcqCueOn,...
    'tFixAcq',        tFixAcq,        'tFixAcqCueOff',   tFixAcqCueOff,...
    'tSearchRespOn',  tSearchRespOn,  'tBhvResp',        tBhvResp,...
    'tSearchOff',     tSearchOff,     'tAllOff',         tAllOff);

% SEND check odd lines
eventmarker(chk.linesOdd);

% FOOTER end------------------------------------------------------------------------------
% DASHBOARD (customize as required)-------------------------------------------------------

lines       = fillDashboard(TrialData.VariableChanges, TrialRecord);
for lineNum = 1:length(lines)
    dashboard(lineNum, char(lines(lineNum, 1)), [1 1 1]);
end