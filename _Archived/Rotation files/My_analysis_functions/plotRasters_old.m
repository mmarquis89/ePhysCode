function plotRasters(bl)

spikeTimes = cell(bl.nTrials, 1);
for iTrial = 1:bl.nTrials
    spikeTimes{iTrial} = (bl.spikes(iTrial).locs ./ bl.sampRate)';     % Convert spike locations to seconds and save in cell array
end

% Plot all trials in chronological order
% figure(5); clf; hold on; set(gcf,'Position',[25 350 1500 550],'Color',[1 1 1]);
% plotSpikeRaster(spikeTimes, 'PlotType', 'Vertline', 'AutoLabel', true); hold on;
% plot([bl.stimOnTime,bl.stimOnTime],ylim, 'Color', 'r')
% plot([bl.stimOnTime+bl.stimLength, bl.stimOnTime+bl.stimLength], ylim, 'Color', 'r')
% title({'Raster plot of all spikes across trials',['Trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))], ...
%     ['Stimulus voltage = ' num2str(bl.stimVoltage) 'V     Duration = ' num2str(1000*bl.stimLength) ' ms'], ...
%     ['Duty cycle range: ' num2str(bl.stimVals(1)) '% - ' ...
%     num2str(bl.stimVals(end)) '% (' num2str(bl.nStims) ' total)']});

% Plot all trials ordered by stim intensity
stimSort = sortrows([bl.intensities; 1:length(bl.intensities)]');
sortedSpikes = spikeTimes(stimSort(:,2));
figure(6); clf; hold on; set(gcf,'Position',[25 350 1500 550],'Color',[1 1 1]);
plotSpikeRaster(sortedSpikes, 'PlotType', 'Vertline', 'AutoLabel', true); hold on;
plot([bl.stimOnTime,bl.stimOnTime],ylim, 'Color', 'r', 'linewidth',2)
plot([bl.stimOnTime+bl.stimLength, bl.stimOnTime+bl.stimLength], ylim, 'Color', 'r','linewidth',2)
% title({'Raster plot of all spikes across trials (sorted by intensity)',['Trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))], ...
%     ['Stimulus voltage = ' num2str(bl.stimVoltage) 'V     Duration = ' num2str(1000*bl.stimLength) ' ms'], ...
%     ['Duty cycle range: ' num2str(bl.stimVals(1)) '% - ' ...
%     num2str(bl.stimVals(end)) '% (' num2str(bl.nStims) ' total)']});

end