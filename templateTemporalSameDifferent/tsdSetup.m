% SETUP CONDITIONS file for Temporal Same-Different task
% For NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% This code is essentially a template that can be modified to create the inputs needed for
% the ml_makeConditionsTemporalSameDifferent.m function (which actually creates the 
% conditions file)
% 
% Initial section of the template is editable by experimenter to setup the image
% pairs/lists etc. as per the experimental requirement. 
%
% Latter portion of the template 'INFO' section onwards should not need to be modified in
% a standard scenario. Only modify if you know the downstream effects.
%
% IMPORTANT!! DON'T rename the following variables:
%   timimgFileName, conditionsFileName, stimFixCueColorFlag, stimFixCueAboveStimFlag
%   holdInitPeriod, fixInitPeriod, samplePeriod, delayPeriod, testPeriod, responsePeriod
%   imgPairs, sdPairs, block, frequency, expectedResponse, trialFlag, info
%
% VERSION HISTORY
% 10-Nov-2021 - Thomas - Throgoughly commented and explained the logic
% 31-Dec-2022 - Thomas - Reduced to 80 stims. Updated the trials so they are same on all
%                        executions of this code and updated conditions file name
% ----------------------------------------------------------------------------------------

clc; clear; close all;

% TIMING file name - No need to change if using template codes as is. But if modifying the
% timing file for your own experiment, do rename the timing file and update the entry
% below
timingFileName = 'tsdTiming';

% CONDITIONS file name - feel free to modify it according to your experiment.
% An input of "experimentName" will create the conditions file -"TSD-experimentName.txt"
conditionsFileName = 'template';

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

% DURATION to show the sample stimuli for (can't be 0)
samplePeriod   = 200;

% DURATION of delay between sample and test presentation for (can be 0)
delayPeriod    = 200;

% DURATION of test stimuli (can't be 0, but less than or equal to respPeriod)
testPeriod     = 5000;

% DURATION available for monkey to make response(can't be 0, or less than testPeriod)
respPeriod     = 5000;

%% CREATE the conditions/trials and related variables
% READ image names
imgFiles  = dir('.\stim\*.png');
numImages = length(imgFiles);

% CREATE the image pairs - each row is a condition/trial
samePairs = [1:numImages; 1:numImages]';
diffPairs = [1:numImages; 100-(1:numImages)]';
pairs     = [samePairs; diffPairs];

% LABEL conditions/trial with block number
imgPairs         = [];
block            = [];
frequency        = [];
expectedResponse = [];
trialFlag        = [];
blockL           = 12;
halfVal          = blockL/2;
count            = 1;

% FILL imgPairs, block, frequency, expectedResonse, trialFlag etc.
while(count <= ((length(pairs)) / blockL))
    
    % COUNT samePairs remaining to be allotted to blocks
    % Assumption is that number of same and diff trial are equal
    remTrials = length(samePairs);
    
    % RANDOMLY pick halfVal same pairs
    rng('shuffle');
    select              = randperm(remTrials, halfVal);
    imgPairs            = [imgPairs; samePairs(select, :)];
    expectedResponse    = [expectedResponse; ones(length(select),1)];
    trialFlag           = [trialFlag; ones(length(select),1)];
    samePairs(select,:) = [];
    
    % RANDOMLY pick halfVal diff pairs
    rng('shuffle');
    select   = randperm(remTrials, halfVal);
    imgPairs = [imgPairs; diffPairs(select, :)];
    expectedResponse    = [expectedResponse; 2.*ones(length(select),1)];
    trialFlag           = [trialFlag; 2.*ones(length(select),1)];
    diffPairs(select,:) = [];
    
    % YOU may also assign free-choice pairs by assigning and expectedResponse of 0
    
    % LABEL conditions/trial with block number
    block     = [block; count*(ones(blockL, 1))];
    
    % LABEL conditions/trial with a frequency value. Generally keep as 1, check MonkeyLogic
    % website for detailed usage
    frequency = [frequency; (ones(blockL, 1))];
    
    count = count + 1;
end

% PREPARE file names for stims in condition file - images are in folder 'stim'
for trialID = 1:length(imgPairs)    
    sampleImageID = imgPairs(trialID, 1);
    testImageID   = imgPairs(trialID, 2);
    
    tempVar             = strsplit(imgFiles(sampleImageID).name, '.');
    sdPairs{trialID, 1} = ['.\stim\' tempVar{1}];
    tempVar             = strsplit(imgFiles(testImageID).name, '.');
    sdPairs{trialID, 2} = ['.\stim\' tempVar{1}];
end

%% PREPARE the Info fields for each trial 
% DO NOT remove any field as they are required in the timing field!!! These
% are just pairs of string that can be formatted easily with eval
infoFields =  {
    '''sampleImageID'',',           'imgPairs(trialID,1)'
    '''testImageID'',',             'imgPairs(trialID,2)'
    '''sampleImageFile'',',         'sdPairs{trialID,1}'
    '''testImageFile'',',           'sdPairs{trialID,2}'
    '''expectedResponse'',',        'expectedResponse(trialID,1)'
    '''trialFlag'',',               'trialFlag(trialID,1)'
    '''holdInitPeriod'',',          'holdInitPeriod'
    '''fixInitPeriod'',',           'fixInitPeriod'
    '''samplePeriod'',',            'samplePeriod'
    '''delayPeriod'',',             'delayPeriod'
    '''testPeriod'',',              'testPeriod'
    '''respPeriod'',',              'respPeriod'
    '''stimFixCueColorFlag'',',     'stimFixCueColorFlag'
    '''stimFixCueAboveStimFlag'',', 'stimFixCueAboveStimFlag'
    };

% PREPARE Info that will be added to each condition in conditions file and is utilized in
% the timing file
for trialID = 1:length(imgPairs)
    tempVar = [];
    
    % FORMAT each info variable
    for stringID = 1:length(infoFields)         
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
ml_makeConditionsSD(timingFileName, conditionsFileName, sdPairs, info, frequency, block, stimFixCueColorFlag)     
