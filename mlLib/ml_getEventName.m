
function eventName = ml_getEventName(eventNumber)

[event.err, event.pic, event.aud, event.bhv,...
    event.rew, event.exp, event.trl, event.check, event.ascii] = ml_loadEvents();
eventCell = struct2cell(event);

for eventInd = 1:length(eventNumber)
    eventVal = eventNumber(eventInd);
    for cellInd = 1:length(eventCell)
        fieldName = fieldnames(eventCell{cellInd});
        foundInd  = structfun(@(x) x == eventVal,eventCell{cellInd});
        if(sum(foundInd) > 0)
            eventName{eventInd} = fieldName(foundInd);
        end
    end
end
            
