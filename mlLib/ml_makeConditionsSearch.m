% ml_makeConditionsSearch.m - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Creates the condition file (*.txt) in the format readable by MonkeyLogic 2. This file is
% then loaded in the GUI, which in turn loads all taskobjects required to run the
% Present-Absent visual search template experiment.
%
% INPUTS
%
% timingFileName     - the name of the timing file (extension not required).
% conditionsFileName - the name of the conditions file (*.txt).
% tdPairs            - file names (without extension) of the stimuli used in each trial
%                      (target and distractor stimuli).
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
% - 06-Feb-2021 - Thomas  - First implementation (2x2 array, simple search)
% ---------------------------------------------------------------------------------------

function ml_makeConditionsSearch(timingFileName, conditionsFileName, tdPairs, info, frequency, block)
% OPEN the conditions .txt file for writing
conditionsFile = fopen(conditionsFileName, 'w');

% TIMING file name
expTimingFile = timingFileName;
calTimingFile ='calTiming';

% TASK objects - Static
taskObj01Ptd    = 'sqr([3.0 2.5], [1 1 1], 1,  0,  19)';
taskObj02Hold   = 'crc(4, [1 0 1], 1, 25, 0)';
taskObj03Fix    = 'sqr([0.6 0.6], [0.5 0.5 0], 1, 0, 0)';
taskObj04Calib  = 'crc(1, [0.5 0.5 0.5], 1, 0, 0)';
taskObj05Corr   = 'snd(.\aud\correct)';
taskObj06Incorr = 'snd(.\aud\incorrect)';
taskObj07Same   = 'crc(4, [1 0 1], 1, 25, 10)';
taskObj08Diff   = 'crc(4, [1 0 1], 1, 25, -10)';

% WRITE the first line of the conditions file (describes each tab delimited column)
fprintf(conditionsFile, ['Condition\t', 'Info\t',         'Frequency\t',  'Block\t',...
    'Timing File\t',  'TaskObject#1\t', 'TaskObject#2\t', 'TaskObject#3\t',...
    'TaskObject#4\t', 'TaskObject#5\t', 'TaskObject#6\t', 'TaskObject#7\t',...
    'TaskObject#8\t', 'TaskObject#9\t',  'TaskObject#10\t', 'TaskObject#11\t',...
    'TaskObject#12\n']);

% WRITE CALIBRATION conditions - Block 1 -------------------------------------------------
% TASK objects
targetName           = tdPairs{1,1};
distractorName       = tdPairs{1,2};
taskObj09Target      = sprintf('pic(%s, 0, 0)', targetName);
taskObj10Distractor1 = sprintf('pic(%s, 0, 0)', distractorName);
taskObj11Distractor2 = sprintf('pic(%s, 0, 0)', distractorName);
taskObj12Distractor3 = sprintf('pic(%s, 0, 0)', distractorName);

% PRINT to file
fprintf(conditionsFile, ['%d\t', '%s\t', '%d\t', '%d\t', '%s\t', '%s\t',...
    '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\n'],...
    1,                    info{1},              1,                   1,               calTimingFile,...
    taskObj01Ptd,         taskObj02Hold,        taskObj03Fix,        taskObj04Calib,  taskObj05Corr,...
    taskObj06Incorr,      taskObj07Same,        taskObj08Diff,       taskObj09Target, taskObj10Distractor1,...
    taskObj11Distractor2, taskObj12Distractor3);

% WRITE MAIN experiment conditions - Block 2 onward --------------------------------------
% Increment 'block' by 1 as block 1 = calibration
block = block + 1;

for trialID = 1:length(tdPairs)    
    % TASK objects - Variable
    targetName           = tdPairs{trialID,1};
    distractorName       = tdPairs{trialID,2};   
    taskObj09Target      = sprintf('pic(%s, 0, 0)', targetName);
    taskObj10Distractor1 = sprintf('pic(%s, 0, 0)', distractorName);
    taskObj11Distractor2 = sprintf('pic(%s, 0, 0)', distractorName);
    taskObj12Distractor3 = sprintf('pic(%s, 0, 0)', distractorName);
    
    % PRINT to file
    fprintf(conditionsFile, ['%d\t', '%s\t', '%d\t', '%d\t', '%s\t', '%s\t',...
        '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\n'],...
        trialID + 1,          info{trialID},        frequency(trialID),  block(trialID),  expTimingFile,...
        taskObj01Ptd,         taskObj02Hold,        taskObj03Fix,        taskObj04Calib,  taskObj05Corr,...
        taskObj06Incorr,      taskObj07Same,        taskObj08Diff,       taskObj09Target, taskObj10Distractor1,...
        taskObj11Distractor2, taskObj12Distractor3);
end

% CLOSE the conditions file
fclose(conditionsFile);
end