function Rseal = seal_resistance_calc(current, voltage)
% ==============================================================================================
% Uses a current trace from a Vclamp seal test trial (after transients are cancelled) 
% to calculate the approximate seal resistance (in GOhm)
% ==============================================================================================

dV = 5; % Voltage step in mV

%
current1 = median(current(voltage>3)); % Current during high voltage step
current2 = median(current(voltage<1)); % Current during low voltage step
dI = abs(current1 - current2);

% Calculate seal resistance in GOhms
Rseal = (dV / dI);

end