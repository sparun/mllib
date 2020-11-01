% EYE CALIBRATION TRIAL for MonkeyLogic
% - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Presents a set of calibration points where animal has to fixate while pressing the hold
% button. Breaking of fixation/hold or touch outside of hold button will abort the trial.
%
% VERSION HISTORY
% - 14-Jun-2019 - Thomas  - First implementation
%                 Zhivago 
% - 03-Feb-2020 - Harish  - Added fixation contingency to sample on/off period
%                           Added serial data read and store
%                           Added touching outside hold buttons breaks trial
% - 10-Aug-2020 - Thomas  - Removed bulk adding of variables to TrialRecord.User
%                         - Simplified general code structure, specifically on errors
% - 14-Sep-2020 - Thomas  - General changes to code structure to improve legibilty
% - 14-Oct-2020 - Thomas  - Updated all eyejoytrack to absolute time and not rt
% - 29-Oct-2020 - Thomas  - combine calibration codes for template sd and fix 
%                           (only requirement for this was common editable var names) 
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
    'goodPause',   'badPause',      'fixRadius',...
    'fixPeriod',   'calHoldPeriod', 'calRandFlag',...
    'rewardVol',   'rewardLine',    'rewardReps',...
    'rewardRepsGap');
goodPause     = 200; 
badPause      = 1000; 
fixRadius     = 100; 
calFixPeriod  = 500; 
calHoldPeriod = 500; 
calRandFlag   = 1; 
rewardVol     = 0.2;
rewardLine    = 1;
rewardReps    = 1;
rewardRepsGap = 500; 

% PARAMETERS relevant for task timing and hold/fix control
initPeriod = Info.initPeriod;
holdRadius = TrialData.TaskObject.Attribute{1, 2}{1, 2};
reward     = ml_rewardVol2Time(rewardVol);

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

% CALIBRATION locations in DVA and group eventmarkers for easy indexing
calLocs  = [-8,-8; 8,8; 8,-8; -8,8];
calEvts  = [...
    pic.calib1On; pic.calib1Off; pic.calib2On;  pic.calib2Off;...
    pic.calib3On; pic.calib3Off; pic.calib4On;  pic.calib4Off;...
    pic.calib5On; pic.calib5Off; pic.calib6On;  pic.calib6Off;...
    pic.calib7On; pic.calib7Off; pic.calib8On;  pic.calib8Off;...
    pic.calib9On; pic.calib9Off; pic.calib10On; pic.calib10Off];

% RANDOMIZE the position of points if calRandFlag
if(calRandFlag)
    calLocs = calLocs(randperm(size(calLocs, 1)), :);
end

% DECLARE select timing and reward variables as NaN
tHoldButtonOn = NaN;
tTrialInit    = NaN;
tFixAcqCueOn  = NaN;
tFixAcq       = NaN;
tFixAcqCueOff = NaN;
tAllOff       = NaN;
juiceConsumed = NaN;

% HEADER end -----------------------------------------------------------------------------
% TRIAL start ----------------------------------------------------------------------------

% CHECK and proceed only if screen is not being touched
while istouching(), end
outcome = -1;

% SEND check even lines
eventmarker(chk.linesEven);

% TRIAL start
eventmarker(trl.start);

