
analysisDir = 'D:\Dropbox (HMS)\Ephys data\LHDAN_Summary_Analyses';

%% Create plots of voltage data for all odor stims, sorted by cell type > experiment > odor ID

smWin = 1000;
medFilt = 0;
medFiltWin = 300; 
singleTrials = 0;
baselineOffset = 0;

maxOdors = 4;
expPerFigure = 4;

figSize = [1025 780];

try 
    
sortedDataTable = sortrows(odorStimTable, {'cellType', 'expDate', 'expNum'});
tbOdors = dataTable(sortedDataTable);
tbOdors.add_filter('excludeMove', 1);
currDataOut = tbOdors.apply_filters();
uniqueExps = unique(currDataOut(:, [1 2 8]), 'stable', 'rows');

set(0, 'defaultFigurePosition', [680 50 560 420])
figs = {};
figs{1} = figure(1);clf
figs{1}.Color = [1 1 1];
if ~isempty(figSize)
   figs{1}.Position(3:4) = figSize; 
end
expCount = 1; figCount = 1;
for iExp = 1:size(uniqueExps, 1)
    
   % Create a new figure if necessary
   if expCount > expPerFigure
       figCount = figCount + 1;
       expCount = 1;
       figs{figCount} = figure(figCount);clf
       figs{figCount}.Color = [1 1 1];
       if ~isempty(figSize)
           figs{figCount}.Position(3:4) = figSize;
       end
   end
    
   % Get data for just the current experiment
   tbOdors = tbOdors.add_filter('expDate', uniqueExps.expDate{iExp});
   tbOdors = tbOdors.add_filter('expNum', uniqueExps.expNum(iExp));
   tbOdors = tbOdors.clear_filter('odor');
   currExpData = tbOdors.apply_filters();
   
   % Plot data for each odor
   odorList = unique(currExpData.odor);
   for iOdor = 1:numel(odorList)
       if iOdor > maxOdors; continue; end % Temporary
       
       % Get data for just this odor
       tbOdors = tbOdors.add_filter('odor', odorList{iOdor});
       currOdorData = tbOdors.apply_filters();
       
       % Create axes
       ax = subaxis(expPerFigure, maxOdors, iOdor, expCount, ...
                'mr', 0.04, 'ml', 0.09, 'mb', 0.08, 'mt', 0.05, 'sh', 0.04);
       
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
        
       % Plot single trial data if desired, otherwise shade +/- SEM
       if singleTrials
           plot(plotTimes, voltage, 'linewidth', 0.5);
       else
           % Shade +/- SEM downsampled even further)
           dsVoltage = voltage(1:100:end, :);
           dsPlotTimes = plotTimes(1:100:end);
           sd = std(dsVoltage, [], 2, 'omitnan');
           avg = mean(dsVoltage, 2, 'omitnan');
           sd = sd(~isnan(dsPlotTimes));
           avg = avg(~isnan(dsPlotTimes));
           sem = sd ./ (size(dsVoltage, 2)^0.5);
           jbfill(dsPlotTimes(~isnan(dsPlotTimes)), [avg + sem]', [avg - sem]', 'k', 'k', 1, 0.2);
       end
       
       % Plot mean voltage
       hold on
       plot(plotTimes, mean(voltage, 2), 'linewidth', 1.5, 'color', 'k')
       
       % Shade stim epoch
       plot_stim_shading([0 odorOffsetTime])
       
       % Adjust plot axes
       title(regexprep(odorList{iOdor}, '_', '\\_'), 'fontsize', 10)
       if singleTrials
           ylim([min(voltage(:), [], 'omitnan') - 2, max(voltage(:), [], 'omitnan') + 2])
       else
           ylim([min(mean(voltage, 2, 'omitnan'), [], 'omitnan') - 2, ...
                    max(mean(voltage, 2, 'omitnan'), [], 'omitnan') + 2]);
       end
       xlim([plotTimes(1), plotTimes(end)])
       ax = gca;
       if expCount == expPerFigure
           xlabel('Time (sec)')
           xL = xlim();
       else
           xlabel('')
           ax.XTickLabel = '';
       end
       if iOdor == 1
          if baselineOffset
              unitStr = 'delta Vm (mV)';
          else
              unitStr = 'Vm (mV)';
          end
          ylabel({[datestr(datenum(uniqueExps.expDate{iExp}, 'yyyy-mmm-dd'), 'mm�dd'), ...
              ' #', num2str(uniqueExps.expNum(iExp)), ...
              ], ['Type ', uniqueExps.cellType{iExp}], unitStr}, 'fontsize', 12)
       else
           ax.YTickLabel = [];
       end           
       
       
   end%iOdor
   
   expCount = expCount + 1;
   
