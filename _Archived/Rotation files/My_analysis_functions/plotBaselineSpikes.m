function plotBaselineSpikes(bl, smoothWin)
% Plots total number of spikes occuring before the stimulus for each trial
% smoothWin: width of smoothing window to apply to results
% smoothWin = 1 will not smooth at all

totSpikes = NaN(bl.nTrials, 1);
for iTrial = 1:bl.nTrials
    spk = bl.spikes(iTrial).locs;
    spk(spk > bl.stimOnTime * bl.sampRate) = [];
    totSpikes(iTrial) = numel(spk);
end

figure(7); clf;
plot(bl.trialList(1):bl.trialList(end), smooth(totSpikes,smoothWin),'.');
title({'Total non-evoked spikes during trials',['Trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))], ...
    ['Stimulus voltage = ' num2str(bl.stimVoltage) 'V     Duration = ' num2str(1000*bl.stimLength) ' ms'], ...
    ['Duty cycle range: ' num2str(bl.stimVals(1)) '% - ' ...
    num2str(bl.stimVals(end)) '% (' num2str(bl.nStims) ' total)']});
xlabel('Trial number'); ylabel('Smoothed number of total spikes');

end