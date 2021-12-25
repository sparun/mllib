%This function performs spike sorting on each channel separtely based on a
%predefined threshold.
%
%  Mandatory Inputs
% ------------------
% rawData           : (nChannels x nSamples),Raw spike data recorded. 
% channelThreshold  : 1 D vector with dimension = channelThreshold. Data received at each channel is thresholded based on this threshold.  
% ecube             : Structure specifying the hardware related parameters of eCube recording system.
% wirelessStartTime : Time at which the wireless recording started based on
%                     eCube time in seconds.  
%
% Outputs
% -------
% tspikes           :  Cell with dimension nChannels x 1.Within each channel the time of occurance of each spike is shown.  
%
%  Version History:
%   Date                    Author                        Comments
%   1-Sep-2021              Georgin                       Initial version
function tspikes = wm_spikeSortingThreshold(rawData,channelThreshold,ecube,wirelessStartTime)
% Input 
% Data : nchannels x nsamples
nChannel  = size(rawData,1);
nSamples   = size(rawData,2);
wirelessFs = ecube.specs.wirelessFs;

t       = (0:nSamples-1)*(1/wirelessFs);
relT    = t + wirelessStartTime;

tspikes = cell(nChannel,1);
for ch=1:nChannel
spikeIndex   = (rawData(ch,:) > channelThreshold(ch)) ;
tspikes{ch}   = relT(spikeIndex);
end
end