% EYE CALIBRATION TRIAL for MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Presents a set of calibration points where animal has to fixate while pressing the hold
% button. Breaking of fixation/hold or touch outside of hold button will abort the trial.
%
% VERSION HISTORY
%   14-Jun-2019 - Thomas  - First implementation
%                 Zhivago 
%   03-Feb-2020 - Harish  - Added fixation contingency to sample on/off period
%                           Added serial data read and store
%                           Added touching outside hold buttons breaks trial
%   10-Aug-2020 - Thomas  - Removed bulk adding of variables to TrialRecord.User
%                         - Simplified general code structure, specifically on errors
%   14-Sep-2020 - Thomas  - General changes to code structure to improve legibilty
%   14-Oct-2020 - Thomas  - Updated all eyejoytrack to absolute time and not rt
%   29-Oct-2020 - Thomas  - combine calibration codes for template sd and fix 
%                           (only requirement for this was common editable var names) 
%   31-Dec-2020 - Thomas  - Updated editable names and implemented holdRadiusBuffer
%   03-Nov-2021 - Thomas  - Included wmFixCue TaskObject in conditions file
%                 Georgin
%   30-Jan-2023 - Thomas  - Toggling photodiodeCue for last calibOff and separating it
%                 Arun      from holdOff by calFixWrapPeriod. Removed calibration task
%                           timing related info from editables and all undocumented task
%                           related variables are being stored in data.UserVars
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
set_iti(500);

% EDITABLE variables that can be changed during the task
editable('goodPause', 'badPause','taskFixRadius', 'calFixRadius', 'rewardVol');
goodPause        = 200;
badPause         = 500;
taskFixRadius    = 8;
calFixRadius     = 8;
rewardVol        = 0.2;

% PARAMETERS relevant for task timing and hold/fix control
holdInitPeriod   = Info.holdInitPeriod;
holdRadius       = TrialData.TaskObject.Attribute{1, 2}{1, 2};
holdRadiusBuffer = 2;
calFixInitPeriod = 500;
calFixHoldPeriod = 300;
calFixWrapPeriod = 50;
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

% NUMBER of TaskObjects
nTaskObjects  = length(TaskObject);

% POINTERS to TaskObjects
photodiodeCue = 1; 
holdButton    = 2;
calibCue      = 5; 
audioCorr     = 6; 
audioWrong    = 7; 

% CALIBRATION locations in DVA and group eventmarkers for easy indexing
calLocs  = [-8,-8; 8,8; 8,-8; -8,8];
calEvts  = [...
    pic.calib1On; pic.calib1Off; pic.calib2On;  pic.calib2Off;...
    pic.calib3On; pic.calib3Off; pic.calib4On;  pic.calib4Off;...
    pic.calib5On; pic.calib5Off; pic.calib6On;  pic.calib6Off;...
    pic.calib7On; pic.calib7Off; pic.calib8On;  pic.calib8Off;...
    pic.calib9On; pic.calib9Off; pic.calib10On; pic.calib10Off];

% RANDOMIZE the position of points if calRandFlag
calLocs = calLocs(randperm(size(calLocs, 1)), :);

% DECLARE select timing and reward variables as NaN
tHoldButtonOn = NaN;
tTrialInit    = NaN;
tFixAcqCueOn  = NaN(size(calLocs, 1), 1);
tFixAcq       = NaN(size(calLocs, 1), 1);
tFixAcqCueOff = NaN(size(calLocs, 1), 1);
tAllOff       = NaN;
juiceConsumed = NaN;

% HEADER end -----------------------------------------------------------------------------
% TRIAL start ----------------------------------------------------------------------------

% CHECK and proceed only if screen is not being touched
while istouching(), end
outcome = -1;

% TEMPORARY variable that contains the stims visible to monkey on the screen (except ptd)
visibleStims = [];

% SEND check even lines
eventmarker(chk.linesEven);

% TRIAL start
eventmarker(trl.start);
TrialRecord.User.TrialStart(trialNum,:) = datevec(now);

