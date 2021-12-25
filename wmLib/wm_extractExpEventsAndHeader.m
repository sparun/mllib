% This function extracts and process the event codes from the digital data.
% Experiment header are also send as event codes.
%
%  Mandatory Inputs
% ------------------
%    tEcube                : Absolute time recorded in eCube for each netcam sync pulse signal. 
%                            Vector of dim (nSamples x 1) 
%    digitalData           : Integers between 0 and 2^64-1. Vector of dim (nSamples x 1)
%    strobe                : Digital pulse encoding the start of each event code.
%
% Outputs
% -------
%       events      : (nEvents x 2)This matrix contains the event codes
%                      send from ML during the experiment with time
%                      stamp.First column is event code and second column
%                      is eCube time stamp.
%       files       :  This structure contains details required to recreate
%                      all the ML codes used ot run the experiment. Use   
%       info        :  Structure with the current expName, monkeyName, and bhvFile name. 
% 
%  Version History:
%   Date                    Author                        Comments
%                           Georgin             Initial version
%   16-Nov-2021             Georgin, Thomas     Simplified the code.  



function [events, files, info] = wm_extractExpEventsAndHeader(tEcube, digitalData, strobe)
[~, ~, ~, ~, ~, exp, trl, ~, asc] = ml_loadEvents();
ecube                             = wm_ecubeProperties;
channel                           = ecube.digital.eventcodes;

% Ignoring unspecified channels
firstChannel = channel(1);
N            = length(channel);
if(firstChannel > 0)
    digitalData = bitshift(digitalData, -(firstChannel-1)); % ignoring the first N bits
end

value = bitand(digitalData, 2^N-1); % selecting the fi
value = double(value);

strobeIndex  = (diff(strobe)==1); % 1 = rising edge, -1 for falling edge of strobe bit
strobeOffset = 0;
strobeIndex  = strobeIndex + strobeOffset;
value(~strobeIndex) = 0; % discarding event code replicates;

% Extracting event codes
eventTimes   = tEcube(strobeIndex == 1);
eventNumbers = value(strobeIndex == 1);
events(:,1)  = vec(eventNumbers);
events(:,2)  = vec(eventTimes);

%% Run this snippet only if 

% Copying headers and Event codes separately
headerstartIndex = find(events==exp.headerStart);
headerstopIndex  = find(events==exp.headerStop);
if(~isempty(headerstartIndex) && ~isempty(headerstopIndex)) % copying header if exist
    
    % Experiment Name
    startIndex    = find(events==exp.nameStart);
    stopIndex     = find(events==exp.nameStop);
    info.expName       = char(events((startIndex+1):(stopIndex-1)) - asc.shift);
    
    % Monkey Name
    startIndex    = find(events==exp.subjNameStart);
    stopIndex     = find(events==exp.subjNameStop);
    info.monkeyName       = char(events((startIndex+1):(stopIndex-1)) - asc.shift);
    
    % BHV file_name
    startIndex    = find(events==exp.bhvNameStart);
    stopIndex     = find(events==exp.bhvNameStop);
    info.bhvFileName       = char(events((startIndex+1):(stopIndex-1)) - asc.shift);
    
    
    % Header extract
    startIndex    = find(events==exp.filesStart);
    stopIndex     = find(events==exp.filesStop);
    headerContent = events((startIndex+1):(stopIndex-1)) - asc.shift;
    headerContent = double(headerContent);
    files         = wm_headerUint16Double(headerContent);
else
    error('ERROR: Header missing !!')
end
%%
% Remove header info from events (as it is has been extracted)
firstTrialStart = find(events == trl.start,1);
events          = events(firstTrialStart-2:end,:);

% SUCCESS message
disp('SUCCESS! Experiment events and header extracted. Continuing.')
end