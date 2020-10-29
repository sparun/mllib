function ml_makeConditionsSD(timingFileName, conditionsFileName, sdPairs, info, frequency, block)
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
expTimingFile = timingFileName;
calTimingFile ='sdCalTiming';

% FIXED parameters that dont need to be changed for general task
iti          = 200;
buttonRadius = 4;
buttonColor  = [0 1 0];
ptdSize      = 3;
ptdBoxColor  = [1 1 1];
calibRadius  = 1;
calibColor   = [0.5 0.5 0.5];
holdRadius   = buttonRadius;

correctSoundFile   = '.\aud\correct.wav';
incorrectSoundFile = '.\aud\incorrect.wav';

infoFixed = sprintf('''iti'', %d,''holdRadius'', %2.2f,''buttonRadius'', %2.2f,''buttonColor'', [%2.2f %2.2f %2.2f],''calibRadius'', %2.2f,''calibColor'', [%2.2f %2.2f %2.2f], ''ptdBoxSize'', %2.2f, ''ptdBoxColor'',[%2.2f %2.2f %2.2f], ''correctSoundFile'',''%s'',''incorrectSoundFile'',''%s''',...
    iti, holdRadius, buttonRadius, buttonColor, calibRadius, calibColor, ptdSize, ptdBoxColor, correctSoundFile, incorrectSoundFile);

% WRITE the first line of the conditions file (describes each tab delimited column)
fprintf(conditionsFile, 'Condition\tInfo\tFrequency\tBlock\tTiming File\tTaskObject#1\tTaskObject#2\tTaskObject#3\tTaskObject#4\tTaskObject#5\tTaskObject#6\tTaskObject#7\tTaskObject#8\tTaskObject#9\tTaskObject#10\n');

% TASK objects - Static
taskObj1Ptd    = sprintf('sqr([3 2.5], [%d %d %d], 1,  0,  19)', ptdBoxColor);
taskObj2Hold   = sprintf('crc(%d, [%d %d %d], 1, 20,   0)', buttonRadius, buttonColor);
taskObj3Fix    = 'sqr([0.6 0.6], [0.5 0.5 0], 1, 0, 0)';
taskObj4Calib  = sprintf('crc(%1.1f, [%1.1f %1.1f %1.1f], 1, 0, 0)', calibRadius, calibColor);
taskObj5Same   = sprintf('crc(%d, [%d %d %d], 1, 20,  10)', buttonRadius, buttonColor);
taskObj6Diff   = sprintf('crc(%d, [%d %d %d], 1, 20, -10)', buttonRadius, buttonColor);
taskObj7Corr   = 'snd(.\aud\correct)';
taskObj8Incorr = 'snd(.\aud\incorrect)';

%% WRITE CALIBRATION conditions - Block 1 ------------------------------------------------
sampleName = sdPairs{1,1};
testName   = sdPairs{1,2};

% TASK objects - Variable
taskObj9Sample = sprintf('pic(%s, 0, 0)', sampleName);
taskObj10Test  = sprintf('pic(%s, 0, 0)', testName);

% PRINT to file
fprintf(conditionsFile, '%d\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 1,...
    [info{1} infoFixed], 1, 1, calTimingFile,...
    taskObj1Ptd,  taskObj2Hold,   taskObj3Fix,    taskObj4Calib,  taskObj5Same, taskObj6Diff,...
    taskObj7Corr, taskObj8Incorr, taskObj9Sample, taskObj10Test);

%% WRITE MAIN experiment conditions - Block 3 onward -------------------------------------
% Increment 'block' by 2 as block = calibration and block 2 = validation
block = block + 1;

for trialID = 1:length(sdPairs)
    sampleName = sdPairs{trialID,1};
    testName   = sdPairs{trialID,2};
    
    % TASK objects - Variable
    taskObj9Sample = sprintf('pic(%s, 0, 0)', sampleName);
    taskObj10Test  = sprintf('pic(%s, 0, 0)', testName);
    
    % PRINT to file (trialID+2 if cal val bloxcks present)
    fprintf(conditionsFile, '%d\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', trialID + 1,...
        [info{trialID} infoFixed], frequency(trialID), block(trialID), expTimingFile,...
        taskObj1Ptd,  taskObj2Hold,   taskObj3Fix,    taskObj4Calib,  taskObj5Same, taskObj6Diff,...
        taskObj7Corr, taskObj8Incorr, taskObj9Sample, taskObj10Test);
end

% CLOSE the conditions file
fclose(conditionsFile);

end