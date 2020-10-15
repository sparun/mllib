function lines = fillDashboard(tempVars, tempUser)

% DISPLAY the editable parameter values on the dashboard
bufferSize       = 50;
expectedResponse = tempUser.expectedResponse;
responseCorrect  = tempUser.responseCorrect;
invalidInd       = find(responseCorrect ~= 0 & responseCorrect ~= 6);

expectedResponse(invalidInd) = [];
responseCorrect(invalidInd)  = [];

trials           = length(expectedResponse);

% ACCURACY overall of same and diff trials
indSamePairs       = find(expectedResponse == 1);
indDiffPairs       = find(expectedResponse == 2);
nSamePairs         = length(indSamePairs);
nDiffPairs         = length(indDiffPairs);
nCorrectSamePairs  = sum(responseCorrect(indSamePairs)  == 0);
nCorrectDiffPairs  = sum(responseCorrect(indDiffPairs)  == 0);
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
    
    % WEIGHTED running accuracy
    xx               = responseCorrect;
    xx(xx == 0)      = 1;
    xx(xx == 6)      = 0;
    weights          = (1:bufferSize) / (sum(1:bufferSize));
    weightedAccuracy = 100*(nansum(vec(xx).*vec(weights)));
    
else
    rAccuracySamePairs  = accuracySamePairs;
    rAccuracyDiffPairs  = accuracyDiffPairs;
    weightedAccuracy    = NaN;
    nPresentSamePairs   = NaN;
    nPresentDiffPairs   = NaN;
end

% JUICE consumption
totalJuiceConsumed = nansum(tempUser.juiceConsumed);

% DISPLAY strings
lines{1,1}  = sprintf('Good Pause =  %04d ms  |  Bad Pause = %04d ms | Reward =  %1.2f ml | Total Juice = %3.1f ml',...
    tempVars.goodPause, tempVars.badPause, tempVars.rewardVol, totalJuiceConsumed);
lines{2,1} = sprintf('REPONSE ACC: OVERALL (S/D) =  %2.0f / %2.0f  | RUNNING (%d trials) ACC (S/D) = %2.0f / %2.0f',...
    accuracySamePairs, accuracyDiffPairs, bufferSize, rAccuracySamePairs, rAccuracyDiffPairs);
lines{3,1} = sprintf('TRIALS SEEN: Running (S/D) =  %03d / %03d', nPresentSamePairs, nPresentDiffPairs);
lines{4,1} = sprintf('WEIGHTED ACCURACY    =  %2.0f', weightedAccuracy);

end