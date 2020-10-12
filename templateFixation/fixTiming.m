% FIXATION task for Monkeylogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Presents a series of images at center where animal has to fixate while pressing the hold
% button. Breaking of fixation/hold or touch outside of hold button will abort the trial.
%
% VERSION HISTORY
% ----------------------------------------------------------------------------------------
% - 02-Sep-2020 - Thomas  - First implementation
% - 14-Sep-2020 - Thomas  - Updated codes with new implementation of event and error
%                           codes. Simplified code structure and other changes.

%% CHECK if touch and eyesignal are present to continue---------------------------
if ~ML_touchpresent, error('This task requires touch signal input!'); end
if ~ML_eyepresent,   error('This task requires eye signal input!');   end

% REMOVE the joystick cursor
showcursor(false);
global iscan;

%% INIT checks when starting task-------------------------------------------------
if ~isfield(TrialRecord.User, 'initFlag')
    % CHECK if Experiment PC; Initialize IScan if true
    if strcmpi(getenv('COMPUTERNAME'), 'EXPERIMENT-PC') == 1
        IOPort('CloseAll');
        iscan  = ml_psy_init_iscan_ETL300HD();        
        TrialRecord.User.mlPcFlag = 1;
    else
        TrialRecord.User.mlPcFlag = 0;
    end
    
    % CHECK if correct monkey name is entered
    if strcmpi(MLConfig.SubjectName, 'didi') ~= 1 && strcmpi(MLConfig.SubjectName, 'juju') ~= 1
        error('Monkey name is incorrect. It can only be either DiDi or JuJu!');
    end
    
    % POPULATE TrialRecord with event codes
    [TrialRecord.User.err, TrialRecord.User.pic,...
        TrialRecord.User.aud, TrialRecord.User.bhv,...
        TrialRecord.User.rew, TrialRecord.User.exp,...
        TrialRecord.User.trl] = ml_loadEvents();
    
    % SET initFlag
    TrialRecord.User.initFlag = 1;
end

%% PURGE IScan Serial Port--------------------------------------------------------
if(TrialRecord.User.mlPcFlag)
    % CLEAR out ISCAN serial buffer before beginning of this trial
    IOPort('Purge', iscan.port);
    
    % INVALIDATE all 0,0 eye data information with a custom function
    EyeCal.custom_calfunc(@clampEye);
end

%% VARIABLES ---------------------------------------------------------------------
% POINTER to trial number
trialNum = TrialRecord.CurrentTrialNumber;

% ITI (set to 0 to measure true ITI in ML Dashboard)
set_iti(Info.iti);

% PARAMETERS relevant for task timing and hold/fix control
ptdPeriod    = 0.01;
initPeriod   = Info.initPeriod;
holdPeriod   = Info.holdPeriod;
holdRadius   = Info.holdRadius;
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

% POINTERS to TaskObjects
ptd   = 1;  hold  = 2;  fix   = 3;  calib = 4;  audCorr = 5;  audWrong = 6;
stim1 = 7;  stim2 = 8;  stim3 = 9;  stim4 = 10; stim5   = 11;
stim6 = 12; stim7 = 13; stim8 = 14; stim9 = 15; stim10  = 16;

% GROUP TaskObjects and eventmarkers for easy indexing
selStim = [stim1; stim2; stim3; stim4; stim5; stim6; stim7; stim8; stim9; stim10];
selEvts = [...
    pic.fix1On;  pic.fix1Off; pic.fix2On; pic.fix2Off;...
    pic.fix3On;  pic.fix4Off; pic.fix5On; pic.fix5Off;...
    pic.fix6On;  pic.fix6Off; pic.fix7On; pic.fix7Off;...
    pic.fix8On;  pic.fix8Off; pic.fix9On; pic.fix9Off;...
    pic.fix10On; pic.fix10Off];

% EDITABLE variables that can be changed during the task
editable(...
    'goodPause',   'badPause',      'fixRadius',...
    'fixPeriod',   'calHoldPeriod', 'calRandFlag',...
    'rewardVol',   'rewardLine',    'rewardReps',...
    'rewardRepsGap');
goodPause     = 200;
badPause      = 1000;
fixRadius     = 100;
fixPeriod     = 200;
calHoldPeriod = 500;
calRandFlag   = 0;
rewardVol     = 0.2;
rewardLine    = 1;
rewardReps    = 1;
rewardRepsGap = 500;

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

%% TRIAL -------------------------------------------------------------------------
while istouching(), end
outcome = -1;

% TRIAL start
eventmarker(trl.start);

