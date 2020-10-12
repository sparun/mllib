% SAME-DIFF eye calibration task for Monkeylogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Presents a set of calibration points where animal has to fixate while pressing the hold
% button. Breaking of fixation/hold or touch outside of hold button will abort the trial.
%
% VERSION HISTORY
% ----------------------------------------------------------------------------------------
% - 14-Jun-2019 - Thomas  - First implementation
%                 Zhivago 
% - 03-Feb-2020 - Harish  - Added fixation contingency to sample on/off period
%                           Added serial data read and store
%                           Added touching outside hold buttons breaks trial
% - 10-Aug-2020 - Thomas  - Removed bulk adding of variables to TrialRecord.User
%                         - Simplified general code structure, specifically on errors
% - 14-Sep-2020 - Thomas  - General changes to code structure to improve legibilty

%% HEADER START (Will automatically be updated on running UpdateTimingHeaderFooter.m)

%% CHECK if touch and eyesignal are present to continue---------------------------
if ~ML_touchpresent, error('This task requires touch signal input!'); end
if ~ML_eyepresent,   error('This task requires eye signal input!');   end

% REMOVE the joystick cursor
global iscan 

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
    if strcmpi(MLConfig.SubjectName, 'didi') ~= 1 &&...
            strcmpi(MLConfig.SubjectName, 'juju') ~= 1 &&...
            strcmpi(MLConfig.SubjectName, 'coco') ~= 1 &&...
            strcmpi(MLConfig.SubjectName, 'test') ~= 1
        error('Monkey name is incorrect. It can only be: didi, juju, coco or test!');
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

% POINTERS to TaskObjects
ptd  = 1; hold    = 2; fix      = 3; calib  = 4; same = 5; 
diff = 6; audCorr = 7; audWrong = 8; sample = 9; test = 10;  

% SET response button order for SD task
if ~isfield(TrialRecord.User, 'respOrder')
    if strcmpi(MLConfig.SubjectName, 'didi') == 1 || strcmpi(MLConfig.SubjectName, 'test') == 1
        TrialRecord.User.respOrder = [same diff];
    elseif strcmpi(MLConfig.SubjectName, 'juju') == 1 || strcmpi(MLConfig.SubjectName, 'coco') == 1
        TrialRecord.User.respOrder = [same diff];
    end
end

respOrder = TrialRecord.User.respOrder;
    
% CALIBRATION locations in DVA an group eventmarkers for easy indexing
sdLocs  = [0,0; 20,0; 20,15; 20,-15];  % Fix, hold, up & down buttons
calLocs = [sdLocs; 0,15; 0,-15; 10,0]; % See calibration locations map.ppt
selLocs = calLocs;
selEvts = [...
    pic.calib1On;  pic.calib1Off; pic.calib2On; pic.calib2Off;...
    pic.calib3On;  pic.calib4Off; pic.calib5On; pic.calib5Off;...
    pic.calib6On;  pic.calib6Off; pic.calib7On; pic.calib7Off;...
    pic.calib8On;  pic.calib8Off; pic.calib9On; pic.calib9Off;...
    pic.calib10On; pic.calib10Off];

% RANDOMIZE the position of points if calRandFlag
if(calRandFlag)
    selLocs = selLocs(randperm(size(selLocs, 1)), :);
end

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
tFixAcqCueOn  = NaN(size(selLocs,1),1);
tFixAcq       = NaN(size(selLocs,1),1);
tFixAcqCueOff = NaN(size(selLocs,1),1);
tAllOff       = NaN;
juiceConsumed = NaN;

%% HEADER END (Will automatically be updated on running UpdateTimingHeaderFooter.m)

%% TRIAL -------------------------------------------------------------------------
while istouching(), end
outcome = -1;

% TRIAL start
eventmarker(trl.start);

