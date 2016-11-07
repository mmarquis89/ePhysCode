
%% LOAD EXPERIMENT

expData = loadExperiment('01-Sep-2015',1);
    
%% PULL OUT TRIAL BLOCK

trialList = [1];
block = getTrials(expData, trialList);                                                                  % Save trial data and info as "block"

% Create global variables
bl.trialList = trialList;
bl.nTrials = length(block.trialInfo);                                                               % Number of trials in block
bl.sampRate = block.trialInfo(1).sampratein;                                                        % Sampling rate
bl.sampleLength = 1/bl.sampRate;                                                                % Sample duration
bl.time = [bl.sampleLength:bl.sampleLength:bl.sampleLength*length(block.data(:,1,1))];  % Time in seconds of each sample   


bl.rawVoltage = block.data(:,:,3);                                                                  % Scaled Output voltage traces
bl.rawCurrent = block.data(:,:,1);

bl.stimOnTime = block.trialInfo(1).trialduration(1);                                                % Pre-stim time (sec)
bl.stimLength = block.trialInfo(1).trialduration(2);                                                % Stim duration
bl.nSamples = sum(block.trialInfo(1).trialduration)*bl.sampRate;                                % Total # of samples in trials
bl.stimVoltage = block.trialInfo(1).stimIntensity;                                                  % Stimulus voltage

% List of stim intensities (duty cycles)
bl.intensities = zeros(nTrials,1);                                                                  % Stim intensity for each trial
for iTrial = 1:bl.nTrials
   bl.intensities(iTrial) = block.trialInfo(iTrial).stimDutyCyc;
end
bl.stimVals = unique(bl.intensities);                                                           % List of the intensities used
bl.nStims = length(bl.stimVals);                                                                % Save total number of intensities

bl.filteredVoltage = rawVoltage;
bl.filteredCurrent = rawCurrent;

%% PLOT FREQUENCY CONTENT OF FIRST TRIAL

% Calulate frequency power spectrum for each data type
[pfftV, fValsV] = getFreqContent(bl.filteredVoltage(:,1),bl.sampRate);    
[pfftC, fValsC] = getFreqContent(bl.filteredCurrent(:,2),bl.sampRate);

% Plot them each on a log scale
figure(1);clf;subplot(211)
plot(fValsV, 10*log10(pfftV));
title('Voltage'); xlabel('Frequency (Hz)') ;ylabel('PSD(dB)'); xlim([-300 300]);

subplot(212)
plot(fValsV, 10*log10(pfftC));
title('Current'); xlabel('Frequency (Hz)'); ylabel('PSD(dB)'); xlim([-300 300]);

%% USE A 60 HZ FILTER TO REMOVE NOISE
freq = 60;                                                                                      % Set filter parameters
bWidth = 40;
for iTrial = 1:nTrials
    bl.filteredVoltage(:,iTrial) = notchFilter(bl.rawVoltage(:,iTrial),bl.sampRate, freq, bWidth);       % Apply to each trial
    bl.filteredCurrent(:,iTrial) = notchFilter(bl.rawCurrent(:,iTrial),bl.sampRate, freq, bWidth);
end

%% PLOT EACH TRIAL VOLTAGE AND CURRENT

plotTraces(bl);

%% PLOT AVERAGE TRACES FOR EACH INTENSITY

avgTracePlot(bl);

%% PCA WITH AVERAGE VOLTAGE TRACES

Trange = [4.5 8];                     % Set the range in seconds to analyze
plotThresh = 5;                       % Minimum percentage of variance explained by a PC to plot it
pcaPlot(bl, Trange, plotThresh)

%% GET SPIKE LOCS FROM CURRENT

posThresh = 4;                          % Minimum current peak size to be counted as a spike

spikes = getSpikesI(bl, posThresh);     % Find spike locations in all trials
bl.spikes = spikes;                     % Save to data structure
   
    %% Plot normalized current traces to help choose threshold
    normCurrent = bl.current - mean(median(bl.current));
    figure; plot(bl.time, normCurrent);

    %% Look at histogram of peak heights to evaluate choice of threshold
    allPks = [];
    for iTrial = 1:bl.nTrials
        allPks = [allPks; bl.spikes(iTrial).peakVals];
    end
    hist(allPks,20)

%% PLOT SPIKE RASTERS

plotRasters(bl)

%% PLOT TOTAL NUMBER OF PRE-STIMULUS SPIKES FOR EACH TRIAL

smoothWin = 1;                              % Width of smoothing window to apply to results; setting width to 1 will skip smoothing
plotBaselineSpikes(bl, smoothWin);

%% CALCULATE SPIKE COUNT IN RESPONSE PERIOD

bl.responseLength = 300;                                            % Time post-stim (in milliseconds) to collect spikes from
bl.minLatency = 40;                                                 % Minimum time (in milliseconds) after stim to count spike in response
bl.responses = responseCalc(bl, bl.responseLength, bl.minLatency);

% Plot total spikes in response vs. stim intensity
spikeResponsePlot(bl)

%% PSTH

combSpikeLocs = groupSpikes(bl, 0);

