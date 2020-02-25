
%% Create plots of voltage data for all odor stims, sorted by cell type > experiment > odor ID

smWin = 1000;
medFilt = 0;
medFiltWin = 250; 
singleTrials = 1;
baselineOffset = 1;

nOdors = 4;
expPerFigure = 4;

sortedDataTable = sortrows(odorStimTable, {'cellType', 'expDate', 'expNum'});
tbOdors = dataTable(sortedDataTable);
tbOdors.add_filter('excludeMove', 1);
currDataOut = tbOdors.apply_filters();
uniqueExps = unique(currDataOut(:, [1 2]), 'stable', 'rows');

figs = {};
figs{1} = figure(1);clf
figs{1}.Color = [1 1 1];
expCount = 1; figCount = 1;
for iExp = 1:5%size(uniqueExps, 1)
    
   % Create a new figure if necessary
   if expCount > 4
       figCount = figCount + 1;
       expCount = 1;
       figs{figCount} = figure(figCount);clf
       figs{figCount}.Color = [1 1 1];
   end
    
   % Get data for just the current experiment
   tbOdors = tbOdors.add_filter('expDate', uniqueExps.expDate{iExp});
   tbOdors = tbOdors.add_filter('expNum', uniqueExps.expNum(iExp));
   tbOdors = tbOdors.clear_filter('odor');
   currExpData = tbOdors.apply_filters();
   
   % Plot data for each odor
   odorList = unique(currExpData.odor);
   for iOdor = 1:numel(odorList)-1
       if iOdor > 4; iOdor = 4; end % Temporary
       
       % Get data for just this odor
       tbOdors = tbOdors.add_filter('odor', odorList{iOdor});
       currOdorData = tbOdors.apply_filters();
       
       % Create axes
       ax = subaxis(expPerFigure, nOdors, iOdor, expCount, ...
                'mr', 0.05, 'ml', 0.05, 'mb', 0.05, 'mt', 0.05);
       
       % Get (downsampled) voltage data 
       voltage = smoothdata(cell2mat(currOdorData.voltage'), 1, 'gaussian', smWin, 'omitnan');
       voltage = voltage(1:5:end, :);
       
       % Median filter to reduce spike size if desired
       if medFilt
           voltage = movmedian(voltage, medFiltWin, 1, 'omitnan');
       end
       
       % Offset voltage to have the same baseline if desired
       if baselineOffset
           voltage = voltage - repmat(median(voltage, 1, 'omitnan'), size(voltage, 1), 1);
       end
       
       % Calculate plotting times
       sampTimes = (1:size(voltage, 1)) ./ (tbOdors.sourceData.Properties.UserData.sampRate / 5);
       odorOnsetTime = tbOdors.sourceData.Properties.UserData.analysisWinSec(1);
       odorOffsetTime = currData.stimDur(1);
       plotTimes = sampTimes - odorOnsetTime;
        
       % Plot single trial data if desired
       if singleTrials
           plot(plotTimes, voltage, 'linewidth', 0.5);
       end
       
       % Plot mean voltage
       hold on
       plot(plotTimes, mean(voltage, 2), 'linewidth', 1, 'color', 'k')
       
       % Shade stim epoch
       plot_stim_shading([0 odorOffsetTime])
       
       % Adjust plot
       title([currOdorData.cellType{1}, '  -  ', regexprep(odorList{iOdor}, '_', '\\_')])
       ylim([min(voltage(:), [], 'omitnan') - 2, max(voltage(:), [], 'omitnan') + 2])
       
   end%iOdor
   
   expCount = expCount + 1;
   
end

%% Same, but plotting spike rasters instead

smWin = 1000;

nOdors = 4;
expPerFigure = 4;

sortedDataTable = sortrows(odorStimTable, {'cellType', 'expDate', 'expNum'});
tbOdors = dataTable(sortedDataTable);
tbOdors.add_filter('excludeMove', 1);
currDataOut = tbOdors.apply_filters();
uniqueExps = unique(currDataOut(:, [1 2]), 'stable', 'rows');

figs = {};
figs{1} = figure(1);clf
figs{1}.Color = [1 1 1];
expCount = 1; figCount = 1;
for iExp = 1:size(uniqueExps, 1)
    
   % Create a new figure if necessary
   if expCount > 4
       figCount = figCount + 1;
       expCount = 1;
       figs{figCount} = figure(figCount);clf
       figs{figCount}.Color = [1 1 1];
   end
    
   % Get data for just the current experiment
   tbOdors = tbOdors.add_filter('expDate', uniqueExps.expDate{iExp});
   tbOdors = tbOdors.add_filter('expNum', uniqueExps.expNum(iExp));
   tbOdors = tbOdors.clear_filter('odor');
   currExpData = tbOdors.apply_filters();
   
   % Plot data for each odor
   odorList = unique(currExpData.odor);
   for iOdor = 1:numel(odorList)
       if iOdor > 4; iOdor = 4; end % Temporary
       
       % Get data for just this odor
       tbOdors = tbOdors.add_filter('odor', odorList{iOdor});
       currOdorData = tbOdors.apply_filters();
       
       % Create axes
       ax = subaxis(expPerFigure, nOdors, iOdor, expCount, ...
            'mr', 0.05, 'ml', 0.05, 'mb', 0.05, 'mt', 0.05);
       
       
       % Get spike times for current trial
       spikeTimes = [];
       nTrials = size(currOdorData, 1);
       trialLenSamples = size(currOdorData.voltage{1}, 1);
       sampRate = tbOdors.sourceData.Properties.UserData.sampRate;
       for iTrial = 1:nTrials
           spikeTimes = [spikeTimes; currOdorData.spikeSamples{iTrial} + ...
                (trialLenSamples * (iTrial - 1))];
       end
       
%        % Calculate plotting times
%        sampTimes = (1:size(voltage, 1)) ./ (tbOdors.sourceData.Properties.UserData.sampRate / 5);
       odorOnsetTime = tbOdors.sourceData.Properties.UserData.analysisWinSec(1);
       odorOffsetTime = odorOnsetTime + currData.stimDur(1);
%        plotTimes = sampTimes - odorOnsetTime;
       
       % Plot raster
       rasterplot(spikeTimes, nTrials, trialLenSamples, ax, sampRate);
%        
%        ax = gca;
%        ax
       
       % Shade stim epoch
       hold on
       plot_stim_shading([odorOnsetTime odorOffsetTime] * 1000)
       
       % Adjust plot
       title([currOdorData.cellType{1}, '  -  ', regexprep(odorList{iOdor}, '_', '\\_')])
%        ylim([min(voltage(:), [], 'omitnan') - 2, max(voltage(:), [], 'omitnan') + 2])
       
   end%iOdor
   
   expCount = expCount + 1;
   
end

%%






























