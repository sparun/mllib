% CLOSE DAQ SESSION - NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Closes DAQ sessions of both DAQ cards on ML PC after setting all bits to low
%
% VERSION HISTORY
%{
22-Oct-2020 - Thomas  - Added comments
%}
% ----------------------------------------------------------------------------------------

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