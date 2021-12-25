% This function decodes trial events and footer within a trial. 
% 
%
%  Mandatory Inputs
% ------------------
%       events      : (nEvents x 2) A matrix containing the event codes
%                      send from ML during the experiment with time
%                      stamp.First column is event code and second column
%                      is eCube time stamp.
%
% Outputs
% -------
%       trialEvents : 
%       files       :  This structure contains details required to recreate
%                      all the ML codes used ot run the experiment. Use   
%       info        :  Structure with the current expName, monkeyName, and bhvFile name. 
% 
%  Version History:
%   Date                    Author                        Comments
%   16-Nov-2021             Georgin, Thomas             Initial Version  

function [trialEvents,trialFooter]= wm_extractTrialEventsAndFooter(events)
[~, ~, ~, ~, ~, exp, trl, ~, ~] = ml_loadEvents();

tStartInd   =   find(events(:,1) == trl.start);
tStopInd    =   find(events(:,1) == trl.stop);
fStartInd   =   find(events(:,1) == trl.footerStart);
fStopInd    =   find(events(:,1) == trl.footerStop);
nTrials     =   length(tStartInd);
trialEvents =   struct('eventcodes',{},'eventcodenames',{},'tEcube',{},'tEcubePtd',{},'ptdEvents',{});

trialFooter = [];
for trial = 1:nTrials
    trialEvents(trial,1).eventcodes     = events(tStartInd(trial):tStopInd(trial),1);
    trialEvents(trial,1).tEcube         = events(tStartInd(trial):tStopInd(trial),2);
    
    % GET trialEvent names from codeNumbers
    trialEvents(trial,1).eventcodenames = ml_getEventName(trialEvents(trial,1).eventcodes)';
    
    % Trial Footer
    footerCodeNumbers = events(fStartInd(trial)+1:fStopInd(trial),1);
    
    % identifying nans
    footerCodeNumbers(footerCodeNumbers==exp.nan)=nan;
    
    %% General trial properties
    % Identify the tasks
    taskType  = ml_getEventName(footerCodeNumbers(1));
    trialFooter.taskType{trial,1} = taskType{1}(5:end);

    
    trialFooter.trial(trial,1)            = footerCodeNumbers(2)-trl.trialShift;
    trialFooter.block(trial,1)            = footerCodeNumbers(3)-trl.blockShift;  
    trialFooter.trialWBlock(trial,1)      = footerCodeNumbers(4)-trl.trialWBlockShift;
    trialFooter.condition(trial,1)        = footerCodeNumbers(5)-trl.conditionShift;
    trialFooter.trialError(trial,1)       = footerCodeNumbers(6)-trl.outcomeShift;
    trialFooter.expectedResponse(trial,1) = footerCodeNumbers(7)-trl.expRespFree ;
    trialFooter.trialFlag(trial,1)        = footerCodeNumbers(8)-trl.typeShift;
    
    %% Extract editables from footer 
    edtStartIndex       = find(footerCodeNumbers==trl.edtStart);
    edtStopIndex        = find(footerCodeNumbers==trl.edtStop);
    
    editableCodeNumbers = footerCodeNumbers(edtStartIndex+1:edtStopIndex-1);
    
    trialFooter.goodPause(trial,1)        = editableCodeNumbers(1)-trl.shift;
    trialFooter.badPause(trial,1)         = editableCodeNumbers(2)-trl.shift;
    trialFooter.taskFixRadius(trial,1)    = (editableCodeNumbers(3)-trl.shift)/10;
    trialFooter.calFixRadius(trial,1)     = (editableCodeNumbers(4)-trl.shift)/10;
    trialFooter.calFixInitPeriod(trial,1) = editableCodeNumbers(5)-trl.shift;
    trialFooter.calFixHoldPeriod(trial,1) = editableCodeNumbers(6)-trl.shift;
    trialFooter.rewardVol(trial,1)        = (editableCodeNumbers(7)-trl.shift)/1000;
    
    %% Extract Stim Info
    stimInfoStartIndex       = find(footerCodeNumbers==trl.stimStart);
    stimInfoStopIndex        = find(footerCodeNumbers==trl.stimStop);
    stimInfoCodeNumbers      = footerCodeNumbers(stimInfoStartIndex+1:stimInfoStopIndex-1);
    
    if(strcmp(trialFooter.taskType{trial,1},'Calibration'))
        N     =   length(stimInfoCodeNumbers);
        stimInfoCodeNumbers = reshape(stimInfoCodeNumbers,[2,N/2])';
        trialFooter.stimID{trial,1}=nan;
        trialFooter.stimPos{trial,1}=(stimInfoCodeNumbers-trl.picPosShift)/1000;
    else
        N     =   length(stimInfoCodeNumbers);
        stimInfoCodeNumbers = reshape(stimInfoCodeNumbers,[3,N/3]);
        trialFooter.stimID{trial,1}=stimInfoCodeNumbers(1,:)-trl.shift;
        trialFooter.stimPos{trial,1}=(stimInfoCodeNumbers(2:3,:)-trl.picPosShift)/1000;
    end
end 

% SUCCESS message
trialFooter = struct2table(trialFooter);
disp('SUCCESS! Trial events and footer info extracted. Continuing.')
end