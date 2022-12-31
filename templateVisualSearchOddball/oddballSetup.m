% SETUP CONDITIONS file for oddball search task - NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% This code is essentially a template that can be modified to create the inputs needed for
% the ml_makeConditionsSearch.m function (which actually creates the conditions file)
%
% Initial section of the template is editable by experimenter to setup the image
% pairs/lists etc. as per the experimental requirement.
%
% Latter portion of the template 'INFO' section onwards should not need to be modified in
% a standard scenario. Only modify if you know the downstream effects.
%
% IMPORTANT!! DON'T rename the following variables:
%   timimgFileName, conditionsFileName,
%   holdInitPeriod, searchPeriod, responsePeriod
%   tdImgPairs, tdPairs, block, frequency, expectedResponse, trialFlag, info
%
% VERSION HISTORY
%{
01-Mar-2022 - Thomas - Thoroughly commented and explained the logic
%}
% ----------------------------------------------------------------------------------------

clc; clear; close all;

% TIMING file name - No need to change if using template codes as is. But if modifying the
% timing file for your own experiment, do rename the timing file and update the entry
% below
timingFileName = 'oddballTiming';

% CONDITIONS file name - feel free to modify it according to your experiment name for
% consistency. For e.g. "TSD-letterFamiliarity.txt"
conditionsFileName = 'oddballConditions.txt';

% SET the number of distractors per search in the range 1 to 7. Ensure that the arrayLocs
% are only showing required distrator copies by setting other unwanted distractor positions
% to [200,200]. Stim info for these won't be sent in trial footer.
distractorPerTrial = 4;

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
% Mirror Confusion Tall
searchPairs = nchoosek(1:numImages,2);
searchPairs = [searchPairs; fliplr(searchPairs)];
searchFlags = 1:length(searchPairs);

% TASK variables
maxJitterDVA   = 2;
respRadius     = 3.5;
holdXLoc       = 20;
holdYLoc       = 0;
nReps          = 1; % In effect after considering AB and BA searched it will be nReps*2

% PREPARE array locations with target at each position
arrayLocs     = ml_getCircleLocations(10, 15, 90, 0, [20,0], 1);
arrayLocs     = arrayLocs(2:5,:);
for targetPos = 0:3
    finalArrayLocs{targetPos+1} = [circshift(arrayLocs(1:4,:), -targetPos, 1); repmat([200 200],4,1)];
end

%% PREPARE conditions file
% CONDITIONS file name
conditionsFileName = 'OS-templateOddball.txt';

% FILL imgPairs, block, frequency, expectedResonse, trialFlag etc.
tdImgPairs       = repmat(searchPairs,nReps,1);
trialFlag        = repmat(searchFlags,nReps,1)';
block            = repmat(1:nReps,length(searchPairs),1);
block            = block(:);
expectedResponse = 2.*ones(length(block),1);
frequency        = ones(length(block), 1);
targetLocation   = repmat(1:4,length(searchPairs)/4,1);
targetLocation   = targetLocation(:);

% PREPARE file names for stims in condition file - images are in folder 'stim'
% ALSO add the target distractor positions - Here for simplicity possible stim locations
% are constant but it may be different in your individual experiment
tdPairs       = [];
holdX         = [];
holdY         = [];
targetX       = [];
targetY       = [];
distractor01X = [];
distractor01Y = [];
distractor02X = [];
distractor02Y = [];
distractor03X = [];
distractor03Y = [];
distractor04X = [];
distractor04Y = [];
distractor05X = [];
distractor05Y = [];
distractor06X = [];
distractor06Y = [];
distractor07X = [];
distractor07Y = [];

for trialID = 1:length(tdImgPairs)
    % RANDOMLY rearrange possible search stim locations
    holdX(trialID,1)    = holdXLoc;
    holdY(trialID,1)    = holdYLoc;
    tempArrayLocs       = finalArrayLocs{targetLocation(trialID,1)};
    
    % ADDING jitter
    jitterX             = maxJitterDVA.*(rand(8,1)-0.5);
    jitterY             = maxJitterDVA.*(rand(8,1)-0.5);
    tempArrayLocs(:,1)  = tempArrayLocs(:,1) + jitterX;
    tempArrayLocs(:,2)  = tempArrayLocs(:,2) + jitterY;
    
    % STIMULI ID and names
    targetImageID       = tdImgPairs(trialID, 1);
    distractorImageID   = tdImgPairs(trialID, 2);
    
    tempVar             = strsplit(imgFiles(targetImageID).name, '.');
    tdPairs{trialID, 1} = ['.\stim\' tempVar{1}];
    tempVar             = strsplit(imgFiles(distractorImageID).name, '.');
    tdPairs{trialID, 2} = ['.\stim\' tempVar{1}];
    
    % TRIALWISE stimulus locations
    targetX(trialID,1)       = tempArrayLocs(1,1);
    targetY(trialID,1)       = tempArrayLocs(1,2);
    distractor01X(trialID,1) = tempArrayLocs(2,1);
    distractor01Y(trialID,1) = tempArrayLocs(2,2);
    distractor02X(trialID,1) = tempArrayLocs(3,1);
    distractor02Y(trialID,1) = tempArrayLocs(3,2);
    distractor03X(trialID,1) = tempArrayLocs(4,1);
    distractor03Y(trialID,1) = tempArrayLocs(4,2);
    distractor04X(trialID,1) = tempArrayLocs(5,1);
    distractor04Y(trialID,1) = tempArrayLocs(5,2);
    distractor05X(trialID,1) = tempArrayLocs(6,1);
    distractor05Y(trialID,1) = tempArrayLocs(6,2);
    distractor06X(trialID,1) = tempArrayLocs(7,1);
    distractor06Y(trialID,1) = tempArrayLocs(7,2);
    distractor07X(trialID,1) = tempArrayLocs(8,1);
    distractor07Y(trialID,1) = tempArrayLocs(8,2);
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
    '''respRadius'',',              'respRadius'
    '''holdX'',',                   'holdX(trialID,1)'
    '''holdY'',',                   'holdY(trialID,1)'
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
    '''targetLocation'',',          'targetLocation(trialID,1)'
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
ml_makeConditionsOddball(timingFileName, conditionsFileName, tdPairs, info, frequency, block)
