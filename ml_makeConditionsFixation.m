% MAKE CONDITIONS FIXATION - NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Creates the condition file (*.txt) in the format readable by MonkeyLogic 2. This file is
% then loaded in the GUI, which in turn loads all taskobjects required to run the
% Same Diff template experiment.
%
% INPUTS
%   timingFileName      - the name of the timing file (without file extension).
%   conditionsFileName  - the name of the conditions file (without FIX-prefix or file extension).
%   fixNames            - nTrials x 10 - file names (without extension) of the stimuli used in each trial.
%   info                - nTrials x 1 - text string containing variable names followed by variable values
%                         that can be accessed in the timing file (eg:'text','ab','num',1).
%   frequency           - nTrials x 1 - repetitions for each condition within the block (for most cases = 1).
%   block               - nTrials x 1 - block ID for each condition.
%   stimFixCueColorFlag - if 1, stimFixCue visible and same color as initFixCue, else black.
%
% OUTPUT
%   "FIX-conditionsFileName.txt" in the current directory
%
% VERSION HISTORY
% 14-Jun-2019 - Thomas  - First implementation
%               Zhivago
% 09-Mar-2020 - Thomas  - Integrated calibration and validation blocks as block 1
%               Jhilik    and 2 respectively
%               Harish
% 22-Oct-2020 - Thomas  - Removed validation block, fixed info and other minor updates
% 29-Oct-2020 - Thomas  - Removed extra info
% 01-Nov-2020 - Arun    - Changed hold button color to blue from green
%               Jhilik 
% 03-Nov-2021 - Thomas  - Reworked to include stimFix cue, reduced holf brightness and 
%                         fixCue and calibCue size
% 30-Dec-2022 - Thomas  - Updated task name to visual search (oddball) (VSO)
% ----------------------------------------------------------------------------------------

function ml_makeConditionsFixation(timingFileName, conditionsFileName, fixNames, info, frequency, block, stimFixCueColorFlag)
% OPEN the conditions .txt file for writing
conditionsFile = fopen(['FIX-' conditionsFileName '.txt'], 'w');

% TIMING file name
expTimingFile = timingFileName;
calTimingFile = 'calTiming';

% PROPERTIES for static TaskObjects
ptdSqrLoc       = [0 19];
ptdSqrSize      = '[3.0 2.5]';
ptdSqrColor     = '[1 1 1]';
buttonLoc       = 20; % holdButtonX
buttonSize      = '4';
buttonColor     = '[0 0 0.33]';
initFixCueSize  = '0.1';
initFixCueColor = '[1 1 0]';
stimFixCueColor = '[0 0 0]';
calibCueSize    = '0.5';
calibCueColor   = '[0.5 0.5 0.5]';
if stimFixCueColorFlag == 1
    stimFixCueColor = initFixCueColor;
end

% STATIC TaskObjects (1 to 7)
photodiodeCue  = sprintf('sqr(%s, %s, 1, %d, %d)', ptdSqrSize,     ptdSqrColor, ptdSqrLoc(1), ptdSqrLoc(2));
holdButton     = sprintf('crc(%s, %s, 1, %d, 0)',  buttonSize,     buttonColor, buttonLoc(1));
initFixCue     = sprintf('crc(%s, %s, 1, 0,  0)',  initFixCueSize, initFixCueColor);
stimFixCue     = sprintf('crc(%s, %s, 1, 0,  0)',  initFixCueSize, stimFixCueColor);
calibCue       = sprintf('crc(%s, %s, 1, 0,  0)',  calibCueSize,   calibCueColor);
correctAudio   = 'snd(.\aud\correct)';
wrongAudio     = 'snd(.\aud\incorrect)';

% WRITE the first line of the conditions file (describes each tab delimited column)
fprintf(conditionsFile, [...
    'Condition\t',     'Info\t',          'Frequency\t',     'Block\t',         'Timing File\t',...
    'TaskObject#1\t',  'TaskObject#2\t',  'TaskObject#3\t',  'TaskObject#4\t',  'TaskObject#5\t',...
    'TaskObject#6\t',  'TaskObject#7\t',  'TaskObject#8\t',  'TaskObject#9\t',  'TaskObject#10\t',...
    'TaskObject#11\t', 'TaskObject#12\t', 'TaskObject#13\t', 'TaskObject#14\t', 'TaskObject#15\t',...
    'TaskObject#16\t', 'TaskObject#17\n']);

