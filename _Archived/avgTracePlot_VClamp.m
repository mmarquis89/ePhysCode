function [meanTraces] = avgTracePlot(bl,type, startTime, endTime, figDims, yLims)
% PLOT ALIGNED AVERAGE TRACES FOR EACH INTENSITY
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
vHoldsList = sort(unique(bl.vHolds));

for iV = 1:length(vHoldsList)
    cm = [0,0,1;1,0,0;0,1,0];
    if strcmp(type, 'current')
        currentVhold = bl.current(:,bl.vHolds == vHoldsList(iV));
        for iTrial = 1:size(currentVhold,2)
            filteredCurrent(:,iTrial) = medfilt1(currentVhold(:,iTrial), 100);
%             plot(bl.time(startTime*bl.sampRate:endTime*bl.sampRate), filteredCurrent(startTime*bl.sampRate:endTime*bl.sampRate,iTrial))
        end
        meanTrace = mean(filteredCurrent,2);
        meanTraceNorm = meanTrace - (median(meanTrace((bl.stimOnTime - 3) * bl.sampRate:bl.stimOnTime * bl.sampRate)));
        meanTraces(:,iV) = meanTrace;
        yLab = 'Average Current (pA)';
    elseif strcmp(type, 'voltage')
        meanTraceNorm = mean(bl.voltage, 2);
        yLab = 'Average Vm (mV)';
    end
    
    plot(bl.time(startTime*bl.sampRate:endTime*bl.sampRate), meanTraceNorm(startTime*bl.sampRate:endTime*bl.sampRate), 'linewidth', 2, 'color', cm(iV, :));
    if ~isempty(yLims)
        ylim(yLims);
    end
end

% Plot difference between mean traces
meanTraceDiff = meanTraces(:,1)-meanTraces(:,2);
diffRatio = meanTraceDiff ./ meanTraces(:,1);
plot(bl.time(startTime*bl.sampRate:endTime*bl.sampRate), diffRatio(startTime*bl.sampRate:endTime*bl.sampRate), 'linewidth', 2, 'color', cm(length(vHoldsList)+1, :));

if startTime <= bl.pinchOpen
    plot([bl.pinchOpen,bl.pinchOpen],ylim, 'Color', 'r', 'linewidth', 2)
end
plot([bl.stimOnTime,bl.stimOnTime],ylim, 'Color', 'g', 'linewidth', 2)
plot([(bl.stimOnTime + bl.stimLength),(bl.stimOnTime + bl.stimLength)],ylim, 'Color', 'r', 'linewidth', 2)
title({[bl.date ' - ' bl.trialInfo(1).odor], ['Average ' type ' traces for trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))], ['Vhold = ' num2str(sort(unique(bl.vHolds')))]});
ylabel(yLab,'FontSize', 13); xlabel('Time (sec)','FontSize', 13);




end