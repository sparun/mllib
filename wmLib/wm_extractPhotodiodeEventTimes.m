% This function returns time high-to-low and low-to-high transition times based on respective thresholds. 
%
%  Mandatory Inputs
% ------------------
%   photodiode  : (nSamples x 1) vector containing the measured photodiode signal  
%   fs          : Scalar indicating the sampling frequency of the
%                 photodiode measurement.
%   Threhsolds  : [L=H threshold, H-L threshold] or [threshold]
%   minDelayBetweenPtdSignals: Minimum delay between two consecutive visual flips.
%                              This time is decided by refresh rate of the monitor. 
%  Optional Input
% ------------------
%  figFlag     : Flag to generate plot threshold plots or not (default = 1)
%
% Outputs
% -------
%  photodiodeEventTimes : Vector showing the times at which photodiode flip occured
%  unexpectedPtdEventCorrectedFlag : This flag indicates if any photodeiode
%                                   events were corrected using the theoretical minimum delay between two
%                                   consecutive ptd events. 
%
%  Version History:
%   Date                    Author                        Comments
%   16-Nov-2021             Georgin, Thomas               Initial version


  function [photodiodeEventTimes,unexpectedPtdEventCorrectedFlag]= wm_extractPhotodiodeEventTimes(photodiode,fs,Thresholds,minDelayBetweenPtdSignals, figFlag)
if(~exist('figFlag','var')), figFlag =0; end

if (length(Thresholds)==1)
   highIndex     = (photodiode> Thresholds(1));
   photoDiodeIndex = find([0;diff(highIndex)]~=0); 
   photodiodeEventTimes = photoDiodeIndex/fs; % converting to time. 
else
    if(Thresholds(1)<Thresholds(2)) % correcting the order
        lowToHighThreshold = Thresholds(1);
        highToLowThreshold = Thresholds(2);
    else
        highToLowThreshold = Thresholds(1);
        lowToHighThreshold= Thresholds(2);
    end
    
    % Finding the transition region
    transitionSignalIndex     =  (photodiode > lowToHighThreshold & photodiode < highToLowThreshold  );
    photoDiodeIndex      = find([0;diff(transitionSignalIndex)]==1); % finding the first index
    photodiodeEventTimes = photoDiodeIndex/fs; % converting to time.
    
end
    
    
% Checking for unexpected Ptd Events
unexpectedPtdEvent =find(diff(photodiodeEventTimes)<=minDelayBetweenPtdSignals);
if(~isempty(unexpectedPtdEvent))
    photodiodeEventTimes(unexpectedPtdEvent+1)=[];
    unexpectedPtdEventCorrectedFlag = 1; 
else
    unexpectedPtdEventCorrectedFlag = 0;
end

% Plotting the threshold function 
if(figFlag ==1)
    figure;
    subplot(1,2,1)
    plot(photodiode);
    yline(lowToHighThreshold,'r','Low to High Threshold');
    yline(highToLowThreshold,'b','High to Low Threshold');
    ylabel('Amplitude');xlabel('Samples');
    title('Raw photodiode signal');   

    subplot(1,2,2)
    histogram(photodiode);
    xline(lowToHighThreshold,'r','Low to High Threshold');
    xline(highToLowThreshold,'b','High to Low Threshold');
    xlabel('Measured photodiode voltage');ylabel('Counts');
    title('Histogram');
end
end