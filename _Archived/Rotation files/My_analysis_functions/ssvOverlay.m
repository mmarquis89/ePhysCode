function ssvData = ssvOverlay(bl)

hold on
cm = colormap(jet(length(bl.combSpikeLocs)));
for iStim = 1:length(bl.combSpikeLocs);
    disp(iStim)
    length(bl.combSpikeLocs)
    [ssvData.y,ssvData.t,ssvData.optw] = ssvkernel(bl.combSpikeLocs{iStim}./bl.sampRate, linspace(0, bl.nSamples./bl.sampRate, 1000));
    totSpikes = length(bl.combSpikeLocs{iStim})/bl.combIntsCount(iStim);
    totalTime = bl.nSamples/bl.sampRate;
    secPerYpoint = totalTime/length(ssvData.y);
    spikeDist = totSpikes*2*(ssvData.y./100);
    instSpikeRate = spikeDist.*(1/secPerYpoint);
    intLength = totalTime/length(ssvData.y);
    
    % Subtract baseline from seconds 2-4 and trim both ends to cut off artifacts
    ssvData.baseline = mean(ssvData.y(ceil(2/intLength):ceil(4/intLength)));
    ssvData.y2 = ssvData.y - ssvData.baseline;
    ssvData.y2 = ssvData.y2(ceil(1/intLength):end-ceil((2/intLength)));
        
    plot(linspace(1,totalTime-2, length(ssvData.y2)) , totSpikes*ssvData.y2, 'color', cm(iStim,:))    
    drawnow
end

title({['Smoothed, trimmed, and baseline-subracted firing rate across stim intensities'], ...
    [bl.date '   Trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))], ...
    ['Stimulus voltage = ' num2str(bl.stimVoltage) 'V     Duration = ' num2str(1000*bl.stimLength) ' ms'], ...
    ['Duty cycle range: ' num2str(bl.stimVals(1)) '% - ' ...
    num2str(bl.stimVals(end)) '% (' num2str(bl.nStims/2) ' total)']});
xlabel('Time (sec)'); ylabel('Firing (arbitrary units)');

end