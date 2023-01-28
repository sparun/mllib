% CUSTOM alert_function - NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% This function executes pre-defined instructions, when a certain task flow event listed
% below occurs. Possible instructions you can give are stopping/exiting the task, turning
% on/off external devices, sending notifications, etc.
%
% If you want to customize this file for a particular task, make a copy of this file to
% the task directory and edit the copy.  The alert_function.m in the task directory has
% priority over the one in the main ML directory. To activate this alert_function,
% turn on the alert button on the task panel of the main menu.
%
% NOTE - save this file as alert_function.m in local folder when using. Update function
%        name
%
% VERSION HISTORY
%   14-Oct-2020 - Thomas - First version
%   08-Nov-2021 - Thomas - Added clearing of iScan serialport object in
%                          task_aborted hook, throw error if raster threshold not 0
% ----------------------------------------------------------------------------------------

function alert_function(hook,MLConfig,TrialRecord)
% ENSURE path to matlab internal serialport function is at top of MATLAB search path.
% ML also has a serialport function (!!) and ML brings its dependecies to top of path each
% time it starts.
addpath('C:\Program Files\MATLAB\R2020b\toolbox\matlab\serialport')

% GLOBAL variable
global iScan timeStamp apitoken

switch hook
    case 'task_start'
        % When the task starts by '[Space] Start' from the pause menu
        
        % INITIALIZE the experiment and set flags in TrialRecord
        TrialRecord = ml_initExp(TrialRecord, MLConfig);
        
        % OPEN serial port to read and save IScan ASCII serial data at 120Hz (on MLPC)
        if TrialRecord.User.mlPcFlag            
            iScan = serialport('COM1', 115200);
            configureTerminator(iScan,10);
            
            % READ a single ASCII string from IScan to get rid of incomplete first package
            % that happens if serialport object starts reading in between terminators. Now
            % ml_readSerialData will have complete strings read.
            readline(iScan);
            
            % SET the iScan object to append each received datastream to iScan.UserData
            % using the following function
            configureCallback(iScan,"terminator",@ml_readSerialData)
            disp('[UPDATE] - opened serialport session');
        end
        
        % SEND header to eCube if MLPC
        if TrialRecord.User.sendHeaderFlag
            disp('[UPDATE] - sending header to eCube');
            ml_sendHeader(MLConfig);
            disp('[UPDATE] - header info sent to eCube');
        end
        
        % START netCam recordings (requires watchtower server running and
        % cameras to be manually bound on netcam PC
        if TrialRecord.User.recordNetcamFlag
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
        
        % THROW error if raster threshold not 0
        if MLConfig.RasterThreshold ~= 0
            % CLEAR serialport object for IScan at end of experiment
            if TrialRecord.User.mlPcFlag && exist('iScan','var')
                configureCallback(iScan, "off");
                delete(iScan)
                clear iScan
                disp('[UPDATE] - cleared serialport session');
            end
            error('[ERROR] - raster threshold is not correct!! Please set it to 0 in photodiode tuner!')
        end
        
    case 'block_start'
        
    case 'trial_start'
        % PURGE iScan.UserData at trial start
        if TrialRecord.User.mlPcFlag
            iScan.UserData = [];
            timeStamp      = [];
        end
        
    case 'trial_end'
        % STORE iScan.UserData at trial end
        if TrialRecord.User.mlPcFlag            
            serialDataNum = nan(size(iScan.UserData,1),12);
            
            % NOTE: removing this for loop doesn't work for some reason
            for i = 1:length(iScan.UserData)
                serialDataNum(i,:) = str2num(iScan.UserData(i));
            end
            
            TrialRecord.User.serialData{TrialRecord.CurrentTrialNumber} = serialDataNum;
            TrialRecord.User.timeStamp{TrialRecord.CurrentTrialNumber}  = timeStamp;
        end
        
    case 'block_end'
        
    case 'task_end'
        % When '[q] Quit' is selected in the pause menu or the task stops with an error
        % STOP netCam recordings (requires watchtower server running and
        % cameras to be manually bound on netcam PC, recording must be going on)
        if ~isnan(TrialRecord.User.recordNetcamStartTime)
            [outcome] = ml_stopNetcamRecord(apitoken);
            if outcome
                disp('[UPDATE] - stopped netcam recording');
            else
                disp('[UPDATE] - netcam recording NOT stopped!! Please do so manually');
            end
        end
        
        % CLEAR serialport object for IScan at end of experiment
        if TrialRecord.User.mlPcFlag && exist('iScan','var')
            configureCallback(iScan, "off");
            delete(iScan)
            clear iScan
            disp('[UPDATE] - cleared serialport session');
        end
        
    case 'task_aborted'
        % In case that the task stops with an error. The 'task_end' hook will follow.
        
        % CLEAR serialport object for IScan if task aborted with error
        if TrialRecord.User.mlPcFlag && exist('iScan','var')
            configureCallback(iScan, "off");
            delete(iScan)
            clear iScan
            disp('[UPDATE] - cleared serialport session');
        end
    case 'task_paused'
        % When the task is paused with ESC during the task
        
    case 'task_resumed'
        % When the task is resumed by '[Space] Resume' from the pause menu
end
end