end

catch foldME; rethrow(foldME); end

%% Same, but plotting spike rasters instead

maxOdors = 4;
expPerFigure = 5;

figSize = [1025 780];

try
    
sortedDataTable = sortrows(odorStimTable, {'cellType', 'expDate', 'expNum'});
tbOdors = dataTable(sortedDataTable);
tbOdors.add_filter('excludeMove', 1);
currDataOut = tbOdors.apply_filters();
uniqueExps = unique(currDataOut(:, [1 2 8]), 'stable', 'rows');

set(0, 'defaultFigurePosition', [680 50 560 420])
figs = {};
figs{1} = figure(1);clf
figs{1}.Color = [1 1 1];
if ~isempty(figSize)
   figs{1}.Position(3:4) = figSize; 
end
expCount = 1; figCount = 1;
for iExp = 1:size(uniqueExps, 1)
    
   % Create a new figure if necessary
   if expCount > expPerFigure
       figCount = figCount + 1;
       expCount = 1;
       figs{figCount} = figure(figCount);clf
       figs{figCount}.Color = [1 1 1];
       if ~isempty(figSize)
           figs{figCount}.Position(3:4) = figSize;
       end
   end
    
   % Get data for just the current experiment
   tbOdors = tbOdors.add_filter('expDate', uniqueExps.expDate{iExp});
   tbOdors = tbOdors.add_filter('expNum', uniqueExps.expNum(iExp));
   tbOdors = tbOdors.clear_filter('odor');
   currExpData = tbOdors.apply_filters();
   
   % Plot data for each odor
   odorList = unique(currExpData.odor);
   for iOdor = 1:numel(odorList)
       if iOdor > maxOdors; continue; end % Temporary
       
       % Get data for just this odor
       tbOdors = tbOdors.add_filter('odor', odorList{iOdor});
       currOdorData = tbOdors.apply_filters();
       
       % Create axes
       ax = subaxis(expPerFigure, maxOdors, iOdor, expCount, ...
            'mr', 0.04, 'ml', 0.06, 'mb', 0.08, 'mt', 0.05, 'sh', 0.04);
       
       % Get spike times for current trials
       spikeTimes = [];
       nTrials = size(currOdorData, 1);
       trialLenSamples = size(currOdorData.voltage{1}, 1);
       sampRate = tbOdors.sourceData.Properties.UserData.sampRate;
       for iTrial = 1:nTrials
           spikeTimes = [spikeTimes; currOdorData.spikeSamples{iTrial} + ...
                (trialLenSamples * (iTrial - 1))];
       end
       
       % Calculate plotting times
       odorOnsetTime = tbOdors.sourceData.Properties.UserData.analysisWinSec(1);
       odorOffsetTime = odorOnsetTime + currData.stimDur(1);
       
       % Plot raster
       rasterplot(spikeTimes, nTrials, trialLenSamples, 'plotAxes', ax, 'sampRate', sampRate);
       
       % Shade stim epoch
       hold on
       plot_stim_shading([odorOnsetTime odorOffsetTime])
       
       % Adjust plot axes
       title(regexprep(odorList{iOdor}, '_', '\\_'), 'fontsize', 10)
       ax = gca;
       if expCount == expPerFigure
           xlabel('Time (sec)')
           xL = xlim();
           ax.XTickLabel = {cellfun(@str2double, ax.XTickLabel) - odorOnsetTime};
       else
           xlabel('')
           ax.XTickLabel = '';
       end
       if iOdor == 1
          ylabel({[datestr(datenum(uniqueExps.expDate{iExp}, 'yyyy-mmm-dd'), 'mm�dd'), ...
              ' #', num2str(uniqueExps.expNum(iExp)), ...
              ], ['Type ', uniqueExps.cellType{iExp}]}, 'fontsize', 12)
       end


   end%iOdor
   
   expCount = expCount + 1;
   
