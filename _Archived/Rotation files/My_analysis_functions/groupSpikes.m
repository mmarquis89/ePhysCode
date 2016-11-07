function [combSpikeLocs, combIntsCount] = groupSpikes(bl, condense)

% Pull out spikes for all trials
spikeLocs = cell(bl.nTrials,1);
for iTrial = 1:bl.nTrials
    spikeLocs{iTrial} = bl.spikes(iTrial).locs;
end

% Combine spikes of the same stim intensity
stimSpikeLocs = cell(bl.nStims, 1);
for iStim = 1:bl.nStims
   currStim = bl.stimVals(iStim);
   stimSpikeLocs{iStim} = [1; cell2mat(spikeLocs(bl.intensities==currStim)); bl.nSamples];
   intsCount(iStim) = sum(bl.intensities==currStim);
end

% Condense stims if necessary
if condense
    i=1;
    for iStim = 1:2:bl.nStims
        combSpikeLocs{i} = [stimSpikeLocs{iStim}; stimSpikeLocs{iStim+1}];
        combIntsCount(i) = [intsCount(iStim)+intsCount(iStim+1)];
        i=i+1;
    end
else
    combSpikeLocs = stimSpikeLocs';
    combIntsCount = intsCount;
end

end