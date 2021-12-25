function ecube = wm_ecubeProperties()

ecube.specs.netcamFrameRate        = 30;
ecube.specs.digitalFs              = 25000;
ecube.specs.recordedAnalogChannels = [];  % Pick it from file name 
ecube.specs.analogVoltPerBit       = 3.0517578125e-4;
ecube.specs.expectedRecordDuration = 600; % in seconds
ecube.specs.wirelessFs             = [];  % Pick it from file name 

ecube.digital.netcamSync = 1;
ecube.digital.strobe     = 3;
ecube.digital.eventcodes  = 41:64;

ecube.analog.eyeX = 1;
ecube.analog.eyeY = 2;
ecube.analog.photodiode = 3;
end


