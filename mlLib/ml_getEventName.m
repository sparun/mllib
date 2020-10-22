% ml_getEventName.m - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Returns the field name/s for each event codes taken as input. Finds the matching struct
% and filed name and returne the fiel name. In effect it labels event codes for ease
% in understanding the same.
%
% VERSION HISTORY
% ----------------------------------------------------------------------------------------
% - 15-Oct-2020 - Thomas  - Initial implementation

function eventName = ml_getEventName(eventNumber)

% LOAD events
[event.err, event.pic, event.aud, event.bhv,...
    event.rew, event.exp, event.trl, event.check, event.ascii] = ml_loadEvents();
% CONVERT the struct 'event' to its constituent fields and values
eventCell = struct2cell(event);

for eventInd = 1:length(eventNumber)
    eventVal = eventNumber(eventInd);
    
    % REDUCE any xxShift eventmarker to base value such that event code name can be allotted
    if eventVal > 1999 && eventVal < 6000
        eventVal = 2000;
    elseif eventVal > 5999  && eventVal < 6500
        eventVal = 6000;
    elseif eventVal > 6499  && eventVal < 7000
        eventVal = 6500;
    elseif eventVal > 6999  && eventVal < 8000
        eventVal = 7000;
    elseif eventVal > 7999  && eventVal < 8500
        eventVal = 8000;
    elseif eventVal > 8499  && eventVal < 8510
        eventVal = 8500;
    end
    
    % SEARCH across cell of structs to find a match
    for cellInd = 1:length(eventCell)
        fieldName = fieldnames(eventCell{cellInd});
        foundInd  = structfun(@(x) x == eventVal,eventCell{cellInd});
        
        if(sum(foundInd) > 0)
            eventName{eventInd} = char(fieldName(foundInd)); 
            
            if cellInd == 7
                if contains(eventName{eventInd}, 'Shift')
                    temp = string(eventName{eventInd});
                    temp = strsplit(temp, 'Shift');
                    eventName{eventInd} = temp{1};
                end
            end
        end
        
    end
end

