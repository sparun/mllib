function  L1_str = createL1str(bhvFileFullpath,ecubeFolderFullpath,wirelessFileFullpath)
% ------------------------ Vision Lab, IISc-----------------------------------------------
% Use this code is to generate L1 structure from one session. Data recored in ML,
% eCube wired and eCUbe wireless systems are  arranged based on eCube
% timestamps.
%
% Mandatory Inputs
% ----------------
% bhvFileFullpath     = Full path of the ML behavior file (*.bv2). Expected file name format <monkeyname>_<experimentname>_<date>_<time>.bhv2  
% ecubeFolderFullpath = Full path of the folder containing all Analog*.bin & Digital *. bin files.Expected folder name format <monkeyname>_<date>_<time>    
%
% Optional Input
% wirelessFileFullpath = Full path of the wireless data. Expected file format
%                        HSW_<year>_<month>_<day>__<hr>_<minute>_<sec>__<RecordedMinutes>min_<Seconds>sec__hsamp_<nChannels>ch_<SamplingFrequency>sps.bin 
%                        (Default : [])          
%
% Output
% ----------------
% L1_str  : Matlab structure that contains data from a single session.
%           Check field section to know about the variables stored. 
%
% ----------------------------
% Example usage of wm_createL1 
% bhvFileFullpath      = 'E:\development\dataExtraction\data\20211124 juju tsd-template-ver6-0\juju_TSD-template-ver6-0_20211124_174807.bhv2';
% ecubeFolderFullpath  = 'E:\development\dataExtraction\data\20211124 juju tsd-template-ver6-0\juju-tsd-template-ver6-0\juju_2021-11-24_17-44-33\';
% wirelessFileFullpath = 'E:\development\dataExtraction\data\20211124 juju tsd-template-ver6-0\HSW_2021_11_24__17_48_18__03min_37sec__hsamp_192ch_20000sps.bin';
% L1_str = wm_create(bhvFileFullpath,ecubeFolderFullpath,wirelessFileFullpath);
%
%
% CHANGE LOG
% 19 Oct 2021 - Georgin, Thomas & Arun - First drafts
% 

[err, pic, aud, bhv, rew, exp, trl, chk, asc] = ml_loadEvents();

%% Flag's to enable/disable plotting options. 
netcamPFlag      = 1;
photodiodePFlag  = 1;

%% Flag to indicate if you have wireless data or not
if(~exist('flagWirelessData','var') ||~isempty(flagWirelessData))
    flagWirelessData = 1;
else
    flagWirelessData = 0;
end
%% Thresholds used during L1 structure creation.
L1input.channelThreshold      = [1e-4*ones(1,128),3e-4*ones(1,64)];
L1input.netcamDutyCycleThresh = 0.45;
L1input.ptd.Thresholds        = [4.3,4.9]; % Low to High, High to Low
L1input.ptd.minDelayBetweenPtdSignals = (1/60)/2; % 60 Hz is the flip rate of the stim presentation monitor
%% Estimates derived to measure the signal quality of the recorded data.
L1signalEstimate.WirelessPulseDuration = []; % Duration of the recorded start pulse coming from wireless logger to eCube 

%% Extracting Files
% File path extraction
% bhv files
[bhvPath,bhvFileName,bhvExt]= fileparts(bhvFileFullpath);
bhvFile     = [bhvFileName,bhvExt];
% ecube files
ecubeAnalogFiles  = dir([ecubeFolderFullpath '\Analog*']);ecubeAnalogFiles={ecubeAnalogFiles(:).name};
ecubeDigitalFiles = dir([ecubeFolderFullpath '\Digital*']);ecubeDigitalFiles={ecubeDigitalFiles(:).name};
% wireless files
wirelessFile=[];wirelessPath=[];
if(flagWirelessData==1)
[wirelessPath,wirelessFileName,wirelessExt]= fileparts(wirelessFileFullpath);
wirelessFile = [wirelessFileName,wirelessExt];
end

% Verify the recording day across files.
experimentDate = wm_checkBhvEcubeDates(bhvFile, ecubeAnalogFiles, ecubeDigitalFiles, wirelessFile,flagWirelessData); 

%% Reading the Data from files
% READ DIGITAL data 
[digitalData, digitalDataTimestamp] = wm_readDigitalFiles(ecubeDigitalFiles,ecubeFolderFullpath);
  
% READ ANALOG data 
[analogData, analogDataTimestamp]   = wm_readAnalogFiles(ecubeAnalogFiles,ecubeFolderFullpath);

