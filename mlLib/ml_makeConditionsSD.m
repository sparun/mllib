% ml_makeConditionsSD.m - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Creates the condition file (*.txt) in the format readable by MonkeyLogic 2. This file is
% then loaded in the GUI, which in turn loads all taskobjects required to run the
% Same Diff template experiment.
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
% VERSION HISTORY
% - 14-Jun-2019 - Thomas  - First implementation
%                 Zhivago
% - 09-Mar-2020 - Thomas  - Integrated calibration and validation blocks as block 1
%                 Jhilik    and 2 respectively
%                 Harish
% - 22-Oct-2020 - Thomas  - Removed validation block, fixed info and other minor updates
% - 29-Oct-2020 - Thomas  - Removed extra info
% ---------------------------------------------------------------------------------------

function ml_makeConditionsSD(timingFileName, conditionsFileName, sdPairs, info, frequency, block)
% OPEN the conditions .txt file for writing
conditionsFile = fopen(conditionsFileName, 'w');

% TIMING file name
expTimingFile = timingFileName;
calTimingFile ='calTiming';

% TASK objects - Static
taskObj01Ptd    = 'sqr([3.0 2.5], [1 1 1], 1,  0,  19)';
taskObj02Hold   = 'crc(4, [0 1 0], 1, 20, 0)';
taskObj03Fix    = 'sqr([0.6 0.6], [0.5 0.5 0], 1, 0, 0)';
taskObj04Calib  = 'crc(1, [0.5 0.5 0.5], 1, 0, 0)';
taskObj05Corr   = 'snd(.\aud\correct)';
taskObj06Incorr = 'snd(.\aud\incorrect)';
taskObj07Same   = 'crc(4, [0 1 0], 1, 20, 10)';
taskObj08Diff   = 'crc(4, [0 1 0], 1, 20, -10)';

% WRITE the first line of the conditions file (describes each tab delimited column)
fprintf(conditionsFile, ['Condition\t', 'Info\t',         'Frequency\t',  'Block\t',...
    'Timing File\t',  'TaskObject#1\t', 'TaskObject#2\t', 'TaskObject#3\t',...
    'TaskObject#4\t', 'TaskObject#5\t', 'TaskObject#6\t', 'TaskObject#7\t',...
    'TaskObject#8\t', 'TaskObject#9\t', 'TaskObject#10\n']);

% WRITE CALIBRATION conditions - Block 1 -------------------------------------------------
% TASK objects
sampleName      = sdPairs{1,1};
testName        = sdPairs{1,2};
taskObj09Sample = sprintf('pic(%s, 0, 0)', sampleName);
taskObj10Test   = sprintf('pic(%s, 0, 0)', testName);

% PRINT to file
fprintf(conditionsFile, ['%d\t', '%s\t', '%d\t', '%d\t', '%s\t', '%s\t',...
    '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\n'],...
    1,               info{1},       1,             1,               calTimingFile,...
    taskObj01Ptd,    taskObj02Hold, taskObj03Fix,  taskObj04Calib,  taskObj05Corr,...
    taskObj06Incorr, taskObj07Same, taskObj08Diff, taskObj09Sample, taskObj10Test);

% WRITE MAIN experiment conditions - Block 2 onward --------------------------------------
% Increment 'block' by 1 as block 1 = calibration
block = block + 1;

for trialID = 1:length(sdPairs)    
    % TASK objects - Variable
    sampleName      = sdPairs{trialID,1};
    testName        = sdPairs{trialID,2};   
    taskObj09Sample = sprintf('pic(%s, 0, 0)', sampleName);
    taskObj10Test   = sprintf('pic(%s, 0, 0)', testName);
    
    % PRINT to file
    fprintf(conditionsFile, ['%d\t', '%s\t', '%d\t', '%d\t', '%s\t', '%s\t',...
        '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\n'],...
        trialID + 1,     info{trialID}, frequency(trialID), block(trialID),  expTimingFile,...
        taskObj01Ptd,    taskObj02Hold, taskObj03Fix,       taskObj04Calib,  taskObj05Corr,...
        taskObj06Incorr, taskObj07Same, taskObj08Diff,      taskObj09Sample, taskObj10Test);
end

% CLOSE the conditions file
fclose(conditionsFile);
end