
%% Load experiment data  

% expData = loadExperiment('16-Mar-2015',2);
    
%% Pull out trial block
trialList = [20:99];
block = getTrials(expData, trialList);
    
%%  Plot each trial voltage
sampleLength = 1/block.trialInfo(1).sampratein;
time = [sampleLength:sampleLength:sampleLength*length(block.data(:,1,1))];
figure (1);clf; hold on
set(gcf,'Position',[25 350 1250 550],'Color',[1 1 1]);

for iTrial = 1:length(block.trialInfo)
    plot(time, block.data(:,iTrial,3))
end

plot([(block.trialInfo(1).trialduration(1)),(block.trialInfo(1).trialduration(1))],ylim, 'Color', 'red')
plot([(block.trialInfo(1).trialduration(1)+block.trialInfo(1).trialduration(2)),(block.trialInfo(1).trialduration(1)+block.trialInfo(1).trialduration(2))],ylim, 'Color', 'red')
title(['Trial Numbers ' num2str(trialList(1)) '-' num2str(trialList(end)) ]);
ylabel('Vm (mV)');
box off

%% Plot the trials in the block color-coded by stimulus intensity

% sampleLength = 1/block.trialInfo(1).sampratein;
% time = [sampleLength:sampleLength:sampleLength*length(block.data(:,1,1))];
% figure (1);clf; hold on
% set(gcf,'Position',[25 350 1250 550],'Color',[1 1 1]);
% 
% colors = ['m' 'b' 'g' 'k'];
% stims = [1 3 5 10];
% 
% for iTrial = 1:length(block.trialInfo)
%     plotColor = colors(find(stims == block.trialInfo(iTrial).stimDutyCyc));
%     plot(time, block.data(:,iTrial,3), 'Color',plotColor)
% end
% 
% plot([(block.trialInfo(1).trialduration(1)),(block.trialInfo(1).trialduration(1))],ylim, 'Color', 'r')
% title(['Trial Numbers ' num2str(trialList(1)) '-' num2str(trialList(end)) ]);
% ylabel('Vm (mV)');
% box off

%% Find indexes of each spike peak, # of spikes in response, and latency for each trial
for iTrial = 1:length(block.trialInfo)
    [peaks, peakLocs] = findpeaks(block.data(:,iTrial,3));
    peakLocs(peaks < -55) = [];
    stimTime = block.trialInfo(iTrial).trialduration(1)*block.trialInfo(iTrial).sampratein;
    sampRate = block.trialInfo(iTrial).sampratein;
    
    block.spikes(iTrial).locs = peakLocs;                                                                               % Save peak indices
    block.spikes(iTrial).response = sum(peakLocs > stimTime & peakLocs < stimTime+ 0.5*sampRate);                       % Total spikes in response
    block.spikes(iTrial).latency = floor(min(peakLocs(peakLocs > stimTime+(sampRate*.03) & peakLocs < stimTime + 0.5*sampRate))-stimTime)*(1000/sampRate);   % Latency to first spike
end

%% List responses by stim intensity

responses = zeros(length(block.trialInfo),2);
latencies = responses;
for iTrial = 1:length(block.trialInfo)
    
    responses(iTrial,1) = block.trialInfo(iTrial).stimDutyCyc;      % First column - duty cycle
    responses(iTrial,2) = block.spikes(iTrial).response;            % Second column - spikes in 500 ms after stim onset
    
    latencies(iTrial,1) = block.trialInfo(iTrial).stimDutyCyc;
    if ~isempty(block.spikes(iTrial).latency)
        latencies(iTrial, 2) = block.spikes(iTrial).latency;        % latency to first spike
    end
end
latencies(latencies(:,2) == 0, :) = [];                             % Get rid of trials with no spikes

% Check for stimulus-independent change throughout block
close all; figure(1); clf; hold all
plot(1:length(responses(:,1)), responses(:,2),'*')                  % Plot responses over time
%plot(1:length(responses(:,1)), responses(:,1),'*')                 % Plot stim duty cycles over time
title(['Stim strength: ', num2str(block.trialInfo(1).stimIntensity), 'V, ' , 'Duty cycle: ', num2str(min(responses(:,1))), '-', num2str(max(responses(:,1))), ', ITI = ', num2str(floor(sum(block.trialInfo(1).trialduration)))])
xlabel('Trial number'); ylabel('Response (spikes)');

% Scatter plot of responses vs. intensity
figure(2); clf; hold all
plot(responses(:,1), responses(:,2),'*');                           % Plot raw responses
intensities = unique(responses(:,1));
meanResponses = zeros(length(intensities), 1);                        % Plot average responses    
for iStim = 1:length(intensities)
   meanResponses(iStim) = mean(responses(responses(:,1) == intensities(iStim), 2));
end
plot(intensities, meanResponses, 'o', 'Color', 'r') 
xlim([0, max(responses(:,1))]); ylim([0, max(responses(:,2))+1])
title(['Stim strength: ', num2str(block.trialInfo(1).stimIntensity), 'V, ' , 'Duty cycle: ', num2str(min(responses(:,1))), '-', num2str(max(responses(:,1))), ', ITI = ', num2str(floor(sum(block.trialInfo(1).trialduration)))])
xlabel('Stimulus intensity (duty cycle)'); ylabel('Response (spikes)');

% Plot response latency vs. intensity
figure(3); clf; hold all
plot(latencies(:,1), latencies(:,2),'*')
intensities = unique(latencies(:,1));
meanLatencies = zeros(length(intensities), 1);
for iStim = 1:length(intensities)
   meanLatencies(iStim) = mean(latencies(latencies(:,1) == intensities(iStim), 2));
end
plot(intensities, meanLatencies, 'o', 'Color', 'r') 
title(['Stim strength: ', num2str(block.trialInfo(1).stimIntensity), 'V, ' , 'Duty cycle: ', num2str(min(responses(:,1))), '-', num2str(max(responses(:,1))), ', ITI = ', num2str(floor(sum(block.trialInfo(1).trialduration)))])
xlabel('Stimulus intensity (duty cycle)'); ylabel('Latency to first spike');
