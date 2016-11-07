
%% LOAD EXPERIMENT

expData = loadExperiment('17-Nov-2015',1);
    
%% PULL OUT TRIAL BLOCK
bl = [];
blockLists = {7:24, 26:45, 47:66, 68:87, 89:108, 110:129, 131:150, 152:171};
trialList = [32 34 35 45 48]
block = getTrials(expData, trialList);                                                            % Save trial data and info as "block"
block.trialInfo(1).pumpTiming = [.5 .02];

% Create global variables 
bl.trialInfo = block.trialInfo;
bl.date = block.trialInfo(1).date;
bl.trialList = trialList; 
bl.nTrials = length(block.trialInfo);                                                             % Number of trials in block
bl.sampRate = block.trialInfo(1).sampratein;                                                      % Sampling rate
bl.sampleLength = 1/bl.sampRate;                                                                  % Sample duration
bl.time = bl.sampleLength:bl.sampleLength:bl.sampleLength*length(block.data(:,1,1));              % Time in seconds of each sample
bl.trialDuration = block.trialInfo(1).trialduration;
if ~isempty(block.trialInfo(1).ampMode)
   bl.ampMode = block.trialInfo(1).ampMode; 
end
bl.odor = block.trialInfo(1).odor;
bl.Rpipette = pipetteResistanceCalc(expData.trialData(1).scaledOut);

% Get picoPump I/O data
if ~isempty(block.trialInfo(1).pumpOn)
    for iTrial = 1:bl.nTrials
        bl.pumpOn(iTrial) = block.trialInfo(iTrial).pumpOn;
    end
    bl.pumpTiming = block.trialInfo(1).pumpTiming;
end

% This stuff only applies if an odor was presented
if length(bl.trialDuration) > 1   
    % Get vHolds for each trial
     if strcmp(bl.ampMode, 'Vclamp')
        vHolds = zeros(bl.nTrials, 1);
        for iTrial = 1:bl.nTrials
            vHolds(iTrial) = block.trialInfo(iTrial).vHold;
        end
        bl.vHolds = vHolds;
     end    
    % Save valve timing
    bl.pinchOpen = block.trialInfo(1).trialduration(1);                                                % Pre-stim time (sec)
    bl.stimOnTime = block.trialInfo(1).trialduration(1) + block.trialInfo(1).trialduration(2);
    bl.stimLength = block.trialInfo(1).trialduration(3);                                               % Stim duration
end

% Save recorded data
bl.voltage = block.data(:,:,2);             % 10 Vm voltage traces
bl.current = block.data(:,:,1);             % Preamp-filtered current
bl.scaledOut = block.data(:,:,3);           % Scaled Output

% PLOT EACH TRIAL VOLTAGE AND CURRENT
plotTraces(bl);

%% PLOT AVERAGE TRACES
f = figInfo;
f.figDims = [10 500 700 450]; 
f.timeWindow = [12 16];
avgTracePlot(bl, f);


%% PLOT ACCESS AND INPUT RESISTANCES
figure(3); clf; hold all 
figDims = [];
yLims = [];

plotResistance(bl, figDims, yLims);


%% PLOT SUBTRACTED MEAN TRACES

figure(4); clf; hold all
startTime = 12.8;
endTime = 14.4;
plot(bl.time(startTime*bl.sampRate:endTime*bl.sampRate), bl.meanTraces(startTime*bl.sampRate:endTime*bl.sampRate,1))
plot(bl.time(startTime*bl.sampRate:endTime*bl.sampRate), bl.meanTraces(startTime*bl.sampRate:endTime*bl.sampRate,2))
bl.meanTraceDiff = bl.meanTraces(:,1)-bl.meanTraces(:,2);
plot(bl.time(startTime*bl.sampRate:endTime*bl.sampRate), bl.meanTraceDiff(startTime*bl.sampRate:endTime*bl.sampRate))

%%
[b,a] = butter(2,.004,'low');
D = designfilt('lowpassiir', ...
    'PassbandFrequency', 15, ...
    'StopbandFrequency', 100, ...
    'StopbandAttenuation', 100, ...
    'SampleRate', 10000);
fvtool(D)
bl.voltage(:,1) = filtfilt(b,a, bl.current(:,1));

%% PLOT FREQUENCY CONTENT OF FIRST TRIAL
 
% Calulate frequency power spectrum for each data type
[pfftV, fValsV] = getFreqContent(bl.voltage(:,1),bl.sampRate);    
[pfftC, fValsC] = getFreqContent(bl.current(:,1),bl.sampRate);

% Plot them each on a log scale
figure(1);clf;subplot(211)
plot(fValsV, 10*log10(pfftV));
title('Voltage'); xlabel('Frequency (Hz)') ;ylabel('PSD(dB)'); xlim([-300 300]);

subplot(212)
plot(fValsV, 10*log10(pfftC));
title('Current'); xlabel('Frequency (Hz)'); ylabel('PSD(dB)'); xlim([-300 300]);

%% USE A 60+120 HZ FILTER TO REMOVE LINE NOISE
freq = 60;                                                                                      % Set filter parameters
bWidth = 40;
for iTrial = 1:bl.nTrials
    bl.voltage(:,iTrial) = notchFilter(bl.voltage(:,iTrial),bl.sampRate, freq, bWidth);       % Apply to each trial
    bl.current(:,iTrial) = notchFilter(bl.current(:,iTrial),bl.sampRate, freq, bWidth);
end

freq = 120;                                                                                      % Set filter parameters
bWidth = 40;
for iTrial = 1:bl.nTrials
    bl.voltage(:,iTrial) = notchFilter(bl.voltage(:,iTrial),bl.sampRate, freq, bWidth);       % Apply to each trial
    bl.current(:,iTrial) = notchFilter(bl.current(:,iTrial),bl.sampRate, freq, bWidth);
end

