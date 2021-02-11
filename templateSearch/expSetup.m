clc; clear;

% FILE names
timingFileName     = 'searchTiming';
conditionsFileName = 'searchConditions.txt';
imgFiles           = dir('.\stim\*.jpg');

% SETUP search pairs
nStim = 25;
nFeat = 5; % independent colour and shape features

% Present Searches
presentPairs = [];
imageIndex   = reshape(vec(1:nStim), 5, 5);

for k = 0:nFeat-1
    sI = [];
    for i = 1:nFeat
        for j = 1:nFeat
            sj = j + k;
            if(sj > nFeat)
                sj = sj - nFeat;
            end
            if(i == sj)
                sI = [sI; imageIndex(i, j)];
            end
        end
    end
    
    presentPairs = [presentPairs; nchoosek(sI, 2)];
end

presentPairs(1:2:end, :) = fliplr(presentPairs(1:2:end, :));

% Absent Searches
absentPairs = [vec(1:nStim), vec(1:nStim)];
absentPairs = repmat(absentPairs, [2, 1]);
searchPairs = [absentPairs;  presentPairs];

% BLOCK creation
tdImgPairs = [];
block      = [];
frequency  = [];
blockL     = 12; %10 with stimNew
halfVal    = blockL/2;
count      = 1;

while(count <= ((length(searchPairs)) / blockL))
    
    remTrials = length(absentPairs);
    
    rng('shuffle');
    select     = randperm(remTrials, halfVal);
    tdImgPairs = [tdImgPairs; absentPairs(select, :)];
    absentPairs(select,:) = [];
    
    rng('shuffle');
    select     = randperm(remTrials, halfVal);
    tdImgPairs = [tdImgPairs; presentPairs(select, :)];
    presentPairs(select,:) = [];
    
    block     = [block; count*(ones(blockL, 1))];
    frequency = [frequency; (ones(blockL, 1))];
    count     = count + 1;
end

%% VARIABLES - trial timings
holdInitPeriod = 10000;
fixInitPeriod  = 350;
searchPeriod   = 5000;
respPeriod     = 5000;

% INFO fields
infoFields =  {
    '''targetImageID'',',       'tdImgPairs(trialID,1)'
    '''distractorImageID'',',   'tdImgPairs(trialID,2)'
    '''targetImageFile'',',     'tdPairs{trialID,1}'
    '''distractorImageFile'',', 'tdPairs{trialID,2}'
    '''expectedResponse'',',    'expectedResponse(trialID,1)'
    '''trialFlag'',',           'trialFlag(trialID,1)'
    '''holdInitPeriod'',',      'holdInitPeriod'
    '''fixInitPeriod'',',       'fixInitPeriod'
    '''searchPeriod'',',        'searchPeriod'
    '''respPeriod'',',          'respPeriod'
    };

% TRIAL info
for trialID = 1:length(tdImgPairs)
    
    targetImageID       = tdImgPairs(trialID, 1);
    distractorImageID   = tdImgPairs(trialID, 2);
    
    tempVar             = strsplit(imgFiles(targetImageID).name, '.');
    tdPairs{trialID, 1} = ['.\stim\' tempVar{1}];
    tempVar             = strsplit(imgFiles(distractorImageID).name, '.');
    tdPairs{trialID, 2} = ['.\stim\' tempVar{1}];
    
    if targetImageID == distractorImageID
        expectedResponse(trialID,1)  = 1;
        trialFlag(trialID,1)  = 1;
    else
        expectedResponse(trialID, 1) = 2;
        trialFlag(trialID,1)  = 2;
    end
    
    tempVar = [];
    
    for stringID = 1:length(infoFields)
         
        value      = eval(char(infoFields(stringID,2)));
        stringVal  = char(infoFields(stringID,1));
        
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
    
    info{trialID} = tempVar;    
end

%% CREATE conditions file
ml_makeConditionsSearch(timingFileName, conditionsFileName, tdPairs, info, frequency, block)     
