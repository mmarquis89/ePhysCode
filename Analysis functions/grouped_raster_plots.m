function [h] = grouped_raster_plots(bl, figInfo, histOverlay, nBins, rasterGroups, groupNames)
%============================================================================================================================
% PLOTS RASTERS SEPARATED BY ARBITRARY TRIAL GROUPS
% bl = trial block structure
% figInfo = object with (optional) properties:
                % timeWindow = [startTime, stopTime] in seconds
                % figDims [X Y width height]
% histOverlay = boolean specifying whether to overlay a PSTH
% nBins = the number of bins to use for the PSTH
% rasterGroups = a vector of length nTrials with the desired grouping of trials for the rasters (e.g. [1 2 2 1 3])
% groupNames = a cell array containing a string to use as the title of each raster group subplot
%============================================================================================================================

% Convert spike locations to seconds and save in cell array
spikeTimes = cell(bl.nTrials, 1);
for iTrial = 1:bl.nTrials
    spikeTimes{iTrial} = (bl.spikes(iTrial).locs ./ bl.sampRate)';     
end

% Set figInfo properties and annotation line info
figInfo.yLabel = 'Trial Number';
figInfo.xLabel = 'Time (sec)';
if ~isempty(bl.altStimDuration)
    annotLines = {bl.altStimStartTime, bl.stimOnTime, bl.stimOnTime + bl.stimLength, bl.altStimStartTime + bl.altStimLength};    
    annotColors = [1,0,1; 0,0,0; 0,0,0; 1,0,1];
else
    annotLines = {bl.stimOnTime, bl.stimOnTime + bl.stimLength};    
    annotColors = [0,0,0; 0,0,0];
end

% Set up figure
h = figure(7);clf; hold on
nGroups = length(unique(rasterGroups));
spDim1 = floor(sqrt(nGroups));
spDim2 = ceil(sqrt(nGroups));
spDim1=spDim2; % Temp fix for a sizing bug

% Separate spikes and plot rasters
for iGroup = 1:nGroups
    groupSpk = spikeTimes(rasterGroups==iGroup);
    subplot(spDim1, spDim2, iGroup);
    figInfo.title = [strrep(groupNames{iGroup},'_','\_')];
    plot_rasters(h, bl, figInfo, groupSpk, annotLines, annotColors);
    
    % Overlay histogram
    if histOverlay
        ax = axes('Position', get(gca, 'Position'));
        histogram([groupSpk{:}],linspace(figInfo.timeWindow(1), figInfo.timeWindow(2), nBins));
        ax.Color = 'None';
        ax.XColor = 'None';
        ax.YColor = 'None';
        ax.YLim(2) = ax.YLim(2) * 4;
    end
end

end%function