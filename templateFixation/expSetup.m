clc; clear;

% FILE names
timingFileName     = 'fixTiming';
conditionsFileName = 'fixConditions.txt';

% IMAGE PAIRS - load filenames and make pairs
imgFiles    = dir('.\stim\*.bmp');
numImages   = length(imgFiles);
imgPerTrial = 4;
imgList     = nchoosek(1:numImages, imgPerTrial);
imgList     = [imgList; fliplr(imgList)];
imgList     = imgList(randperm(size(imgList, 1)), :);
block       = [ones(10,1); 2*ones(10,1); 3*ones(10,1);];
frequency   = ones(30,1);
trialFlag   = ones(30,1);

%% VARIABLES - trial timings
initPeriod   = 10000;
holdPeriod   = 200; 
samplePeriod = 400;
delayPeriod  = 200;

% INFO fields
infoFields =  {
    '''imgPerTrial'',',  'imgPerTrial'
    '''trialFlag'',',    'trialFlag(trialID,1)'
    '''initPeriod'',',   'initPeriod'
    '''holdPeriod'',',   'holdPeriod'
    '''samplePeriod'',', 'samplePeriod'
    '''delayPeriod'',',  'delayPeriod'
    };

% TRIAL info
maxImgPerTrial = 10;
diff = maxImgPerTrial - size(imgList,2);

if diff > 0
    imgList = [imgList ones(size(imgList,1), diff)];
end

for trialID = 1:length(imgList)
    for i = 1:10
        tempVar             = strsplit(imgFiles(imgList(trialID,i)).name, '.');
        fixNames{trialID, i} = ['.\stim\' tempVar{1}];
    end
    
    tempVar = [];
    
    for stringID   = 1:length(infoFields)
        value      = eval(char(infoFields(stringID,2)));
        stringVal  = char(infoFields(stringID,1));
        
        if isnumeric(value)
            tempVar = [tempVar stringVal num2str(value) ','];
        else
            tempVar = [tempVar stringVal '''' value '''' ','];
        end
    end
    
    info{trialID} = tempVar;    
end

% CREATE conditions file
ml_makeConditionsFix(timingFileName, conditionsFileName, fixNames, info, frequency, block)      
