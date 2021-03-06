function [h] = odor_raster_plots(bl, figInfo, histOverlay, nBins)
%============================================================================================================================
% PLOTS RASTERS FOR EACH ODOR
% bl = trial block structure
% figInfo = object with (optional) properties:
                % timeWindow = [startTime, stopTime] in seconds
                % figDims [X Y width height]
% histOverlay = boolean specifying whether to overlay a PSTH with 1 second bins
% nBins = the number of bins to use for the PSTH
%============================================================================================================================

% Convert spike locations to seconds and save in cell array
spikeTimes = cell(bl.nTrials, 1);
for iTrial = 1:bl.nTrials
    spikeTimes{iTrial} = (bl.spikes(iTrial).locs ./ bl.sampRate)';     
end

% Get ordered odor list
[~,valveList] = sort(unique([bl.trialInfo.valveID], 'stable'));
odors = unique(bl.odors,'stable');
odors = odors(valveList);

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
spDim1 = floor(sqrt(length(odors)));
spDim2 = ceil(sqrt(length(odors)));
spDim1=spDim2; % Temp fix for a sizing bug

% Separate spikes and plot rasters
for iOdor = 1:numel(odors)
    odorSpk = spikeTimes([bl.trialInfo.valveID]==iOdor);
%     odorSpk = {[odorSpk{:}]};
    subplot(spDim1, spDim2, iOdor);
    figInfo.title = [strrep(odors{iOdor},'_','\_')];
    plot_rasters(h, bl, figInfo, odorSpk, annotLines, annotColors);
    
    % Overlay histogram
    if histOverlay
        ax = axes('Position', get(gca, 'Position'));
        histogram([odorSpk{:}],linspace(figInfo.timeWindow(1), figInfo.timeWindow(2), nBins));
        ax.Color = 'None';
        ax.XColor = 'None';
        ax.YColor = 'None';
        ax.YLim(2) = ax.YLim(2) * 4;
    end
end

end