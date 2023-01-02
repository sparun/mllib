% SETUP CONDITIONS file for Spatial Same-Different task 
% For NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% This code is essentially a template that can be modified to create the inputs needed for
% the ml_makeConditionsSpatialSameDifferent.m function (which actually creates the 
% conditions file). There are 8 possible locations for the stimuli in the array and this
% code DOES NOT ensure equal sampling of all locations for the target on 
% target-present/diff trials (presently randomly assigned). Experimenter should ensure 
% that for their experiment in a way that makes sense for them. 
% 
% Initial section of the template is editable by experimenter to setup the image
% pairs/lists etc. as per the experimental requirement. 
%
% Latter portion of the template 'INFO' section onwards should not need to be modified in
% a standard scenario. Only modify if you know the downstream effects.
%
% IMPORTANT!! DON'T rename the following variables:
%   timimgFileName, conditionsFileName, stimFixCueColorFlag, stimFixCueAboveStimFlag
%   holdInitPeriod, fixInitPeriod, searchPeriod, responsePeriod
%   tdImgPairs, tdPairs, block, frequency, expectedResponse, trialFlag, info
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
timingFileName = 'ssdTiming';

% CONDITIONS file name - feel free to modify it according to your experiment.
% An input of "experimentName" will create the conditions file -"SSD-experimentName.txt"
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
% NOTE: depending on the stimuli locations this option may have differing effects. Always
% run you code and check
stimFixCueAboveStimFlag = 0; 

% SET the number of distractors per search in the range 1 to 7. Ensure that the arrayLocs
% are only showing required distrator copies by setting other unwanted distractor positions
% to [200,200]. Stim information for these (unwanted positions) won't be sent in trial footer.
distractorPerTrial = 7;

%% TIMINGS of the task (all in milliseconds)
% DURATION available for monkey to initiate the trial by pressing the hold button
holdInitPeriod = 10000;

% DURATION available for monkey to acquire fixation after initiating the trial
fixInitPeriod  = 500;

