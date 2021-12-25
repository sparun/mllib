%  This functions add ptd detected visual events into the trial events. 
% 
%
%  Mandatory Inputs
% ------------------
% ptdEvents   = Vector indicating the time of occurance of ptd event' 
% trialEvents = array of structures with event codes, event names, event times as fields (1 x ntrials) 
%
% Outputs
% -------
% Add ptdEvents to the trialEvents structure. 
% 
%  Version History:
%   Date                    Author                        Comments
%   11-Nov-2021             Georgin,                        Initial Version 

function trialEvents=wm_addPtdEvents(ptdEvents,trialEvents)
nTrials = size(trialEvents,1);
for trial=1:nTrials
    trialStartTime  = trialEvents(trial).tEcube(1);
    trialStopTime   = trialEvents(trial).tEcube(end);
    eventIndex      = ptdEvents>trialStartTime & ptdEvents<trialStopTime;
    trialEvents(trial).ptdEvents = ptdEvents(eventIndex);
end
end