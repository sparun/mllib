function lines = fillDashboard(tempVars, tempUser)

% DISPLAY the editable parameter values on the dashboard
bufferSize       = 50;
expectedResponse = tempUser.expectedResponse;
responseCorrect  = tempUser.responseCorrect;
invalidInd       = find(responseCorrect ==8); % Ignoring the non-attempted trials 

expectedResponse(invalidInd) = [];
responseCorrect(invalidInd)  = [];

trials           = length(expectedResponse);

% ACCURACY overall of same and diff trials
indSamePairs       = find(expectedResponse == 1);
indDiffPairs       = find(expectedResponse == 2);
nSamePairs         = length(indSamePairs);
nDiffPairs         = length(indDiffPairs);
nCorrectSamePairs  = nansum(responseCorrect(indSamePairs)  == 0);
nCorrectDiffPairs  = nansum(responseCorrect(indDiffPairs)  == 0);
accuracySamePairs  = 100*(nCorrectSamePairs  / nSamePairs);
accuracyDiffPairs  = 100*(nCorrectDiffPairs  / nDiffPairs);

if isnan(accuracySamePairs),   accuracySamePairs   = 0; end
if isnan(accuracyDiffPairs),   accuracyDiffPairs   = 0; end

% RUNNING ACCURACY
if max(trials) > bufferSize
    expectedResponse    = expectedResponse(end-bufferSize+1:end);
    responseCorrect     = responseCorrect(end-bufferSize+1:end);
    
    
    indSamePairs        = find(expectedResponse == 1);
    indDiffPairs        = find(expectedResponse == 2);
    nSamePairs          = length(indSamePairs);
    nDiffPairs          = length(indDiffPairs);
    nCorrectSamePairs   = sum(responseCorrect(indSamePairs)  == 0);
    nCorrectDiffPairs   = sum(responseCorrect(indDiffPairs)  == 0);
    rAccuracySamePairs  = 100*nCorrectSamePairs  / nSamePairs;
    rAccuracyDiffPairs  = 100*nCorrectDiffPairs  / nDiffPairs;
    
    nPresentSamePairs   = 100*nSamePairs / (nSamePairs + nDiffPairs);
    nPresentDiffPairs   = 100*nDiffPairs / (nSamePairs + nDiffPairs);
    
    % Running accuracy
    xx               = responseCorrect;
    xx(xx ~= 0)      = -1; % all errors after initiating a trial is represented by -1
    xx(xx == 0)      = 1;  % all correct trials are represented by 1
    xx(xx == -1)     = 0;  % convering -1 to 0
    %weights          = (1:bufferSize) / (sum(1:bufferSize));
    %weightedAccuracy = 100*(nansum(vec(xx).*vec(weights)));
    Accuracy = 100*nanmean(xx); % accuracy on initiated trials

% Error percetage 
    error_percentage=zeros(4,1); %  Hold|No Fix| Fix Maintain |Response
    xx = responseCorrect;
    xx(xx==0) =[]; % discarding the correct trials 
    xx(xx~=9 &xx~=7 & xx~=4 &xx~=3 &xx~=6& xx~=1) =[]; % discarding all other values except 9,7,4,3,6
    hold_errors=find(xx==9 |xx==7);error_percentage(1)=100*length(hold_errors)/length(xx);
    noFix_errors=find(xx==4);error_percentage(2)=100*length(noFix_errors)/length(xx);
    fixMaintain_errors=find(xx==3);error_percentage(3)=100*length(fixMaintain_errors)/length(xx);
    resp_errors=find(xx==6 | xx==1);error_percentage(4)=100*length(resp_errors)/length(xx);  
else
    rAccuracySamePairs  = accuracySamePairs;
    rAccuracyDiffPairs  = accuracyDiffPairs;
    Accuracy            = NaN;
    nPresentSamePairs   = NaN;
    nPresentDiffPairs   = NaN;
    error_percentage    = nan(4,1);
end

% JUICE consumption
totalJuiceConsumed = nansum(tempUser.juiceConsumed);

% DISPLAY strings
lines{1,1}  = sprintf('Good Pause =  %04d ms  |  Bad Pause = %04d ms | Reward =  %1.2f ml | Total Juice = %3.1f ml',...
    tempVars.goodPause, tempVars.badPause, tempVars.rewardVol, totalJuiceConsumed);
lines{2,1} = sprintf('REPONSE ACC: OVERALL (S/D) =  %2.0f / %2.0f  | RUNNING (%d trials) ACC (S/D) = %2.0f / %2.0f',...
    accuracySamePairs, accuracyDiffPairs, bufferSize, rAccuracySamePairs, rAccuracyDiffPairs);
lines{3,1} = sprintf('TRIALS SEEN: Running (S/D) =  %03d / %03d', nPresentSamePairs, nPresentDiffPairs);
lines{4,1} = sprintf('ACCURACY    =  %2.0f |  Error Percentage (Hold:FixAcq.:FixMain.:Resp) = %2.0f:%2.0f:%2.0f:%2.0f ', Accuracy,error_percentage);

end