


parentDir = 'D:\Dropbox (HMS)\Ephys data';
expDirs = dir(fullfile(parentDir, '2017*'));



s = load_experiment(expDate, expNumber, parentDir);

%% Save current allExpData table

save(fullfile(parentDir, 'allExpMetadata.mat'), 'allExpData', '-v7.3')


%% Identify unique values across all LH-DAN experiments
uniqueVals = [];
for iExp = 1:size(testTable, 1)
    
    currExpDate = testTable{iExp, 1};
    currExpNum = str2double(testTable{iExp, 2});
    
    disp([currExpDate, ' ', num2str(currExpNum)])
    ex = load_experiment(currExpDate, currExpNum, parentDir);
    
    % Convert empty empty values in [odor] and [altStimType] fields to character arrays
    for iTrial = 1:numel(ex.expInfo)
       if isempty(ex.expInfo(iTrial).odor)
          ex.expInfo(iTrial).odor = ''; 
       end
       if isempty(ex.expInfo(iTrial).altStimType)
           ex.expInfo(iTrial).altStimType = ''; 
       end
       
    end
    
    % Save unique values from certain fields
    uniqueVals(iExp).odor = unique({ex.expInfo.odor}); 
    uniqueVals(iExp).trialduration = unique(cellfun(@num2str, {ex.expInfo.trialduration}, ...
                'uniformoutput', 0));
    uniqueVals(iExp).altStimDuration = unique(cellfun(@num2str, {ex.expInfo.altStimDuration}, ... 
                'uniformoutput', 0));
    uniqueVals(iExp).altStimType = unique([ex.expInfo.altStimType]);
    uniqueVals(iExp).sampratein = unique([ex.expInfo.sampratein]);
    uniqueVals(iExp).samprateout = unique([ex.expInfo.samprateout]);
    uniqueVals(iExp).variableGain = unique([ex.expInfo.variableGain]);
    uniqueVals(iExp).ImGain = unique([ex.expInfo.ImGain]);
    uniqueVals(iExp).VmGain = unique([ex.expInfo.VmGain]);
    uniqueVals(iExp).ImOffset1 = unique([ex.expInfo.ImOffset1]);
    uniqueVals(iExp).filterFreq = unique([ex.expInfo.filterFreq]);
    uniqueVals(iExp).scaledOutMode = unique({ex.expInfo.scaledOutMode});
    
end


%% COMBINE METADATA INTO ONE GIANT STRUCTURE
% Static fields: AltStimType, sampratein, samprateout, ImGain, VmGain, ImOffset1, filterFreq, altStimDuration
% Single val per experiment: Rpipette

% clear allExpData
for iExp = 1:size(allExpData, 1)
    
    currExpDate = allExpData.expDate(iExp, :);
    currExpNum = allExpData.expNum(iExp);
    
    disp([currExpDate, ' ', num2str(currExpNum)])
    ex = load_experiment(currExpDate, currExpNum, parentDir);
    
    % Record data that does not change throughout the experiment
    s = [];
    s.sampRateIn = 20000;
    s.sampRateOut = 20000;
    s.Rpipette = ex.expInfo(1).Rpipette;
    s.expDate = ex.expInfo(1).date;
    s.expNum = ex.expInfo(1).expNum;
    
    % Get a list of all the odors that were presented
    expOdors = {ex.expInfo.odor};
    s.expOdors = sort(unique(expOdors(~cellfun(@isempty, expOdors)), 'stable'));
    
    
    % Copy important trial info over to new struct
    nTrials = numel(ex.expInfo);
    for iTrial = 1:nTrials
%         s.trialMetadata(iTrial).trialNum = ex.expInfo(iTrial).trial;
%         s.trialMetadata(iTrial).odor = ex.expInfo(iTrial).odor;
%         s.trialMetadata(iTrial).scaledOutMode = ex.expInfo(iTrial).scaledOutMode;
%         s.trialMetadata(iTrial).trialDuration = sum(ex.expInfo(iTrial).trialduration);
%         s.trialMetadata(iTrial).stepStartTime = ex.expInfo(iTrial).stepStartTime;
%         s.trialMetadata(iTrial).stepLength = ex.expInfo(iTrial).stepLength;
        allExpData.trialMetadata{iExp}(iTrial).stepStartTime = ex.expInfo(iTrial).stepStartTime;
        allExpData.trialMetadata{iExp}(iTrial).stepLength = ex.expInfo(iTrial).stepLength;
