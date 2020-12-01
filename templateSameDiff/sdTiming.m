% SAME-DIFF TRIAL for MonkeyLogic 
% - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Presents a sample and test image at the center of the screen but separated temporally.
% Provides two touch button on the right side (from subjects' POV) as responses:
%   - Top button for 'same' response, and
%   - Bottom button for 'diff' response.
%
% VERSION HISTORY
% - 14-Jun-2019 - Thomas  - First implementation
%                 Zhivago
% - 03-Feb-2020 - Harish  - Added fixation contingency to hold and sample on/off period
%                         - Added serial data read and store
%                         - Added trial break when dragging hand
% - 07-Mar-2020 - Thomas  - Added separation of hold and fixation error types
%                 Georgin - Flipped button order for JuJu
%                         - Sending footer information as eventmarker()
%                         - Dashboard outsourced to function fillDashboard()
% - 10-Aug-2020 - Thomas  - Removed bulk adding of variables to TrialRecord.User
%                         - Simplified general code structure, specifically on errors
% - 14-Sep-2020 - Thomas  - General changes to code structure to improve legibilty
% - 14-Oct-2020 - Thomas  - Updated all eyejoytrack to absolute time and not rt
% ----------------------------------------------------------------------------------------
% HEADER start ---------------------------------------------------------------------------

% CHECK if touch and eyesignal are present to continue
if ~ML_touchpresent, error('This task requires touch signal input!'); end
if ~ML_eyepresent,   error('This task requires eye signal input!');   end

% REMOVE the joystick cursor
showcursor(false);

% POINTER to trial number
trialNum = TrialRecord.CurrentTrialNumber;

% ITI (set to 0 to measure true ITI in ML Dashboard)
set_iti(0);

% EDITABLE variables that can be changed during the task
editable(...
    'goodPause',    'badPause',     'taskFixRadius',...
    'calFixRadius', 'calFixPeriod', 'calFixHoldPeriod', 'calFixRandFlag',...
    'rewardVol',    'rewardLine',   'rewardReps',       'rewardRepsGap');
goodPause        = 200;
badPause         = 1000;
taskFixRadius    = 12;
calFixRadius     = 6; 
calFixPeriod     = 500;
calFixHoldPeriod = 200; 
calFixRandFlag   = 1; 
rewardVol        = 0.2;
rewardLine       = 1;
rewardReps       = 1;
rewardRepsGap    = 500;

% PARAMETERS relevant for task timing and hold/fix control
initPeriod   = Info.initPeriod;
holdPeriod   = Info.holdPeriod;
holdRadius   = TrialData.TaskObject.Attribute{1, 2}{1, 2};
samplePeriod = Info.samplePeriod;
delayPeriod  = Info.delayPeriod;
testPeriod   = Info.testPeriod;
respPeriod   = Info.respPeriod;
reward       = ml_rewardVol2Time(rewardVol);

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
ptd      = 1; 
hold     = 2;
fix      = 3; 
calib    = 4; 
audCorr  = 5; 
audWrong = 6; 
same     = 7;
diff     = 8; 
sample   = 9; 
test     = 10;

% SET response button order for SD task
if ~isfield(TrialRecord.User, 'respOrder')
    if strcmpi(MLConfig.SubjectName, 'didi') == 1 || strcmpi(MLConfig.SubjectName, 'test') == 1
        TrialRecord.User.respOrder = [same diff];
    elseif strcmpi(MLConfig.SubjectName, 'juju') == 1 || strcmpi(MLConfig.SubjectName, 'coco') == 1
        TrialRecord.User.respOrder = [same diff];
    end
end
respOrder = TrialRecord.User.respOrder;

% DECLARE select timing and reward variables as NaN
tHoldButtonOn   = NaN;
tTrialInit      = NaN;
tFixAcqCueOn    = NaN;
tFixAcq         = NaN;
tFixAcqCueOff   = NaN;
tSampleOn       = NaN;
tSampleOff      = NaN;
tFixMaintCueOn  = NaN;
tFixMaintCueOff = NaN;
tTestRespOn     = NaN;
tBhvResp        = NaN;
tTestOff        = NaN;
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
        '~touchtarget', hold, holdRadius,...
        initPeriod);
    
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
        '~touchtarget',  hold, holdRadius,...
        'acquirefix',    fix,  taskFixRadius,...
        holdPeriod);
    
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
    
    % CHECK hold and fixation in HOLD period
    ontarget = eyejoytrack(...
        'releasetarget', hold, holdRadius,...
        '~touchtarget',  hold, holdRadius,...
        'holdfix',    fix,  taskFixRadius,...
        holdPeriod);
    
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
    
    % REMOVE fixation cue and PRESENT sample image
    tFixAcqCueOff = toggleobject([fix sample ptd], 'eventmarker', [pic.fixOff pic.sampleOn]);
    tSampleOn     = tFixAcqCueOff;
    
    % CHECK hold and fixation in SAMPLE ON period
    ontarget = eyejoytrack(...
        'releasetarget', hold,   holdRadius,...
        '~touchtarget',  hold,   holdRadius,...
        'holdfix',       sample, taskFixRadius,...
        samplePeriod);
    
    if ontarget(1) == 0
        % Error if monkey has released hold
        event   = [pic.holdOff pic.sampleOff bhv.holdNotMaint];
        outcome = err.holdBreak; break
    elseif ontarget(2) == 1
        % Error if monkey touched outside
        event   = [pic.holdOff pic.sampleOff bhv.holdOutside];
        outcome = err.holdOutside; break
    elseif ontarget(3) == 0
        % Error if monkey went outside fixRadius
        event   = [pic.holdOff pic.sampleOff bhv.fixNotMaint];
        outcome = err.fixBreak; break
    else
        % Correctly held fixation & hold
        eventmarker([bhv.holdMaint bhv.fixMaint]);
    end
    
    % REMOVE sample image and PRESENT fixation cue
    tSampleOff     = toggleobject([sample fix ptd], 'eventmarker', [pic.sampleOff pic.fixOn]);
    tFixMaintCueOn = tSampleOff;
    
    % CHECK hold and fixation in DELAY period
    ontarget = eyejoytrack('releasetarget', hold, holdRadius,...
        '~touchtarget', hold, holdRadius, 'holdfix', fix, taskFixRadius, delayPeriod);
    
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
        event   = [pic.holdOff pic.fixOff bhv.fixNotMaint];
        outcome = err.fixBreak; break
    else
        % Correctly held fixation & hold
        eventmarker([bhv.holdMaint bhv.fixMaint]);
    end
    
    % REMOVE fixation cue and PRESENT test and response buttons
    tFixMaintCueOff = toggleobject([fix hold test same diff ptd], 'eventmarker',...
        [pic.fixOff pic.holdOff pic.choiceOn pic.testOn]);
    tTestRespOn     = tFixMaintCueOff;
    
    % WAIT for response in TEST ON period
    [chosenResp, ~, tBhvResp] = eyejoytrack(...
        'touchtarget',  respOrder, holdRadius,...
        '~touchtarget', hold,      holdRadius,...
        testPeriod);
    
    % REMOVE test image
    tTestOff = toggleobject([test ptd],'eventmarker', pic.testOff);
    
    % WAIT for response if TEST period < RESP period
    if testPeriod < respPeriod
        [chosenResp, ~, tBhvResp] = eyejoytrack('touchtarget', respOrder, holdRadius,...
            '~touchtarget', hold, holdRadius, (respPeriod - testPeriod));
    end
    
    % RECORD reaction time
    rt = tBhvResp - tTestRespOn;
    
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
tAllOff = toggleobject(1:10, 'status', 'off', 'eventmarker', event);

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
cCalFixPeriod     = trl.edtShift + TrialRecord.Editable.calFixPeriod;
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
eventmarker(cCalFixPeriod); 
eventmarker(cCalFixHoldPeriod);
eventmarker(cRewardVol);

