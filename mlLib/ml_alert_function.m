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

global iScan TrialRecord

switch hook
	case 'task_start'
		% When the task starts by '[Space] Start' from the pause menu
		ml_sendHeader(MLConfig)
		disp('Header sent');
        TrialRecord.user.tester = 1;
        
%         % OPEN serial port to read and save IScan serial data at 120Hz
%         % Params selected in IScan interface        
%         iScan = serialport('COM1', 115200);
%         configureTerminator(iScan,10)
%         configureCallback(iScan,"terminator",@ml_readSerialData)
	case 'block_start'
		
	case 'trial_start'
        % PURGE iScan.UserData before trial start
%         iScan.UserData = [];
        
	case 'trial_end'
		
	case 'block_end'
		
	case 'task_end'
		% When '[q] Quit' is selected in the pause menu or the task stops with an error

	case 'task_aborted'
		% In case that the task stops with an error. The 'task_end' hook will follow.
		
	case 'task_paused'
		% When the task is paused with ESC during the task
		
	case 'task_resumed'
		% When the task is resumed by '[Space] Resume' from the pause menu
		
end

end