while outcome < 0
    % REPOSTITION the hold button
    reposition_object(hold, [28 0]);
    
    % PRESENT hold button
    tHoldButtonOn = toggleobject([hold ptd], 'eventmarker', pic.holdOn);
    pause(ptdPeriod);
    toggleobject(ptd);
    
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
    for locID = 1:size(selLocs,1)
        reposition_object(calib, selLocs(locID,:));
        
        % PRESENT fixation cue
        tFixAcqCueOn(locID) = toggleobject([calib ptd], 'eventmarker', selEvts(locID*2-1));
        pause(ptdPeriod);
        toggleobject(ptd);
    
        % WAIT for fixation and check for hold maintenance
        [ontarget, ~, tFixAcq(locID)] = eyejoytrack(...
            'releasetarget',hold,  holdRadius,...
            '~touchtarget', hold,  holdRadius,...
            'acquirefix',   calib, fixRadius,...
            holdPeriod);
        
        if ontarget(1) == 0
            % Error if monkey has released hold            
            event   = [pic.holdOff selEvts(locID*2) bhv.holdNotMaint];  %#ok<*NASGU>
            outcome = err.holdBreak; break
        elseif ontarget(2) == 1
            % Error if monkey touched outside
            event   = [pic.holdOff selEvts(locID*2) bhv.holdOutside]; 
            outcome = err.holdOutside; break
        elseif ontarget(3) == 0
            % Error if monkey never looked inside fixRadius
            event   = [pic.holdOff selEvts(locID*2) bhv.fixNotInit]; 
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
            fixPeriod);
        
        if ontarget(1) == 0
            % Error if monkey has released hold 
            event   = [pic.holdOff selEvts(locID*2) bhv.holdNotMaint]; 
            outcome = err.holdBreak; break
        elseif ontarget(2) == 1
            % Error if monkey touched outside
            event   = [pic.holdOff selEvts(locID*2) bhv.holdOutside]; 
            outcome = err.holdOutside; break
        elseif ontarget(3) == 0
            % Error if monkey went outside fixRadius
            event   = [pic.holdOff selEvts(locID*2) bhv.fixNotMaint]; 
            outcome = err.fixBreak; break
        else
            % Correctly held fixation & hold
            eventmarker([bhv.holdMaint bhv.fixMaint]);
        end
        
        % REMOVE the calibration image image off
        tFixAcqCueOff(locID) = toggleobject([calib ptd], 'eventmarker', selEvts(locID*2)); 
        pause(ptdPeriod);
        toggleobject(ptd);
    end
    
    % TRIAL finished successfully if this point reached on last item
    if locID == size(selLocs,1)
        event   = [pic.holdOff bhv.respCorr rew.juice];
        outcome = err.respCorr;
    end
end

%% FOOTER START (Will automatically be updated on running UpdateTimingHeaderFooter.m)
trialerror(outcome);
tAllOff = toggleobject(1:10, 'status', 'off', 'eventmarker', event);

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

%% SEND trial footer eventmarkers-------------------------------------------------
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
TrialRecord.User.juiceConsumed(trialNum)    = juiceConsumed;
TrialRecord.User.responseCorrect(trialNum)  = outcome;
TrialRecord.User.expectedResponse(trialNum) = 0;

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
    'tTrialInit',    tTrialInit,    'tFixAcqCueOn',  tFixAcqCueOn,...
    'tFixAcq',       tFixAcq,       'tFixAcqCueOff', tFixAcqCueOff,...
    'tAllOff',       tAllOff,       'ptdPeriod',     ptdPeriod);

%% FOOTER END (Will automatically be updated on running UpdateTimingHeaderFooter.m)

%% DASHBOARD (CUSTOMIZE AS REQUIRED)----------------------------------------------
lines       = fillDashboard(TrialData.VariableChanges, TrialRecord.User);
for lineNum = 1:length(lines)
    dashboard(lineNum, char(lines(lineNum, 1)), [1 1 1]);
end