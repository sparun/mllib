function alert_function(hook,MLConfig,TrialRecord)
% NIMH MonkeyLogic
%
% This function executes pre-defined instructions, when a certain task flow
% event listed below occurs.  Possible instructions you can give are
% stopping/exiting the task, turning on/off external devices, sending
% notifications, etc.
%
% If you want to customize this file for a particular task, make a copy of
% this file to the task directory and edit the copy.  The alert_function.m
% in the task directory has priority over the one in the main ML directory.
%
% To make this alert_function executed, turn on the alert button on the
% task panel of the main menu.
%
% VERSION HISTORY
% - 14-Oct-2020 - Thomas  - First version
% ----------------------------------------------------------------------------------------

% ENSURE path to matlab internal serialport function is at top of MATLAB search path.
% ML also has a serialport function (!!) and ML brings its dependecies to top of path each
% time it starts.
addpath('C:\Program Files\MATLAB\R2020b\toolbox\matlab\serialport')

% GLOBAL variable
global iScan timeStamp apitoken

switch hook
    case 'task_start'
        % When the task starts by '[Space] Start' from the pause menu
        % INIT exp and set flags in TrialRecord
        TrialRecord = ml_initExp(TrialRecord, MLConfig);
        
        if TrialRecord.User.mlPcFlag
            % OPEN serial port to read and save IScan ASCII serial data at 120Hz
            iScan = serialport('COM1', 115200);
            configureTerminator(iScan,10)
            configureCallback(iScan,"terminator",@ml_readSerialData)
            disp('[UPDATE] - opened serialport session');
        end
        
        if TrialRecord.User.sendHeaderFlag
            % SEND header to eCube if MLPC
            disp('[UPDATE] - sending header to eCube');
            ml_sendHeader(MLConfig);
            disp('[UPDATE] - header info sent to eCube');
        end
        
        if TrialRecord.User.recordNetcamFlag
            % START netCam recordings (requires watchtower server running and
            % cameras to be manually bound on netcam PC
            [outcome, apitoken] = ml_startNetcamRecord(MLConfig);
            if outcome
                disp('[UPDATE] - started netcam recording');
                TrialRecord.User.recordNetcamStartTime = clock;
            else
                disp('[UPDATE] - started netcam recording NOT started!!');
                TrialRecord.User.recordNetcamStartTime = NaN;
            end
        else
            TrialRecord.User.recordNetcamStartTime = NaN;
        end
        
    case 'block_start'
        
    case 'trial_start'
        if TrialRecord.User.mlPcFlag
            % PURGE iScan.UserData at trial start
            iScan.UserData = [];
            timeStamp      = [];
        end
        
    case 'trial_end'
        if TrialRecord.User.mlPcFlag
            % STORE iScan.UserData at trial end
            TrialRecord.User.serialData{TrialRecord.CurrentTrialNumber} = iScan.UserData;
            TrialRecord.User.timeStamp{TrialRecord.CurrentTrialNumber}  = timeStamp;
        end
        
    case 'block_end'
        
    case 'task_end'
        % When '[q] Quit' is selected in the pause menu or the task stops with an error
        if ~isnan(TrialRecord.User.recordNetcamStartTime)
            % STOP netCam recordings (requires watchtower server running and
            % cameras to be manually bound on netcam PC, recording must be going on)
            [outcome] = ml_stopNetcamRecord(apitoken);
            if outcome
                disp('[UPDATE] - stopped netcam recording');
            else
                disp('[UPDATE] - netcam recording NOT stopped!! Please do so manually');
            end
        end
        
        if TrialRecord.User.mlPcFlag
            configureCallback(iScan, "off");
            delete(iScan)
            clear iScan
            disp('[UPDATE] - cleared serialport session');
        end
        
    case 'task_aborted'
        % In case that the task stops with an error. The 'task_end' hook will follow.
        
    case 'task_paused'
        % When the task is paused with ESC during the task
        
    case 'task_resumed'
        % When the task is resumed by '[Space] Resume' from the pause menu
end
end
