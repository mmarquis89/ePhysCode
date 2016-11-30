function [rInput] = calcRinput(data, sR, Istep, stepStart, stepLength, calcWin)
% =========================================================================================================
% Calculates input resistance in GOhm of a current clamp trial with a test step.
    % data = the vector of raw Vm data (in mV)
    % sR = the sampling rate of the trial
    % Istep = magnitude of the current step in pA
    % stepStart = current step start time in sec
    % stepLength = current step length in sec
    % calcWin = window size in seconds to average across before the beginning and end of the current step
% =========================================================================================================

stepEnd = stepStart + stepLength;

dI = Istep * 10^-12; % Convert Istep from pA to Amps
data = data / 1000; % Convert data from mV to Volts

vStart = mean(data(sR*(stepStart-calcWin):sR*stepStart));   % Mean Vm during the period before current step
vStep = mean(data(sR*(stepEnd-calcWin):sR*stepEnd));        % Mean Vm during the final portion of the current step

dV = vStart - vStep;    % Calculate dV

rInput = abs((dV / dI)) / 10^9; % Calculate input resistance and convert to GOhm

end