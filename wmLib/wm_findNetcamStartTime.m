% This function calculates the netcam start time wrt eCube start time.  Start
% time is calculated by finding the time at which the duty cycle of the
% netcam sync pulse changes from 0.2 to 0.5. 
% Mandatory Inputs
%------------------
%    tEcube                : Absolute time recorded in eCube for each netcam sync pulse signal. 
%                            Vector of dim (nSamples x 1) 
%    netcamSync            : Synchrionizing signal send by netcam to ecube box. Vector of dim (nSamples x 1)
%    netcamDutyCycleThresh : Threshold of the ON duty cycle. All netcamSync pulses with dutycycle 
%                            above this threshold will be considered as ON. 
%    ecube                 : Structure specifying the hardware related parameters of eCube recording system.
%
% Optional Inputs
%    figFlag    : Flag which determines if the detected start time
%                 overlayed on duty cycle will be shown or not. (Default: figFlag =1)
% Outputs
% -------
%       netcamStartTime      : Time at which netcamera was started based on eCube start
%                              time in seconds. 
% 
%  Version History:
%   Date                    Author                        Comments
%                           Georgin             Initial version
%   16-Nov-2021             Georgin, Thomas     Simplified the code.           

function netcamStartTime =wm_findNetcamStartTime(tEcube, netcamSync,netcamDutyCycleThresh, ecube,figFlag)

if(~exist('figFlag','var')), figFlag =1; end
t                  = tEcube;
netcamsync         = netcamSync;
camera_fps         = ecube.specs.netcamFrameRate;
fs                 = ecube.specs.digitalFs;
Threshold          = netcamDutyCycleThresh;
%% Finding approximate the start of recording
buffer_time=3;

nSampleperdutycycle=floor(fs/camera_fps);
windowWidth=fs;
Nsteps=length(t)/windowWidth; % 1s steps
energyWithinWindow=[];
for i=1:Nsteps
    index=(i-1)*windowWidth+(1:windowWidth);
    energyWithinWindow(i)=mean(netcamsync(index));
end
approx_start_time=find(energyWithinWindow>=Threshold,1); % Energy threshold based on duty cycle of netcam


if(~isempty(approx_start_time)),
    index=find(t>(approx_start_time-buffer_time) &t<(approx_start_time));
    
    % Approximate Netcam Sync
    selectedNetcamSync=netcamsync(index);
    selectedTime=t(index);
    %% Finding exact start of recording
    prev_value=selectedNetcamSync(1);
    count=0;
    nConstantSamples=[];
    tOfFlip=[];
    % conting the samples having no prev_value
    for i=1:length(selectedNetcamSync)
        if(prev_value==selectedNetcamSync(i))
            count=count+1;
        else
            prev_value=selectedNetcamSync(i);
            nConstantSamples=[nConstantSamples;count];
            tOfFlip=[tOfFlip;selectedTime(i)];
            count=0;
        end
    end
    
    nConstantSamples(1:2)=[];tOfFlip(1:2)=[]; % first measurement might be wrong.
    normalizedSampleCount=nConstantSamples./nSampleperdutycycle;
    index=find(normalizedSampleCount>0.4 & normalizedSampleCount<0.6,1); % Expecting
    netcamStartTime=tOfFlip(index(1)-1);
    
    if(figFlag==1)
        figure;
        plot(selectedTime,selectedNetcamSync);hold on;
        line([netcamStartTime,netcamStartTime],[0,1],'Color','red','LineStyle','--','LineWidth',2);
        title_str=sprintf('Video Start time = %2.4f seconds',netcamStartTime);
        title(title_str);
        xlabel('eCube time axis');
        ylabel('Netcam Digital Pulse')
    end
    
    % SUCCESS message
    disp('SUCCESS! Netcam recording start time extracted. Continuing..')
else
    netcamStartTime=[];
    disp('WARNING! Netcam starting pulse not detected. Continuing.. ')
end