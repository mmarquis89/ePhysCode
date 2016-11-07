function pcaProjPlot(bl)
% PCA WITH AVERAGE VOLTAGE TRACES
% Trange: the range [start end] in seconds to analyze 
% plotThresh: percentage of variance explained required to plot a PC
hold on
plot(bl.stimVals,bl.PCAresults.score(:,1),'o')
title({'Projection onto PC1 for each stimulus intensity',[bl.date, '   Trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))], ...
    ['Stimulus voltage = ' num2str(bl.stimVoltage) 'V     Duration = ' num2str(1000*bl.stimLength) ' ms'], ...
    ['Duty cycle range: ' num2str(bl.stimVals(1)) '% - ' ...
    num2str(bl.stimVals(end)) '% (' num2str(bl.nStims) ' total)']});
ylabel('Scores'); xlabel('Stimulus Intensity (duty cycle)');
end