% DURATION of search stimuli (can't be 0, but less than or equal to respPeriod)
searchPeriod   = 5000;

% DURATION available for monkey to make response(can't be 0, or less than testPeriod)
respPeriod     = 5000;

%% CREATE the conditions/trials and related variables
% READ image names
imgFiles  = dir('.\stim\*.png');
numImages = length(imgFiles);

% CREATE the image pairs - each row is a condition/trial
absentPairs  = [1:numImages; 1:numImages]';
presentPairs = [1:numImages; numImages:-1:1]';
allPairs     = [absentPairs; presentPairs];

% BLOCK creation
tdImgPairs       = [];
block            = [];
frequency        = [];
expectedResponse = [];
trialFlag        = [];
blockL           = 16; 
halfVal          = blockL/2;
count            = 1;

% FILL imgPairs, block, frequency, expectedResonse, trialFlag etc.
while(count <= ((length(allPairs)) / blockL))
    
    % COUNT absentPairs remaining to be allotted to blocks
    % Assumption is that number of same and diff trial are equal    
    remTrials = length(absentPairs);
    
    % RANDOMLY pick halfVal absent search pairs
    rng('shuffle');
    select                = randperm(remTrials, halfVal);
    tdImgPairs            = [tdImgPairs; absentPairs(select, :)];
    expectedResponse      = [expectedResponse; ones(length(select),1)];
    trialFlag             = [trialFlag; ones(length(select),1)];
    absentPairs(select,:) = [];
    
    % RANDOMLY pick halfVal present search pairs
    rng('shuffle');
    select                 = randperm(remTrials, halfVal);
    tdImgPairs             = [tdImgPairs; presentPairs(select, :)];
    expectedResponse       = [expectedResponse; 2.*ones(length(select),1)];
    trialFlag              = [trialFlag; 2.*ones(length(select),1)];
    presentPairs(select,:) = [];
    
    block     = [block; count*(ones(blockL, 1))];
    frequency = [frequency; (ones(blockL, 1))];
    count     = count + 1;
end

% PREPARE file names for stims in condition file - images are in folder 'stim'
% ALSO add the target distractor positions - Here for simplicity possible stim locations
% are constant but it may be different in your individual experiment

taskStimRadius = 5;
arrayLocs   = [...
    0,                taskStimRadius;...
    0,               -taskStimRadius;...
    taskStimRadius,   0;...
    -taskStimRadius,  0;...
    taskStimRadius,   taskStimRadius;...
    taskStimRadius,  -taskStimRadius;...
    -taskStimRadius,  taskStimRadius;...
    -taskStimRadius, -taskStimRadius];

for trialID = 1:length(tdImgPairs) 
    
    % RANDOMLY rearrange possible search stim locations
    arrayLocs = arrayLocs(randperm(size(arrayLocs, 1)), :);
    
    targetImageID       = tdImgPairs(trialID, 1);
    distractorImageID   = tdImgPairs(trialID, 2);
    
    tempVar             = strsplit(imgFiles(targetImageID).name, '.');
    tdPairs{trialID, 1} = ['.\stim\' tempVar{1}];
    tempVar             = strsplit(imgFiles(distractorImageID).name, '.');
    tdPairs{trialID, 2} = ['.\stim\' tempVar{1}];
    
    targetX(trialID,1)       = arrayLocs(1,1);
    targetY(trialID,1)       = arrayLocs(1,2);
    distractor01X(trialID,1) = arrayLocs(2,1);
    distractor01Y(trialID,1) = arrayLocs(2,2);
    distractor02X(trialID,1) = arrayLocs(3,1);
    distractor02Y(trialID,1) = arrayLocs(3,2);
    distractor03X(trialID,1) = arrayLocs(4,1);
    distractor03Y(trialID,1) = arrayLocs(4,2);
    distractor04X(trialID,1) = arrayLocs(5,1);
    distractor04Y(trialID,1) = arrayLocs(5,2);
    distractor05X(trialID,1) = arrayLocs(6,1);
    distractor05Y(trialID,1) = arrayLocs(6,2);
    distractor06X(trialID,1) = arrayLocs(7,1);
    distractor06Y(trialID,1) = arrayLocs(7,2);
    distractor07X(trialID,1) = arrayLocs(8,1);
    distractor07Y(trialID,1) = arrayLocs(8,2);
end

%% PREPARE the Info fields for each trial 
% DO NOT remove any field as they are required in the timing field!!! These
% are just pairs of string that can be formatted easily with eval
infoFields =  {
    '''targetImageID'',',           'tdImgPairs(trialID,1)'
    '''distractorImageID'',',       'tdImgPairs(trialID,2)'
    '''targetImageFile'',',         'tdPairs{trialID,1}'
    '''distractorImageFile'',',     'tdPairs{trialID,2}'
    '''expectedResponse'',',        'expectedResponse(trialID,1)'
    '''trialFlag'',',               'trialFlag(trialID,1)'
    '''holdInitPeriod'',',          'holdInitPeriod'
    '''fixInitPeriod'',',           'fixInitPeriod'
    '''searchPeriod'',',            'searchPeriod'
    '''respPeriod'',',              'respPeriod'
    '''stimFixCueColorFlag'',',     'stimFixCueColorFlag'
    '''stimFixCueAboveStimFlag'',', 'stimFixCueAboveStimFlag'
    '''targetX'',',                 'targetX(trialID,1)'
    '''targetY'',',                 'targetY(trialID,1)'
    '''distractor01X'',',           'distractor01X(trialID,1)'
    '''distractor01Y'',',           'distractor01Y(trialID,1)'
    '''distractor02X'',',           'distractor02X(trialID,1)'
    '''distractor02Y'',',           'distractor02Y(trialID,1)'
    '''distractor03X'',',           'distractor03X(trialID,1)'
    '''distractor03Y'',',           'distractor03Y(trialID,1)'
    '''distractor04X'',',           'distractor04X(trialID,1)'
    '''distractor04Y'',',           'distractor04Y(trialID,1)'
    '''distractor05X'',',           'distractor05X(trialID,1)'
    '''distractor05Y'',',           'distractor05Y(trialID,1)'
    '''distractor06X'',',           'distractor06X(trialID,1)'
    '''distractor06Y'',',           'distractor06Y(trialID,1)'
    '''distractor07X'',',           'distractor07X(trialID,1)'
    '''distractor07Y'',',           'distractor07Y(trialID,1)'
    '''distractorPerTrial'',',      'distractorPerTrial'    
    };

% PREPARE Info that will be added to each condition in conditions file and is utilized in
% the timing file
for trialID = 1:length(tdImgPairs)
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
ml_makeConditionsSpatialSameDifferent(timingFileName, conditionsFileName, tdPairs, info, frequency, block, stimFixCueColorFlag)     