% RUN trial sequence till outcome registered
while outcome < 0
    % REPOSTITION the hold button
    reposition_object(holdButton, [28 0]);
    
    % PRESENT hold button
    tHoldButtonOn = toggleobject([holdButton photodiodeCue], 'eventmarker', pic.holdOn);
    visibleStims  = holdButton;
    
    % WAIT for touch in INIT period
    [ontarget, ~, tTrialInit] = eyejoytrack(...
        'touchtarget',  holdButton, holdRadius,...
        '~touchtarget', holdButton, holdRadius + holdRadiusBuffer,...
        holdInitPeriod);

    if(sum(ontarget) == 0)
        % Error if there's no touch anywhere
        event   = [bhv.holdNotInit pic.holdOff];
        outcome = err.holdNil; break
    elseif ontarget(2) == 1
        % Error if any touch outside hold button
        event   = [bhv.holdOutside pic.holdOff];
        outcome = err.holdOutside; break
    else
        % Correctly initiated hold
        eventmarker(bhv.holdInit);
    end
           
    % LOOP for presenting calib at each selLoc
    for locID = 1:size(calLocs,1)
        reposition_object(calibCue, calLocs(locID,:));
        
        % PRESENT fixation cue
        tFixAcqCueOn(locID) = toggleobject([calibCue photodiodeCue], 'eventmarker', calEvts(locID*2-1));
        visibleStims        = [holdButton calibCue];
        
        % WAIT for fixation and check for hold maintenance
        [ontarget, ~, tFixAcq(locID)] = eyejoytrack(...
            'releasetarget',holdButton,  holdRadius,...
            '~touchtarget', holdButton,  holdRadius + holdRadiusBuffer,...
            'acquirefix',   calibCue, calFixRadius,...
            calFixInitPeriod);
        
        if ontarget(1) == 0
            % Error if monkey has released hold            
            event   = [bhv.holdNotMaint pic.holdOff calEvts(locID*2)];
            outcome = err.holdBreak; break
        elseif ontarget(2) == 1
            % Error if monkey touched outside
            event   = [bhv.holdOutside pic.holdOff calEvts(locID*2)]; 
            outcome = err.holdOutside; break
        elseif ontarget(3) == 0
            % Error if monkey never looked inside fixRadius
            event   = [bhv.fixNotInit pic.holdOff calEvts(locID*2)]; 
            outcome = err.fixNil; break
        else
            % Correctly acquired fixation and held hold
            eventmarker([bhv.holdMaint bhv.fixInit]);
        end
        
        % CHECK fixation and hold maintenance for fixationPeriod
        ontarget = eyejoytrack(...
            'releasetarget',holdButton,  holdRadius,...
            '~touchtarget', holdButton,  holdRadius + holdRadiusBuffer,...
            'holdfix',      calibCue, calFixRadius,...
            calFixHoldPeriod);
        
        if ontarget(1) == 0
            % Error if monkey has released hold 
            event   = [bhv.holdNotMaint pic.holdOff calEvts(locID*2)]; 
            outcome = err.holdBreak; break
        elseif ontarget(2) == 1
            % Error if monkey touched outside
            event   = [bhv.holdOutside pic.holdOff calEvts(locID*2)]; 
            outcome = err.holdOutside; break
        elseif ontarget(3) == 0
            % Error if monkey went outside fixRadius
            event   = [bhv.fixNotMaint pic.holdOff calEvts(locID*2)]; 
            outcome = err.fixBreak; break
        else
            % Correctly held fixation & hold
            eventmarker([bhv.holdMaint bhv.fixMaint]);
        end
        
        if locID ~= size(calLocs,1)
            % REMOVE the calibration image image off and continue the trial
            tFixAcqCueOff(locID) = toggleobject(calibCue, 'eventmarker', calEvts(locID*2));
            visibleStims         = holdButton;
        else
            % REMOVE the calibration image image off and toggle photodiode cue as
            % calibration completed successfully
            tFixAcqCueOff(locID) = toggleobject([calibCue photodiodeCue], 'eventmarker', calEvts(locID*2));
            visibleStims         = holdButton;
        end
    end
    
    % TRIAL finished successfully if all stims fixated correctly
    if outcome < 0
        event   = [bhv.respCorr pic.holdOff rew.juice]; % Seding pic.holdOff first to
        outcome = err.respCorr;
    end
end

% WAIT for some period so we have a temporal difference between the last calibOff and
% holdButtonOff
idle(calFixWrapPeriod);

% SET trial outcome and remove all visible stimuli
trialerror(outcome);
tAllOff = toggleobject([visibleStims photodiodeCue], 'eventmarker', event);

% REWARD monkey if correct response given
if outcome == err.holdNil
    % TRIAL not initiated; give good pause
    idle(goodPause);
elseif outcome == err.respCorr
    % CORRECT response; give reward, audCorr & good pause
    juiceConsumed = TrialRecord.Editable.rewardVol;
    goodmonkey(reward,'juiceline', 1,'numreward', 1,'pausetime', 1, 'nonblocking', 1);
    toggleobject(audioCorr);
    idle(goodPause);
