function ml_readSerialData(iScan,evt)
global timeStamp
    data           = readline(iScan);
    iScan.UserData = [iScan.UserData; data];
    timeStamp      = [timeStamp; clock];
end