
% Record trial parameters
    sampRate = 10000;
    trialDuration = [2 2];                      % Trial duration (pre-stim, clean valve, post-stim)
    stimVolts = 5;    
    
    valveStim = [ones(sampRate * trialDuration(1), 1)*stimVolts; zeros(sampRate * trialDuration(2), 1)];                                       % Make sure valves are closed
    valveOut = [valveStim];
    valveOut(end) = 0; 

    %% Session based acquisition code for inputs  
    
%    CHANNEL SET-UP:
%       0  Scaled Out 
%       1  Im  
%       2  10Vm  
%       3  Amplifier Gain
%       4  Amplifier Filter Freq
%       5  Amplifier Mode
    
    % Setup session and input channels
    s = daq.createSession('ni');
    s.DurationInSeconds = sum(trialDuration);
    s.Rate = sampRate;
%     s.addAnalogInputChannel('Dev1',[0:5],'Voltage');
%     for i=1:6
%         s.Channels(1,i).InputType = 'SingleEnded';
%     end    
    
    % Add valve control output channels
%     s.addAnalogOutputChannel('Dev1', 0 , 'Voltage');            % Clean valve output channel
%     s.addDigitalChannel('Dev1', 'port0/line0', 'OutputOnly');   % Pinch valve digital output channel
    
%     s.addAnalogOutputChannel('Dev2', 0, 'Voltage');
%     s.addAnalogOutputChannel('Dev2', 1, 'Voltage');
%     s.queueOutputData([valveOut]);
    
    s.Rate = sampRate;
    x = s.startForeground();
   
    