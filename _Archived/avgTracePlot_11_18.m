function [meanTraces] = avgTracePlot(bl,type, startTime, endTime, figDims, yLims)
% PLOT ALIGNED AVERAGE TRACES
% Currently also overlays median-filtered traces from individual trials
% type = 'current' or 'voltage'
% startTime = time in seconds from beginning of trial to start plotting
% endTime = same as above, but for end of plotting
% figDims (optional, [] for default) = position and size of figure window: [X, Y, width, height]
% yLims (optional, [] for default) = [yMin, yMax]

figure(1); clf; hold on;
if ~isempty(figDims)
    set(gcf,'Position',figDims,'Color',[1 1 1]);
end
set(gca,'LooseInset',get(gca,'TightInset'))

if strcmp(type, 'current')
    meanTrace = mean(filteredCurrent,2);
    meanTraceNorm = meanTrace - (median(meanTrace((bl.stimOnTime - 3) * bl.sampRate:bl.stimOnTime * bl.sampRate)));
    yLab = 'Average Current (pA)';
elseif strcmp(type, 'voltage')
    meanTraceNorm = mean(bl.voltage, 2);
    yLab = 'Average Vm (mV)';
end
meanTraces = meanTraceNorm;

plot(bl.time(startTime*bl.sampRate:endTime*bl.sampRate), meanTraceNorm(startTime*bl.sampRate:endTime*bl.sampRate), 'linewidth', 2, 'color', 'b');
if ~isempty(yLims)
    ylim(yLims);
end


if startTime <= bl.pinchOpen
    plot([bl.pinchOpen,bl.pinchOpen],ylim, 'Color', 'r', 'linewidth', 2)
end
plot([bl.stimOnTime,bl.stimOnTime],ylim, 'Color', 'g', 'linewidth', 2)
plot([(bl.stimOnTime + bl.stimLength),(bl.stimOnTime + bl.stimLength)],ylim, 'Color', 'r', 'linewidth', 2)

title({[bl.date ' - ' bl.trialInfo(1).odor], ['Average ' type ' traces for trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]});
ylabel(yLab,'FontSize', 13); xlabel('Time (sec)','FontSize', 13);




end