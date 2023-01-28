% fillDashboard.m - VisionLab, IISc
%
% Example code that will return text strings for display on MonkeyLogic control screen
% where the whole and running accuracies as well as a summary of editable variables is
% shown. 
%
% INPUT
%   editables              - editables contain variables to display related to task
%   TrialRecord            - contains record of trials (correct, incorrect etc.)
%
% OUTPUT
%   line                   - formatted lines for display
%
% NOTE: This is only for templateTemporalSameDifferent and temporalSpatialSameDifferent
%
% VERSION HISTORY
%    21-Feb-2021 - Thomas  - First documentation
%                  Jhilik
%                  Georgin
% ----------------------------------------------------------------------------------------

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
rt(calInd)      = [];
expResp(calInd) = [];
resCorr(calInd) = [];
choResp(calInd) = [];
trlFlag(calInd) = [];

% IGNORE the non-attempted trials
invIndx          = find(resCorr ==8);
expResp(invIndx) = [];
resCorr(invIndx) = [];
choResp(invIndx) = [];
trlFlag(invIndx) = [];

% OVERALL accuracy of same and diff trials
indSame       = find(expResp == 1);
indDiff       = find(expResp == 2);
nSame         = length(indSame);
nDiff         = length(indDiff);
nCorrectSame  = nansum(resCorr(indSame)  == 0);
nCorrectDiff  = nansum(resCorr(indDiff)  == 0);
wAccuracySame = 100*(nCorrectSame  / nSame);
wAccuracyDiff = 100*(nCorrectDiff  / nDiff);

if isnan(wAccuracySame),   wAccuracySame   = 0; end
if isnan(wAccuracyDiff),   wAccuracyDiff   = 0; end

% RUNNING accuracy
trials  = length(expResp);
bufSize = 50;
if trials > bufSize
    
    % RUNNING accuracy on Same Diff Trials
    expResp       = expResp(end-bufSize+1:end);
    resCorr       = resCorr(end-bufSize+1:end);
    indSame       = find(expResp == 1);
    indDiff       = find(expResp == 2);
    nSame         = length(indSame);
    nDiff         = length(indDiff);
    nCorrectSame  = sum(resCorr(indSame)  == 0);
    nCorrectDiff  = sum(resCorr(indDiff)  == 0);
    rAccuracySame = 100*nCorrectSame  / nSame;
    rAccuracyDiff = 100*nCorrectDiff  / nDiff;
    
    % CALCULATE percentage of SAME and DIFF trials seen
    rPresentSame = 100*nSame / (nSame + nDiff);
    rPresentDiff = 100*nDiff / (nSame + nDiff);
    
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
    noFixErr      = find(temp==4);
    rErrorPerc(2) = 100 * length(noFixErr)/length(temp);
    fixMaintErr   = find(temp==3);
    rErrorPerc(3) = 100 * length(fixMaintErr)/length(temp);
    respErr       = find(temp==6 | temp==1);
    rErrorPerc(4) = 100 * length(respErr)/length(temp);
else
    rAccuracySame = wAccuracySame;
    rAccuracyDiff = wAccuracyDiff;
    rAccuracy     = NaN;
    rPresentSame  = NaN;
    rPresentDiff  = NaN;
    rErrorPerc    = nan(4,1);
end

% JUICE consumption
totalJuiceConsumed = nansum(TrialRecord.User.juiceConsumed);

% DISPLAY strings
lines{1,1} = sprintf('Good Pause =  %04d ms  |  Bad Pause = %04d ms | Reward =  %1.2f ml | Total Juice = %3.2f ml',...
    editables.goodPause, editables.badPause, editables.rewardVol, totalJuiceConsumed);
lines{2,1} = sprintf('ACCURACY: OVERALL (S/D) =  %2.0f/%2.0f  | RUNNING (%d trials) (S/D - Tot) = %2.0f/%2.0f - %2.0f',...
    wAccuracySame, wAccuracyDiff, bufSize, rAccuracySame, rAccuracyDiff, rAccuracy);
lines{3,1} = sprintf('TRIALS SEEN: Running (S/D) =  %03d / %03d',...
    rPresentSame, rPresentDiff);
lines{4,1} = sprintf('ERROR Percent (Hold/FixAcq/FixMaint/Resp) = %2.0f/%2.0f/%2.0f/%2.0f ',...
    rErrorPerc);
end