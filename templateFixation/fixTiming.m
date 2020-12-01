% FIXATION TRIAL for Monkeylogic
% - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Presents a series of images at center where animal has to fixate while pressing the hold
% button. Breaking of fixation/hold or touch outside of hold button will abort the trial.
%
% VERSION HISTORY
% - 02-Sep-2020 - Thomas  - First implementation
% - 14-Sep-2020 - Thomas  - Updated codes with new implementation of event and error
%                           codes. Simplified code structure and other changes.
% - 14-Oct-2020 - Thomas  - Updated all eyejoytrack to absolute time and not rt
% - 29-Oct-2020 - Thomas  - Updated to match the version of templateSD
% ----------------------------------------------------------------------------------------
% HEADER start ---------------------------------------------------------------------------

% CHECK if touch and eyesignal are present to continue---------------------------
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
    'goodPause',    'badPause',     'taskFixRadius',...
    'calFixRadius', 'calFixPeriod', 'calFixHoldPeriod', 'calFixRandFlag',...
    'rewardVol',    'rewardLine',   'rewardReps',       'rewardRepsGap');
goodPause        = 200;
badPause         = 1000;
taskFixRadius    = 100;
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
ptd   = 1;  hold  = 2;  fix   = 3;  calib = 4;  audCorr = 5;  audWrong = 6;
stim1 = 7;  stim2 = 8;  stim3 = 9;  stim4 = 10; stim5   = 11;
stim6 = 12; stim7 = 13; stim8 = 14; stim9 = 15; stim10  = 16;

% GROUP TaskObjects and eventmarkers for easy indexing
selStim = [stim1; stim2; stim3; stim4; stim5; stim6; stim7; stim8; stim9; stim10];
selEvts  = [...
    pic.fix1On; pic.fix1Off; pic.fix2On;  pic.fix2Off;...
    pic.fix3On; pic.fix3Off; pic.fix4On;  pic.fix4Off;...
    pic.fix5On; pic.fix5Off; pic.fix6On;  pic.fix6Off;...
    pic.fix7On; pic.fix7Off; pic.fix8On;  pic.fix8Off;...
    pic.fix9On; pic.fix9Off; pic.fix10On; pic.fix10Off];

% DECLARE select timing and reward variables as NaN
tHoldButtonOn = NaN;
tTrialInit    = NaN;
tFixCueOn     = NaN;
tFixAcq       = NaN;
tFixCueOff    = NaN;
tSampleOn     = NaN;
tSampleOff    = NaN;
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
TrialRecord.User.TrialStart(trialNum,:) = datevec(now);

% RUN trial sequence till outcome registered
while outcome < 0    
    % PRESENT hold button
    tHoldButtonOn = toggleobject([hold ptd], 'eventmarker', pic.holdOn);
    
    % WAIT for touch in INIT period
    [ontarget, ~, tTrialInit] = eyejoytrack(...
        'touchtarget',  hold, holdRadius, ...
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
    tFixCueOn(1,:) = toggleobject([fix ptd], 'eventmarker', pic.fixOn);
    
    % WAIT for fixation and CHECK for hold in HOLD period
    [ontarget, ~, tFixAcq] = eyejoytrack(...
        'releasetarget',hold, holdRadius,...
        '~touchtarget', hold, holdRadius,...
        'acquirefix',   fix,  taskFixRadius,...
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
        event   = [pic.holdOff pic.fixOff bhv.fixNotInit];
        outcome = err.fixNil; break
    else
        % Correctly acquired fixation and held hold
        eventmarker([bhv.holdMaint bhv.fixInit]);
    end
    
    % CHECK hold and fixation in DELAY period
    ontarget = eyejoytrack(...
        'releasetarget',hold, holdRadius,...
        '~touchtarget', hold, holdRadius,...
        'holdfix',      fix,  taskFixRadius,...
        delayPeriod);
    
    if ontarget(1) == 0
        % Error if monkey released hold
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
    
    % LOOP for presenting stim
    for itemID = 1:Info.imgPerTrial
        
        % REMOVE fixation cue & PRESENT stim
        tFixCueOff(itemID,:) = toggleobject([fix selStim(itemID) ptd],...
            'eventmarker', [pic.fixOff selEvts(2*itemID)-1]);
        tSampleOn(itemID,:)  = tFixCueOff(itemID,:);
        
        % CHECK fixation and hold maintenance for samplePeriod
        ontarget = eyejoytrack(...
            'releasetarget',hold,            holdRadius,...
            '~touchtarget', hold,            holdRadius,...
            'holdfix',      selStim(itemID), taskFixRadius,...
            samplePeriod);
        
        if ontarget(1) == 0
            % Error if monkey released hold
            event   = [pic.holdOff selEvts(2*itemID) bhv.holdNotMaint];
            outcome = err.holdBreak; break
        elseif ontarget(2) == 1
            % Error if monkey touched outside
            event   = [pic.holdOff selEvts(2*itemID) bhv.holdOutside];
            outcome = err.holdOutside; break
        elseif ontarget(3) == 0
            % Error if monkey went outside fixRadius
            event   = [pic.holdOff selEvts(2*itemID) bhv.fixNotMaint];
            outcome = err.fixBreak; break
        else
            % Correctly held fixation & hold
            eventmarker([bhv.holdMaint bhv.fixMaint]);
        end
        
        % REMOVE stimulus & PRESENT fixation cue
        tSampleOff(itemID,:)     = toggleobject([fix selStim(itemID) ptd],...
            'eventmarker', [selEvts(2*itemID) pic.fixOn]);
        tFixCueOn(itemID + 1,:)  = tSampleOff(itemID,:);
        
        % CHECK fixation and hold maintenance for delayPeriod
        ontarget = eyejoytrack(...
            'releasetarget',hold,            holdRadius,...
            '~touchtarget', hold,            holdRadius,...
            'holdfix',      selStim(itemID), taskFixRadius,...
            delayPeriod);
        
        if ontarget(1) == 0
            % Error if monkey released hold
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
    end
    
    % TRIAL finished successfully if this point reached on last item
    if itemID == Info.imgPerTrial
        event   = [pic.fixOff pic.holdOff bhv.respCorr rew.juice];
        outcome = err.respCorr;
    end    
end

% SET trial outcome and remove all stimuli
trialerror(outcome);
tAllOff = toggleobject(1:16, 'status', 'off', 'eventmarker', event);

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
TrialRecord.User.juiceConsumed(trialNum)   = juiceConsumed;
TrialRecord.User.responseCorrect(trialNum) = outcome;
TrialRecord.User.trialFlag(trialNum)       = Info.trialFlag;

% SAVE to Data.UserVars
bhv_variable(...
    'juiceConsumed', juiceConsumed, 'tHoldButtonOn', tHoldButtonOn,...
    'tTrialInit',    tTrialInit,    'tFixCueOn',     tFixCueOn,...
    'tFixAcq',       tFixAcq,       'tFixCueOff',    tFixCueOff,...
    'tSampleOn',     tSampleOn,     'tSampleOff',    tSampleOff,...
    'tAllOff',       tAllOff);

% SEND check odd lines
eventmarker(chk.linesOdd);

% FOOTER end------------------------------------------------------------------------------
% DASHBOARD (customize as required)-------------------------------------------------------

lines       = fillDashboard(TrialData.VariableChanges, TrialRecord.User);
for lineNum = 1:length(lines)
    dashboard(lineNum, char(lines(lineNum, 1)), [1 1 1]);
end