% EDITABLE stop marker
eventmarker(trl.edtStop);

% FOOTER end marker
eventmarker(trl.footerStop);

% SAVE to TrialRecord.user
TrialRecord.User.juiceConsumed(trialNum)    = juiceConsumed;
TrialRecord.User.responseCorrect(trialNum)  = outcome;
TrialRecord.User.expectedResponse(trialNum) = Info.expectedResponse;
TrialRecord.User.trialFlag(trialNum)        = Info.trialFlag;

% SAVE to Data.UserVars
bhv_variable(...
    'juiceConsumed',  juiceConsumed,  'tHoldButtonOn',   tHoldButtonOn,...
    'tTrialInit',     tTrialInit,     'tFixAcqCueOn',    tFixAcqCueOn,...
    'tFixAcq',        tFixAcq,        'tFixAcqCueOff',   tFixAcqCueOff,...
    'tSampleOn',      tSampleOn,      'tSampleOff',      tSampleOff,...
    'tFixMaintCueOn', tFixMaintCueOn, 'tFixMaintCueOff', tFixMaintCueOff,...
    'tTestRespOn',    tTestRespOn,    'tBhvResp',        tBhvResp,...
    'tTestOff',       tTestOff,       'tAllOff',         tAllOff);

% SEND check odd lines
eventmarker(chk.linesOdd);

% FOOTER end------------------------------------------------------------------------------
% DASHBOARD (customize as required)-------------------------------------------------------

lines       = fillDashboard(TrialData.VariableChanges, TrialRecord.User);
for lineNum = 1:length(lines)
    dashboard(lineNum, char(lines(lineNum, 1)), [1 1 1]);
end