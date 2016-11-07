function spikeRates = PSTHCalc(bl, nBins, smoothWin)
% Calculate PSTH spike rates using the specified number of bins
if bl.nStims == 20
    condense = 1;
elseif bl.nStims == 10
    condense = 0;
end
[bl.combSpikeLocs, bl.combIntsCount] = groupSpikes(bl, condense);  % Second argument is a boolean determining whether to condense stims
hold on
cm = colormap(jet(length(bl.combSpikeLocs)));
binWidth = bl.nSamples./nBins;
binTime = binWidth./bl.sampRate;
for iStim = 1:length(bl.combSpikeLocs)    
    [n,x] = hist(bl.combSpikeLocs{iStim},nBins);
    n = n./sum(bl.intensities == bl.stimVals(iStim));
    spikeRates(iStim,:) = n./binTime;
    currSpikes = spikeRates(iStim,:);
    smoothing = smooth(currSpikes(floor(nBins*((bl.stimOnTime*bl.sampRate)./bl.nSamples))+1:end),smoothWin);
    plot(x./bl.sampRate,[currSpikes(1:floor(nBins*((bl.stimOnTime*bl.sampRate)./bl.nSamples))),smoothing'],'color',cm(iStim,:),'linewidth', 2)
end
yl = ylim;
plot([bl.stimOnTime, bl.stimOnTime],[yl(1), yl(2)],'color', 'k','linewidth', 2)
plot([bl.stimOnTime+bl.stimLength, bl.stimOnTime+bl.stimLength],[yl(1), yl(2)],'color', 'k','linewidth', 2)
title({'PSTH spike rates',[bl.date, '  Trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))], ...
    ['Stimulus voltage = ' num2str(bl.stimVoltage) 'V     Duration = ' num2str(1000*bl.stimLength) ' ms'], ...
    ['Duty cycle range: ' num2str(bl.stimVals(1)) '% - ' ...
    num2str(bl.stimVals(end)) '% (' num2str(bl.nStims) ' total)']});
xlabel('Time (sec)','FontSize', 13); ylabel('Smoothed PSTH (spikes/sec)','FontSize', 13)

end