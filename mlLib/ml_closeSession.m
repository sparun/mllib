function ml_closeSession(transmitSession1, transmitSession2)

% SET all bits to low
outputSingleScan(transmitSession1, zeros(1, 24));
outputSingleScan(transmitSession2, 0);

% CLEAR and remove channels
transmitSession1.stop;
transmitSession1.release;
transmitSession1.removeChannel(1:24);
release(transmitSession1);
clear transmitSession1

transmitSession2.stop;
transmitSession2.release;
transmitSession2.removeChannel(1);
release(transmitSession2);
clear transmitSession2
end