%         if numel(ex.expInfo(iTrial).trialduration) > 1
%             s.trialMetadata(iTrial).stimOnsetTime = ex.expInfo(iTrial).trialduration(1);
%             s.trialMetadata(iTrial).stimDur = ex.expInfo(iTrial).trialduration(2);
%         else
%             s.trialMetadata(iTrial).stimOnsetTime = [];
%             s.trialMetadata(iTrial).stimDur = [];
%         end
    end

% allExpData(iExp) = s;
end

%% Extract raw current and voltage data

for iExp = 1:size(allExpData, 1)
    
    currExpDate = allExpData{iExp, 1};
    currExpNum = allExpData{iExp, 2};
    
    disp([currExpDate, ' ', num2str(currExpNum)])
    ex = load_experiment(currExpDate, currExpNum, parentDir);
    
    maxSamples = max(cellfun(@numel, {ex.trialData.current}));
    nTrials = numel(ex.trialData);
    current = nan(maxSamples, nTrials);
    scaledOut = nan(maxSamples, nTrials);
    for iTrial = 1:nTrials
        currTrialSamples = numel(ex.trialData(iTrial).current);
        current(1:currTrialSamples, iTrial) = ex.trialData(iTrial).current;
        scaledOut(1:currTrialSamples, iTrial) = ex.trialData(iTrial).scaledOut;
    end
    
    fileName = [ex.expInfo(1).date, '_', num2str(ex.expInfo(1).expNum), '_raw.mat'];
    saveFile = fullfile(parentDir, 'rawData', fileName);
    save(saveFile, 'current', 'scaledOut', '-v7.3');
    
    % Save downsampled version for comparison
    currentDS = current(1:2:end, :);
    scaledOutDS = scaledOut(1:2:end, :);
    fileName = [ex.expInfo(1).date, '_', num2str(ex.expInfo(1).expNum), '_raw_ds.mat'];
    saveFile = fullfile(parentDir, 'rawData', fileName);
    save(saveFile, 'currentDS', 'scaledOutDS', '-v7.3');
    
end

%%  Extract spike times from current traces in each experiment and save with metadata

% Load an experiment
iExp = 55

% Select spike extraction parameters
threshold = 6;
invert = 0;

currExpDate = allExpData.expDate(iExp, :);
currExpNum = allExpData.expNum(iExp);
disp([currExpDate, ' exp ', num2str(currExpNum)])

% Load current data
load(fullfile(parentDir, 'rawData', [currExpDate, '_', num2str(currExpNum), '_raw.mat']), ...
        'current');
    
bl = struct();
bl.current = current;
bl.sampRate = allExpData.sampRateIn(1);
bl.nTrials = size(current, 2);

% Fill current with zeros for initial voltage clamp trials
vClampTrials = strcmp({allExpData.trialMetadata{iExp}.scaledOutMode}, 'I');
bl.current(:, vClampTrials) = 0;


% Create baseline-subtracted current
bl.normCurrent = [];
bl.trialDuration = max([allExpData.trialMetadata{iExp}.trialDuration]);
for iTrial = 1:bl.nTrials
   bl.normCurrent(:, iTrial) = bl.current(:, iTrial) - median(bl.current(:, iTrial), 'omitnan');
end

% Blank out the current test step as well
for iTrial = 1:bl.nTrials
   stepStartSample = allExpData.trialMetadata{iExp}(iTrial).stepStartTime * bl.sampRate;
   stepEndSample = stepStartSample + ...
            (allExpData.trialMetadata{iExp}(iTrial).stepLength * bl.sampRate);
   bl.normCurrent((stepStartSample-1):(stepEndSample+1), iTrial) = 0;
end

% Plot aligned current traces
figure(1);clf;
plot(bl.normCurrent(1:2:end, :))

% Get spikes
bl.spikes = get_spikes_simple(bl, threshold, invert);