% READ MonkeyLogic BHV file
[mlData, mlConfig, mlTrialRecord]   = mlread(fullfile(bhvPath, bhvFile));

% Read Wireless Data
loggerData=[];  wirelessTimeStamp=[];  WirelessSamplingRate=[];nWirelessChannels=[];
if(flagWirelessData==1)
[loggerData,wirelessTimeStamp,WirelessSamplingRate,nWirelessChannels] = wm_readWirelessData(wirelessPath,wirelessFile);
end

% SAVE data file names
dataFiles = [{bhvFile} ecubeAnalogFiles ecubeDigitalFiles {wirelessFile}]';
ecubeTimestamps.digitalDataTimestamp = digitalDataTimestamp;
ecubeTimestamps.analogDataTimestamp  = analogDataTimestamp;
ecubeTimestamps.wirelessTimeStamp    = wirelessTimeStamp;

%% Extracting eCube data
ecube  = wm_ecubeProperties; %  reading eCube properties
ecube.specs.wirelessFs        = WirelessSamplingRate;
ecube.specs.nWirelessChannels = nWirelessChannels;

tEcube = (0:length(digitalData)-1)*1/ecube.specs.digitalFs;%  defining eCube times
%% Extract strobe, photodiode and netcam sync pulse channels from digital data
strobe             = wm_extractDigitalBits(digitalData, ecube.digital.strobe);
netcamSync         = wm_extractDigitalBits(digitalData, ecube.digital.netcamSync);
wirelessSync       = wm_extractDigitalBits(digitalData, 2);

%% Extract the start time of netcam and wireless recordings
netcamStartTime    = wm_findNetcamStartTime(tEcube, netcamSync,L1input.netcamDutyCycleThresh, ecube, netcamPFlag);
wirelessStartTime=[]; L1signalEstimate.WirelessPulseDuration=[];
if(flagWirelessData==1)
    [wirelessStartTime, L1signalEstimate.WirelessPulseDuration] = wm_findWirelessStartTime(tEcube, wirelessSync, ecube);
end
%% Spike Sorting
channelwisetSpikes=[];
if(flagWirelessData==1)
    channelwisetSpikes = wm_spikeSortingThreshold(loggerData,L1input.channelThreshold,ecube,2); %% CHANGE- TRIAL START TIME IS FIXED to 2
end

%% Extracting raw eye X, Y and photodiode signal from eCube eyeData
analogEyeX        = analogData(:,1);
analogEyeY        = analogData(:,2);
analogEyeArea     = analogData(:,3);
photodiodeData    = analogData(:,4);

%% Extract eventsCodes, experiment Header, trial Footer. 
% extract header, files, basic info
[events, files, info]     = wm_extractExpEventsAndHeader(tEcube, digitalData, strobe);
info.experimentDate       = experimentDate;

% extract trial events and trial footer from event codes
[trialEvents,trialFooter] = wm_extractTrialEventsAndFooter(events);

% Add the PTD events to trial Events
ptdEventTimes   = wm_extractPhotodiodeEventTimes(photodiodeData,ecube.specs.digitalFs,L1input.ptd.Thresholds,L1input.ptd.minDelayBetweenPtdSignals,photodiodePFlag); % All Data 
trialEvents     = wm_addPtdEvents(ptdEventTimes,trialEvents);

% Correcting all the visual events based PTD signal
[trialEvents,meanPtdCorrection_wm]    = wm_correctVisualEvents(trialEvents);
L1signalEstimate.meanPtdCorrection_wm = meanPtdCorrection_wm;

% Finding the relative time axis wrt first visual stim
% [trialEvents, firstVisualEventTime]   = wm_extractRelTime(trialEvents,trialFooter);

