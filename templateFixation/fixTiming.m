% FIXATION TRIAL for Monkeylogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Presents a series of images at center where animal has to fixate while pressing the hold
% button. Breaking of fixation/hold or touch outside of hold button will abort the trial.
% 
% VERSION HISTORY
%   02-Sep-2020 - Thomas  - First implementation
%   14-Sep-2020 - Thomas  - Updated codes with new implementation of event and error
%                           codes. Simplified code structure and other changes.
%   14-Oct-2020 - Thomas  - Updated all eyejoytrack to absolute time and not rt
%   29-Oct-2020 - Thomas  - Updated to match the version of templateSD
%   31-Dec-2020 - Thomas  - Updated editable names and implemented holdRadiusBuffer and
%                           accomodated code for stimOffPeriod of 0
%   03-Nov-2021 - Thomas  - Updated to deal with wmFixCue
%   05-Nov-2021 - Thomas  - wmFixCue renamed to generalized stimFixFlag, option to show
%                 Georgin   fixCue throughout trial introduced.
%   30-Jan-2023 - Thomas  - Removed calibration task timing related info from editables 
%                 Arun      and all undocumented task related variables are being stored
%                           in data.UserVars
% ----------------------------------------------------------------------------------------

% HEADER start ---------------------------------------------------------------------------

% CHECK if touch and eyesignal are present to continue------------------------------------
if ~ML_touchpresent, error('This task requires touch signal input!'); end
if ~ML_eyepresent,   error('This task requires eye signal input!');   end

% REMOVE the joystick cursor
showcursor(false);

% POINTER to trial number
trialNum = TrialRecord.CurrentTrialNumber;

% ITI (set to 0 to measure true ITI in ML Dashboard)
set_iti(500);

% EDITABLE variables that can be changed during the task
editable(...
    'goodPause',      'badPause',...
    'taskFixRadius',  'calFixRadius',   'rewardVol');
goodPause        = 200;
badPause         = 1000;
taskFixRadius    = 10;
calFixRadius     = 8;
rewardVol        = 0.2;

% PARAMETERS relevant for task timing and hold/fix control
holdInitPeriod   = Info.holdInitPeriod;
fixInitPeriod    = Info.fixInitPeriod;
fixHoldPeriod    = 300;
holdRadius       = TrialData.TaskObject.Attribute{1, 2}{1, 2};
holdRadiusBuffer = 2;
stimOnPeriod     = Info.stimOnPeriod;
stimOffPeriod    = Info.stimOffPeriod;
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
photodiodeCue = 1;  holdButton = 2;  initFixCue = 3;  stimFixCue = 4;
calibCue      = 5;  audioCorr  = 6;  audioWrong = 7;  stim1      = 8;
stim2         = 9;  stim3      = 10; stim4      = 11; stim5      = 12;
stim6         = 13; stim7      = 14; stim8      = 15; stim9      = 16;
stim10        = 17; 

% GROUP TaskObjects and eventmarkers for easy indexing
selStim = [stim1; stim2; stim3; stim4; stim5; stim6; stim7; stim8; stim9; stim10];
selEvts  = [...
    pic.stim1On; pic.stim1Off; pic.stim2On;  pic.stim2Off;...
    pic.stim3On; pic.stim3Off; pic.stim4On;  pic.stim4Off;...
    pic.stim5On; pic.stim5Off; pic.stim6On;  pic.stim6Off;...
    pic.stim7On; pic.stim7Off; pic.stim8On;  pic.stim8Off;...
    pic.stim9On; pic.stim9Off; pic.stim10On; pic.stim10Off];

% HANDLE reordering of stimFixCue above or below stims
if Info.stimFixCueAboveStimFlag
    TaskObject.Zorder(stimFixCue) = 1;
    TaskObject.Zorder(selStim) = 0;
else
    TaskObject.Zorder(stimFixCue) = 0;
    TaskObject.Zorder(selStim) = 1;
end