%% WRITE CALIBRATION conditions - Block 1
% DUMMY TaskObjects for calibration trial (8 to 17)
fixationImage01 = sprintf('pic(%s, 0, 0)', fixNames{1,1});
fixationImage02 = sprintf('pic(%s, 0, 0)', fixNames{1,2});
fixationImage03 = sprintf('pic(%s, 0, 0)', fixNames{1,3});
fixationImage04 = sprintf('pic(%s, 0, 0)', fixNames{1,4});
fixationImage05 = sprintf('pic(%s, 0, 0)', fixNames{1,5});
fixationImage06 = sprintf('pic(%s, 0, 0)', fixNames{1,6});
fixationImage07 = sprintf('pic(%s, 0, 0)', fixNames{1,7});
fixationImage08 = sprintf('pic(%s, 0, 0)', fixNames{1,8});
fixationImage09 = sprintf('pic(%s, 0, 0)', fixNames{1,9});
fixationImage10 = sprintf('pic(%s, 0, 0)', fixNames{1,10});

% PRINT to file
fprintf(conditionsFile, [...
    '%d\t',          '%s\t',          '%d\t',          '%d\t',          '%s\t',...
    '%s\t',          '%s\t',          '%s\t',          '%s\t',          '%s\t',...
    '%s\t',          '%s\t',          '%s\t',          '%s\t',          '%s\t',...
    '%s\t',          '%s\t',          '%s\t',          '%s\t',          '%s\t',...
    '%s\t',          '%s\n'],...
    1,               info{1},          1,              1,               calTimingFile,...
    photodiodeCue,   holdButton,      initFixCue,      stimFixCue,      calibCue,...
    correctAudio,    wrongAudio,      fixationImage01, fixationImage02, fixationImage03,...
    fixationImage04, fixationImage05, fixationImage06, fixationImage07, fixationImage08,...
    fixationImage09, fixationImage10);

%% WRITE MAIN experiment conditions - Block 2 onward
% Increment 'block' by 1 as block 1 = calibration
block = block + 1;

for trialID = 1:size(fixNames,1)
    % VARIBLE TaskObjects for Fixation trials (8 to 17)
    fixationImage01 = sprintf('pic(%s, 0, 0)', fixNames{trialID,1});
    fixationImage02 = sprintf('pic(%s, 0, 0)', fixNames{trialID,2});
    fixationImage03 = sprintf('pic(%s, 0, 0)', fixNames{trialID,3});
    fixationImage04 = sprintf('pic(%s, 0, 0)', fixNames{trialID,4});
    fixationImage05 = sprintf('pic(%s, 0, 0)', fixNames{trialID,5});
    fixationImage06 = sprintf('pic(%s, 0, 0)', fixNames{trialID,6});
    fixationImage07 = sprintf('pic(%s, 0, 0)', fixNames{trialID,7});
    fixationImage08 = sprintf('pic(%s, 0, 0)', fixNames{trialID,8});
    fixationImage09 = sprintf('pic(%s, 0, 0)', fixNames{trialID,9});
    fixationImage10 = sprintf('pic(%s, 0, 0)', fixNames{trialID,10});
    
    % PRINT to file
    fprintf(conditionsFile, [...
    '%d\t',          '%s\t',          '%d\t',             '%d\t',          '%s\t',...
    '%s\t',          '%s\t',          '%s\t',             '%s\t',          '%s\t',...
    '%s\t',          '%s\t',          '%s\t',             '%s\t',          '%s\t',...
    '%s\t',          '%s\t',          '%s\t',             '%s\t',          '%s\t',...
    '%s\t',          '%s\n'],...
    trialID + 1,     info{trialID},   frequency(trialID), block(trialID),  expTimingFile,...
    photodiodeCue,   holdButton,      initFixCue,         stimFixCue,      calibCue,...
    correctAudio,    wrongAudio,      fixationImage01,    fixationImage02, fixationImage03,...
    fixationImage04, fixationImage05, fixationImage06,    fixationImage07, fixationImage08,...
    fixationImage09, fixationImage10);    
end

% CLOSE the conditions file
fclose(conditionsFile);
end