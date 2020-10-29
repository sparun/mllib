% ml_makeConditionsFix.m - Vision Lab, IISc
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
% ---------------------------------------------------------------------------------------

function ml_makeConditionsFix_modified(timingFileName, conditionsFileName, sdPairs, info, frequency, block)
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

% WRITE the first line of the conditions file (describes each tab delimited column)
fprintf(conditionsFile, ['Condition\t',   'Info\t',          'Frequency\t',  'Block\t',...
    'Timing File\t',   'TaskObject#1\t',  'TaskObject#2\t',  'TaskObject#3\t',...
    'TaskObject#4\t',  'TaskObject#5\t',  'TaskObject#6\t',  'TaskObject#7\t',...
    'TaskObject#8\t',  'TaskObject#9\t',  'TaskObject#10\t', 'TaskObject#11\t',...
    'TaskObject#12\t', 'TaskObject#13\t', 'TaskObject#14\t', 'TaskObject#15\t',...
    'TaskObject#16\n']);

% WRITE CALIBRATION conditions - Block 1 -------------------------------------------------
% TASK objects
taskObj07Fix01 = sprintf('pic(%s, 0, 0)', fixNames{1,1});
taskObj08Fix02 = sprintf('pic(%s, 0, 0)', fixNames{1,2});
taskObj09Fix03 = sprintf('pic(%s, 0, 0)', fixNames{1,3});
taskObj10Fix04 = sprintf('pic(%s, 0, 0)', fixNames{1,4});
taskObj11Fix05 = sprintf('pic(%s, 0, 0)', fixNames{1,5});
taskObj12Fix06 = sprintf('pic(%s, 0, 0)', fixNames{1,6});
taskObj13Fix07 = sprintf('pic(%s, 0, 0)', fixNames{1,7});
taskObj14Fix08 = sprintf('pic(%s, 0, 0)', fixNames{1,8});
taskObj15Fix09 = sprintf('pic(%s, 0, 0)', fixNames{1,9});
taskObj16Fix10 = sprintf('pic(%s, 0, 0)', fixNames{1,10});

if strcmpi(info{1}(end),',')
    info{1} = info{1}(1:end-1);
end

% PRINT to file
fprintf(conditionsFile, ['%d\t', '%s\t', '%d\t', '%d\t', '%s\t', '%s\t',...
    '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t',...
    '%s\t', '%s\t', '%s\t', '%s\t', '%s\n'],...
    1,               info{1},        1,              1,                calTimingFile,...
    taskObj01Ptd,    taskObj02Hold,  taskObj03Fix,   taskObj04Calib,   taskObj05Corr,...
    taskObj06Incorr, taskObj07Fix01, taskObj08Fix02, taskObj09Fix03,   taskObj10Fix04,...
    taskObj11Fix05,  taskObj12Fix06, taskObj13Fix07, taskObj14Fix08,   taskObj15Fix09,...
    taskObj16Fix10);

% WRITE MAIN experiment conditions - Block 2 onward --------------------------------------
% Increment 'block' by 1 as block 1 = calibration
block = block + 1;

for trialID = 1:length(sdPairs)
    
    taskObj07Fix01 = sprintf('pic(%s, 0, 0)', fixNames{trialID,1});
    taskObj08Fix02 = sprintf('pic(%s, 0, 0)', fixNames{trialID,2});
    taskObj09Fix03 = sprintf('pic(%s, 0, 0)', fixNames{trialID,3});
    taskObj10Fix04 = sprintf('pic(%s, 0, 0)', fixNames{trialID,4});
    taskObj11Fix05 = sprintf('pic(%s, 0, 0)', fixNames{trialID,5});
    taskObj12Fix06 = sprintf('pic(%s, 0, 0)', fixNames{trialID,6});
    taskObj13Fix07 = sprintf('pic(%s, 0, 0)', fixNames{trialID,7});
    taskObj14Fix08 = sprintf('pic(%s, 0, 0)', fixNames{trialID,8});
    taskObj15Fix09 = sprintf('pic(%s, 0, 0)', fixNames{trialID,9});
    taskObj16Fix10 = sprintf('pic(%s, 0, 0)', fixNames{trialID,10});
    
    if strcmpi(info{1}(end),',')
        info{1} = info{1}(1:end-1);
    end
        
    % PRINT to file
    fprintf(conditionsFile, ['%d\t', '%s\t', '%d\t', '%d\t', '%s\t', '%s\t',...
        '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t', '%s\t',...
        '%s\t', '%s\t', '%s\t', '%s\t', '%s\n'],...
        trialID + 1,     info{trialID},  frequency(trialID), block(trialID),  expTimingFile,...
        taskObj01Ptd,    taskObj02Hold,  taskObj03Fix,       taskObj04Calib,  taskObj05Corr,...
        taskObj06Incorr, taskObj07Fix01, taskObj08Fix02,     taskObj09Fix03,  taskObj10Fix04,...
        taskObj11Fix05,  taskObj12Fix06, taskObj13Fix07,     taskObj14Fix08,  taskObj15Fix09,...
        taskObj16Fix10);
    
end

% CLOSE the conditions file
fclose(conditionsFile);
end