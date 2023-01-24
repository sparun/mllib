% READ SERIAL DATA - NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Read each uniques serial port data line received and append it to buffer of serialport
% object. Ue this function for e.g. as below - 
%   "configureCallback(iScan,"terminator",@ml_readSerialData)"
% 
% VERSION HISTORY
%{
15-Oct-2020  - Thomas - First implementation
%}
%-----------------------------------------------------------------------------------------

function ml_readSerialData(iScan, evt)
global timeStamp
    % READ stream of datastream received on serialport object
    data           = readline(iScan);
    
    % ADD the recorded datastream to the serialport object
    iScan.UserData = [iScan.UserData; data];
    
    % ADD timestamp also for each datastream received
    % datevec(now) has millisecond precision but depends on how the data was received
    timeStamp      = [timeStamp; datevec(now)];
end