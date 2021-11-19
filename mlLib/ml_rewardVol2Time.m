% CALCULATE MOTOR RUN TIME FOR JUICE - NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Converts required juice volume into juice motor ON duration (in millliseconds) based on 
% calibration using differing periods on ON time and dispensed juice. The models terms
% must be calculated from a dedicated juice calibration routine and modelling effort.
% 
% VERSION HISTORY
%{
15-Oct-2020 - Thomas - First commented and update variable names
09-Nov-2021 - Thomas - Elaborated the model terms 
%}
%-----------------------------------------------------------------------------------------

function rewardTime = ml_rewardVol2Time(rewardVol)  
% LINEAR MODEL y = aX + b values (from calibration)
a = 1.02;
X = rewardVol;
b = -0.0439;

% MOTOR RUN TIME needed to deliver required juice
Y          = 1000*((a*X) + b);
rewardTime = Y;
end