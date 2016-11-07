%% LOAD EXPERIMENT

expData = loadExperiment('22-Sep-2015',2);
    
%% PULL OUT TRIAL BLOCK

trialLists = {7:32, 33:57, 58:82, 83:107, 108:132, 133:157, 158:207};
for iBl = 1:length(trialLists)
    block{iBl} = getTrials(expData, trialLists{iBl});                                                                  % Save trial data and info as "block"

    % Create global variables
    bl(iBl).date = block{iBl}.trialInfo(1).date;
    bl(iBl).trialList = trialLists{iBl}; 
    bl(iBl).nTrials = length(block{iBl}.trialInfo);                                                               % Number of trials in block
    bl(iBl).sampRate = block{iBl}.trialInfo(1).sampratein;                                                        % Sampling rate
    bl(iBl).sampleLength = 1/bl(iBl).sampRate;                                                                % Sample duration
    bl(iBl).time = [bl(iBl).sampleLength:bl(iBl).sampleLength:bl(iBl).sampleLength*length(block{iBl}.data(:,1,1))];  % Time in seconds of each sample   
    
    % New Additions
%     bl(iBl).odor = block{iBl}.trialInfo(1).odor;
%     bl(iBl).scaledOutMode = block{iBl}.trialInfo(1).scaledOutMode;
    
    bl(iBl).rawVoltage = block{iBl}.data(:,:,2);                                                                  % 10 Vm voltage traces
    bl(iBl).rawCurrent = block{iBl}.data(:,:,1);                                                                  % Im current traces

    bl(iBl).pinchOpen = block{iBl}.trialInfo(1).trialduration(1);                                                % Pre-stim time (sec)
    bl(iBl).stimOnTime = block{iBl}.trialInfo(1).trialduration(1) + block{iBl}.trialInfo(1).trialduration(2);
    bl(iBl).stimLength = block{iBl}.trialInfo(1).trialduration(3);                                                % Stim duration
    bl(iBl).nSamples = sum(block{iBl}.trialInfo(1).trialduration)*bl(iBl).sampRate;                                % Total # of samples in trials                                                           % Save total number of intensities

    bl(iBl).filteredVoltage = bl(iBl).rawVoltage;
    bl(iBl).filteredCurrent = bl(iBl).rawCurrent;

end

%% PLOT EACH TRIAL VOLTAGE AND CURRENT

plotTraces(bl);

%% PLOT AVERAGE TRACES

type = 'current';  % current or voltage
avgTracePlot(bl, type);

%%
[b,a] = butter(2,.004,'low');
D = designfilt('lowpassiir', ...
    'PassbandFrequency', 15, ...
    'StopbandFrequency', 100, ...
    'StopbandAttenuation', 100, ...
    'SampleRate', 10000);
fvtool(D)
bl.filteredVoltage(:,1) = filtfilt(b,a, bl.filteredCurrent(:,1));

%% PLOT FREQUENCY CONTENT OF FIRST TRIAL
 
% Calulate frequency power spectrum for each data type
[pfftV, fValsV] = getFreqContent(bl.filteredVoltage(:,1),bl.sampRate);    
[pfftC, fValsC] = getFreqContent(bl.filteredCurrent(:,1),bl.sampRate);

% Plot them each on a log scale
figure(1);clf;subplot(211)
plot(fValsV, 10*log10(pfftV));
title('Voltage'); xlabel('Frequency (Hz)') ;ylabel('PSD(dB)'); xlim([-300 300]);

subplot(212)
plot(fValsV, 10*log10(pfftC));
title('Current'); xlabel('Frequency (Hz)'); ylabel('PSD(dB)'); xlim([-300 300]);

%% USE A 60+120 HZ FILTER TO REMOVE NOISE
freq = 60;                                                                                      % Set filter parameters
bWidth = 40;
for iTrial = 1:bl.nTrials
    bl.filteredVoltage(:,iTrial) = notchFilter(bl.filteredVoltage(:,iTrial),bl.sampRate, freq, bWidth);       % Apply to each trial
    bl.filteredCurrent(:,iTrial) = notchFilter(bl.filteredCurrent(:,iTrial),bl.sampRate, freq, bWidth);
end

freq = 120;                                                                                      % Set filter parameters
bWidth = 40;
for iTrial = 1:bl.nTrials
    bl.filteredVoltage(:,iTrial) = notchFilter(bl.filteredVoltage(:,iTrial),bl.sampRate, freq, bWidth);       % Apply to each trial
    bl.filteredCurrent(:,iTrial) = notchFilter(bl.filteredCurrent(:,iTrial),bl.sampRate, freq, bWidth);
end