function Ra = accessResistanceCalc(sealTestCurrent, sampRate)
% Uses a current trace from a Vclamp seal test trial to calculate the access resistance (in MOhm)

dV = 5; % Voltage step in mV

% Find all peaks that are far enough apart to be the transients
[It, ItLocs] = findpeaks(sealTestCurrent, 'MinPeakDistance', (0.015*sampRate));

% Remove first and last peak
It([1, end]) = [];
ItLocs([1, end]) = [];

% Get average current value from 5-1 msecs before each peak
Ibase = zeros(length(It), 1);
for iPk = 1:length(It)
    Ibase(iPk) = mean(sealTestCurrent(ItLocs(iPk)-.005*sampRate:ItLocs(iPk)-.001*sampRate));
end

% Calculate average transient size
dIt = mean(It - Ibase);

% Calculate access resistance in MOhms
Ra = (dV / dIt) * 1000;
    
end