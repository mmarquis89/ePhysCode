
% Record trial parameters
    sampRate = 10000;
    trialDuration = [2 9]; % Trial duration ([TimePerValve, nValves])
    stimVolts = 5;    
    
%     baseOutput = zeros(prod(trialDuration)*sampRate, 1);
%     valveStim = zeros(trialDuration(2), prod(trialDuration)*sampRate);
%     
%     for iValve = 0:trialDuration(2)-1
%         currOut = baseOutput;
%         currOut(2*iValve*sampRate+1:(2*iValve+trialDuration(1))*sampRate) = 1;
%         currOut(end) = 0; % Make sure valves are closed
%         valveStim(iValve+1, :) = currOut;        
%     end
%     valveOut = [valveStim]';
%     valveOut(1:end-1,1) = 1;
%     valveOut(:, 1:5) = valveOut(:, 1:5) * stimVolts;


     valveOut = [zeros(2*sampRate,1); ones(2*sampRate, 1)];
     valveOut = [valveOut; valveOut; valveOut];
     valveOut(end) = 0;
     valveOut = [valveOut, valveOut, valveOut, valveOut, valveOut];
     valveOut(:,1) = 5;
     valveOut(end, 1) = 0;
    
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
    
    % Add analog output channels
%     s.addAnalogOutputChannel('Dev1', 0 , 'Voltage');                % 3-way valve output channel
    s.addAnalogOutputChannel('Dev2', 0, 'Voltage');               % Clean valve output channels
    s.addDigitalChannel('Dev2', 'port0/line28:31', 'OutputOnly');   % Pinch valve digital output channels
    
    s.queueOutputData(valveOut);
    
    s.Rate = sampRate;
    x = s.startForeground();
   
    