%% Extract Raw Eye Data
nTrials              = size(trialEvents,1);
rawEyeData           = cell(nTrials,1);
for trial =1:nTrials
    trialStart        = trialEvents(trial).tEcube(1);
    trialStop         = trialEvents(trial).tEcube(end);
    eCubeTimeIndex    = find(tEcube>=trialStart & tEcube <=trialStop);
    
    trialTime         =  tEcube(eCubeTimeIndex);
    rawEyeData{trial} =  [trialTime',analogEyeX(eCubeTimeIndex),analogEyeY(eCubeTimeIndex),analogEyeArea(eCubeTimeIndex)]; 
end

%% Calculate RT
nTrials     = size(trialEvents,1);
RT          = nan(nTrials,1);
for trial =1:nTrials
    trialStart        = trialEvents(trial).tEcube(1);
    trialStop         = trialEvents(trial).tEcube(end);
    if( strcmp(trialFooter.taskType{trial},'SameDiff')) % Same-Different, 
        if(trialFooter.trialError(trial) == 0 || trialFooter.trialError(trial) == 6)
            absoluteTestONtime  = trialEvents(trial).tEcube(trialEvents(trial).eventcodes == pic.testOn);
            absoluteRespGiven   = trialEvents(trial).tEcube(trialEvents(trial).eventcodes == bhv.respGiven);
            RT(trial)           = (absoluteRespGiven-absoluteTestONtime);
        end
    elseif(strcmp(trialFooter.taskType{trial},'Search')) % Search
        if(trialFooter.trialError(trial) == 0 || trialFooter.trialError(trial) == 6)
            absoluteSampleONtime  = trialEvents(trial).tEcube(trialEvents(trial).eventcodes == pic.sampleOn);
            absoluteRespGiven     = trialEvents(trial).tEcube(trialEvents(trial).eventcodes == bhv.respGiven);
            RT(trial)             = (absoluteRespGiven-absoluteSampleONtime);
        end
    end
end

%% Extracting Spikes trialwise
nTrials     = size(trialEvents,1);
nChannel    = size(channelwisetSpikes,1);
absSpikes   = cell(nTrials,nChannel);
for trial =1:nTrials
    trialStart        = trialEvents(trial).tEcube(1);
    trialStop         = trialEvents(trial).tEcube(end);
    for ch =1:nChannel
        cSpikes  = channelwisetSpikes{ch};
        absSpikes{trial,ch} = cSpikes(cSpikes>=trialStart & cSpikes<=trialStop);
    end
end

%% Extracting Analog Data from ML and store
% all calcualtions are in ms
mlFs       = mlConfig.AISampleRate;
touchData  = cell(nTrials,1);
serialData = [];
RecordedSerialData  = mlTrialRecord.User.serialData;
serialTimeStamp     = mlTrialRecord.User.timeStamp;

% Extracting all visual events 
fieldNames   = fieldnames(pic);
allVisEvents = zeros(length(fieldNames),1);
for i=1:length(fieldNames)
    allVisEvents(i) =  pic.(fieldNames{i});
end
% Delete all common visual events except calib, hold and fix
%allVisEvents(allVisEvents<pic.calib1On)=[]; 

transformedEyeData=cell(nTrials,1);
for trial = 1:nTrials
    trialBehvCodes            =  mlData(trial).BehavioralCodes;  
    tStartInd = find(trialBehvCodes.CodeNumbers == trl.start);
    tStopInd  = find(trialBehvCodes.CodeNumbers == trl.stop);
    tStart    = trialBehvCodes.CodeTimes(tStartInd);
    tStop     = trialBehvCodes.CodeTimes(tStopInd);
    

    cEventCodes_wm        = trialEvents(trial).eventcodes;
    ctEcube_wm            = trialEvents(trial).tEcube;
    cStartTime_wm         = ctEcube_wm(cEventCodes_wm==trl.start);
    cStimOnTime_wm        = ctEcube_wm(cEventCodes_wm==pic.sampleOn);
    SampleONwrtTrialStart = cStimOnTime_wm-cStartTime_wm;
    
    
    relPtdSampleON_ml = tStart+SampleONwrtTrialStart;
 
    % calculate relative time wrt sample on time.
    trialEyeData   = mlData(trial).AnalogData.Eye;
    tML            = 0:(1000/mlFs):length(trialEyeData)-1; % sampling 1 ms
    trialInd       = find(tML>=tStart & tML<=tStop);
    trialTime      = tML(trialInd)-relPtdSampleON_ml;
    transformedEyeData{trial,1} = [trialTime'/1000, trialEyeData(trialInd,:)];  % time axis in seconds

    % Touch Data
    % We have observed that, sometimes there is a 1 sample diference between touch data and Eye data
    % We can't solve here, and hence we assume that its some additonal
    % sample coming at the end.
    trialTouchData   = mlData(trial).AnalogData.Touch;
    tMLtouch         = 0:(1000/mlFs):length(trialTouchData)-1; % sampling 1 ms
    trialInd         = find(tMLtouch>=tStart & tMLtouch<=tStop);
    trialTime        = tMLtouch(trialInd)-relPtdSampleON_ml;
    
    touchData{trial} = [trialTime'/1000, trialTouchData(trialInd,:)];
   
    % Generating serial data with time stamp.
    % Extract serial Data
    % finding the time delay in start of trial wrt to serial read start
    serialDataTime      = datetime(serialTimeStamp{trial});
  
    %Pupil X, Pupil Y, CRx, Cry, Pupil W, Pupil H
    serialData(trial,1).RecordDateTime       = datetime(serialTimeStamp{trial});
    serialData(trial,1).eye1.pupilX          = RecordedSerialData{trial}(:,1);
    serialData(trial,1).eye1.pupilY          = RecordedSerialData{trial}(:,2);
    serialData(trial,1).eye1.crX             = RecordedSerialData{trial}(:,3);
    serialData(trial,1).eye1.crY             = RecordedSerialData{trial}(:,4);
    serialData(trial,1).eye1.pupilW          = RecordedSerialData{trial}(:,5);
    serialData(trial,1).eye1.pupilH          = RecordedSerialData{trial}(:,6);
    serialData(trial,1).eye1.pupilArea       = RecordedSerialData{trial}(:,7);
    serialData(trial,1).eye2.gazeX           = RecordedSerialData{trial}(:,8);
    serialData(trial,1).eye2.gazeY           = RecordedSerialData{trial}(:,9);
    serialData(trial,1).eye2.pupilArea       = RecordedSerialData{trial}(:,10);
    serialData(trial,1).vergence             = RecordedSerialData{trial}(:,11);
    serialData(trial,1).timeStamp            = RecordedSerialData{trial}(:,12);
    serialData(trial,1).mlTrialDateTime      = datetime(mlData(trial).TrialDateTime);
end    
%% Trial Properties
% Trial Footer + Some info from bhv2 file
trialProperties=trialFooter;  % copying trial footer table
for trial =1:size(trialEvents,2)
    
    trialProperties.holdInitPeriod(trial)  = mlData(trial).TaskObject.CurrentConditionInfo.holdInitPeriod;
    trialProperties.fixInitPeriod(trial)   = mlData(trial).TaskObject.CurrentConditionInfo.fixInitPeriod;
    
    if( strcmp(trialFooter.taskType{trial},'SameDiff'))
        % SD related
        trialProperties.samplePeriod(trial)    = mlData(trial).TaskObject.CurrentConditionInfo.samplePeriod;
        trialProperties.testPeriod(trial)      = mlData(trial).TaskObject.CurrentConditionInfo.testPeriod;
        trialProperties.respPeriod(trial)      = mlData(trial).TaskObject.CurrentConditionInfo.respPeriod;
    elseif( strcmp(trialFooter.taskType{trial},'Fix'))
        % Fixation 
        trialProperties.stimOnPeriod(trial)    = mlData(trial).TaskObject.CurrentConditionInfo.stimOnPeriod;
        trialProperties.stimOffPeriod(trial)   = mlData(trial).TaskObject.CurrentConditionInfo.stimOffPeriod;
    elseif(strcmp(trialFooter.taskType{trial},'Search'))
         % Search
        trialProperties.searchPeriod(trial)    = mlData(trial).TaskObject.CurrentConditionInfo.searchPeriod;
        trialProperties.respPeriod(trial)      = mlData(trial).TaskObject.CurrentConditionInfo.respPeriod;
    end

    % Calibration Related
    trialProperties.calFixHoldPeriod(trial) = mlData(trial).VariableChanges.calFixHoldPeriod;
    trialProperties.calFixInitPeriod(trial) = mlData(trial).VariableChanges.calFixInitPeriod;
    trialProperties.calFixRadius(trial)     = mlData(trial).VariableChanges.calFixRadius;
    trialProperties.calFixRandFlag(trial)   = mlData(trial).VariableChanges.calFixRandFlag;  
end
expectedResponse = trialProperties.expectedResponse;
responseCorrect  = double(trialProperties.trialError==0);

%% Extract Stimuli
if ~exist('stim', 'dir'), mkdir('stim'); end;
mlexportstim('stim',fullfile(bhvPath,bhvFileName));
d = dir('./stim/*.png');
images = cell(length(d),1);
for i=1:length(d)
    images{i} = imread(['./stim/',d(i).name]);
end

%% FINAL L1_str
L1_str.experimentName    = info.expName;
L1_str.experimentDate    = info.experimentDate;
L1_str.monkeyName        = info.monkeyName;
L1_str.images            = images;
L1_str.trialProperties   = trialProperties; 
L1_str.responseCorrect   = responseCorrect;
L1_str.RT                = RT;
L1_str.trialEvents       = trialEvents;
L1_str.rawEyeData        = rawEyeData;
L1_str.mlEyeData         = transformedEyeData;
L1_str.touchData         = touchData;
L1_str.additionalEyeData = serialData;
L1_str.tspikeabs         = absSpikes;

L1_str.info.ecubeParam           = ecube;
L1_str.info.mlConfig             = mlConfig;
L1_str.info.recordStart.netcam   = netcamStartTime;
L1_str.info.recordStart.wireless = wirelessStartTime;
L1_str.info.ecubeTimestamps      = ecubeTimestamps;
L1_str.info.dataFiles            = dataFiles; % no path only file name
L1_str.info.expFiles             = files;
L1_str.info.L1inputParams        = L1input;
L1_str.info.L1signalEstimate     = L1signalEstimate;

% Fields of L1_str
n=0;fields={};
n=n+1;fields{n,1}= 'experimentName     = Name of the experiment';
n=n+1;fields{n,1}= 'experimentDate     = Date of running the experiment';
n=n+1;fields{n,1}= 'monkeyName         = Monkey Name';
n=n+1;fields{n,1}= 'images             = All stims used in this experiment (cell, nstim x 1)';
n=n+1;fields{n,1}= 'trialProperties    = Trialwise collections of all experimental parameters (table, ntrials x nParameters)';
n=n+1;fields{n,1}= 'responseCorrect    = Response Correct (ntrials x 1)';
n=n+1;fields{n,1}= 'RT                 = Reaction Time in seconds, ntrials x 1';
n=n+1;fields{n,1}= 'trialEvents        = Struct array with fields of size nTrials x1. Fields for each trial, eventcodes, eventcodenames, tEcube (absolute time corresponding to event code), tEcubePtd (eventcodes corrected based on ptd), ptdEvents(Photo diode event times )'; 
n=n+1;fields{n,1}= 'rawEyeData         = Eye Data transmitted from ISCAN, each cell is a matirx with 4 cols representating absolute eCube time, eyeX, eyeY,eyeArea(cell, ntrial x 1)';
n=n+1;fields{n,1}= 'mlEyeData          = ML tranformed eye Data which was used during the task,each cell is a matirx with 3 cols representating absolute eCube time, eyeX, eyeY.(cell, ntrial x 1)';
n=n+1;fields{n,1}= 'touchData          = First five touch events recorded in ML, each cell is a matrix with 6 cols representing relaive time, touchX1, touchY1,.. touch X5, touchY5. (cell, ntrial x 1)';
n=n+1;fields{n,1}= 'additionalEyeData  = Twelve eye related parameters send from eyeScan through serial interface and time of reception of these parameters. Parameters are (pupilX, pupilY, crX, crY, pupilW, pupilH,pupilArea) of eye1,(gazeX, gazeY, pupil Area) of eye2, vergence and timeStamp(array of structures, 1 x ntrials)';
n=n+1;fields{n,1}= 'tspikeabs          = Spike time wrt to eCube time, cell ntrial x nchannel';
L1_str.fields    = fields;

% Fields of L1_str.info
n=0;fields={};
n=n+1;fields{n,1}= 'ecubeParam         = Hardware related parameters of eCube recording system (struct)';
n=n+1;fields{n,1}= 'mlConfig           = Experiment and harwared related configuration details stored by ML';
n=n+1;fields{n,1}= 'recordStart        = Start times of netcam and wireless recording wrt eCube time (struct)';
n=n+1;fields{n,1}= 'ecubeTimestamps    = Time stamp of the recorded eCube files. This time stap can be used to check if there are any recording delays';
n=n+1;fields{n,1}= 'dataFiles          = File names of data files used to create this L1_str.';
n=n+1;fields{n,1}= 'expFiles           = Files, contents, and file creation data and time of all matlab files used to run the experiment. Use "ml_unpackHeader" to recreate the files';
n=n+1;fields{n,1}= 'L1inputParams      = Parametric choice while running the decoding codes at L1 level';
n=n+1;fields{n,1}= 'L1signalEstimate   = Signal quality checked at L1 level, Wireless start pulse duration, meanPtd & std of time correction per trial in seconds).';
L1_str.info.fields = fields;
end
