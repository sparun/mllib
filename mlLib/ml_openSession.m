function[transmitSession1, transmitSession2] = ml_openSession()
% GET all DAQ devices
evtMarkerCard = daq.getDevices;
evtMarkerCard = evtMarkerCard(2);

% CREATE a session for sending 24-bit words on PCI-6503
transmitSession1 = daq.createSession(evtMarkerCard.Vendor.ID);
transmitSession1.addDigitalChannel('Dev2', 'Port0/Line0:7','OutputOnly');
transmitSession1.addDigitalChannel('Dev2', 'Port1/Line0:7','OutputOnly');
transmitSession1.addDigitalChannel('Dev2', 'Port2/Line0:7','OutputOnly');

% CREATE a session for sending strobe bit on PCI-6221
transmitSession2 = daq.createSession(evtMarkerCard.Vendor.ID);
transmitSession2.addDigitalChannel('Dev1', 'Port1/Line0','OutputOnly');

% SET word bits to low and strobe bit to high
outputSingleScan(transmitSession1, zeros(1, 24));
outputSingleScan(transmitSession2, 1);