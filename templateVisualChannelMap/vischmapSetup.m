% SETUP CONDITIONS file for Visual Channel Map
% ----------------------------------------------------------------------------------------
% Single block fixation task with 16 images x 16 reps of stimuli used to map visual
% channels on each day/experiment.
%
% VERSION HISTORY
%   30-Jan-2023 - Shubho - Initial implementation
% ----------------------------------------------------------------------------------------

clc; clear; close all;

% TIMING file name - No need to change if using template codes as is. But if modifying the
% timing file for your own experiment, do rename the timing file and update the entry
% below
timingFileName = 'fixTiming';

% CONDITIONS file name - feel free to modify it according to your experiment.
% An input of "experimentName" will create the conditions file -"FIX-experimentName.txt"
conditionsFileName = 'vischmap';

% SELECT if the stimFix cue color - after first stim is flipped to screen is visible or 
% not. A value of 1 means that the fix cue is same color as the initFix cue i.e. yellow 
% whereas 0 means the color is black (and on the black background it will be invisible).
% NOTE: Use in confunction with stimFixCueAboveStimFlag for intended effect
stimFixCueColorFlag = 0; 

% CHOOSE if the stimFix cue with be shown on top of stimulus on the screen on behind them.
% For e.g. if you want to have a fixation spot on throughout the trial, keep the following
% value 1 and stimFixCueColor as 1. For a traditional task we only want to shoe fixation
% cue between stimuli, so we keep the following value as 0. NOTE: This setting has to be
% used in conjuntion with stimFixCueColorFlag for intended effect.
stimFixCueAboveStimFlag = 0; % If 1, show fix above stim, else below

%% TIMINGS of the task (all in milliseconds)
% DURATION available for monkey to initiate the trial by pressing the hold button
holdInitPeriod = 10000;

% DURATION available for monkey to acquire fixation after initiating the trial
fixInitPeriod  = 500;

% DURATION to show the stimuli for (can't be 0)
stimOnPeriod   = 200;

% DURATION of ISI for (can be 0)
stimOffPeriod  = 200;

%% CREATE the conditions/trials and related variables
% READ image names
imgFiles    = dir('.\stim\*.png');
numImages   = length(imgFiles);

% CREATE the imgList - every 2 consecutive trial gives 1 rep of every image
imgPerTrial     = 8;  % fixTiming.m can handle max 10 stim presentation/trial
nReps           = 16; % total reps of each stim
nTrialsPerBlock = 32; % total number of corret trials to end whole expt

stimIDs     = (1:numImages);
imgList     = [];
unitRep = [1:length(stimIDs)/2; length(stimIDs)/2 + (1:length(stimIDs)/2)];
for i=1:nReps
    randInd = randperm(numel(unitRep));
    temp    = reshape(unitRep(randInd), size(unitRep));
    imgList = [imgList; temp];
end

% USE imgList to prepare a matched matrix of image file names (no need for extension here
% unless you have same files in different extensions in the stim directory)
maxImgPerTrial     = 10;
extraImagePerTrial = maxImgPerTrial - size(imgList,2);

% INSERT ones for any stim per trial < 10 as we need some dummy image names in conditions
% We can't insert 0's or NaN's as the timing file should still populate the unwanted
% TaskObject.
if extraImagePerTrial > 0
    imgList = [imgList ones(size(imgList,1), extraImagePerTrial)];
elseif extraImagePerTrial < 0
    error('fixTiming.m can only show max 10 images per trial!')
end

% PREPARE file names for stims in condition file - images are in folder 'stim'
for trialID = 1:size(imgList,1)
    for i = 1:10
        tempVar             = strsplit(imgFiles(imgList(trialID,i)).name, '.');
        fixNames{trialID, i} = ['.\stim\' tempVar{1}];
    end
end

% LABEL conditions/trial with block number
nTrials         = size(imgList,1);
block           = ones(nTrials,1);

% LABEL conditions/trial with a frequency value. Generally keep as 1, check MonkeyLogic
% website for detailed usage
frequency       = ones(nTrials,1);

% LABEL conditions/trial with a trialFlag that can be used for analysis in fillDashboard
% or for post recording analysis as a quick way to pick trials of interest
trialFlag       = ones(nTrials,1);

%% PREPARE the Info fields for each trial 
% DO NOT remove any field as they are required in the timing field!!! These
% are just pairs of string that can be formatted easily with eval
infoFields =  {
    '''imgPerTrial'',',             'imgPerTrial'
    '''fixationImage01ID'',',       'imgList(trialID,1)'
    '''fixationImage02ID'',',       'imgList(trialID,2)'
    '''fixationImage03ID'',',       'imgList(trialID,3)'
    '''fixationImage04ID'',',       'imgList(trialID,4)'
    '''fixationImage05ID'',',       'imgList(trialID,5)'
    '''fixationImage06ID'',',       'imgList(trialID,6)'
    '''fixationImage07ID'',',       'imgList(trialID,7)'
    '''fixationImage08ID'',',       'imgList(trialID,8)'
    '''fixationImage09ID'',',       'imgList(trialID,9)'
    '''fixationImage10ID'',',       'imgList(trialID,10)'
    '''fixationImage01File'',',     'fixNames{trialID,1}'
    '''fixationImage02File'',',     'fixNames{trialID,2}'
    '''fixationImage03File'',',     'fixNames{trialID,3}'
    '''fixationImage04File'',',     'fixNames{trialID,4}'
    '''fixationImage05File'',',     'fixNames{trialID,5}'
    '''fixationImage06File'',',     'fixNames{trialID,6}'
    '''fixationImage07File'',',     'fixNames{trialID,7}'
    '''fixationImage08File'',',     'fixNames{trialID,8}'
    '''fixationImage09File'',',     'fixNames{trialID,9}'
    '''fixationImage10File'',',     'fixNames{trialID,10}'
    '''trialFlag'',',               'trialFlag(trialID,1)'
    '''holdInitPeriod'',',          'holdInitPeriod'
    '''fixInitPeriod'',',           'fixInitPeriod'
    '''stimOnPeriod'',',            'stimOnPeriod'
    '''stimOffPeriod'',',           'stimOffPeriod'
    '''stimFixCueColorFlag'',',     'stimFixCueColorFlag'
    '''stimFixCueAboveStimFlag'',', 'stimFixCueAboveStimFlag'
    };

% PREPARE Info that will be added to each condition in conditions file and is utilized in
% the timing file
for trialID = 1:size(imgList,1)
   tempVar = [];
    
   % FORMAT each info variable
    for stringID   = 1:length(infoFields)
        value      = eval(char(infoFields(stringID,2)));
        stringVal  = char(infoFields(stringID,1));        
        
        % CHECK if Info item is number or not (some are strings, like stim file names)
        if isnumeric(value)
            if stringID == length(infoFields)
                tempVar = [tempVar stringVal sprintf('%03d',value)];
            else
                tempVar = [tempVar stringVal sprintf('%03d',value) ','];
            end
        else
            if stringID == length(infoFields)
                tempVar = [tempVar stringVal '''' value ''''];
            else
                tempVar = [tempVar stringVal '''' value '''' ','];
            end
        end
    end
    
    % ADD to info for current trial
    info{trialID} = tempVar;
end

%% CREATE conditions file
ml_makeConditionsFixation(timingFileName, conditionsFileName, fixNames,...
    info, frequency, block, stimFixCueColorFlag)
