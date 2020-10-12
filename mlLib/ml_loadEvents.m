% ml_loadEvents.m -> Declare event codes
% 
% EVENT CODES PLAN
%  000-009  ML error codes
%  100-199  Common visual events       (hold on/off, fix on/off) 
%  200-299  Calibration event codes    (10 cues x 2 on/off) 
%  300-399  Fixation task events       (10 stimuli x 2 on/off)
%  400-499  SD task events             (sample on/off, test on/off, choice on/off)
%  500-599  Auditory stimuli events    (max 30 stimuli x 2 on/off)
%  600-699  Monkey behavioural events
%  700-799  Reward events
%  FILL IN THE REST

function [err, pic, aud, bhv, rew, exp, trl, check, ascii] = ml_loadEvents()

% TRIAL ERROR values
err.holdNil          = 8; % ignored - hold not initiated
err.holdOutside      = 9; % aborted - outside touch
err.holdBreak        = 7; % lever break - hold not maintained
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
pic.fix1On           = 300;
pic.fix1Off          = 301;
pic.fix2On           = 302;
pic.fix2Off          = 303;
pic.fix3On           = 304;
pic.fix3Off          = 305;
pic.fix4On           = 306;
pic.fix4Off          = 307;
pic.fix5On           = 308;
pic.fix5Off          = 309;
pic.fix6On           = 310;
pic.fix6Off          = 311;
pic.fix7On           = 312;
pic.fix7Off          = 313;
pic.fix8On           = 314;
pic.fix8Off          = 315;
pic.fix9On           = 316;
pic.fix9Off          = 317;
pic.fix10On          = 318;
pic.fix10Off         = 319;

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
bhv.respCorr         = 609;
bhv.respWrong        = 610;
bhv.respNil          = 611;

% REWARD
rew.juice            = 700;

% EXP HEADER - sent before first trial in alert_function.m
exp.headerStart      = 1000;
exp.headerStop       = 1001;
exp.nameStart        = 1002;
exp.nameStop         = 1003;
exp.subjNameStart    = 1004;
exp.subjNameStop     = 1005;
exp.filesStart       = 1006;
exp.filesStop        = 1007;

% TRL FOOTER - sent after every trial
trl.start            = 1101;
trl.stop             = 1102;
trl.footerStart      = 1103;
trl.footerStop       = 1104;

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
 
% CHECK - events to check individual line reliability
check.linesEven      = 5592405;
check.linesOdd       = 11184810;

% ASCII SHIFT - add before sending ascii values
ascii.shift          = 10000;
end

% CODES for exracting text(fieldname) from eventmarker value
% eventVal  = 1;
% selCode   = err;
% fieldName = fieldnames(selCode);
% ind       = structfun(@(x) x == eventVal,err);
% evtName   = fieldName(ind);