% Plot all spikes overlaid
figure(2);clf;hold on
for iTrial = 1:bl.nTrials
    locs = bl.spikes(iTrial).locs;
    if ~isempty(locs)'
        for iSpk = 1:length(locs)
            if locs(iSpk) > .004*bl.sampRate && locs(iSpk) < bl.sampRate*(sum(bl.trialDuration)-.006)
                plot(bl.normCurrent(locs(iSpk)-(.004*bl.sampRate):locs(iSpk)+(.006*bl.sampRate), iTrial))
            end
        end
    end
end

% Save spike times to allExpData table
allExpData.spikes{iExp} = bl.spikes;

%% Convert spike locs to times
for iExp = 1:size(allExpData, 1)
   for iTrial = 1:numel(allExpData.spikes{iExp})
       allExpData.spikes{iExp}(iTrial).times = allExpData.spikes{iExp}(iTrial).locs / ...
                allExpData.sampRateIn(iExp);
   end
end




%% Process optic flow data

maxFlowFrames = 0;
for iExp = 1:size(allExpData, 1)
    
    currExpDate = allExpData.expDate(iExp, :);
    currExpNum = allExpData.expNum(iExp, :);
    disp([currExpDate, ' ', num2str(currExpNum)])
    
    currFlowFile = fullfile(parentDir, currExpDate, ['E', num2str(currExpNum), 'OpticFlowData.mat']);
    if exist(currFlowFile, 'file')
        load(currFlowFile)
        try
            maxFlowFrames = max([max(cellfun(@numel, allFlow)), maxFlowFrames]);
        catch
            maxFlowFrames = max([max(cellfun(@numel, flowData)), maxFlowFrames]);
        end
        clear allFlow flowData
    end
end
maxTrials = max(cellfun(@numel, {allExpData.trialMetadata}));
allFlowData = nan(maxFlowFrames, maxTrials, size(allExpData, 1)); % --> [frame, trial, exp]

for iExp = 1:size(allExpData, 1)
    
    currExpDate = allExpData.expDate(iExp, :);
    currExpNum = allExpData.expNum(iExp, :);
    disp([currExpDate, ' ', num2str(currExpNum)])
    
    
    currFlowFile = fullfile(parentDir, currExpDate, ['E', num2str(currExpNum), 'OpticFlowData.mat']);
    if exist(currFlowFile, 'file')
        load(currFlowFile)
        try
            allExpData.flowDataTest{iExp} = allFlow;
%             for iTrial = 1:numel(allFlow)
%                 allFlowData(1:numel(allFlow{iTrial}), iTrial, iExp) = allFlow{iTrial};
%             end
        catch
            allExpData.flowDataTest{iExp} = flowData;
%             for iTrial = 1:numel(flowData)
%                 allFlowData(1:numel(flowData{iTrial}), iTrial, iExp) = flowData{iTrial};
%             end
        end
        clear flowData allFlow
    end
    
end


%% Figure out which trials are missing flow data frames
FRAME_RATE = 30;
% 
% frameCounts = nan(size(allExpData.flowData{1}, 2), size(allExpData, 1));
% expectedFrames = frameCounts;
% for iExp = 1:size(allExpData, 1)
%     
%     nTrials = numel(allExpData.trialMetadata{iExp});
%     for iTrial = 1:nTrials
%         
%         expectedFrames(iTrial, iExp) = FRAME_RATE * ...
%                     allExpData.trialMetadata{iExp}(iTrial).trialDuration;
%                 
%         currTrialFlow = allExpData.flowData{iExp}(:, iTrial);
%         
%         frameCounts(iTrial, iExp) = sum(~isnan(currTrialFlow));
%     end    
% end

expectedFrames = []; frameCounts = [];
for iExp = 1:size(allExpData, 1)
    
    nTrials = numel(allExpData.trialMetadata{iExp});
    
    % Count actual frames
    if ~isempty(allExpData.flowDataTest{iExp})
        for iTrial = 1:nTrials            
            frameCounts(iTrial, iExp) = numel(allExpData.flowDataTest{iExp}{iTrial});
        end
    else
        frameCounts(iExp, :) = 0;
    end
    
    % Calculate expected frames
    for iTrial = 1:nTrials
        expectedFrames(iTrial, iExp) = FRAME_RATE * ...
            allExpData.trialMetadata{iExp}(iTrial).trialDuration;
    end
    
