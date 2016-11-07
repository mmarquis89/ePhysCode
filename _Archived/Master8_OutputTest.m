 

trialDuration = [7 6 1 6];
stimVolts = 8;
sampRate = 10000;
    
pretOut = zeros(sampRate * trialDuration(1), 1);            % Make pre-stim output vector
stim = ones(sampRate * trialDuration(2), 1) * stimVolts;
postStimOut = zeros(sampRate * trialDuration(3), 1);        % Make post-stim output vector

stimData = [preStimOut; stim; postStimOut];
stimData(end) = 0;

Vhold = -45;
testPulseLength = 1;

prePulse = ones(1 * sampRate, 1) * (Vhold / 20);
testPulse = ones(testPulseLength * sampRate, 1) * ((Vhold-5) / 20);
postPulse = ones((sum(trialDuration)* sampRate - length(prePulse) - (testPulseLength*sampRate)),1) * (Vhold / 20);

extCommand = [prePulse; testPulse; postPulse];
extCommand(end) = 0;
plot(extCommand)

s = daq.createSession('ni');
 
s.addAnalogInputChannel('Dev1',[0:5],'Voltage');
for i=1:6
    s.Channels(1,i).InputType = 'SingleEnded';
end
s.DurationInSeconds = sum(trialDuration); %sum(data(n).trialduration);
s.Rate = sampRate;% data(n).sampratein;  
s.addAnalogOutputChannel('Dev1', 0 , 'Voltage');
 s.addAnalogOutputChannel('Dev1', 1 , 'Voltage');
s.Rate = sampRate; %data(n).samprateout;
s.queueOutputData([stimData, extCommand]);

x = s.startForeground();