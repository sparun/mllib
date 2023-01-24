% MAKE CONDITIONS VISUAL SEARCH (ODDBALL) - NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Creates the condition file (*.txt) in the format readable by MonkeyLogic 2. This file is
% then loaded in the GUI, which in turn loads all taskobjects required to run the
% Visual Search (Oddball) experiment.
%
% INPUTS
%   timingFileName      - the name of the timing file (without file extension).
%   conditionsFileName  - the name of the conditions file (without VSO-prefix or file extension).
%   tdPairs             - nTrials x 2 (target, distractor) - file names (without file extension)
%                         of the stimuli used in each trial
%   info                - nTrials x 1 - text string containing variable names followed by variable values
%                         that can be accessed in the timing file (eg:'text','ab','num',1).
%   frequency           - nTrials x 1 - repetitions for each condition within the block (for most cases = 1).
%   block               - nTrials x 1 - block ID for each condition.
%
% OUTPUT
%   "VSO-conditionsFileName.txt" in the current directory
%
% VERSION HISTORY
% 27-Feb-2022 - Thomas  - First implementation
% 30-Dec-2022 - Thomas  - Updated task name to visual search (oddball) (VSO)
% ----------------------------------------------------------------------------------------

function ml_makeConditionsVisualSearchOddball(timingFileName, conditionsFileName, tdPairs, info, frequency, block)
% OPEN the conditions .txt file for writing
conditionsFile = fopen(['VSO-' conditionsFileName '.txt'], 'w');

% TIMING file name
expTimingFile = timingFileName;
calTimingFile = 'calTiming';

% PROPERTIES for static TaskObjects
ptdSqrLoc       = [0 19];
ptdSqrSize      = '[3.0 2.5]';
ptdSqrColor     = '[1 1 1]';
buttonLoc       = [20 10]; % [holdButtonX/respButtonX respButtonY]
buttonSize      = '4';
buttonColor     = '[0.33 0.33 0]';
initFixCueSize  = '0.1';
initFixCueColor = '[1 1 0]';
stimFixCueColor = '[0 0 0]';
calibCueSize    = '0.5';
calibCueColor   = '[0.5 0.5 0.5]';

% STATIC TaskObjects (1 to 7)
photodiodeCue  = sprintf('sqr(%s, %s, 1, %d, %d)',  ptdSqrSize,     ptdSqrColor, ptdSqrLoc(1), ptdSqrLoc(2));
holdButton     = sprintf('crc(%s, %s, 1, %d, 0)',   buttonSize,     buttonColor, buttonLoc(1));
initFixCue     = sprintf('crc(%s, %s, 1, 0,  0)',   initFixCueSize, initFixCueColor);
stimFixCue     = sprintf('crc(%s, %s, 1, 0,  0)',   initFixCueSize, stimFixCueColor);
calibCue       = sprintf('crc(%s, %s, 1, 0,  0)',   calibCueSize,   calibCueColor);
sameButton     = sprintf('crc(%s, %s, 1, %d, %d)',  buttonSize,     buttonColor, buttonLoc(1), buttonLoc(2));
diffButton     = sprintf('crc(%s, %s, 1, %d, -%d)', buttonSize,     buttonColor, buttonLoc(1), buttonLoc(2));
correctAudio   = 'snd(.\aud\correct)';
wrongAudio     = 'snd(.\aud\incorrect)';

% WRITE the first line of the conditions file (describes each tab delimited column)
fprintf(conditionsFile, [...
    'Condition\t',     'Info\t',          'Frequency\t',     'Block\t',         'Timing File\t',...
    'TaskObject#1\t',  'TaskObject#2\t',  'TaskObject#3\t',  'TaskObject#4\t',  'TaskObject#5\t',...
    'TaskObject#6\t',  'TaskObject#7\t',  'TaskObject#8\t',  'TaskObject#9\t',  'TaskObject#10\t',...
    'TaskObject#11\t', 'TaskObject#12\t', 'TaskObject#13\t', 'TaskObject#14\t', 'TaskObject#15\t',...
    'TaskObject#16\t', 'TaskObject#17\n']);

% WRITE CALIBRATION conditions - Block 1 -------------------------------------------------
% DUMMY TaskObjects for calibration trial (10 to 17)
target       = sprintf('pic(%s, 0, 0)', tdPairs{1,1});
distractor01 = sprintf('pic(%s, 0, 0)', tdPairs{1,2});
distractor02 = sprintf('pic(%s, 0, 0)', tdPairs{1,2});
distractor03 = sprintf('pic(%s, 0, 0)', tdPairs{1,2});
distractor04 = sprintf('pic(%s, 0, 0)', tdPairs{1,2});
distractor05 = sprintf('pic(%s, 0, 0)', tdPairs{1,2});
distractor06 = sprintf('pic(%s, 0, 0)', tdPairs{1,2});
distractor07 = sprintf('pic(%s, 0, 0)', tdPairs{1,2});

% PRINT to file
fprintf(conditionsFile, [...
    '%d\t',        '%s\t',       '%d\t',       '%d\t',       '%s\t',...
    '%s\t',        '%s\t',       '%s\t',       '%s\t',       '%s\t',...
    '%s\t',        '%s\t',       '%s\t',       '%s\t',       '%s\t',...
    '%s\t',        '%s\t',       '%s\t',       '%s\t',       '%s\t',...
    '%s\t',        '%s\n'],...
    1,             info{1},      1,            1,            calTimingFile,...
    photodiodeCue, holdButton,   initFixCue,   stimFixCue,   calibCue,...
    correctAudio,  wrongAudio,   sameButton,   diffButton,   target,...
    distractor01,  distractor02, distractor03, distractor04, distractor05,...
    distractor06,  distractor07);

% WRITE MAIN experiment conditions - Block 2 onward --------------------------------------
% Increment 'block' by 1 as block 1 = calibration
block = block + 1;

for trialID = 1:length(tdPairs)    
    % VARIBLE TaskObjects for Search trials (10 to 17)
    target       = sprintf('pic(%s, 0, 0)', tdPairs{trialID,1});
    distractor01 = sprintf('pic(%s, 0, 0)', tdPairs{trialID,2});
    distractor02 = sprintf('pic(%s, 0, 0)', tdPairs{trialID,2});
    distractor03 = sprintf('pic(%s, 0, 0)', tdPairs{trialID,2});
    distractor04 = sprintf('pic(%s, 0, 0)', tdPairs{trialID,2});
    distractor05 = sprintf('pic(%s, 0, 0)', tdPairs{trialID,2});
    distractor06 = sprintf('pic(%s, 0, 0)', tdPairs{trialID,2});
    distractor07 = sprintf('pic(%s, 0, 0)', tdPairs{trialID,2});
    
    % PRINT to file
    fprintf(conditionsFile, [...
        '%d\t',        '%s\t',        '%d\t',             '%d\t',        '%s\t',...
        '%s\t',        '%s\t',        '%s\t',             '%s\t',        '%s\t',...
        '%s\t',        '%s\t',        '%s\t',             '%s\t',        '%s\t',...
        '%s\t',        '%s\t',        '%s\t',             '%s\t',        '%s\t',...
        '%s\t',        '%s\n'],...
        trialID + 1,   info{trialID}, frequency(trialID), block(trialID), expTimingFile,...
        photodiodeCue, holdButton,    initFixCue,         stimFixCue,     calibCue,...
        correctAudio,  wrongAudio,    sameButton,         diffButton,     target,...
        distractor01,  distractor02,  distractor03,       distractor04,   distractor05,...
        distractor06,  distractor07);
end

% CLOSE the conditions file
fclose(conditionsFile);
end