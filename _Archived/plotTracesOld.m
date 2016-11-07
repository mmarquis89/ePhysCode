function plotTraces(bl)

%% PLOT EACH TRIAL VOLTAGE AND CURRENT

tRange = [1:bl.nTrials];
if bl.nTrials > 1
    cm = colormap(jet(length(tRange)));
else
    cm = [0 0 1];
end

% Voltage
figure (1);clf; hold all
set(gcf,'Position',[10 550 1650 400],'Color',[1 1 1]);
set(gca,'LooseInset',get(gca,'TightInset'))
for iTrial = tRange
    plot(bl.time(.05*bl.sampRate:end), bl.voltage((.05*bl.sampRate:end),iTrial), 'color', cm(iTrial,:))
end
if length(bl.trialDuration) > 1
    plot([bl.pinchOpen,bl.pinchOpen],ylim, 'Color', 'r', 'linewidth', 2)
    plot([bl.stimOnTime,bl.stimOnTime],ylim, 'Color', 'g', 'linewidth', 2)
    plot([(bl.stimOnTime + bl.stimLength),(bl.stimOnTime + bl.stimLength)],ylim, 'Color', 'r', 'linewidth', 2)
end
if isfield(bl, 'pumpOn')
    if bl.pumpOn
        pumpStart = sum(bl.trialDuration(1:2)) - bl.pumpTiming(1);
        plot([pumpStart, pumpStart], ylim, 'Color' , 'm', 'linewidth', 2)  % PicoPump ejection
    end
end
title({[bl.date], ['Voltage traces for trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]});
ylabel('Vm (mV)');
xlabel('Time (sec)');
box off

% Current
figure (2);clf; hold all
set(gcf,'Position',[10 50 1650 400],'Color',[1 1 1]);
set(gca,'LooseInset',get(gca,'TightInset'))
for iTrial = tRange
    plot(bl.time(.05*bl.sampRate:end), bl.current((.05*bl.sampRate:end),iTrial), 'color', cm(iTrial,:))
end
if length(bl.trialDuration) > 1
    plot([bl.pinchOpen,bl.pinchOpen],ylim, 'Color', 'r', 'linewidth', 2)
    plot([bl.stimOnTime,bl.stimOnTime],ylim, 'Color', 'g', 'linewidth', 2)
    plot([(bl.stimOnTime + bl.stimLength),(bl.stimOnTime + bl.stimLength)],ylim, 'Color', 'r', 'linewidth', 2)
end
title({[bl.date], ['Current traces for trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]});
ylabel('Current (pA)')
xlabel('Time (sec)');
box off

end