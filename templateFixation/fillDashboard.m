% fillDashboard.m - VisionLab, IISc
%{
Example code that will return text strings for display on MonkeyLogic control screen
where juice consumed is plotted. The function takes TrialData.VariableChanges and
TrialRecord as input and return an array of formatted strings.

Note: this is only for template Fix

VERSION HISTORY
- 21-Feb-2021 - Thomas  - First documentation
%}
function lines = fillDashboard(editables, TrialRecord)

% JUICE consumption
totalJuiceConsumed = nansum(TrialRecord.User.juiceConsumed);

% DISPLAY strings
lines{1,1}  = sprintf('Good Pause =  %04d ms  |  Bad Pause = %04d ms | Reward = ml/click =  %1.2f ml | Total Juice = %3.1f ml',...
    editables.goodPause, editables.badPause, editables.rewardVol, totalJuiceConsumed);
end