% DECLARE select timing and reward variables as NaN
tHoldButtonOn = NaN;
tTrialInit    = NaN;
tFixCueOn     = NaN(Info.imgPerTrial+1, 1);
tFixAcq       = NaN;
tFixCueOff    = NaN(Info.imgPerTrial+1, 1);
tStimOn       = NaN(Info.imgPerTrial, 1);
tStimOff      = NaN(Info.imgPerTrial, 1);
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
    % PRESENT hold button
    tHoldButtonOn = toggleobject([holdButton photodiodeCue], 'eventmarker', pic.holdOn);
    visibleStims  = holdButton;
    
    % WAIT for touch in INIT period
    [ontarget, ~, tTrialInit] = eyejoytrack(...
        'touchtarget',  holdButton, holdRadius, ...
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
    
    % PRESENT fixation cue
    tFixCueOn(1,:) = toggleobject([initFixCue photodiodeCue], 'eventmarker', pic.fixOn);
    visibleStims   = [holdButton initFixCue];
    
    % WAIT for fixation and CHECK for hold in HOLD period
    [ontarget, ~, tFixAcq] = eyejoytrack(...
        'releasetarget', holdButton, holdRadius,...
        '~touchtarget',  holdButton, holdRadius + holdRadiusBuffer,...
        'acquirefix',    initFixCue, taskFixRadius,...
        fixInitPeriod);
    
    if ontarget(1) == 0
        % Error if monkey has released hold
        event   = [bhv.holdNotMaint pic.holdOff pic.fixOff];
        outcome = err.holdBreak; break
    elseif ontarget(2) == 1
        % Error if monkey touched outside
        event   = [bhv.holdOutside pic.holdOff pic.fixOff];
        outcome = err.holdOutside; break
    elseif ontarget(3) == 0
        % Error if monkey never looked inside fixRadius
        event   = [bhv.fixNotInit pic.holdOff pic.fixOff];
        outcome = err.fixNil; break
    else
        % Correctly acquired fixation and held hold
        eventmarker([bhv.holdMaint bhv.fixInit]);
    end
    
    % CHECK hold and fixation in FIXHOLD period (to stabilize eye gaze)
    ontarget = eyejoytrack(...
        'releasetarget', holdButton, holdRadius,...
        '~touchtarget',  holdButton, holdRadius + holdRadiusBuffer,...
        'holdfix',       initFixCue, taskFixRadius,...
        fixHoldPeriod);
    
    if ontarget(1) == 0
        % Error if monkey released hold
        event   = [bhv.holdNotMaint pic.holdOff pic.fixOff];
        outcome = err.holdBreak; break
    elseif ontarget(2) == 1
        % Error if monkey touched outside
        event   = [bhv.holdOutside pic.holdOff pic.fixOff];
        outcome = err.holdOutside; break
    elseif ontarget(3) == 0
        % Error if monkey went outside fixRadius
        event   = [bhv.fixNotMaint pic.holdOff pic.fixOff];
        outcome = err.fixBreak; break
    else
        % Correctly held fixation & hold
        eventmarker([bhv.holdMaint bhv.fixMaint]);
    end
    
    % LOOP for presenting stim - here initFixCue is removed and stimFixCue is kept on
    % till end of trials. The dynamics of visibility of stimFixCue are determined by
    % variables Info.stimFixCueAboveStimFlag and the inherent color of stimFixCue as
    % determined when creating conditions file
    for itemID = 1:Info.imgPerTrial
        % CHECK if first stim, if not then stimOffPeriod > 0
        if itemID == 1
            % REMOVE init fixation cue & PRESENT stimFixCue and stimulus
            tFixCueOff(itemID,:) = toggleobject([initFixCue stimFixCue selStim(itemID) photodiodeCue],...
                'eventmarker', [pic.fixOff selEvts(2*itemID)-1]);
            tStimOn(itemID,:)  = tFixCueOff(itemID,:);
            visibleStims       = [holdButton stimFixCue selStim(itemID)];
        elseif stimOffPeriod > 0
            % PRESENT stimulus
            tFixCueOff(itemID,:) = toggleobject([selStim(itemID) photodiodeCue],...
                'eventmarker', [pic.fixOff selEvts(2*itemID)-1]);
            tStimOn(itemID,:)  = tFixCueOff(itemID,:);
            visibleStims       = [holdButton stimFixCue selStim(itemID)];
        else
            % REMOVE previous stimulus and present current stimulus
            tStimOn(itemID,:) = toggleobject([selStim(itemID-1) selStim(itemID) photodiodeCue],...
                'eventmarker', [selEvts(2*itemID)-2 selEvts(2*itemID)-1]);
            tStimOff(itemID-1,:) = tStimOn(itemID,:);
            visibleStims         = [holdButton stimFixCue selStim(itemID)];
        end
        
        % CHECK fixation and hold maintenance for stimOnPeriod
        ontarget = eyejoytrack(...
            'releasetarget', holdButton, holdRadius,...
            '~touchtarget',  holdButton, holdRadius + holdRadiusBuffer,...
            'holdfix',       stimFixCue, taskFixRadius,...
            stimOnPeriod);
        
        if ontarget(1) == 0
            % Error if monkey released hold
            event   = [bhv.holdNotMaint pic.holdOff selEvts(2*itemID)];
            outcome = err.holdBreak; break
        elseif ontarget(2) == 1
            % Error if monkey touched outside
            event   = [bhv.holdOutside pic.holdOff selEvts(2*itemID)];
            outcome = err.holdOutside; break
        elseif ontarget(3) == 0
            % Error if monkey went outside fixRadius
            event   = [bhv.fixNotMaint pic.holdOff selEvts(2*itemID)];
            outcome = err.fixBreak; break
        else
            % Correctly held fixation & hold
            eventmarker([bhv.holdMaint bhv.fixMaint]);
        end
        
        % CHECK if stimOffPeriod > 0
        if stimOffPeriod > 0
            % REMOVE stimulus & PRESENT WM fixation cue
            tStimOff(itemID,:)  = toggleobject([selStim(itemID) photodiodeCue],...
                'eventmarker', [selEvts(2*itemID)]);
            tFixCueOn(itemID+1,:) = tStimOff(itemID,:);
            visibleStims          = [holdButton stimFixCue];
            
            % CHECK fixation and hold maintenance for stimOffPeriod
            ontarget = eyejoytrack(...
                'releasetarget',holdButton, holdRadius,...
                '~touchtarget', holdButton, holdRadius + holdRadiusBuffer,...
                'holdfix',      stimFixCue,   taskFixRadius,...
                stimOffPeriod);
            
            if ontarget(1) == 0
                % Error if monkey released hold
                event   = [bhv.holdNotMaint pic.holdOff];
                outcome = err.holdBreak; break
            elseif ontarget(2) == 1
                % Error if monkey touched outside
                event   = [bhv.holdOutside pic.holdOff];
                outcome = err.holdOutside; break
            elseif ontarget(3) == 0
                % Error if monkey went outside fixRadius
                event   = [bhv.fixNotMaint pic.holdOff];
                outcome = err.fixBreak; break
            else
                % Correctly held fixation & hold
                eventmarker([bhv.holdMaint bhv.fixMaint]);
            end
        end
    end
    
    % TRIAL finished successfully as all stims fixated correctly and no error
    % This check is needed as 'break' only breaks the preceding for loop and
    % not the while loop (which checks for outcome < 0)
    if outcome < 0
        if stimOffPeriod > 0
            % MARK stimFixCue for removal
            visibleStims = [holdButton stimFixCue];
            event        = [bhv.respCorr pic.holdOff rew.juice];
        else
            % MARK last stimuli for removal
            visibleStims = [holdButton stimFixCue selStim(itemID)];
            event        = [bhv.respCorr pic.holdOff selEvts(2*itemID) rew.juice];
        end
        outcome = err.respCorr;
    end
end

% SET trial outcome and remove all visible stimuli
trialerror(outcome);
tAllOff = toggleobject([visibleStims photodiodeCue], 'eventmarker', event);
if outcome == 0
    if stimOffPeriod > 0
        tFixCueOff(itemID+1,:) = tAllOff;
    else
        tStimOff(itemID,:) = tAllOff;
    end
end

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
cFixID(1)  = trl.shift + Info.fixationImage01ID;
cFixID(2)  = trl.shift + Info.fixationImage02ID;
cFixID(3)  = trl.shift + Info.fixationImage03ID;
cFixID(4)  = trl.shift + Info.fixationImage04ID;
cFixID(5)  = trl.shift + Info.fixationImage05ID;
cFixID(6)  = trl.shift + Info.fixationImage06ID;
cFixID(7)  = trl.shift + Info.fixationImage07ID;
cFixID(8)  = trl.shift + Info.fixationImage08ID;
cFixID(9)  = trl.shift + Info.fixationImage09ID;
cFixID(10) = trl.shift + Info.fixationImage10ID;
cFixID     = cFixID(1:Info.imgPerTrial);
cFixX      = nan(Info.imgPerTrial,1);
cFixY      = nan(Info.imgPerTrial,1);

for imgInd = 1:Info.imgPerTrial
    % Fixation stimuli TaskObject starts from 8
    cFixX(imgInd) = trl.picPosShift + TaskObject.Position((stim1-1)+imgInd,1)*1000;
    cFixY(imgInd) = trl.picPosShift + TaskObject.Position((stim1-1)+imgInd,2)*1000;
end

% FOOTER start marker
eventmarker(trl.footerStart);

% INDICATE type of trial run
eventmarker(trl.taskFix);

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

% SEND stim info - imageID, X position and Y position
for imgIDSend = 1:Info.imgPerTrial
    eventmarker([cFixID(imgIDSend) cFixX(imgIDSend) cFixY(imgIDSend)]);
end

% STIM INFO start marker
eventmarker(trl.stimStop);

% FOOTER end marker
eventmarker(trl.footerStop);

% SAVE to TrialRecord.user
TrialRecord.User.fixationImageID(trialNum,1)  = Info.fixationImage01ID;
TrialRecord.User.fixationImageID(trialNum,2)  = Info.fixationImage02ID;
TrialRecord.User.fixationImageID(trialNum,3)  = Info.fixationImage03ID;
TrialRecord.User.fixationImageID(trialNum,4)  = Info.fixationImage04ID;
TrialRecord.User.fixationImageID(trialNum,5)  = Info.fixationImage05ID;
TrialRecord.User.fixationImageID(trialNum,6)  = Info.fixationImage06ID;
TrialRecord.User.fixationImageID(trialNum,7)  = Info.fixationImage07ID;
TrialRecord.User.fixationImageID(trialNum,8)  = Info.fixationImage08ID;
TrialRecord.User.fixationImageID(trialNum,9)  = Info.fixationImage09ID;
TrialRecord.User.fixationImageID(trialNum,10) = Info.fixationImage10ID;
TrialRecord.User.imgPerTrial(trialNum)        = Info.imgPerTrial;
TrialRecord.User.trialFlag(trialNum)          = Info.trialFlag;
TrialRecord.User.expectedResponse(trialNum)   = NaN;
TrialRecord.User.chosenResponse(trialNum)     = NaN;
TrialRecord.User.responseCorrect(trialNum)    = outcome;
TrialRecord.User.juiceConsumed(trialNum)      = juiceConsumed;

% SAVE to Data.UserVars
bhv_variable(...
    'fixHoldPeriod', fixHoldPeriod, 'holdRadiusBuffer', holdRadiusBuffer,...
    'juiceConsumed', juiceConsumed, 'tHoldButtonOn',    tHoldButtonOn,...
    'tTrialInit',    tTrialInit,    'tFixCueOn',        tFixCueOn,...
    'tFixAcq',       tFixAcq,       'tFixCueOff',       tFixCueOff,...
    'tStimOn',       tStimOn,       'tStimOff',         tStimOff,...
    'tAllOff',       tAllOff);

% FOOTER end------------------------------------------------------------------------------
% DASHBOARD (customize as required)-------------------------------------------------------

lines       = fillDashboard(TrialData.VariableChanges, TrialRecord);
for lineNum = 1:length(lines)
    dashboard(lineNum, char(lines(lineNum, 1)), [1 1 1]);
end