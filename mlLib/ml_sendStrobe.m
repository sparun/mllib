% ml_sendStrobe.m - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% SEND a strobe pulse on a single bit session opened by ml_openSession.m
% 
% VERSION HISTORY
% - 15-Oct-2020  - Thomas - First commented
%-----------------------------------------------------------------------------------------

function ml_sendStrobe(transmitSession2)
% Strobe
outputSingleScan(transmitSession2, 0);
outputSingleScan(transmitSession2, 1);
end