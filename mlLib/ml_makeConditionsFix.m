function ml_makeConditionsFix(timingFileName, conditionsFileName, fixNames, info, frequency, block)
% ----------------------------------------------------------------------------------------
% Creates the condition file (*.txt) in the format readable by MonkeyLogic 2. This file is
% then loaded in the GUI, which in turn loads all taskobjects required to run the
% experiment.
%
% INPUTS
%
% timingFileName     - the name of the timing file (extension not required).
% conditionsFileName - the name of the conditions file (*.txt).
% sdPairs            - file names (without extension) of the stimuli used in each trial
%                      (sample and test stimuli).
% info               - text string containing variable names followed by variable values
%                      that can be accessed in the timing file (eg:'text','ab','num',1).
% frequency          - the repetitions required for each condition to counter-balance.
% block              - the block ID for each condition.
%
% OUTPUT
%
% "conditionsFileName.txt" in the current directory
%
% ----------------------------------------------------------------------------------------
% VERSION HISTORY
% ----------------------------------------------------------------------------------------
% - 14-Jun-2019  - Thomas and Zhivago - First implementation
% ----------------------------------------------------------------------------------------
% - 09-Mar-2020  - Thomas, Jhilik and Harish - Integrated calibration and validation
%                                              blocks as block 1 and 2 respectively
% ---------------------------------------------------------------------------------------

% OPEN the conditions .txt file for writing
conditionsFile = fopen(conditionsFileName, 'w');

% TIMING file name
expTimingFile  = timingFileName;
calTimingFile  = 'fixCalTiming';

% FIXED parameters that dont need to be changed for general task
iti          = 200;
buttonRadius = 4;
buttonColor  = [0 1 0];
ptdSize      = 3;
ptdBoxColor  = [1 1 1];
calibRadius  = 1;
calibColor   = [0.5 0.5 0.5];
holdRadius   = buttonRadius;

correctSoundFile   = '.\dep\correct.wav';
incorrectSoundFile = '.\dep\incorrect.wav';

infoFixed = sprintf('''iti'', %d,''holdRadius'', %2.2f,''buttonRadius'', %2.2f,''buttonColor'', [%2.2f %2.2f %2.2f],''calibRadius'', %2.2f,''calibColor'', [%2.2f %2.2f %2.2f], ''ptdBoxSize'', %2.2f, ''ptdBoxColor'',[%2.2f %2.2f %2.2f], ''correctSoundFile'',''%s'',''incorrectSoundFile'',''%s''',...
    iti, holdRadius, buttonRadius, buttonColor, calibRadius, calibColor, ptdSize, ptdBoxColor, correctSoundFile, incorrectSoundFile);

% WRITE the first line of the conditions file (describes each tab delimited column)
fprintf(conditionsFile, 'Condition\tInfo\tFrequency\tBlock\tTiming File\tTaskObject#1\tTaskObject#2\tTaskObject#3\tTaskObject#4\tTaskObject#5\tTaskObject#6\tTaskObject#7\tTaskObject#8\tTaskObject#9\tTaskObject#10\tTaskObject#11\tTaskObject#12\tTaskObject#13\tTaskObject#14\tTaskObject#15\tTaskObject#16\n');

% TASK objects - Static
taskObj1Ptd    = sprintf('sqr([%d %d], [%d %d %d], 1,  0,  19)', ptdSize, ptdSize, ptdBoxColor);
taskObj2Hold   = sprintf('crc(%d, [%d %d %d], 1, 20,   0)', buttonRadius, buttonColor);
taskObj3Fix    = 'sqr([0.3 0.3], [0.5 0.5 0], 1, 0, 0)';
taskObj4Calib  = sprintf('crc(%1.1f, [%1.1f %1.1f %1.1f], 1, 0, 0)', calibRadius, calibColor);
taskObj5Corr   = 'snd(.\dep\correct)';
taskObj6Incorr = 'snd(.\dep\incorrect)';

%% WRITE CALIBRATION conditions - Block 1 ------------------------------------------------

trialID = 1;
% TASK objects - Variable
taskObj7Fix1   = sprintf('pic(%s, 0, 0)', fixNames{trialID,1});
taskObj8Fix2   = sprintf('pic(%s, 0, 0)', fixNames{trialID,2});
taskObj9Fix3   = sprintf('pic(%s, 0, 0)', fixNames{trialID,3});
taskObj10Fix4  = sprintf('pic(%s, 0, 0)', fixNames{trialID,4});
taskObj11Fix5  = sprintf('pic(%s, 0, 0)', fixNames{trialID,5});
taskObj12Fix6  = sprintf('pic(%s, 0, 0)', fixNames{trialID,6});
taskObj13Fix7  = sprintf('pic(%s, 0, 0)', fixNames{trialID,7});
taskObj14Fix8  = sprintf('pic(%s, 0, 0)', fixNames{trialID,8});
taskObj15Fix9  = sprintf('pic(%s, 0, 0)', fixNames{trialID,9});
taskObj16Fix10 = sprintf('pic(%s, 0, 0)', fixNames{trialID,10});

% PRINT to file
fprintf(conditionsFile, '%d\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 1,...
    [info{trialID} infoFixed], 1, 1, calTimingFile, taskObj1Ptd, taskObj2Hold, taskObj3Fix,...
    taskObj4Calib, taskObj5Corr,  taskObj6Incorr,...
    taskObj7Fix1,  taskObj8Fix2,  taskObj9Fix3,   taskObj10Fix4, taskObj11Fix5,...
    taskObj12Fix6, taskObj13Fix7, taskObj14Fix8,  taskObj15Fix9, taskObj16Fix10);

%% WRITE MAIN experiment conditions - Block 2 onward -------------------------------------
% Increment 'block' by 1 as block 1 = calibration
block = block + 1;

for trialID = 1:length(fixNames)
    
    % TASK objects - Variable
    taskObj7Fix1   = sprintf('pic(%s, 0, 0)', fixNames{trialID,1});
    taskObj8Fix2   = sprintf('pic(%s, 0, 0)', fixNames{trialID,2});
    taskObj9Fix3   = sprintf('pic(%s, 0, 0)', fixNames{trialID,3});
    taskObj10Fix4  = sprintf('pic(%s, 0, 0)', fixNames{trialID,4});
    taskObj11Fix5  = sprintf('pic(%s, 0, 0)', fixNames{trialID,5});
    taskObj12Fix6  = sprintf('pic(%s, 0, 0)', fixNames{trialID,6});
    taskObj13Fix7  = sprintf('pic(%s, 0, 0)', fixNames{trialID,7});
    taskObj14Fix8  = sprintf('pic(%s, 0, 0)', fixNames{trialID,8});
    taskObj15Fix9  = sprintf('pic(%s, 0, 0)', fixNames{trialID,9});
    taskObj16Fix10 = sprintf('pic(%s, 0, 0)', fixNames{trialID,10});
    
    % PRINT to file
    fprintf(conditionsFile, '%d\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', trialID + 1,...
        [info{trialID} infoFixed], frequency(trialID), block(trialID), expTimingFile, taskObj1Ptd, taskObj2Hold, taskObj3Fix,...
        taskObj4Calib, taskObj5Corr, taskObj6Incorr,...
        taskObj7Fix1, taskObj8Fix2, taskObj9Fix3, taskObj10Fix4, taskObj11Fix5,...
        taskObj12Fix6, taskObj13Fix7, taskObj14Fix8, taskObj15Fix9, taskObj16Fix10);
end

% CLOSE the conditions file
fclose(conditionsFile);

end