function [yLims] = avgTracePlot(bl,b,a,D)
% PLOT AVERAGE VOLTAGE TRACES FOR EACH INTENSITY
hold on;
cm = colormap(jet(bl.nStims));
if bl.nStims == 20
    step = 2;
else
    step = 1;
end
for iStim = 1:step:bl.nStims
    meanTrace = mean(bl.filteredVoltage(:,bl.intensities==bl.stimVals(iStim) | bl.intensities == bl.stimVals(iStim+(step-1))),2);
    plot(bl.time, filtfilt(D,meanTrace), 'Color', cm(iStim, :), 'linewidth', 2); 
    yMins(iStim) = min(meanTrace);
    yMaxes(iStim) = max(meanTrace);
end
yLims = [min(yMins), max(yMaxes)];
plot([bl.stimOnTime,bl.stimOnTime],ylim, 'Color', 'k', 'linewidth', 2)
plot([bl.stimOnTime+bl.stimLength, bl.stimOnTime+bl.stimLength], ylim, 'Color', 'k', 'linewidth', 2)
% title({'Average voltage traces for each intensity',[bl.date, '  Trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))], ...
%     ['Stimulus voltage = ' num2str(bl.stimVoltage) 'V     Duration = ' num2str(1000*bl.stimLength) ' ms'], ...
%     ['Duty cycle range: ' num2str(bl.stimVals(1)) '% - ' ...
%     num2str(bl.stimVals(end)) '% (' num2str(bl.nStims) ' total)']});
ylabel('Average Vm (mV)','FontSize', 13); xlabel('Time (sec)','FontSize', 13);

end