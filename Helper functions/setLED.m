function setLED(powerLevel)
%=======================================================================================================
% Sets the scope LED lamp's power to the desired level (and leaves it that way until further notice)
%   powerLevel = desired LED power output, expressed as a percent (i.e. 0-100)
% 
% Note that the maximum command voltage for the LED controller is actually only 5V, but I'm using a 
% voltage divider to cut the input voltage in half, so this function treats the max as 10V.
%=======================================================================================================

% Set up stimulus
outputVec = ones(1000, 1) * (10 * powerLevel/100);

% Create and run session
s = daq.createSession('ni');
s.Rate = 10000; % Doesn't really matter what this is
s.addAnalogInputChannel('Dev2', 0, 'Voltage')  % This "dummy" input channel is used just for its clock
s.addAnalogOutputChannel('Dev2', 1, 'Voltage');
s.queueOutputData(outputVec);
x = s.startForeground(); % Recorded data from input channel is discarded

end