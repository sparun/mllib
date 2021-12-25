function [hsdata,hsts,samplingRate,nch] = wm_readWirelessData(folderName,fileName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reads a specific eCube recorded wireless neural data .bin file specified by the variable
% fileName, and provides the recorded voltage in each channel
%
% Mandatory Inputs
%------------------
%    folderName     : the complete path where the .bin file is kept
%    fileName       : the .bin file name. Foramt-> HSW_YYYY_MM_DD__HH_MM_SS__
%                     <recording duration in minutes> min_<remaining recording
%                     duration in seconds>sec__hsamp_<nch>ch_<samplingRate>sps.bin
% 
% Outputs
% -------
%       hsdata      :  The time series voltage data (Volts) recorded in each channel
%                     a vector of nChannels x (sampling rate * recorded duration in seconds)
%       timeStamp   : eCube timestamp
%       samplingRate: The sampling rate at which recording is done 
%       nch         : number of channels used in recording


%  Version History:
%   Date                    Author                        Comments
%                           Georgin           Initial version
%   12-Jan- 2021            Sini Simon M      Changes for converting to a lib function
%   01-Nov-2021             Georgin           Fixed the bug, uint16-> int16 
%                                           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extracting the sampling rate and number of channels from the fileName
delimiterPos = strfind(fileName,'_');
dotPos = strfind(fileName,'.');

samplingRate = str2num(fileName(delimiterPos(end)+1: (dotPos-4))); 
nch  = str2num(fileName(delimiterPos(end -1)+1: (delimiterPos(end)-3)));

hsdata = []; hsts = [];

fp = fopen([folderName '/' fileName], 'r');
ts = fread(fp, 1, 'uint64=>uint64'); % read eCube 1000 MHz timestamp from start of every file
hsts = cat(1, hsts, ts);
%Dchxs = fread(fp, [nch,inf], 'int16=>single');
Dchxs = fread(fp, [nch,inf], 'int16=>single');
hsdata = cat(2, hsdata, Dchxs*6.25e-3/32768); % convert to volts
end
