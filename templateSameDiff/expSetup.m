clc; clear;

% FILE names
timingFileName     = 'sdTiming';
conditionsFileName = 'sdConditions.txt';

% IMAGE PAIRS - load filenames and make pairs
imgFiles  = dir('.\stim\*.bmp');
numImages = length(imgFiles);
samePairs = [1:numImages; 1:numImages]';
diffPairs = [1:numImages; 100-(1:numImages)]';
biasCorr  = lcm(length(diffPairs), length(samePairs));
diffPairs = repmat(diffPairs, (biasCorr/length(diffPairs)), 1);
samePairs = repmat(samePairs, (biasCorr/length(samePairs)), 1);

samePairs = [samePairs; fliplr(samePairs)];
diffPairs = [diffPairs; fliplr(diffPairs)];
pairs     = [samePairs; diffPairs];

% BLOCK creation
imgPairs  = [];
block     = [];
frequency = [];
blockL    = 12;
halfVal   = blockL/2;
count     = 1;

while(count <= ((length(pairs)) / blockL))
    
    remTrials = length(samePairs);
    
    rng('shuffle');
    select   = randperm(remTrials, halfVal);
    imgPairs = [imgPairs; samePairs(select, :)];
    samePairs(select,:) = [];
    
    rng('shuffle');
    select   = randperm(remTrials, halfVal);
    imgPairs = [imgPairs; diffPairs(select, :)];
    diffPairs(select,:) = [];
    
    block     = [block; count*(ones(blockL, 1))];
    frequency = [frequency; (ones(blockL, 1))];
    
    count = count + 1;
end

%% VARIABLES - trial timings
initPeriod   = 10000;
holdPeriod   = 200; 
samplePeriod = 400;
delayPeriod  = 200;
testPeriod   = 5000;
respPeriod   = 5000;

% INFO fields
infoFields =  {
    '''sampleImageID'',',    'imgPairs(trialID,1)'
    '''testImageID'',',      'imgPairs(trialID,2)'
    '''sampleImageFile'',',  'sdPairs{trialID,1}'
    '''testImageFile'',',    'sdPairs{trialID,2}'
    '''expectedResponse'',', 'expectedResponse(trialID,1)'
    '''trialFlag'',',        'trialFlag(trialID,1)'
    '''initPeriod'',',       'initPeriod'
    '''holdPeriod'',',       'holdPeriod'
    '''samplePeriod'',',     'samplePeriod'
    '''delayPeriod'',',      'delayPeriod'
    '''testPeriod'',',       'testPeriod'
    '''respPeriod'',',       'respPeriod'
    };

% TRIAL info
for trialID = 1:length(imgPairs)
    
    sampleImageID = imgPairs(trialID, 1);
    testImageID   = imgPairs(trialID, 2);
    
    tempVar             = strsplit(imgFiles(sampleImageID).name, '.');
    sdPairs{trialID, 1} = ['.\stim\' tempVar{1}];
    tempVar             = strsplit(imgFiles(testImageID).name, '.');
    sdPairs{trialID, 2} = ['.\stim\' tempVar{1}];
    
    if sampleImageID == testImageID
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
ml_makeConditionsSD(timingFileName, conditionsFileName, sdPairs, info, frequency, block)     