% RUN trial sequence till outcome registered
while outcome < 0
    % REPOSTITION the hold button
    reposition_object(hold, [28 0]);
    
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
           
    % LOOP for presenting calib at each selLoc
    for locID = 1:size(calLocs,1)
        reposition_object(calib, calLocs(locID,:));
        
        % PRESENT fixation cue
        tFixAcqCueOn(locID) = toggleobject([calib ptd], 'eventmarker', calEvts(locID*2-1));
    
        % WAIT for fixation and check for hold maintenance
        [ontarget, ~, tFixAcq(locID)] = eyejoytrack(...
            'releasetarget',hold,  holdRadius,...
            '~touchtarget', hold,  holdRadius,...
            'acquirefix',   calib, fixRadius,...
            calFixPeriod);
        
        if ontarget(1) == 0
            % Error if monkey has released hold            
            event   = [pic.holdOff calEvts(locID*2) bhv.holdNotMaint];  
            outcome = err.holdBreak; break
        elseif ontarget(2) == 1
            % Error if monkey touched outside
            event   = [pic.holdOff calEvts(locID*2) bhv.holdOutside]; 
            outcome = err.holdOutside; break
        elseif ontarget(3) == 0
            % Error if monkey never looked inside fixRadius
            event   = [pic.holdOff calEvts(locID*2) bhv.fixNotInit]; 
            outcome = err.fixNil; break
        else
            % Correctly acquired fixation and held hold
            eventmarker([bhv.holdMaint bhv.fixInit]);
        end
        
        % CHECK fixation and hold maintenance for fixationPeriod
        ontarget = eyejoytrack(...
            'releasetarget',hold,  holdRadius,...
            '~touchtarget', hold,  holdRadius,...
            'holdfix',      calib, fixRadius,...
            calHoldPeriod);
        
        if ontarget(1) == 0
            % Error if monkey has released hold 
            event   = [pic.holdOff calEvts(locID*2) bhv.holdNotMaint]; 
            outcome = err.holdBreak; break
        elseif ontarget(2) == 1
            % Error if monkey touched outside
            event   = [pic.holdOff calEvts(locID*2) bhv.holdOutside]; 
            outcome = err.holdOutside; break
        elseif ontarget(3) == 0
            % Error if monkey went outside fixRadius
            event   = [pic.holdOff calEvts(locID*2) bhv.fixNotMaint]; 
            outcome = err.fixBreak; break
        else
            % Correctly held fixation & hold
            eventmarker([bhv.holdMaint bhv.fixMaint]);
        end
        
        % REMOVE the calibration image image off
        tFixAcqCueOff(locID) = toggleobject(calib, 'eventmarker', calEvts(locID*2));
    end
    
    % TRIAL finished successfully if this point reached on last item
    if locID == size(calLocs,1)
        event   = [pic.holdOff bhv.respCorr rew.juice];
        outcome = err.respCorr;
    end
end

% SET trial outcome and remove all stimuli
trialerror(outcome);
tAllOff = toggleobject(1:10, 'status', 'off', 'eventmarker', event);

% TRIAL end
eventmarker(trl.stop);

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
cTrialFlag   = trl.typeShift;

if isfield(Info, 'trialFlag')
    cTrialFlag = cTrialFlag + Info.trialFlag;
end

% ASSIGN trial footer editable
cGoodPause     = trl.edtShift + TrialRecord.Editable.goodPause;
cBadPause      = trl.edtShift + TrialRecord.Editable.badPause;
cFixRadius     = trl.edtShift + TrialRecord.Editable.fixRadius;
cFixPeriod     = trl.edtShift + TrialRecord.Editable.fixPeriod;
cCalHoldPeriod = trl.edtShift + TrialRecord.Editable.calHoldPeriod;
cRewardVol     = trl.edtShift + TrialRecord.Editable.rewardVol*1000;

% FOOTER start 
eventmarker(trl.footerStart);

% FOOTER information
eventmarker(cTrial);     
eventmarker(cBlock);     
eventmarker(cTrialWBlock);
eventmarker(cCondition); 
eventmarker(cTrialError); 
eventmarker(cTrialFlag);

% SEND editable in following order
eventmarker(cGoodPause); 
eventmarker(cBadPause); 
eventmarker(cFixRadius);
eventmarker(cFixPeriod); 
eventmarker(cCalHoldPeriod);
eventmarker(cRewardVol);

% EDITABLE stop marker
eventmarker(trl.edtStop);

% FOOTER end 
eventmarker(trl.footerStop);

% SAVE to TrialRecord.user
TrialRecord.User.juiceConsumed(trialNum)    = juiceConsumed;
TrialRecord.User.responseCorrect(trialNum)  = outcome;
TrialRecord.User.expectedResponse(trialNum) = NaN;
TrialRecord.User.trialFlag(trialNum)        = NaN;

% SAVE to Data.UserVars
bhv_variable(...
    'juiceConsumed', juiceConsumed, 'tHoldButtonOn', tHoldButtonOn,...
    'tTrialInit',    tTrialInit,    'tFixAcqCueOn',  tFixAcqCueOn,...
    'tFixAcq',       tFixAcq,       'tFixAcqCueOff', tFixAcqCueOff,...
    'tAllOff',       tAllOff);

% SEND check odd lines
eventmarker(chk.linesOdd);

% FOOTER end------------------------------------------------------------------------------
% DASHBOARD (customize as required)-------------------------------------------------------

lines       = fillDashboard(TrialData.VariableChanges, TrialRecord.User);
for lineNum = 1:length(lines)
    dashboard(lineNum, char(lines(lineNum, 1)), [1 1 1]);
end