end

% Mark trials that have the correct number of flow data frames
goodTrials = [];
for iExp = 1:size(allExpData, 1)
%     allExpData.flowData{iExp} = struct();
%     allExpData.flowData{iExp}.flowData = allExpData.flowData{iExp};
%     allExpData.flowData{iExp}.expectedFrames = expectedFrames(:, iExp);
%     allExpData.flowData{iExp}.frameCounts = frameCounts(:, iExp);
% %     allExpData.flowData{iExp} = rmfield(allExpData.flowData{iExp}, 'goodVidTrials');
    allExpData.flowData{iExp}.badVidTrials = ~(expectedFrames(:, iExp) == frameCounts(:, iExp) & ...
            expectedFrames(:, iExp) > 0);
end


%% Identify recordings that are from confirmed or high-confidence putative LH-DANs

danList = {'PPM2', 'A', 'B', 'C', 'D', 'ANT'};
cellTypeList = DANtable.CellType;
cellTypeList(contains(cellTypeList, 'D?')) = {'D'};
cellTypeList(contains(cellTypeList, 'B?')) = {'B'};

LHDANexps = ismember(cellTypeList, danList);

LHDANexpData = allExpData(LHDANexps, :);

%% Get overview of odors presented to LH-DANs

% allOdors = [allExpData.odors{:}]';
allOdors = [LHDANexpData.odors{:}]';
odorList = unique(allOdors);
odorCounts = zeros(size(odorList));
for iOdor = 1:numel(odorList)
    odorCounts(iOdor) = sum(strcmp(allOdors, odorList{iOdor}));
    disp([odorList{iOdor}, ': ', num2str(odorCounts(iOdor))])
end

%% Break down by cell type
LHDANtypeList = cellTypeList(LHDANexps);
for iType = 1:numel(danList)
    disp('  ')
    disp([' --- ', danList{iType}, ' ---'])
    currTypeData = LHDANexpData(strcmp(danList{iType}, LHDANtypeList), :);
    allOdors = [currTypeData.odors{:}]';
    odorList = unique(allOdors);
    odorCounts = zeros(size(odorList));
    for iOdor = 1:numel(odorList)
        odorCounts(iOdor) = sum(strcmp(allOdors, odorList{iOdor}));
        disp([odorList{iOdor}, ': ', num2str(odorCounts(iOdor))])
    end
end

%% Identify movement frames

currExp = 55;
smWin = 5;
smReps = 3;

flowThresh = 0.025;

nTrials = numel(allExpData.flowData{currExp}.flowData);
maxTrials = numel(allExpData.flowData{currExp}.badVidTrials);
flowMat = allFlowData(:, :, currExp); % --> [frame, maxTrial]
flowMat(flowMat == 0) = nan;
figure(1);clf;plot(flowMat);


% Smooth, offset baseline of each trial and omit artificially high first frame
flowMat(1, :) = 0;
flowMat = repeat_smooth(flowMat, smReps, 'smWin', smWin);
flowMat = flowMat - repmat(median(flowMat,'omitnan'), size(flowMat, 1), 1);
flowMat(flowMat < 0) = 0;

% Plot processed flow overlay for all trials
figure(2);clf;plot(flowMat);
hold on; plot(1:size(flowMat, 1), ones(1, size(flowMat, 1)) .* flowThresh, 'k', 'linewidth', 2);

% Plot processed flow concatenated for all trials
plotTimes = (1:1:sum(~isnan(flowMat(:)))) ./ FRAME_RATE;
figure(3);clf;plot(plotTimes, flowMat(~isnan(flowMat)));
hold on; plot((1:sum(~isnan(flowMat(:))))./ FRAME_RATE, ones(1, sum(~isnan(flowMat(:)))) .* flowThresh, 'r', 'linewidth', 2);

