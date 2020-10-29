% ml_blockChange.m BLOCK CHANGE function for Monkeylogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Selects the next block to run randomly from selected blocks in ML GUI. Runs calibration
% block if available, else picks random block for first trial. Thereafter, selects random
% block unless calibration block run manually from pause menu (in this case block before
% calibration block is run again). Exhausts selected blocks without repeat (unless
% calibration block run manually).
%
% VERSION HISTORY
% ----------------------------------------------------------------------------------------
% - 14-Sep-2020 - Thomas  - First implementation

function nextBlock = ml_blockChange(TrialRecord)

% SELECT first block----------------------------------------------------------------------
if TrialRecord.CurrentTrialNumber == 1
    % ADD blockList to TrialRecord
    TrialRecord.User.blockList = sort(TrialRecord.BlocksSelected);
    
    if TrialRecord.User.blockList(1) == 1
        % CALIB block selected if CALIB block in in blockList
        nextBlock = TrialRecord.User.blockList(1);
        return
    else
        % RANDOM block selected if CALIB block not in blockList
        nextBlock = datasample(TrialRecord.User.blockList, 1, 'Replace', false);
        TrialRecord.User.blockList(TrialRecord.User.blockList == nextBlock) = [];
        return
    end
end

% RERUN previous block if CALIB block run manually----------------------------------------
if length(TrialRecord.BlockOrder) > 1 && TrialRecord.BlockOrder(end) == 1
    tempBlockOrder = TrialRecord.BlockOrder;
    tempBlockOrder(tempBlockOrder == 1) = [];
    nextBlock = tempBlockOrder(end);
    return
end

% SELECT next block if non-CALIB block previously run-------------------------------------
if isempty(TrialRecord.User.blockList)
    % NO more blocks to run (-1 quits the exp straight to summary screen)
    nextBlock = -1;
else
    % SELECT random block from blockList to run and remove it from blockList
    nextBlock = datasample(TrialRecord.User.blockList, 1, 'Replace', false);
    TrialRecord.User.blockList(TrialRecord.User.blockList == nextBlock) = [];
end

end