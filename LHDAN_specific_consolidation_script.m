%%
parentDir = 'D:\Dropbox (HMS)\Ephys data';
expDirs = dir(fullfile(parentDir, '2017*'));

%% Identify recordings that are from confirmed or high-confidence putative LH-DANs

load(fullfile(parentDir, 'DAN_recording_table.mat'), 'DANtable');


danList = {'PPM2', 'A', 'B', 'C', 'D', 'ANT'};
cellTypeList = DANtable.CellType;
cellTypeList(contains(cellTypeList, 'D?')) = {'D'};
cellTypeList(contains(cellTypeList, 'B?')) = {'B'};
LHDANexps = ismember(cellTypeList, danList);

% Pull out data from LH-DAN experiments only
load(fullfile(parentDir, 'allExpMetadata.mat'), 'allExpData');
load(fullfile(parentDir, 'allFlowData.mat'), 'allFlowData');
expData = allExpData(LHDANexps, :);
flowData = allFlowData(:, :, LHDANexps);
LHDANtable = DANtable(LHDANexps, :);

% Load pre-separated LED stim timing data
load(fullfile(parentDir, 'LHDAN_lightStimData.mat'), 'LHDAN_lightStimData');

% Load scaled out voltage data and add to expData table
for iExp = 1:size(expData, 1)
    currExpDate = expData{iExp, 1};
    currExpNum = expData{iExp, 2};
    disp([currExpDate, ' ', num2str(currExpNum)])
    fileName = [currExpDate, '_', num2str(currExpNum), '_raw.mat'];
    load(fullfile(parentDir, 'rawData', fileName), 'scaledOut');
    expData.scaledOut{iExp} = scaledOut;
end

% Add field for cell type
expData.cellType = cellTypeList(LHDANexps);

% Store generally useful variables
sampRate = expData.sampRateIn(1);
FRAME_RATE = 30;

sz = size(expData.flowData{1}.processedFlowMat);
maxFrames = sz(1);
maxTrials = sz(2);
maxSamples = max(cellfun(@(x) size(x, 1), expData.scaledOut(:)));

sampTimes = (1:1:maxSamples) ./ sampRate;
frameTimes = (1:1:maxFrames) ./ FRAME_RATE;

sampleAlignedFrames = [];
for iFrame = 1:maxFrames
   [~, sampleAlignedFrames(iFrame)] = min(abs(sampTimes - frameTimes(iFrame))); 
end
frameAlignedSamples = [];
for iSamp = 1:maxSamples
   [~, frameAlignedSamples(iSamp)] = min(abs(frameTimes - sampTimes(iSamp))); 
end


%% Get overview of odors presented to LH-DANs

disp('  ')
disp(' --- All LH-DANs ---')
allOdors = [expData.odors{:}]';
odorList = unique(allOdors);
odorCounts = zeros(size(odorList));
for iOdor = 1:numel(odorList)
    odorCounts(iOdor) = sum(strcmp(allOdors, odorList{iOdor}));
    disp([odorList{iOdor}, ': ', num2str(odorCounts(iOdor))])
end

% Break down by cell type
LHDANtypeList = cellTypeList(LHDANexps);
for iType = 1:numel(danList)
    disp('  ')
    disp([' --- ', danList{iType}, ' ---'])
    currTypeData = expData(strcmp(danList{iType}, LHDANtypeList), :);
    allOdors = [currTypeData.odors{:}]';
    odorList = unique(allOdors);
    odorCounts = zeros(size(odorList));
    for iOdor = 1:numel(odorList)
        odorCounts(iOdor) = sum(strcmp(allOdors, odorList{iOdor}));
        disp([odorList{iOdor}, ': ', num2str(odorCounts(iOdor))])
    end
end


%% Create table of data for each odor stim

analysisWinSec = [4 5];

try 
    
% Create table and add custom metadata
odorStimTable = table();
odorStimTable.Properties.UserData.analysisWinSec = analysisWinSec;
odorStimTable.Properties.UserData.sampRate = sampRate;
odorStimTable.Properties.UserData.FRAME_RATE = FRAME_RATE;