% Plot sorted processed flow data
figure(4);clf;plot(sort(flowMat(:)))
hold on; plot(1:sum(~isnan(flowMat(:))), ones(1, sum(~isnan(flowMat(:)))) .* flowThresh, 'r', 'linewidth', 2);
yL = ylim(); ylim([0 yL(2) * 0.5])

% Identify move frames
allExpData.flowData{currExp}.moveThresh = flowThresh;
allExpData.flowData{currExp}.moveFrames = flowMat >= flowThresh;
allExpData.flowData{currExp}.processedFlowMat = flowMat;
figure(5);clf;imagesc(flowMat')
xlim([0, 900]); ylim([1, nTrials+1]);
figure(6);clf;imagesc(flowMat' >= flowThresh);
xlim([0, 900]); ylim([1, nTrials+1]);


%% Attempt to identify trials in which the light stimulus was presented

flowThresh = 3;

flowArr = allFlowData(:, :, LHDANexps); % --> [frame, trial, exp]
flowArr(flowArr == 0) = nan;
flowArr(1, :, :) = nan;
rsFlowArr = reshape(flowArr, size(flowArr, 1), []);

flowArr(flowArr > flowThresh) = flowThresh;
flowThreshArr = flowArr  == flowThresh;

% Create reshaped version for visualization
rsFlowArr(rsFlowArr > flowThresh) = flowThresh;
rsFlowThreshArr = rsFlowArr == flowThresh;
figure(8);clf;
imagesc(rsFlowArr')
figure(9);clf;
imagesc(rsFlowThreshArr')


% Use threshold to identify light onset/offset transitions
lightOnsetFrames = {};
lightOffsetFrames = {};
for iExp = 1:size(flowArr, 3)
    disp(iExp)
    for iTrial = 1:size(flowArr, 2)
        
        currTrialFlowStr = regexprep(num2str(flowThreshArr(:, iTrial, iExp)'), ' ', '');
        
        flowTransitions = regexp(currTrialFlowStr, '01');
        lightOffsetFrames{iExp, iTrial} = flowTransitions(2:2:end);
        lightOnsetFrames{iExp, iTrial} = flowTransitions(1:2:end);
        if mod(numel(flowTransitions), 2)
            lightOffsetFrames{iExp, iTrial}(end + 1) = numel(~isnan(flowArr(:, iTrial, iExp))); % Treat last frame of trial as offset
        end
        
        
    end
end

%% Make manual adjustments to LED stim data

currExp = 9;

    % 2/2 #1 - scope light trials (just ignoring them)
    % 3/8 #1 - scope light trial (just ignoring) extra stim trial? - 23 not real stim trial
    % 3/16 #1 - scope light trial - no flow data from those trials anyway
    % 3/23 #1 - extra trial at end - not sure what I was doing but 84 is not a real stim trial
    % 5/1 #2 - extra stim trial? - 8 not a real stim trial
    % 5/29 #2 - extra stim trial? - 22 not a real stim trial
    % 5/30 #2 - extra stim trial? - #32 IS a real stim trial
    % 6/2 #2 - extra stim trial? - #26 is not a real stim trial
    % 6/29 #1 - missing stim trials, extra stim trial? - NO missing stim trials (#19 is not a usable stim trial), #29 is NOT a real stim trial

figure(7);clf;
imagesc(flowArr(:, :, currExp)');

disp([expData.expDate(currExp, :), ' #', num2str(expData.expNum(currExp))])
disp(find(~cellfun(@isempty, lightOnsetFrames(currExp, :))))
disp(find(~cellfun(@isempty, lightOffsetFrames(currExp, :))))

% %%
% badTrial = 29;
% 
% lightOnsetFrames(currExp, badTrial) = lightOnsetFrames(currExp, badTrial+1);
% lightOffsetFrames(currExp, badTrial) = lightOnsetFrames(currExp, badTrial+1);

% %%

% Save data 
for i=1:24
   test.lightOnsetFrames{i} = lightOnsetFrames(i, :);
   test.lightOffsetFrames{i} = lightOffsetFrames(i, :);    
end

LHDAN_lightStimData = test(:, [1 2 12 13]);

save('D:\Dropbox (HMS)\Ephys data\LHDAN_lightStimData', 'LHDAN_lightStimData', '-v7.3')



















