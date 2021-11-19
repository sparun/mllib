% LOAD eventcodes - NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Define the eventcodes that may be transmitted during a calib, fixation, same-different
% and search task. Each value is assigned to a struct in certain logical groupings such
% that dissimilar events are not together and makes later decoding (i.e. gettign event
% name label from event code easy)
%
% VERSION HISTORY
%{
09-Nov-2021 - Zhivago - Final version
              Thomas  
              Georgin
%}
% ----------------------------------------------------------------------------------------

function [err, pic, aud, bhv, rew, exp, trl, chk, asc] = ml_loadEvents()
% TRIAL ERROR values (for setting trialerror in ML, not sent as eventmarker)
err.holdNil          = 8; % hold not initiated
err.holdOutside      = 9; % outside touch
err.holdBreak        = 7; % hold not maintained
err.fixNil           = 4; % no fixation
err.fixBreak         = 3; % break fixation
err.respNil          = 1; % no response
err.respEarly        = 5; % early response - not used
err.respLate         = 2; % late response - not used
err.respCorr         = 0; % correct response
err.respWrong        = 6; % incorrect response

% VISUAL STIM - common events
pic.holdOn           = 100;
pic.holdOff          = 101;
pic.fixOn            = 102;
pic.fixOff           = 103;

% VISUAL STIM - Calibration block
pic.calib1On         = 200;
pic.calib1Off        = 201;
pic.calib2On         = 202;
pic.calib2Off        = 203;
pic.calib3On         = 204;
pic.calib3Off        = 205;
pic.calib4On         = 206;
pic.calib4Off        = 207;
pic.calib5On         = 208;
pic.calib5Off        = 209;
pic.calib6On         = 210;
pic.calib6Off        = 211;
pic.calib7On         = 212;
pic.calib7Off        = 213;
pic.calib8On         = 214;
pic.calib8Off        = 215;
pic.calib9On         = 216;
pic.calib9Off        = 217;
pic.calib10On        = 218;
pic.calib10Off       = 219;

% VISUAL STIM - Fixation task
pic.stim1On          = 300;
pic.stim1Off         = 301;
pic.stim2On          = 302;
pic.stim2Off         = 303;
pic.stim3On          = 304;
pic.stim3Off         = 305;
pic.stim4On          = 306;
pic.stim4Off         = 307;
pic.stim5On          = 308;
pic.stim5Off         = 309;
pic.stim6On          = 310;
pic.stim6Off         = 311;
pic.stim7On          = 312;
pic.stim7Off         = 313;
pic.stim8On          = 314;
pic.stim8Off         = 315;
pic.stim9On          = 316;
pic.stim9Off         = 317;
pic.stim10On         = 318;
pic.stim10Off        = 319;

% VISUAL STIM - Same Different task
pic.sampleOn         = 400;
pic.sampleOff        = 401;
pic.testOn           = 402;
pic.testOff          = 403;
pic.choiceOn         = 404;
pic.choiceOff        = 405;

% AUDIO STIMULI - 300-399 range
aud.temp             = 500;

% BEHAVIOR - explicit monkey behavior
bhv.holdInit         = 600;
bhv.holdNotInit      = 601;
bhv.holdMaint        = 602;
bhv.holdNotMaint     = 603;
bhv.holdOutside      = 604;
bhv.fixInit          = 605;
bhv.fixNotInit       = 606;
bhv.fixMaint         = 607;
bhv.fixNotMaint      = 608;
bhv.respGiven        = 609;
bhv.respCorr         = 610;
bhv.respWrong        = 611;
bhv.respNil          = 612;

% REWARD
rew.juice            = 700;

% EXP HEADER - sent before first trial in alert_function.m
exp.nan              =  999;
exp.headerStart      = 1000;
exp.headerStop       = 1001;
exp.nameStart        = 1002;
exp.nameStop         = 1003;
exp.subjNameStart    = 1004;
exp.subjNameStop     = 1005;
exp.bhvNameStart     = 1006;
exp.bhvNameStop      = 1007;
exp.filesStart       = 1008;
exp.filesStop        = 1009;

% TRL FOOTER - sent after every trial
trl.start            = 1101;
trl.stop             = 1102;
trl.footerStart      = 1103;
trl.footerStop       = 1104;
trl.taskCalib        = 1105;
trl.taskFix          = 1106;
trl.taskSameDiff     = 1107;
trl.taskSearch       = 1108;

% TRL FOOTER SHIFT - add to actual value
trl.trialShift       = 2000;
trl.blockShift       = 6000;
trl.trialWBlockShift = 6500;
trl.conditionShift   = 7000;
trl.typeShift        = 8000;
trl.outcomeShift     = 8500;

% TRL FOOTER EXPECTED RESPONSE 
trl.expRespFree      = 9000;
trl.expRespSame      = 9001;
trl.expRespDiff      = 9002;

% TRL FOOTER EDITABLE - sent within trial footer 
trl.edtStart         = 9100;
trl.edtStop          = 9101;

% TRL FOOTER STIM IDS - sent within trial footer 
trl.stimStart        = 9200;
trl.stimStop         = 9201;

% TRL FOOTER SHIFT
trl.shift            = 10000;

% TRL FOOTER PIC POSITION SHIFT- in dva between range of 100000-199999 (midpoint 150000)
% Usage = Value(dva)*1000 + trl.picPosShift (for e.g. -8*1000+150000 = 142000)
trl.picPosShift      = 150000;

% ASCII SHIFT - add before sending ascii values
asc.shift            = 200000;

% CHECK - events to check individual digital line reliability
chk.linesEven        = 5592405;
chk.linesOdd         = 11184810;
end