function plotTraces(bl)

%% PLOT EACH TRIAL VOLTAGE AND CURRENT

tRange = [1:bl.nTrials];
cm = colormap(jet(length(tRange)));

% Voltage
figure (1);clf; hold all
set(gcf,'Position',[25 500 1800 400],'Color',[1 1 1]);
for iTrial = tRange
    plot(bl.time, bl.filteredVoltage(:,iTrial), 'Color', cm(iTrial,:))
end
plot([bl.stimOnTime,bl.stimOnTime],ylim, 'Color', 'red')
plot([(bl.stimOnTime + bl.stimLength),(bl.stimOnTime + bl.stimLength)],ylim, 'Color', 'red')
title({['Voltage traces for trials ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]});
ylabel('Vm (mV)');
xlabel('Time (sec)');
box off

% Current
figure (2);clf; hold all
set(gcf,'Position',[25 10 1800 400],'Color',[1 1 1]);
for iTrial = tRange
    plot(bl.time, bl.filteredCurrent(:,iTrial), 'Color', cm(iTrial,:))
end
plot([bl.stimOnTime,bl.stimOnTime],ylim, 'Color', 'red')
plot([(bl.stimOnTime + bl.stimLength),(bl.stimOnTime + bl.stimLength)],ylim, 'Color', 'red')
title({['Current traces for trials ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]});
ylabel('Current (pA)')
xlabel('Time (sec)');
box off

end