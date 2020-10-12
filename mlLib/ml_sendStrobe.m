% SEND a strobe pulse on a single bit session

function ml_sendStrobe(transmitSession2)
% Strobe
outputSingleScan(transmitSession2, 0);
% WaitSecs(0.00001);
outputSingleScan(transmitSession2, 1);
% WaitSecs(0.00001);
end