else
    % WRONG response; give audWrong & badpause
    toggleobject(audioWrong);
    idle(badPause);
end

% TRIAL end
eventmarker(trl.stop);
TrialRecord.User.TrialStop(trialNum,:) = datevec(now);

% SEND check odd lines
eventmarker(chk.linesOdd);

% TURN photodiode (and all stims) state to off at end of trial. Basically, all other
% items will be off by now. This line is to clear photodiode explicitely.
toggleobject(1:nTaskObjects, 'status', 'off');

% TRIAL end ------------------------------------------------------------------------------ 
% FOOTER start --------------------------------------------------------------------------- 

% ASSIGN trial footer eventmarkers
cTrial       = trl.trialShift       + TrialRecord.CurrentTrialNumber;
cBlock       = trl.blockShift       + TrialRecord.CurrentBlock;
cTrialWBlock = trl.trialWBlockShift + TrialRecord.CurrentTrialWithinBlock;
cCondition   = trl.conditionShift   + TrialRecord.CurrentCondition;
cTrialError  = trl.outcomeShift     + outcome;
cExpResponse = exp.nan;
cTrialFlag   = trl.typeShift;

if isfield(Info, 'trialFlag')
    cTrialFlag = cTrialFlag + Info.trialFlag;
end

% ASSIGN trial footer editable
cGoodPause        = trl.shift + TrialRecord.Editable.goodPause;
cBadPause         = trl.shift + TrialRecord.Editable.badPause;
cTaskFixRadius    = trl.shift + TrialRecord.Editable.taskFixRadius*10;
cCalFixRadius     = trl.shift + TrialRecord.Editable.calFixRadius*10;
cRewardVol        = trl.shift + TrialRecord.Editable.rewardVol*1000;

% PREPARE stim info - sets of stim ID, stimPosX and stimPosY to transmit
cCalIDLocs = nan(1,(size(calLocs,1) + numel(calLocs)));
count      = 1;

for calLocsR = 1:size(calLocs,1)
    % ADD nan as stim ID
    cCalIDLocs(count) = exp.nan;
    count             = count + 1;
    
    % ADD stim X Y positions
    for calLocsC =1:size(calLocs,2)
        cCalIDLocs(count) = trl.picPosShift + calLocs(calLocsR,calLocsC)*1000;
        count             = count + 1;
    end
end

% FOOTER start marker
eventmarker(trl.footerStart);

% INDICATE type of trial run
eventmarker(trl.taskCal);

% SEND footers
eventmarker([cTrial cBlock cTrialWBlock cCondition cTrialError cExpResponse cTrialFlag]);      

% EDITABLE start marker
eventmarker(trl.edtStart);

% SEND editable in following order
eventmarker([cGoodPause cBadPause cTaskFixRadius cCalFixRadius cRewardVol]);

% EDITABLE stop marker
eventmarker(trl.edtStop);

% STIM INFO start marker
eventmarker(trl.stimStart);

% SEND calib point locations
eventmarker(cCalIDLocs);

% STIM INFO start marker
eventmarker(trl.stimStop);

% FOOTER end marker
eventmarker(trl.footerStop);

% SAVE to TrialRecord.user
TrialRecord.User.trialFlag(trialNum)        = NaN;
TrialRecord.User.expectedResponse(trialNum) = NaN;
TrialRecord.User.chosenResponse(trialNum)   = NaN;
TrialRecord.User.responseCorrect(trialNum)  = outcome;
TrialRecord.User.juiceConsumed(trialNum)    = juiceConsumed;

% SAVE to Data.UserVars
bhv_variable(...
    'holdRadiusBuffer', holdRadiusBuffer, 'calFixInitPeriod', calFixInitPeriod,...
    'calFixHoldPeriod', calFixHoldPeriod, 'calFixWrapPeriod', calFixWrapPeriod,...
    'juiceConsumed',    juiceConsumed,    'tHoldButtonOn',    tHoldButtonOn,...
    'tTrialInit',       tTrialInit,       'tFixAcqCueOn',     tFixAcqCueOn,...
    'tFixAcq',          tFixAcq,          'tFixAcqCueOff',    tFixAcqCueOff,...
    'tAllOff',          tAllOff);

% FOOTER end------------------------------------------------------------------------------
% DASHBOARD (customize as required)-------------------------------------------------------

lines       = fillDashboard(TrialData.VariableChanges, TrialRecord);
for lineNum = 1:length(lines)
    dashboard(lineNum, char(lines(lineNum, 1)), [1 1 1]);
end