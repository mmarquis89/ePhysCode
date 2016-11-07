function results = pcaPlot(bl, Trange, plotThresh)
% PCA WITH AVERAGE VOLTAGE TRACES
% Trange: the range [start end] in seconds to analyze 
% plotThresh: percentage of variance explained required to plot a PC

Trange = Trange*bl.sampRate;
avgV = NaN(bl.nStims,diff(Trange)+1);

% Save average voltage traces
for iStim = 1:bl.nStims
    avgV(iStim,:) = mean(bl.filteredVoltage(Trange(1):Trange(2),bl.intensities==bl.stimVals(iStim))');
end

% PCA
[results.coeff,results.score,results.latent,results.tsquared,results.explained,results.mu] = pca(avgV);

% Find out how many PCs it takes to explain plotThresh% of the variance
topPCs = results.explained(results.explained>plotThresh);

% Plot the top PCs
if numel(topPCs) > 5
    cm = colormap(jet(numel(topPCs)));
else
    cm = ['r' 'b' 'g' 'k' 'y']';  
end

hold all
for iStim = 1:numel(topPCs)
    trace = results.coeff(:, iStim);
    plot(1:length(trace), trace, 'Color', cm(iStim,:));
end
plot([bl.stimOnTime,bl.stimOnTime],ylim, 'Color', 'k')
plot([bl.stimOnTime+bl.stimLength, bl.stimOnTime+bl.stimLength], ylim, 'Color', 'k')
title({'Top PCs of average voltage traces by intensity',[bl.date, '   Trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))], ...
    ['% variance explained by top PCs: ' num2str(ceil(topPCs'))], ...
    ['Stimulus voltage = ' num2str(bl.stimVoltage) 'V     Duration = ' num2str(1000*bl.stimLength) ' ms'], ...
    ['Duty cycle range: ' num2str(bl.stimVals(1)) '% - ' ...
    num2str(bl.stimVals(end)) '% (' num2str(bl.nStims) ' total)']});
ylabel('Scores'); xlabel('Time (samples)');

end