% This function calcualte the wireless start time wrt eCube start time. The time 
% is calculated by finding the continous chunk of time greater than the
% threshold.
%
%  Mandatory Inputs
% ------------------
%    tEcube                : Absolute time recorded in eCube for each netcam sync pulse signal. 
%                            Vector of dim (nSamples x 1) 
%    wirelessSync          : Synchrionizing pusle send by wireless module to ecube box. Vector of dim (nSamples x 1)
%    ecube                 : Structure specifying the hardware related parameters of eCube recording system.
%
% Optional Inputs
%    figFlag    : Flag which determines if the detected start time
%                 overlayed on duty cycle will be shown or not. (Default: figFlag =1)
% Outputs
% -------
%       wirelessStartTime   : Time at which wireless reording was started based on eCube start time in seconds. 
%       pulseDuration       : Duration of detected start pulse in milli seconds.
% 
%  Version History:
%   Date                    Author                        Comments
%                           Georgin             Initial version
function [wirelessStartTime, pulseDuration] = wm_findWirelessStartTime(tEcube, wirelessSync, ecube,figFlag)

if(~exist('figFlag','var')), figFlag =1; end

fs          = ecube.specs.digitalFs;
threshold   = 0.25;
pulseIndex  = find(wirelessSync>=threshold);

cond1 = isempty(pulseIndex); % wireless ON but not started
cond2 = sum(wirelessSync)==length(wirelessSync); % wireless OFF. 
cond3 = sum(diff(pulseIndex)==1)==(length(pulseIndex)-1); % All values in the high pulse is 1, all ON

if ~cond1 && ~cond2 && cond3
    pulseDuration = length(pulseIndex)/fs*1000; % ms
    disp(['SUCCESS! Wireless start pulse detected with Pulse Width = ',num2str(pulseDuration),'ms']);
    wirelessStartTime = tEcube(pulseIndex(1));
    
    if(figFlag==1),
        figure;
        index= max(pulseIndex(1)-3*fs,1):(pulseIndex(1)+3*fs);
        plot(tEcube(index),wirelessSync(index));hold on;
        line([wirelessStartTime,wirelessStartTime],[0,1],'Color','red','LineStyle','--','LineWidth',2);
        title_str=sprintf('Wireless start time = %2.4f seconds',wirelessStartTime);
        title(title_str);
        xlabel('eCube time axis');
        ylabel('Wireless Sync Pulse')
    end
else
    pulseDuration     =[];
    wirelessStartTime =[];
    disp('ERROR! Wireless start pulse not detected');
end





end