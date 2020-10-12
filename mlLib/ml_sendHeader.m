% sendHeader.m - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Opens 24 channels on PCI-6503 and a strobe channel on PCI-6221. Transmits a strobed
% 24-bit words from a headerStr (header string) bounded by header start and header end 
% markers. 
%
% REQUIRED: MATLAB DAQ toolbox
%
% ----------------------------------------------------------------------------------------
% VERSION HISTORY
% ----------------------------------------------------------------------------------------
% - 07-03-2020  - Georgin - First implementation
%                 Thomas
% - 19-09-2020  - Thomas  - Updated event codes implemented

function ml_sendHeader(MLConfig)

% LOAD mlErrorCodes and evtCodes
[~, ~, ~, ~, ~, exp, ~, ~, ascii] = ml_loadEvents();

%% OPEN DAQ Session---------------------------------------------------------------
[transmitSession1, transmitSession2] = ml_openSession();
nBits = 24; % number of bits transmitted in parallel each time

% HEADER start Marker
evtCodeBin = dec2binvec(exp.headerStart,nBits);
outputSingleScan(transmitSession1, evtCodeBin);
ml_sendStrobe(transmitSession2);

%% TRANSMIT EXPNAME---------------------------------------------------------------
expName     = MLConfig.ExperimentName;
transmitStr = double(expName);

% START Marker
evtCodeBin = dec2binvec(exp.nameStart,nBits);
outputSingleScan(transmitSession1, evtCodeBin);
ml_sendStrobe(transmitSession2);

% TRANSMIT
for i = 1:length(transmitStr)
    evtCodeBin = dec2binvec(ascii.shift + transmitStr(i),nBits);
    outputSingleScan(transmitSession1, evtCodeBin);
    ml_sendStrobe(transmitSession2);
end

% STOP Marker
evtCodeBin = dec2binvec(exp.nameStop,nBits);
outputSingleScan(transmitSession1, evtCodeBin);
ml_sendStrobe(transmitSession2);

%% TRANSMIT MONKEY NAME-----------------------------------------------------------
expName     = MLConfig.SubjectName;
transmitStr = double(expName);

% START Marker
evtCodeBin = dec2binvec(exp.subjNameStart,nBits);
outputSingleScan(transmitSession1, evtCodeBin);
ml_sendStrobe(transmitSession2);

% TRANSMIT
for i = 1:length(transmitStr)
    evtCodeBin = dec2binvec(ascii.shift + transmitStr(i),nBits);
    outputSingleScan(transmitSession1, evtCodeBin);
    ml_sendStrobe(transmitSession2);
end

% STOP Marker
evtCodeBin = dec2binvec(exp.subjNameStop,nBits);
outputSingleScan(transmitSession1, evtCodeBin);
ml_sendStrobe(transmitSession2);

%% TRANSMIT FILES-----------------------------------------------------------------
% PACK allowed files for header transmission
allowedFileTypes = {'*.m' '*.mat' '*.txt'};
files            = ml_packHeader(allowedFileTypes);

% CREATE header for transmission
transmitStr = ml_makeHeader(files);

% START Marker
evtCodeBin = dec2binvec(exp.filesStart,nBits); %
outputSingleScan(transmitSession1, evtCodeBin);
ml_sendStrobe(transmitSession2);

% TRANSMIT
for i = 1:length(transmitStr)
    evtCodeBin = dec2binvec(ascii.shift + transmitStr(i),nBits);
    outputSingleScan(transmitSession1, evtCodeBin);
    ml_sendStrobe(transmitSession2);
end

% STOP Marker
evtCodeBin = dec2binvec(exp.filesStop,nBits);
outputSingleScan(transmitSession1, evtCodeBin);
ml_sendStrobe(transmitSession2);

%% CLOSE DAQ Session -------------------------------------------------------------

% HEADER stop Marker
evtCodeBin = dec2binvec(exp.headerStop,nBits);
outputSingleScan(transmitSession1, evtCodeBin);
ml_sendStrobe(transmitSession2);

ml_closeSession(transmitSession1, transmitSession2)
clear transmitSession1 transmitSession2
end