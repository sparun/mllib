% fillDashboard.m - VisionLab, IISc
%{
Example code that will return text strings for display on MonkeyLogic control screen
where the whole and running accuracies as well as a summary of editable variables is
shown. The function takes TrialData.VariableChanges and TrialRecord as input and return
an array of formatted strings.

Note: this is only for template SD and templateSearch

VERSION HISTORY
- 02-Mar-2022 - Thomas  - First documentation
%}

function lines = fillDashboard(editables, TrialRecord)
% ASSIGN variables
blocks  = TrialRecord.BlocksPlayed;
rt      = TrialRecord.ReactionTimes;
resCorr = TrialRecord.User.responseCorrect;
expResp = TrialRecord.User.expectedResponse;
choResp = TrialRecord.User.chosenResponse;
trlFlag = TrialRecord.User.trialFlag;

% IGNORE trials from calibration block
calInd          = find(blocks == 1);
resCorr(calInd) = [];

% IGNORE the non-attempted trials
invIndx          = find(resCorr ==8);
resCorr(invIndx) = [];

% OVERALL accuracy of same and diff trials
nTrials   = length(resCorr);
nCorrect  = nansum(resCorr == 0);
wAccuracy = 100*(nCorrect / nTrials);

if isnan(wAccuracy),   wAccuracy = 0; end

% RUNNING accuracy
trials  = length(resCorr);
bufSize = 50;
if trials > bufSize
    
    % RUNNING accuracy on Same Diff Trials
    resCorr   = resCorr(end-bufSize+1:end);
    nTrials   = length(resCorr);
    nCorrect  = nansum(resCorr == 0);
    rAccuracy = 100*(nCorrect / nTrials);
    
    % RUNNING accuracy on initiated trials
    temp             = resCorr;
    temp(temp ~= 0)  = -1; % all errors after initiating a trial is represented by -1
    temp(temp == 0)  = 1;  % all correct trials are represented by 1
    temp(temp == -1) = 0;  % convering -1 to 0
    rAccuracy        = 100*nanmean(temp); % Accuracy on initiated trials
    
    % ERROR percetages split
    rErrorPerc      = zeros(4,1); %  Hold|No Fix|Fix Maintain|Response
    temp            = resCorr;
    temp(temp == 0) = []; % discarding the correct trials
    
    % DISCARD all other values except 9,7,4,3,6
    temp(temp~=9 & temp~=7 & temp~=4 &temp~=3 & temp~=6 & temp~=1) = [];
    
    % FIND and assign types of errors
    holdErr       = find(temp==9 |temp==7);
    rErrorPerc(1) = 100 * length(holdErr)/length(temp);
    respErr       = find(temp==6 | temp==1);
    rErrorPerc(2) = 100 * length(respErr)/length(temp);
else
    rAccuracy     = NaN;
    rErrorPerc    = nan(2,1);
end

% JUICE consumption
totalJuiceConsumed = nansum(TrialRecord.User.juiceConsumed);

% DISPLAY strings
lines{1,1} = sprintf('Good Pause =  %04d ms  |  Bad Pause = %04d ms | Reward =  %1.2f ml | Total Juice = %3.2f ml',...
    editables.goodPause, editables.badPause, editables.rewardVol, totalJuiceConsumed);
lines{2,1} = sprintf('ACCURACY: OVERALL =  %2.0f  | RUNNING (%d trials) = %2.0f',...
    wAccuracy, bufSize, rAccuracy);
lines{3,1} = sprintf('ERROR Percent (Hold/Resp) = %2.0f/%2.0f ',...
    rErrorPerc);
end