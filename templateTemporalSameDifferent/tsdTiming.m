% SAME-DIFFERENT TRIAL in MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Presents a sample and test image at the center of the screen but separated temporally.
% Provides two touch button on the right side (from subjects' POV) as responses:
%  - Top button for 'same' response, and
%  - Bottom button for 'diff' response.
%
% VERSION HISTORY
%   14-Jun-2019 - Thomas  - First implementation
%                 Zhivago
%   03-Feb-2020 - Harish  - Added fixation contingency to hold and sample on/off period
%                         - Added serial data read and store
%                         - Added trial break when dragging hand
%   07-Mar-2020 - Thomas  - Added separation of hold and fixation error types
%                 Georgin - Flipped button order for JuJu
%                         - Sending footer information as eventmarker()
%                         - Dashboard outsourced to function fillDashboard()
%   10-Aug-2020 - Thomas  - Removed bulk adding of variables to TrialRecord.User
%                         - Simplified general code structure, specifically on errors
%   14-Sep-2020 - Thomas  - General changes to code structure to improve legibilty
%   14-Oct-2020 - Thomas  - Updated all eyejoytrack to absolute time and not rt
%   31-Dec-2020 - Thomas  - Updated editable names and implemented holdRadiusBuffer
%   26-Oct-2021 - Thomas  - Included tRespOff and eventmarker to indicated response given
%                           by monkey. Also updated handling testPeriod < respPeriod
%   03-Nov-2021 - Thomas  - Included wmFixCue TaskObject in conditions file and task
%   05-Nov-2021 - Thomas  - wmFixCue renamed to generalized stimFixFlag, option to show
%                 Georgin   fixCue throughout trial introduced.
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
editable(...
    'goodPause',     'badPause',         'taskFixRadius',...
    'calFixRadius',  'calFixInitPeriod', 'calFixHoldPeriod',...
    'calFixRandFlag','rewardVol');
goodPause        = 200;
badPause         = 1000;
taskFixRadius    = 10;
calFixRadius     = 8;
calFixInitPeriod = 500;
calFixHoldPeriod = 300;
calFixRandFlag   = 1;
rewardVol        = 0.2;

% PARAMETERS relevant for task timing and hold/fix control
holdInitPeriod   = Info.holdInitPeriod;
fixInitPeriod    = Info.fixInitPeriod;
fixHoldPeriod    = 300;
holdRadius       = TrialData.TaskObject.Attribute{1, 2}{1, 2};
holdRadiusBuffer = 2;
samplePeriod     = Info.samplePeriod;
delayPeriod      = Info.delayPeriod;
testPeriod       = Info.testPeriod;
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

% NUMBER of TaskObjects
nTaskObjects  = length(TaskObject);

% POINTERS to TaskObjects
photodiodeCue = 1; 
holdButton    = 2;
initFixCue    = 3; 
stimFixCue    = 4;
calibCue      = 5; 
audioCorr     = 6; 
audioWrong    = 7; 
sameButton    = 8;
diffButton    = 9; 
sampleImage   = 10; 
testImage     = 11;

% HANDLE reordering of stimFixCue above or below stims
if Info.stimFixCueAboveStimFlag
    TaskObject.Zorder(stimFixCue) = 1;
    TaskObject.Zorder([sampleImage testImage]) = 0;
else
    TaskObject.Zorder(stimFixCue) = 0;
    TaskObject.Zorder([sampleImage testImage]) = 1;
end

% SET response button order for SD task
if ~isfield(TrialRecord.User, 'respOrder')
    TrialRecord.User.respOrder = [sameButton diffButton];
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
tRespOff        = NaN; 
tAllOff         = NaN;
juiceConsumed   = NaN;

% HEADER end -----------------------------------------------------------------------------
% TRIAL start ----------------------------------------------------------------------------

% CHECK and proceed only if screen is not being touched
while istouching(), end
outcome      = -1;

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
    
    % PRESENT fixation cue
    tFixAcqCueOn = toggleobject([initFixCue photodiodeCue], 'eventmarker', pic.fixOn);
    visibleStims = [holdButton initFixCue];
    
    % WAIT for fixation and CHECK for hold in HOLD period
    [ontarget, ~, tFixAcq] = eyejoytrack(...
        'releasetarget', holdButton, holdRadius,...
        '~touchtarget',  holdButton, holdRadius + holdRadiusBuffer,...
        'acquirefix',    initFixCue,  taskFixRadius,...
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
    
    % CHECK hold and fixation in HOLD period (200ms to stabilize eye gaze)
    ontarget = eyejoytrack(...
        'releasetarget', holdButton, holdRadius,...
        '~touchtarget',  holdButton, holdRadius + holdRadiusBuffer,...
        'holdfix',       initFixCue,  taskFixRadius,...
        fixHoldPeriod); 
    
    if ontarget(1) == 0
        % Error if monkey has released hold 
        event   = [bhv.holdNotMaint pic.holdOff pic.fixOff]; 
        outcome = err.holdBreak; break
    elseif ontarget(2) == 1
        % Error if monkey touched outside
        event   = [bhv.holdOutside pic.holdOff pic.fixOff]; 
        outcome = err.holdOutside; break
    elseif ontarget(3) == 0
        % Error if monkey went outside fixRadius
        event   = [bhv.fixNotMaint pic.holdOff pic.sampleOff]; 
        outcome = err.fixBreak; break
    else
        % Correctly held fixation & hold
        eventmarker([bhv.holdMaint bhv.fixMaint]);
    end    
    
    % REMOVE fixation cue and PRESENT sample image and stimFixCue - here initFixCue is
    % removed and delayFixCue is kept on till end of trials. The dynamics of visibility
    % of delayFixCue are determined by variables Info.stimFixCueAboveStimFlag and the
    % inherent color of stimFixCue as determined when creating conditions file
    tFixAcqCueOff = toggleobject([initFixCue stimFixCue sampleImage photodiodeCue], 'eventmarker', [pic.fixOff pic.sampleOn]);
    tSampleOn     = tFixAcqCueOff;
    visibleStims  = [holdButton stimFixCue sampleImage];
    
    % CHECK hold and fixation in SAMPLE ON period
    ontarget = eyejoytrack(...
        'releasetarget', holdButton, holdRadius,...
        '~touchtarget',  holdButton, holdRadius + holdRadiusBuffer,...
        'holdfix',       stimFixCue, taskFixRadius,...
        samplePeriod);
    
    if ontarget(1) == 0
        % Error if monkey has released hold
        event   = [bhv.holdNotMaint pic.holdOff pic.sampleOff];
        outcome = err.holdBreak; break
    elseif ontarget(2) == 1
        % Error if monkey touched outside
        event   = [bhv.holdOutside pic.holdOff pic.sampleOff];
        outcome = err.holdOutside; break
    elseif ontarget(3) == 0
        % Error if monkey went outside fixRadius
        event   = [bhv.fixNotMaint pic.holdOff pic.sampleOff];
        outcome = err.fixBreak; break
    else
        % Correctly held fixation & hold
        eventmarker([bhv.holdMaint bhv.fixMaint]);
    end
    
    % HANDLE sample removal and test presentation considering delayPeriod duration
    if delayPeriod == 0
        % REMOVE sample and PRESENT test and response buttons
        tSampleOff = toggleobject([sampleImage holdButton testImage sameButton diffButton photodiodeCue], 'eventmarker',...
            [pic.sampleOff pic.holdOff pic.choiceOn pic.testOn]);
        tTestRespOn  = tSampleOff;
        visibleStims = [stimFixCue testImage sameButton diffButton];
    else
        % REMOVE sample image 
        tSampleOff     = toggleobject([sampleImage photodiodeCue], 'eventmarker', pic.sampleOff);
        tFixMaintCueOn = tSampleOff;
        visibleStims   = [holdButton stimFixCue];
        
        % CHECK hold and fixation in DELAY period
        ontarget = eyejoytrack(...
            'releasetarget', holdButton,   holdRadius,...
            '~touchtarget',  holdButton,   holdRadius + holdRadiusBuffer,...
            'holdfix',       stimFixCue,  taskFixRadius,...
            delayPeriod);
        
        if ontarget(1) == 0
            % Error if monkey has released hold
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
        
        % REMOVE fixation cue and PRESENT test and response buttons
        tFixMaintCueOff = toggleobject([holdButton testImage sameButton diffButton photodiodeCue], 'eventmarker',...
            [pic.holdOff pic.choiceOn pic.testOn]);
        tTestRespOn     = tFixMaintCueOff;
        visibleStims    = [stimFixCue testImage sameButton diffButton];
    end
               
    % WAIT for response in TEST ON period
    [chosenResp, ~, tBhvResp] = eyejoytrack(...
        'touchtarget',  respOrder,  holdRadius,...
        '~touchtarget', holdButton, holdRadius + holdRadiusBuffer,...
        testPeriod);
    
    % CHECK if response given
    if sum(chosenResp) > 0
        eventmarker(bhv.respGiven);
        
        % RECORD reaction time
        rt = tBhvResp - tTestRespOn;
    end
    
    % HANDLE situations where testPeriod < respPeriod
    if testPeriod < respPeriod && sum(chosenResp) == 0
        % REMOVE test image
        tTestOff     = toggleobject([testImage photodiodeCue],'eventmarker', pic.testOff);
        visibleStims = [stimFixCue sameButton diffButton];
        
        % WAIT for response if TEST period < RESP period
        [chosenResp, ~, tBhvResp] = eyejoytrack(...
            'touchtarget',  respOrder,  holdRadius,...
            '~touchtarget', holdButton, holdRadius + holdRadiusBuffer,...
            (respPeriod - testPeriod));
        
        % CHECK if response given
        if sum(chosenResp) > 0
            eventmarker(bhv.respGiven);
            
            % RECORD reaction time
            rt = tBhvResp - tTestRespOn;
        end
        event = [];
    else
        event = pic.testOff;
    end
    
    % MARK the behavioral outcome
    if chosenResp(1) == 0 && chosenResp(2) == 0
        % Error if no response from monkey
        event   = [bhv.respNil event pic.choiceOff];
        outcome = err.respNil; break
    elseif chosenResp(1) == 0 && chosenResp(2) == 1
        % Error if monkey touched outside
        event   = [bhv.holdOutside event pic.choiceOff];
        outcome = err.holdOutside; break
    elseif Info.expectedResponse == 0
        % Correct response by monkey on ambigous/free-choice trial
        event   = [bhv.respCorr event pic.choiceOff rew.juice];
        outcome = err.respCorr; break
    elseif chosenResp(1) == Info.expectedResponse
        % Correct response by monkey
        event   = [bhv.respCorr event pic.choiceOff rew.juice];
        outcome = err.respCorr; break   
    elseif chosenResp(1) ~= Info.expectedResponse
        % Wrong response by monkey
        event   = [bhv.respWrong event pic.choiceOff];
        outcome = err.respWrong; break
    end
end

% SET trial outcome and remove all visible stimuli
trialerror(outcome);
tAllOff  = toggleobject([visibleStims photodiodeCue], 'eventmarker', event);
if sum(visibleStims == testImage) > 0
    tTestOff = tAllOff;
end
if sum(ismember(visibleStims, respOrder)) > 0    
    tRespOff = tAllOff;
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
cExpResponse = trl.expRespFree      + Info.expectedResponse;
cTrialFlag   = trl.typeShift;

if isfield(Info, 'trialFlag')
    cTrialFlag = cTrialFlag + Info.trialFlag;
end

% ASSIGN trial footer editable
cGoodPause        = trl.shift + TrialRecord.Editable.goodPause;
cBadPause         = trl.shift + TrialRecord.Editable.badPause;
cTaskFixRadius    = trl.shift + TrialRecord.Editable.taskFixRadius*10;
cCalFixRadius     = trl.shift + TrialRecord.Editable.calFixRadius*10;
cCalFixInitPeriod = trl.shift + TrialRecord.Editable.calFixInitPeriod;
cCalFixHoldPeriod = trl.shift + TrialRecord.Editable.calFixHoldPeriod;
cRewardVol        = trl.shift + TrialRecord.Editable.rewardVol*1000;

% PREPARE stim info - sets of stim ID, stimPosX and stimPosY to transmit
cSampleID = trl.shift + Info.sampleImageID;
cSampleX  = trl.picPosShift + TaskObject.Position(sampleImage,1)*1000;
cSampleY  = trl.picPosShift + TaskObject.Position(sampleImage,2)*1000;
cTestID   = trl.shift + Info.testImageID;
cTestX    = trl.picPosShift + TaskObject.Position(testImage,1)*1000;
cTestY    = trl.picPosShift + TaskObject.Position(testImage,2)*1000;

% FOOTER start marker
eventmarker(trl.footerStart);

% INDICATE type of trial run
eventmarker(trl.taskTsd);

% SEND footers
eventmarker([cTrial cBlock cTrialWBlock cCondition cTrialError cExpResponse cTrialFlag]);      

% EDITABLE start marker
eventmarker(trl.edtStart);

% SEND editable in following order
eventmarker([...
    cGoodPause        cBadPause         cTaskFixRadius cCalFixRadius...
    cCalFixInitPeriod cCalFixHoldPeriod cRewardVol]);

% EDITABLE stop marker
eventmarker(trl.edtStop);

% STIM INFO start marker
eventmarker(trl.stimStart);

% SEND stim info - imageID, X position and Y position
eventmarker([cSampleID cSampleX cSampleY cTestID cTestX cTestY]);

% STIM INFO start marker
eventmarker(trl.stimStop);

% FOOTER end marker
eventmarker(trl.footerStop);

% SAVE to TrialRecord.user
TrialRecord.User.sampleID(trialNum)           = Info.sampleImageID;
TrialRecord.User.testID(trialNum)             = Info.testImageID;
TrialRecord.User.trialFlag(trialNum)          = Info.trialFlag;
TrialRecord.User.expectedResponse(trialNum)   = Info.expectedResponse;
if exist('chosenResp','var')
    TrialRecord.User.chosenResponse(trialNum) = chosenResp(1);
else
    TrialRecord.User.chosenResponse(trialNum) = NaN;
end
TrialRecord.User.responseCorrect(trialNum)    = outcome;
TrialRecord.User.juiceConsumed(trialNum)      = juiceConsumed;

% SAVE to Data.UserVars
bhv_variable(...
    'juiceConsumed',  juiceConsumed,  'tHoldButtonOn',   tHoldButtonOn,...
    'tTrialInit',     tTrialInit,     'tFixAcqCueOn',    tFixAcqCueOn,...
    'tFixAcq',        tFixAcq,        'tFixAcqCueOff',   tFixAcqCueOff,...
    'tSampleOn',      tSampleOn,      'tSampleOff',      tSampleOff,...
    'tFixMaintCueOn', tFixMaintCueOn, 'tFixMaintCueOff', tFixMaintCueOff,...
    'tTestRespOn',    tTestRespOn,    'tBhvResp',        tBhvResp,...
    'tTestOff',       tTestOff,       'tRespOff',        tRespOff,...
    'tAllOff',        tAllOff);

% FOOTER end------------------------------------------------------------------------------
% DASHBOARD (customize as required)-------------------------------------------------------

lines       = fillDashboard(TrialData.VariableChanges, TrialRecord);
for lineNum = 1:length(lines)
    dashboard(lineNum, char(lines(lineNum, 1)), [1 1 1]);
end