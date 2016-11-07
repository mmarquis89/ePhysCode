function spikeResponsePlot(bl)
% Scatter plot of total spikes during response period vs. stimulus intensity
hold all
set(gcf,'Color',[1 1 1]);
plot(bl.responses(:,1), bl.responses(:,2),'*');                         % Plot raw responses
meanResponses = zeros(bl.nStims, 1);                                      
semVals = zeros(bl.nStims,1);
for iStim = 1:bl.nStims
   currStim = bl.responses(bl.responses(:,1) == bl.stimVals(iStim), 2);
   meanResponses(iStim) = mean(currStim);
   semVals(iStim) = std(currStim)/sqrt(length(currStim));
end
plot(bl.stimVals, meanResponses, 'o', 'Color', 'r','linewidth', 2)                     % Plot average responses 
errorbar(bl.stimVals, meanResponses, semVals, 'linewidth', 2);                          % Add SEM error bars
xlim([0, max(bl.responses(:,1))]); ylim([0, max(bl.responses(:,2))+1])
title({['Number of spikes in first ' num2str(bl.responseLength) ' ms for each stim intensity'], ...
    [bl.date '   Trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))], ...
    ['Stimulus voltage = ' num2str(bl.stimVoltage) 'V     Duration = ' num2str(1000*bl.stimLength) ' ms'], ...
    ['Duty cycle range: ' num2str(bl.stimVals(1)) '% - ' ...
    num2str(bl.stimVals(end)) '% (' num2str(bl.nStims) ' total)']});
xlabel('Stimulus intensity (duty cycle)','FontSize', 13); ylabel('Response (spikes)','FontSize', 13);

end