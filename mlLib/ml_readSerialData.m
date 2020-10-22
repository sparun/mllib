% ml_readSerialData.m - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Read each uniques serial port data line received and append it to buffer of serialport
% object
% 
% VERSION HISTORY
% - 15-Oct-2020  - Thomas - First implementation
%-----------------------------------------------------------------------------------------

function ml_readSerialData(iScan,evt)
global timeStamp
    data           = readline(iScan);
    iScan.UserData = [iScan.UserData; data];
    timeStamp      = [timeStamp; clock];
end