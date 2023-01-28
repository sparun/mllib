% fillDashboard.m - VisionLab, IISc
%
% Example code that will return text strings for display on MonkeyLogic control screen
% where juice consumed is plotted. 
%
% INPUT
%   editables              - editables contain variables to display related to task
%   TrialRecord            - contains record of trials (correct, incorrect etc.)
%
% OUTPUT
%   line                   - formatted lines for display
%
% NOTE: This is only for templateFixation
%
% VERSION HISTORY
%    21-Feb-2021 - Thomas  - First documentation
% ----------------------------------------------------------------------------------------

function lines = fillDashboard(editables, TrialRecord)

% JUICE consumption
totalJuiceConsumed = nansum(TrialRecord.User.juiceConsumed);

% DISPLAY strings
lines{1,1}  = sprintf('Good Pause =  %04d ms  |  Bad Pause = %04d ms | Reward = ml/click =  %1.2f ml | Total Juice = %3.1f ml',...
    editables.goodPause, editables.badPause, editables.rewardVol, totalJuiceConsumed);
end