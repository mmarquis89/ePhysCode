
%% COMPARE ACROSS CELLS OF A TYPE
cellType = 'PNs';
blockers = 0;
cellList = {'May04' 'May05'};%fieldnames(allBl.(cellType));
nCells = numel(cellList);
if blockers
    newList = cellList;
    hadBlockers = ones(nCells, 1);
    for iCell = 1:nCells
        if length(allBl.(cellType).(cellList{iCell})) < 2
            hadBlockers(iCell) = 0;
        end
    end
    cellList = cellList(hadBlockers==1);
    nCells = numel(cellList);
end

%% Average Voltages
figure(1);clf;
set(gcf,'Color',[1 1 1]);
[b,a] = butter(2,.004,'low');
D = designfilt('lowpassiir', ...
    'PassbandFrequency', 15, ...
    'StopbandFrequency', 100, ...
    'StopbandAttenuation', 100, ...
    'SampleRate', 10000);
%fvtool(D)
axes = [-65, -36, ;  -55, -22];
for iCell = [3]%1:nCells
    %subplot(2, ceil(nCells/2), iCell)
    currBl = allBl.(cellType).(cellList{iCell}).CurrPN(blockers+1);
    [yLims] = avgTracePlot(currBl, b, a, D);
    %ylim([yLims(1)-1, yLims(2)+1]);
 %   ylim(axes(iCell, :))
    xlim([4.9 6]);
    title(cellList{iCell}, 'FontSize', 13)
    set(gca, 'FontSize', 13, 'linewidth', 2)
    ylabel('Average Vm (mV)','FontSize', 13); xlabel('Time (sec)','FontSize', 13);
end
% if blockers == 0
%     suptitle(['Average Voltage Traces (' cellType ')'])
% else
%     suptitle(['Average Voltage Traces (' cellType ') - Inhibition Blocked'])
% end

%% PCA shapes...
figure(2);clf;
Trange = [4.3 8];                      % Set the range in seconds to analyze
plotThresh = 15;                       % Minimum percentage of variance explained by a PC to plot it
for iCell = 1:nCells
    subplot(2, ceil(nCells/2), iCell)
    currBl = allBl.(cellType).(cellList{iCell})(blockers+1);
    pcaPlot(currBl, Trange, plotThresh);
end
if blockers == 0
    suptitle(['PCA Coeffs (' cellType ')'])
else
    suptitle(['PCA Coeffs (' cellType ') - Inhibition Blocked'])
end

%% ...PCA projections
figure(3);clf;
for iCell = 1:nCells
    subplot(2, ceil(nCells/2), iCell)
    currBl = allBl.(cellType).(cellList{iCell})(blockers+1);
    pcaProjPlot(currBl);
end
if blockers == 0
    suptitle(['Projections onto PC 1 (' cellType ')'])
else
    suptitle(['Projections onto PC 1 (' cellType ') - Inhibition Blocked'])
end

%% Spike counts
figure(4);clf;
for iCell = 1:nCells
    subplot(2, ceil(nCells/2), iCell)
    currBl = allBl.(cellType).(cellList{iCell}).CurrPN(blockers+1);
    spikeResponsePlot(currBl);
    title(cellList{iCell},'FontSize', 13)
    set(gca, 'FontSize', 13, 'linewidth', 2)
end
% if blockers == 0
%     suptitle(['Responses vs. Stim Intensity (' cellType ')'])
% else
%     suptitle(['Responses vs. Stim Intensity (' cellType ') - Inhibition Blocked'])
% end

%% Rasters
currCell = 2;
for iCell = currCell
    currBl = allBl.(cellType).(cellList{iCell}).CurrPN(blockers+1);
    plotRasters(currBl);
    title(cellList{iCell})
    %ylim([0 113])
    xlim([4 6])
        title(cellList{iCell}, 'FontSize', 13)
    set(gca, 'FontSize', 13, 'linewidth', 2)
    xlabel('Time (s)')
    ylabel('Trial')
end

%% PSTH Estimates
figure(6);clf;
set(gcf,'Color',[1 1 1]);
yL = [110 140 110 90];
xL = [4.95 5.8; 4.45 5.4; 4.95 5.8; 4.95 5.8];
for iCell = 1:nCells
    subplot(2, ceil(nCells/2), iCell)
    currBl = allBl.(cellType).(cellList{iCell}).CurrPN(blockers+1); 
    hold on
    cm = colormap(jet(length(currBl.combSpikeLocs)));
    nBins = 1000;
    smoothWin = 5;
    spikeRates{iCell} = PSTHCalc(currBl, nBins, smoothWin);
    ylim([0 yL(iCell)])
    xlim(xL(iCell,:));
    yl = ylim;
    plot([currBl.stimOnTime, currBl.stimOnTime],[yl(1), yl(2)],'color', 'k','linewidth', 2)
    plot([currBl.stimOnTime+currBl.stimLength, currBl.stimOnTime+currBl.stimLength],[yl(1), yl(2)],'color', 'k','linewidth', 2)
    title(cellList{iCell},'FontSize', 13)
    set(gca, 'FontSize', 13, 'linewidth', 2)
end
% if blockers == 0
%     suptitle(['Responses vs. Stim Intensity (' cellType ')'])
% else
%     suptitle(['Responses vs. Stim Intensity (' cellType ') - Inhibition Blocked'])
% end
% figure;
% for iCell = 1:nCells
%    subplot(2, ceil(nCells/2), iCell)
%    imagesc(spikeRates{iCell})
% end
%% KDE Overlays
% figure(6);clf;
% for iCell = 1:nCells
%     subplot(2, ceil(nCells/2), iCell)
%     currBl = allBl.(cellType).(cellList{iCell})(blockers+1);
%     test = ssvOverlay(currBl);
% end
% if blockers == 0
%     suptitle(['Responses vs. Stim Intensity (' cellType ')'])
% else
%     suptitle(['Responses vs. Stim Intensity (' cellType ') - Inhibition Blocked'])
% end