stimCount = 0;
for iExp = 1:size(expData, 1)
    nTrials = numel(expData.trialMetadata{iExp});
    disp([expData{iExp, 1}, ' #', num2str(expData{iExp, 2})]) 
    for iTrial = 1:nTrials
        if ~isempty(expData.trialMetadata{iExp}(iTrial).odor)
            
            stimCount = stimCount + 1;

            % Basic metadata and stim timing
            warning('off')
            odorStimTable.expDate{stimCount} = expData.expDate(iExp, :);
            warning('on')
            odorStimTable.expNum(stimCount) = expData.expNum(iExp);
            fieldNames = fieldnames(expData.trialMetadata{iExp});
            for iField = [1 2 4 5 6] % trialNum, odor, trialDuration, stimOnsetTime, stimDur
                try
                    odorStimTable.(fieldNames{iField})(stimCount) = ...
                            expData.trialMetadata{iExp}(iTrial).(fieldNames{iField});
                catch
                    odorStimTable.(fieldNames{iField}){stimCount} = ...
                            expData.trialMetadata{iExp}(iTrial).(fieldNames{iField});
                end
            end%iField     
            odorStimTable.cellType{stimCount} = expData.cellType{iExp};
            
            % Get analysis window start and end frames
            stimOnsetFrame = time2idx(odorStimTable.stimOnsetTime(stimCount), frameTimes);
            awPreStimFrameTarget = analysisWinSec(1) * FRAME_RATE;
            awPostStimFrameTarget = analysisWinSec(2) * FRAME_RATE;
            awStartFrame = stimOnsetFrame - awPreStimFrameTarget;
            awEndFrame = stimOnsetFrame + awPostStimFrameTarget - 1;
            if awStartFrame < 1
                awStartFrame = 1;
            end
            if awEndFrame > odorStimTable.trialDuration(stimCount) * FRAME_RATE
                awEndFrame = odorStimTable.trialDuration(stimCount) * FRAME_RATE;
            end
            
            % Do the same thing except for voltage data samples
            stimOnsetSample = time2idx(odorStimTable.stimOnsetTime(stimCount), sampTimes);
            awPreStimSampleTarget = analysisWinSec(1) * sampRate;
            awPostStimSampleTarget = analysisWinSec(2) * sampRate;
            awStartSample = stimOnsetSample - awPreStimSampleTarget;
            awEndSample = stimOnsetSample + awPostStimSampleTarget - 1;
            if awStartSample < 1
                awStartSample = 1;
            end
            if awEndSample > odorStimTable.trialDuration(stimCount) * sampRate
                awEndSample = odorStimTable.trialDuration(stimCount) * sampRate;
            end
            
            % Pull out fly movement data in analysis window
            odorStimTable.badVidTrial(stimCount) = expData.flowData{iExp}.badVidTrials(iTrial);
            preStimMoveFrames = expData.flowData{iExp}.moveFrames(awStartFrame:stimOnsetFrame-1, ...
                    iTrial);
            postStimMoveFrames = expData.flowData{iExp}.moveFrames(stimOnsetFrame:awEndFrame, ...
                    iTrial);
            if numel(preStimMoveFrames) < awPreStimFrameTarget
                preStimMoveFrames = [nan(1, awPreStimFrameTarget - numel(preStimMoveFrames)), ...
                        preStimMoveFrames];
            end
            if numel(postStimMoveFrames) < awPostStimFrameTarget
                postStimMoveFrames = [postStimMoveFrames, nan(1, awPostStimFrameTarget - ...
                        numel(postStimMoveFrames))];
            end
            odorStimTable.moveFrames{stimCount} = [preStimMoveFrames; postStimMoveFrames];
            if sum(odorStimTable.moveFrames{stimCount}) == 0 && ~odorStimTable.badVidTrial(stimCount)
                odorStimTable.excludeMove(stimCount) = 1;
            else
                odorStimTable.excludeMove(stimCount) = 0;
            end
                
            % Pull out voltage data in analysis window
            preStimVmSamples = expData.scaledOut{iExp}(awStartSample:stimOnsetSample-1, iTrial);
            postStimVmSamples = expData.scaledOut{iExp}(stimOnsetSample:awEndSample, iTrial);
            if numel(preStimVmSamples) < awPreStimSampleTarget
                preStimVmSamples = [nan(1, awPreStimSampleTarget - numel(preStimVmSamples))'; ...
                        preStimVmSamples];
            end
            if numel(postStimVmSamples) < awPostStimSampleTarget
                postStimVmSamples = [postStimVmSamples; nan(1, awPostStimSampleTarget - ...
                        numel(postStimVmSamples))'];
            end
            odorStimTable.voltage{stimCount} = [preStimVmSamples; postStimVmSamples];
            
            % Pull out spikes in analysis window
            trialSpikeSamples = expData.spikes{iExp}(iTrial).locs;
            odorStimTable.spikeSamples{stimCount} = trialSpikeSamples(trialSpikeSamples > ...
                    awStartSample & trialSpikeSamples < awEndSample) - awStartSample;
        end%if
    end%iTrial
end%iExp


    
catch foldME; rethrow(foldME); end

%% Create table of data for each movement epoch onset

minEpochDur = 0.2;
quiescenceWin = 1;
analysisDur = 2;

try
    
minEpochFrames = round(minEpochDur * FRAME_RATE);
quiescenceWinFrames = round(quiescenceWin * FRAME_RATE);
analysisDurFrames = round(analysisDur * FRAME_RATE);

% Create table and add metadata
moveEpochTable = table();
moveEpochTable.Properties.UserData.minEpochDur = minEpochDur;
moveEpochTable.Properties.UserData.quiescenceWin = quiescenceWin;
moveEpochTable.Properties.UserData.analysisDur = analysisDur;
moveEpochTable.Properties.UserData.sampRate = sampRate;
moveEpochTable.Properties.UserData.FRAME_RATE = FRAME_RATE;

epochCount = 0;
for iExp = 1:size(expData, 1)
    nTrials = numel(expData.trialMetadata{iExp});
    disp([expData{iExp, 1}, ' #', num2str(expData{iExp, 2})])
    for iTrial = 1:nTrials
        
        currTrialMD = expData.trialMetadata{iExp}(iTrial);
        
        % Restrict to odor or LED stim trials to ensure I'm not including some other manipulation
        if ~expData.flowData{iExp}.badVidTrials(iTrial) && ...
                (~isempty(currTrialMD.odor) || ...
                ~isempty(LHDAN_lightStimData.lightOnsetFrames{iExp}{iTrial})) && ...
                strcmp(currTrialMD.scaledOutMode, 'V')
            
            % Identify movement epochs that meet quiescenceWin and duration requirements
            currTrialMoveFrames = expData.flowData{iExp}.moveFrames(:, iTrial);
            moveFramesStr = regexprep(num2str(currTrialMoveFrames'), ' ', '');
            moveFramesStr = moveFramesStr(1:numel(expData.flowData{iExp}.flowData{iTrial}));
            targetPattern = ['(?<=0{', num2str(quiescenceWinFrames), ....
                    '})1{', num2str(minEpochFrames), '}.{', num2str(analysisDurFrames - ...
                    minEpochFrames), '}'];
            [moveEpochOnsets, analysisWinOffsets] = regexp(moveFramesStr, targetPattern);
            
            % Make sure there wasn't an stimulus or a current test step within the analysis window
            if ~isempty(moveEpochOnsets)
                quiescenceWinOnsets = moveEpochOnsets - quiescenceWinFrames;
                IstepFrames = [currTrialMD.stepStartTime, currTrialMD.stepStartTime + ...
                        currTrialMD.stepLength] * FRAME_RATE;
                for iEpoch = 1:numel(quiescenceWinOnsets)
                    
                    currOnset = quiescenceWinOnsets(iEpoch);
                    currOffset = analysisWinOffsets(iEpoch);
                    
                    % Istep
                    if currOnset <= IstepFrames(2) && currOffset >= IstepFrames(1) 
                        quiescenceWinOnsets(iEpoch) = nan;
                        analysisWinOffsets(iEpoch) = nan;
                        moveEpochOnsets(iEpoch) = nan;
                    end
                    
                    % Odor
                    if ~isempty(currTrialMD.odor) 
                        odorStimFrames = [currTrialMD.stimOnsetTime, currTrialMD.stimOnsetTime + ...
                                currTrialMD.stimDur] * FRAME_RATE;
                        if currOnset < odorStimFrames(2) && currOffset >= odorStimFrames(1)
                            quiescenceWinOnsets(iEpoch) = nan;
                            analysisWinOffsets(iEpoch) = nan;
                            moveEpochOnsets(iEpoch) = nan;
                        end
                    end
                    
                    % Light
                    if ~isempty(LHDAN_lightStimData.lightOnsetFrames{iExp}{iTrial}) 
                        lightStimFrames = [LHDAN_lightStimData.lightOnsetFrames{iExp}{iTrial}', ...
                                LHDAN_lightStimData.lightOffsetFrames{iExp}{iTrial}'];
                        if currOnset < lightStimFrames(2) && currOffset >= lightStimFrames(1)
                            quiescenceWinOnsets(iEpoch) = nan;
                            analysisWinOffsets(iEpoch) = nan;
                            moveEpochOnsets(iEpoch) = nan;
                        end                        
                    end%if
                    
                end%iEpoch
                quiescenceWinOnsets = quiescenceWinOnsets(~isnan(quiescenceWinOnsets));
                analysisWinOffsets = analysisWinOffsets(~isnan(analysisWinOffsets));
                moveEpochOnsets = quiescenceWinOnsets(~isnan(quiescenceWinOnsets));
                
                % Add entry to table for each valid move epoch
                for iEpoch = 1:numel(moveEpochOnsets)
                    epochCount = epochCount + 1;
                   
                    currStartFrame = quiescenceWinOnsets(iEpoch);
                    currEndFrame = analysisWinOffsets(iEpoch);
                    
                    % Basic trial info
                    warning('off')
                    moveEpochTable.expDate{epochCount} = expData.expDate(iExp, :);
                    warning('on')
                    moveEpochTable.expNum(epochCount) = expData.expNum(iExp);
                    moveEpochTable.trialNum(epochCount) = currTrialMD.trialNum;
                    moveEpochTable.trialDuration(epochCount) = currTrialMD.trialDuration;
                    moveEpochTable.cellType{epochCount} = expData.cellType{iExp};
                    
                    % Movement data
                    moveEpochTable.moveFrames{epochCount} = ...
                            expData.flowData{iExp}.moveFrames(currStartFrame:currEndFrame, iTrial);
                    moveEpochTable.flowData{epochCount} = ...
                        expData.flowData{iExp}.processedFlowMat(currStartFrame:currEndFrame, iTrial);
                    
                    % Find start and end samples
                    currStartSample = time2idx(frameTimes(currStartFrame), sampTimes);
                    currEndSample = time2idx(frameTimes(currEndFrame), sampTimes);
                    
                    % Voltage data
                    moveEpochTable.voltage{epochCount} = ...
                            expData.scaledOut{iExp}(currStartSample:currEndSample, iTrial);
                   
                    % Spiking data
                    trialSpikeSamples = expData.spikes{iExp}(iTrial).locs;
                    moveEpochTable.spikeSamples{epochCount} = ...
                            trialSpikeSamples(trialSpikeSamples > currStartSample & ...
                            trialSpikeSamples < currEndSample) - currStartSample;
                        
                end%iEpoch                
            end%if            
        end%if
    end%iTrial
end%iExp

% Trim a sample off of the voltage where necessary to account for rounding errors
minSamples = min(cellfun(@numel, moveEpochTable.voltage));
for iEpoch = 1:size(moveEpochTable, 1)
    moveEpochTable.voltage{iEpoch} = moveEpochTable.voltage{iEpoch}(1:minSamples);
end

disp(['Created table with ', num2str(size(moveEpochTable, 1)), ' fly movement epochs'])
    
catch foldME; rethrow(foldME); end

%% Create table of data for each LED stim onset and offset

analysisWinSec = [4 4];

try
analysisWinFrames = analysisWinSec * FRAME_RATE;

% Create table and add custom metadata
lightStimTable = table();
lightStimTable.Properties.UserData.analysisWinSec = analysisWinSec;
lightStimTable.Properties.UserData.sampRate = sampRate;
lightStimTable.Properties.UserData.FRAME_RATE = FRAME_RATE;

stimCount = 0;
for iExp = 1:size(expData, 1)
    nTrials = numel(expData.trialMetadata{iExp});
    disp([expData{iExp, 1}, ' #', num2str(expData{iExp, 2})])
    for iTrial = 1:nTrials
        currTrialOnsets = LHDAN_lightStimData.lightOnsetFrames{iExp}{iTrial};
        currTrialOffsets = LHDAN_lightStimData.lightOffsetFrames{iExp}{iTrial};
        currTrialMD = expData.trialMetadata{iExp}(iTrial);
        if ~isempty(currTrialOnsets) && strcmp(currTrialMD.scaledOutMode, 'V')
            
            % Get current trial's movement data and set frames overlapping with light stims to zero
            currTrialFrames = expData.flowData{iExp}.moveFrames(:, iTrial);
            stimDurs = currTrialOffsets - currTrialOnsets;
            for iStim = 1:numel(currTrialOnsets)
                if currTrialOnsets(iStim) < 5
                    winSize = currTrialOnsets(iStim) - 1;
                else
                    winSize = 5;
                end
                if (currTrialOnsets(iStim) + 25) < currTrialOffsets(iStim)
                    currTrialFrames(currTrialOnsets(iStim)-winSize:currTrialOnsets(iStim)+25) = 0;
                else
                    currTrialFrames(currTrialOnsets(iStim)-winSize:currTrialOffsets(iStim)) = 0;
                end
                currTrialFrames(currTrialOffsets(iStim)-winSize:currTrialOffsets(iStim)+8) = 0;
            end
           
            % Identify windows around light onsets
            for iStim = 1:numel(currTrialOnsets)
            
                currStartFrame = currTrialOnsets(iStim) - analysisWinFrames(1);
                currEndFrame = currTrialOnsets(iStim) + analysisWinFrames(2);
                
                currTrialFrameCount = numel(expData.flowData{iExp}.flowData{iTrial});
                if currStartFrame > 0 && currEndFrame <= currTrialFrameCount
                    
                    stimCount = stimCount + 1;
                    
                    % Basic metadata and stim timing
                    warning('off')
                    lightStimTable.expDate{stimCount} = expData.expDate(iExp, :);
                    warning('on')
                    lightStimTable.expNum(stimCount) = expData.expNum(iExp);
                    lightStimTable.trialNum(stimCount) = currTrialMD.trialNum;
                    lightStimTable.trialDuration(stimCount) = currTrialMD.trialDuration;
                    lightStimTable.cellType{stimCount} = expData.cellType{iExp};
                    lightStimTable.stimAlignment{stimCount} = 'Onset';
                    lightStimTable.badVidTrial(stimCount) = ...
                            expData.flowData{iExp}.badVidTrials(iTrial);
                        
                    % Record any other light stim onsets and offsets in analysis window
                    lightStimTable.otherStimOnsets{stimCount} = currTrialOnsets( ...
                            currTrialOnsets >= currStartFrame & ...
                            currTrialOnsets < currEndFrame & ...
                            currTrialOnsets ~= currTrialOnsets(iStim)) - currStartFrame; 
                    lightStimTable.otherStimOffsets{stimCount} = currTrialOffsets( ...
                            currTrialOffsets >= currStartFrame & ...
                            currTrialOffsets < currEndFrame) - currStartFrame;                   
                    
                    % Movement data
                    lightStimTable.moveFrames{stimCount} = ...
                            currTrialFrames(currStartFrame:currEndFrame);
                    lightStimTable.flowData{stimCount} = ...
                        expData.flowData{iExp}.processedFlowMat(currStartFrame:currEndFrame, iTrial);              

                    % Find start and end samples
                    currStartSample = time2idx(frameTimes(currStartFrame), sampTimes);
                    currEndSample = time2idx(frameTimes(currEndFrame), sampTimes);
                    
                    % Voltage data
                    lightStimTable.voltage{stimCount} = ...
                            expData.scaledOut{iExp}(currStartSample:currEndSample, iTrial);
                   
                    % Spiking data
                    trialSpikeSamples = expData.spikes{iExp}(iTrial).locs;
                    lightStimTable.spikeSamples{stimCount} = ...
                            trialSpikeSamples(trialSpikeSamples > currStartSample & ...
                            trialSpikeSamples < currEndSample) - currStartSample;
                    
                end%if                
            end%iStim
            
            % Identify windows around light offsets
            for iStim = 1:numel(currTrialOffsets)
            
                currStartFrame = currTrialOffsets(iStim) - analysisWinFrames(1);
                currEndFrame = currTrialOffsets(iStim) + analysisWinFrames(2);
                
                currTrialFrameCount = numel(expData.flowData{iExp}.flowData{iTrial});
                if currStartFrame > 0 && currEndFrame <= currTrialFrameCount
                    
                    stimCount = stimCount + 1;
                    
                    % Basic metadata and stim timing
                    warning('off')
                    lightStimTable.expDate{stimCount} = expData.expDate(iExp, :);
                    warning('on')
                    lightStimTable.expNum(stimCount) = expData.expNum(iExp);
                    lightStimTable.trialNum(stimCount) = currTrialMD.trialNum;
                    lightStimTable.trialDuration(stimCount) = currTrialMD.trialDuration;
                    lightStimTable.cellType{stimCount} = expData.cellType{iExp};
                    lightStimTable.stimAlignment{stimCount} = 'Offset';
                    lightStimTable.badVidTrial(stimCount) = ...
                            expData.flowData{iExp}.badVidTrials(iTrial);

                    % Record any other light stim onsets and offsets in analysis window
                    lightStimTable.otherStimOnsets{stimCount} = currTrialOnsets( ...
                            currTrialOnsets >= currStartFrame & ...
                            currTrialOnsets < currEndFrame) - currStartFrame;
                    lightStimTable.otherStimOffsets{stimCount} = currTrialOffsets( ...
                            currTrialOffsets >= currStartFrame & ...
                            currTrialOffsets < currEndFrame & ...
                            currTrialOffsets ~= currTrialOffsets(iStim)) - currStartFrame;   
                        
                    % Movement data
                    lightStimTable.moveFrames{stimCount} = ...
                            currTrialFrames(currStartFrame:currEndFrame);
                    lightStimTable.flowData{stimCount} = ...
                        expData.flowData{iExp}.processedFlowMat(currStartFrame:currEndFrame, iTrial);              

                    % Find start and end samples
                    currStartSample = time2idx(frameTimes(currStartFrame), sampTimes);
                    currEndSample = time2idx(frameTimes(currEndFrame), sampTimes);
                    
                    % Voltage data
                    lightStimTable.voltage{stimCount} = ...
                            expData.scaledOut{iExp}(currStartSample:currEndSample, iTrial);
                   
                    % Spiking data
                    trialSpikeSamples = expData.spikes{iExp}(iTrial).locs;
                    lightStimTable.spikeSamples{stimCount} = ...
                            trialSpikeSamples(trialSpikeSamples > currStartSample & ...
                            trialSpikeSamples < currEndSample) - currStartSample;
                    
                end%if                
            end%iStim
            
        end%if
    end%iTrial
end%iExp

% Trim a sample off of the voltage where necessary to account for rounding errors
minSamples = min(cellfun(@numel, lightStimTable.voltage));
for iStim = 1:size(lightStimTable, 1)
    lightStimTable.voltage{iStim} = lightStimTable.voltage{iStim}(1:minSamples);
end

disp(['Created table with ', num2str(sum(strcmp(lightStimTable.stimAlignment, 'Onset'))), ...
        ' LED stim onsets and ', num2str(sum(strcmp(lightStimTable.stimAlignment, 'Offset'))), ...
        ' offsets']);

catch foldME; rethrow(foldME); end

%% Determine which movement frames in lightStimTable are ambiguous due to the light stim itself

try
    
figure(1);clf;hold on
flowData = cell2mat(lightStimTable.flowData');%(strcmp(lightStimTable.stimAlignment, stimAlign))');
flowData(flowData > 1) = 1;
imagesc(flowData');
hold on

maskArr = zeros(size(flowData));


otherStimOnsets = lightStimTable.otherStimOnsets;%(strcmp(lightStimTable.stimAlignment, stimAlign));
otherStimOffsets = lightStimTable.otherStimOffsets;%(strcmp(lightStimTable.stimAlignment, stimAlign));

onsetPadFrames = [3 10];
offsetPadFrames = [3 8];

% for iStim = 1:numel(otherStimOnsets)
for iStim = 1:size(lightStimTable, 1)
   
    currStimAlign = lightStimTable.stimAlignment{iStim};
    
    currStimOnsets = otherStimOnsets{iStim};
    currStimOffsets = otherStimOffsets{iStim};
    
    currStimOnsetWins = [currStimOnsets' - onsetPadFrames(1), currStimOnsets', ...
            currStimOnsets' + onsetPadFrames(2)];
    currStimOffsetWins = [currStimOffsets' - offsetPadFrames(1), currStimOffsets', ...
            currStimOffsets' + offsetPadFrames(2)];
        
    % Add alignment onset/offset to the list of stims in current trial
    analysisWinFrames = lightStimTable.Properties.UserData.analysisWinSec * ...
        lightStimTable.Properties.UserData.FRAME_RATE;
    if strcmp(currStimAlign, 'Onset')
        currStimOnsets(end + 1) = analysisWinFrames(1);
        currStimOnsetWins(end + 1, :) = [analysisWinFrames(1) - onsetPadFrames(1), ...
                analysisWinFrames(1), analysisWinFrames(1) + onsetPadFrames(2)];
    else
        currStimOffsets(end + 1) = analysisWinFrames(1);
        currStimOffsetWins(end + 1, :) = [analysisWinFrames(1) - offsetPadFrames(1), ...
            analysisWinFrames(1), analysisWinFrames(1) + offsetPadFrames(2)];
    end
    
    if ~isempty(currStimOnsets) && ~isempty(currStimOffsets)
        
        for iOnset = 1:numel(currStimOnsets)
            currOnsetFrame = currStimOnsets(iOnset);
            
            currWin = currStimOnsetWins(iOnset, :);
            
            % Trim any overlaps with a recent stim offset
            precedingOverlap = find(currStimOffsetWins(:, 3) > currWin(1) & ...
                    currStimOffsetWins(:, 2) < currWin(2));
            if ~isempty(precedingOverlap)
                currStimOnsetWins(iOnset, 1) = currStimOnsetWins(iOnset, 2) - 1;
                currStimOffsetWins(precedingOverlap, 3) = currStimOnsetWins(iOnset, 2) - 2;
            end
            
            % Trim any overlaps with the next stim offset
            trailingOverlap = find(currStimOffsetWins(:, 1) < currWin(3) & ...
                    currStimOffsetWins(:, 2) > currWin(2));
            if ~isempty(trailingOverlap)
               currStimOnsetWins(iOnset, 3) = currStimOffsetWins(trailingOverlap, 2) - 2; 
               currStimOffsetWins(trailingOverlap, 1) = currStimOffsetWins(trailingOverlap, 2) - 1;
            end
            
        end%iOnset  
    
    end%if 
    
    % Plot onsets for current trial
    if ~isempty(currStimOnsetWins)
        for iOnset = 1:size(currStimOnsetWins, 1)
            
            % Trim window if it extends beyond the edges of the trial
            currWin = currStimOnsetWins(iOnset, :);
            if currWin(1) < 1
                currWin(1) = 1;
            elseif currWin(3) > size(flowData, 1)
                currWin(3) = size(flowData, 1);
            end
           
            jbfill([currWin(1) - 0.5, currWin(3) + 0.5], [iStim iStim] - 0.5, ...
                    [iStim iStim] + 0.5, [0 1 0], [0 1 0], 1, 1);
                
            % Add to mask array
            maskArr(currWin(1):currWin(3), iStim) = 1;            
        end
    end
    
    % Plot offsets for current trial
    if ~isempty(currStimOffsetWins)
        for iOffset = 1:size(currStimOffsetWins, 1)
            
            % Trim window if it extends beyond the edges of the trial
            currWin = currStimOffsetWins(iOffset, :);
            if currWin(1) < 1
                currWin(1) = 1;
            elseif currWin(3) > size(flowData, 1)
                currWin(3) = size(flowData, 1);
            end
            
            jbfill([currWin(1) - 0.5, currWin(3) + 0.5], [iStim iStim] - 0.5, ...
                    [iStim iStim] + 0.5, [1 0 0], [1 0 0], 1, 1);
                
            % Add to mask array
            maskArr(currWin(1):currWin(3), iStim) = 2;   
        end
    end 
end%iStim   
    
for iStim = 1:size(lightStimTable, 1)
   lightStimTable.ambiguousMoveFrames{iStim} = maskArr(:, iStim); 
end

catch foldME; rethrow(foldME); end

%% Print summary counts of odor stim data

try
    
tbOdors = dataTable(odorStimTable);
tbOdors = tbOdors.add_filter('excludeMove', 1);

cellTypes = unique(odorStimTable.cellType);
varNames = {'Cell_Type', 'Odor_Name', 'Total_Stims', 'n_flies'};
outputTable = [];
for iType = 1:numel(cellTypes)
    
    % Create dataTable object and add new cell type filter
    tbOdors = tbOdors.clear_filter('odor');
    tbOdors = tbOdors.add_filter('cellType', cellTypes{iType});
    tbCurrType = tbOdors.apply_filters();
    
    % Filter by each odor and add stim and experiment counts to output table
    odorList = unique(tbCurrType.odor);
    for iOdor = 1:numel(odorList)
        
        % Filter by current odor
        tbOdors = tbOdors.clear_filter('odor');
        tbOdors = tbOdors.add_filter('odor', odorList{iOdor});
        currOutput = tbOdors.apply_filters();
        
        % Count number of unique experiments in current table subset
        expIDs = cellfun(@(x, y) [x, ' ', num2str(y)], currOutput.expDate, ...
                num2cell(currOutput.expNum), 'uniformoutput', 0);
            
        % Add new row to output table
        newRow = {cellTypes{iType}, odorList{iOdor}, size(currOutput, 1), ...
                numel(unique(expIDs))};
        if isempty(outputTable)
            outputTable = cell2table(newRow, 'VariableNames', varNames);
        else
            outputTable = [outputTable; newRow];
        end        
    end    
end

catch foldME; rethrow(foldME); end

% Create one version sorted by odor and one sorted by cell type
odorSummaryTable = sortrows(outputTable(:, [2 1 3 4]), 'Odor_Name');
cellTypeSummaryTable = sortrows(outputTable, 'Cell_Type');

disp(cellTypeSummaryTable)











