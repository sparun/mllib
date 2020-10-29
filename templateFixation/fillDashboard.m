function lines = fillDashboard(tempVars, tempUser)

% JUICE consumption
totalJuiceConsumed = nansum(tempUser.juiceConsumed);

% DISPLAY strings
lines{1,1}  = sprintf('Good Pause =  %04d ms  |  Bad Pause = %04d ms | Reward = ml/click =  %1.2f ml | Total Juice = %3.1f ml',...
    tempVars.goodPause, tempVars.badPause, tempVars.rewardVol, totalJuiceConsumed);
end