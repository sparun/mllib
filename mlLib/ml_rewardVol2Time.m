% ml_rewardVol2Time.m - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Converts required juice volume into juice motor ON duration based on calibration using
% differing periods on ON time and dispensed juice
% 
% VERSION HISTORY
% - 15-Oct-2020  - Thomas - First commented and update variable names
%-----------------------------------------------------------------------------------------

function rewardTime = ml_rewardVol2Time(rewardMl)  

rewardTime = 1000*(1.02 * rewardMl - 0.0439);

end