while outcome < 0
    
    % PRESENT hold button
    tHoldButtonOn = toggleobject([hold ptd], 'eventmarker', pic.holdOn);
    pause(ptdPeriod);
    toggleobject(ptd);
    
    % WAIT for touch in INIT period
    [ontarget, tTrialInit] = eyejoytrack(...
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
    pause(ptdPeriod);
    toggleobject(ptd);
    
    % WAIT for fixation and check for hold maintenance
    [ontarget, tFixAcq] = eyejoytrack(...
        'releasetarget',hold, holdRadius,...
        '~touchtarget', hold, holdRadius,...
        'acquirefix',   fix,  fixRadius,...
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
    
    % CHECK fixation and hold maintenance for delayPeriod
    [ontarget, ~] = eyejoytrack(...
        'releasetarget',hold, holdRadius,...
        '~touchtarget', hold, holdRadius,...
        'holdfix',      fix,  fixRadius,...
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
        pause(ptdPeriod);
        toggleobject(ptd);
        
        % CHECK fixation and hold maintenance for samplePeriod
        [ontarget, ~] = eyejoytrack(...
            'releasetarget',hold,            holdRadius,...
            '~touchtarget', hold,            holdRadius,...
            'holdfix',      selStim(itemID), fixRadius,...
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
        pause(ptdPeriod);
        toggleobject(ptd);
        
        % CHECK fixation and hold maintenance for delayPeriod
        [ontarget, ~] = eyejoytrack(...
            'releasetarget',hold,            holdRadius,...
            '~touchtarget', hold,            holdRadius,...
            'holdfix',      selStim(itemID), fixRadius,...
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

trialerror(outcome);
tAllOff = toggleobject(1:16, 'status', 'off', 'eventmarker', event);

%% REWARD monkey if correct response given----------------------------------------
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

% TRIAL end
eventmarker(trl.stop);

%% TRIAL FOOTER-------------------------------------------------------------------
cTrial       = trl.trialShift       + TrialRecord.CurrentTrialNumber;
cBlock       = trl.blockShift       + TrialRecord.CurrentBlock;
cTrialWBlock = trl.trialWBlockShift + TrialRecord.CurrentTrialWithinBlock;
cCondition   = trl.conditionShift   + TrialRecord.CurrentCondition;
cTrialError  = trl.outcomeShift     + outcome;
cTrialFlag   = trl.typeShift;

if isfield(Info, 'trialFlag')
    cTrialFlag = cTrialFlag + Info.trialFlag;
end

% FOOTER start 
eventmarker(trl.footerStart);

% FOOTER information
eventmarker(cTrial);     eventmarker(cBlock);      eventmarker(cTrialWBlock);
eventmarker(cCondition); eventmarker(cTrialError); eventmarker(cTrialFlag);

% FOOTER end 
eventmarker(trl.footerStop);

%% SAVE to TrialRecord.user-------------------------------------------------------
TrialRecord.User.juiceConsumed(trialNum)   = juiceConsumed;
TrialRecord.User.responseCorrect(trialNum) = outcome;

%% SAVE to Data.UserVars----------------------------------------------------------
% ISCAN serialData ?? ADD eventmarker for IScan serial on off purge ??
if(TrialRecord.User.mlPcFlag)
    % SAVE IScan serial eye data ?? on correct trials ??
    [data, when, errMsg] = IOPort('Read', iscan.port);
    [paramTable, params] = ml_decode_bin_stream_ETL300HD(data);
    serialData           = [];
    
    if ~isempty(paramTable)
        serialData.pupilX     = paramTable(:,1);
        serialData.pupilY     = paramTable(:,2);
        serialData.cornealX   = paramTable(:,3);
        serialData.cornealY   = paramTable(:,4);
        serialData.dx         = paramTable(:,5);
        serialData.dy         = paramTable(:,6);
        serialData.data       = data;
        serialData.paramTable = paramTable;
        serialData.when       = when;
    end
    bhv_variable('serialData', {serialData});
end

% SAVE timing and reward related information
bhv_variable(...
    'juiceConsumed', juiceConsumed, 'tHoldButtonOn', tHoldButtonOn,...
    'tTrialInit',    tTrialInit,    'tFixCueOn',     tFixCueOn,...
    'tFixAcq',       tFixAcq,       'tFixCueOff',    tFixCueOff,...
    'tSampleOn',     tSampleOn,     'tSampleOff',    tSampleOff,...
    'tAllOff',       tAllOff,       'ptdPeriod',     ptdPeriod);

%% DASHBOARD (CUSTOMIZE AS REQUIRED)----------------------------------------------
% lines       = fillDashboard(TrialData, TrialRecord);
% for lineNum = 1:length(lines)
% 	dashboard(lineNum, char(lines(lineNum, 1)), [1 1 1]);
% end

%% EYE-CAL FUNCTION---------------------------------------------------------------
function xy = clampEye(xy)
% FIND 0,0 gaze readings and remove them
qBad        = xy(:, 1) == 0 | xy(:, 2) == 0;
xy(qBad, :) = [];

if isempty(xy), return, end

% FIND eccentric points and remove them
ecc         = sqrt(xy(:, 1).^2 + xy(:, 2).^2);
qBad        = find(ecc > 50);
xy(qBad, :) = [];
end