end

catch foldME; rethrow(foldME); end

%% Same idea, but now plotting both the voltage traces and the rasters for each experiment 

saveFigs = 1;
baseSaveFileName = 'LH-DAN_odor_response_meanTraces+rasters';

smWin = 1000;
medFilt = 0;
medFiltWin = 300; 
singleTrials = 0;
baselineOffset = 0;

maxOdors = 4;
expPerFigure = 4;

figSize = [1255 850];

try
    
sortedDataTable = sortrows(odorStimTable, {'cellType', 'expDate', 'expNum'});
tbOdors = dataTable(sortedDataTable);
tbOdors.add_filter('excludeMove', 1);
currDataOut = tbOdors.apply_filters();
uniqueExps = unique(currDataOut(:, [1 2 8]), 'stable', 'rows');

set(0, 'defaultFigurePosition', [680 50 560 420])
figs = {};
figs{1} = figure(1);clf
figs{1}.Color = [1 1 1];
if ~isempty(figSize)
   figs{1}.Position(3:4) = figSize; 
end
expCount = 1; figCount = 1;
for iExp = 1:size(uniqueExps, 1)
    
   % Create a new figure if necessary
   if expCount > expPerFigure
       
       % Save old figure
       if saveFigs
           saveName = [baseSaveFileName, '_part_', num2str(figCount)];
           save_figure(figs{figCount}, analysisDir, saveName);
       end
       
       % Create new figure
       figCount = figCount + 1;
       expCount = 1;
       figs{figCount} = figure(figCount);clf
       figs{figCount}.Color = [1 1 1];
       if ~isempty(figSize)
           figs{figCount}.Position(3:4) = figSize;
       end
   end
    
   % Get data for just the current experiment
   tbOdors = tbOdors.add_filter('expDate', uniqueExps.expDate{iExp});
   tbOdors = tbOdors.add_filter('expNum', uniqueExps.expNum(iExp));
   tbOdors = tbOdors.clear_filter('odor');
   currExpData = tbOdors.apply_filters();
   
   % Plot data for each odor
   odorList = unique(currExpData.odor);
   for iOdor = 1:numel(odorList)
       if iOdor > maxOdors; continue; end % Temporary
       
       % Get data for just this odor
       tbOdors = tbOdors.add_filter('odor', odorList{iOdor});
       currOdorData = tbOdors.apply_filters();
       
       % Create axes for voltage plot
       axCountY = (5*expPerFigure) - 1;
       currAxOffsetY = 5 * (expCount - 1);
       ax = subaxis(axCountY, maxOdors, iOdor, currAxOffsetY + 1, 1, 2, ...
                'mr', 0.04, 'ml', 0.1, 'mb', 0.08, 'mt', 0.05, 'sh', 0.03, 'sv', 0);
       
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
        
       % Plot single trial data if desired, otherwise shade +/- SEM
       if singleTrials
           plot(plotTimes, voltage, 'linewidth', 0.5);
       else
           % Shade +/- SEM downsampled even further)
           dsVoltage = voltage(1:100:end, :);
           dsPlotTimes = plotTimes(1:100:end);
           sd = std(dsVoltage, [], 2, 'omitnan');
           avg = mean(dsVoltage, 2, 'omitnan');
           sd = sd(~isnan(dsPlotTimes));
           avg = avg(~isnan(dsPlotTimes));
           sem = sd ./ (size(dsVoltage, 2)^0.5);
           jbfill(dsPlotTimes(~isnan(dsPlotTimes)), [avg + sem]', [avg - sem]', 'k', 'k', 1, 0.2);
       end
       
       % Plot mean voltage
       hold on
       plot(plotTimes, mean(voltage, 2), 'linewidth', 1.5, 'color', 'k')
       
       % Shade stim epoch
       plot_stim_shading([0 odorOffsetTime])
       
       % Adjust plot axes
       title(regexprep(odorList{iOdor}, '_', '\\_'), 'fontsize', 11)
       if singleTrials
           ylim([min(voltage(:), [], 'omitnan') - 2, max(voltage(:), [], 'omitnan') + 2])
       else
           ylim([min(mean(voltage, 2, 'omitnan'), [], 'omitnan') - 2, ...
                    max(mean(voltage, 2, 'omitnan'), [], 'omitnan') + 2]);
       end
       xlim([plotTimes(1), plotTimes(end)])
       ax = gca;
       if expCount == expPerFigure
           xlabel('Time (sec)')
           xL = xlim();
       else
           xlabel('')
           ax.XTickLabel = '';
       end
       if iOdor == 1
           yL = ylim;
          if baselineOffset
              unitStr = '\Delta Vm (mV)';
              shiftDist = 0.4 * diff(yL);
          else
              unitStr = 'Vm (mV)';
              shiftDist = 0.3 * diff(yL);
          end
          t = ylabel({[datestr(datenum(uniqueExps.expDate{iExp}, 'yyyy-mmm-dd'), 'mmm�dd'), ...
              ' #', num2str(uniqueExps.expNum(iExp)), ...
              ' - Type ', uniqueExps.cellType{iExp}], '', unitStr}, 'fontsize', 11, ...
              'horizontalalignment', 'right');
          t.Position(2) = t.Position(2) + shiftDist;
       else
           ax.YTickLabel = [];
       end           
       
       % Create axes for spike rasters
       ax = subaxis(axCountY, maxOdors, iOdor, currAxOffsetY + 3, 1, 2, ...
            'mr', 0.04, 'ml', 0.1, 'mb', 0.08, 'mt', 0.05, 'sh', 0.03, 'sv', 0);
       
       % Get spike times for current trials
       spikeTimes = [];
       nTrials = size(currOdorData, 1);
       trialLenSamples = size(currOdorData.voltage{1}, 1);
       sampRate = tbOdors.sourceData.Properties.UserData.sampRate;
       for iTrial = 1:nTrials
           spikeTimes = [spikeTimes; currOdorData.spikeSamples{iTrial} + ...
                (trialLenSamples * (iTrial - 1))];
       end
       
       % Calculate plotting times
       odorOnsetTime = tbOdors.sourceData.Properties.UserData.analysisWinSec(1);
       odorOffsetTime = odorOnsetTime + currData.stimDur(1);
       
       % Plot raster
       rasterplot(spikeTimes, nTrials, trialLenSamples, 'plotAxes', ax, 'sampRate', sampRate);
       
       % Shade stim epoch
       hold on
       plot_stim_shading([odorOnsetTime odorOffsetTime])
       
       % Adjust plot axes
       ax = gca;
       ax.XLim(1) = 0;
       if expCount == expPerFigure
           xlabel('Time (sec)')
           xL = xlim();
           ax.XTickLabel = {cellfun(@str2double, ax.XTickLabel) - odorOnsetTime};
       else
           xlabel('')
           ax.XTickLabel = '';
       end
       if iOdor == 1
           ylabel('Trial')
       else
           ylabel('')
       end

   end%iOdor
   
   expCount = expCount + 1;
   
end%iExp

% Save final figure
if saveFigs
    saveName = [baseSaveFileName, '_part_', num2str(figCount)];
    save_figure(figs{figCount}, analysisDir, saveName);
end

catch foldME; rethrow(foldME); end


    



