%% Pull out spikes for all trials
spikeLocs = cell(nTrials,1);
for iTrial = 1:bl.nTrials
    spikeLocs{iTrial} = bl.spikes(iTrial).locs;
end

% Combine spikes of the same stim intensity
stimSpikeLocs = cell(bl.nStims, 1);
for iStim = 1:bl.nStims
   currStim = bl.stimVals(iStim);
   stimSpikeLocs{iStim} = cell2mat(spikeLocs(bl.intensities==currStim));
   intsCount(iStim) = sum(bl.intensities==currStim);
end

% Condense stims
i=1;
for iStim = 1:2:bl.nStims
    combSpikeLocs{i} = [stimSpikeLocs{iStim}; stimSpikeLocs{iStim+1}];
    combIntsCount(i) = [intsCount(iStim)+intsCount(iStim+1)];
    i=i+1;
end


%% OVERLAY SCALED SSVKERNAL ESTIMATES 

figure(1);clf;hold on
cm = colormap(jet(length(combSpikeLocs)));
KDEPeaks = NaN(length(combSpikeLocs)-1, 2);
for iStim = 2:length(combSpikeLocs);

    [y,t,optw] = ssvkernel(combSpikeLocs{iStim}./sampRate, linspace(0, nSamples./sampRate, 1000));
    totSpikes = length(combSpikeLocs{iStim})/combIntsCount(iStim);
    totalTime = nSamples/sampRate;
    secPerYpoint = totalTime/length(y);
    spikeDist = totSpikes*2*(y./100);
    instSpikeRate = spikeDist.*(1/secPerYpoint);
    intLength = totalTime/length(y);
    
    % Save intial peak values (5-5.3 sec)
%     scaledY = totSpikes*y;
%     [pks, locs] = findpeaks(scaledY(floor(5/intLength):ceil(5.3/intLength)));
%     KDEPeaks(iStim-1, :) = [pks, locs];
    
    % Subtract baseline from seconds 2-4 and trim both ends to cut off artifacts
    baseline = mean(y(ceil(2/intLength):ceil(4/intLength)));
    y = y - baseline;
    y = y(ceil(1/intLength):end-ceil((2/intLength)));
        
    plot(linspace(1,totalTime-2, length(y)) , totSpikes*y, 'color', cm(iStim,:))    
    drawnow
end

title({['Smoothed, trimmed, and baseline-subracted firing rate for neighboring pairs of stim intensities'],['Trial numbers: ' num2str(trialList(1)) '-' num2str(trialList(end))], ...
    ['Stimulus voltage = ' num2str(stimVoltage) 'V     Duration = ' num2str(1000*stimLength) ' ms'], ...
    ['Duty cycle range: ' num2str(stimVals(1)) '% - ' ...
    num2str(stimVals(end)) '% (' num2str(nStims/2) ' total)']});
xlabel('Time (sec)'); ylabel('Firing (arbitrary units)');
    

%% PLOT THE HISTOGRAMS FOR EACH COMBINED STIM

figure(2);clf;hold on
cm = colormap(jet(length(combSpikeLocs)));
clear hNorm;clear h;
for iStim = 1:length(combSpikeLocs);
    subplot(3, 4, iStim)
    h = hist(combSpikeLocs{iStim},200);
    totalTime = nSamples/sampRate;
    hNorm(iStim,:) = h - (mean(h(1:floor((5/totalTime)*200))));
    plot(hNorm(iStim,:))
end

%% PLOT KERNEL DENSITY ESTIMATES ALONGSIDE PSTH

for iStim = 14:20;1:nStims;
    figure(iStim);clf;hold on;
    subplot(311)
    ssvkernel(stimSpikeLocs{iStim}./sampRate,linspace(0, nSamples./sampRate, 1000));  
    title(num2str(iStim));
    
    subplot(312)
    hist(stimSpikeLocs{iStim},100);
    title(num2str(iStim))
    %plot(h)
    
    subplot(313)
    [f,xi,bw] = ksdensity(stimSpikeLocs{iStim}, linspace(0, nSamples, 100), 'width', 3000);
    plot(linspace(0,nSamples,length(f)),f)
    length(f)
end

%% ==========================================================================================================================

%% Attempt to compare PN responses with and without blocking inhibition
figure(1);clf;hold on

withBlockersNorm = (withBlockersPeaks-min(withBlockersPeaks(:))) ./ (max(withBlockersPeaks(:)-min(withBlockersPeaks(:))));
withoutBlockersNorm = (withoutBlockersPeaks-min(withoutBlockersPeaks(:))) ./ (max(withoutBlockersPeaks(:)-min(withoutBlockersPeaks(:))));

withBlockersNorm(1) = [];
withoutBlockersNorm(1) = [];

plot(withBlockersNorm, 'o', 'color', 'r')
plot(withoutBlockersNorm, 'o','color', 'b')

plot(smooth(withBlockersNorm), 'color', 'r')
plot(smooth(withoutBlockersNorm),'color', 'b')

plot((smooth(withoutBlockersNorm-withBlockersNorm,5)), 'color', 'k')

xlim([0 10])

% plot(-(smooth(withoutBlockersNorm)-smooth(withBlockersNorm)), 'color', 'k')
