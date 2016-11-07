%% PLOTTING CELLS AGAINST EACH OTHER

LNlist = {'Mar12'; 'Mar17';};
PNlist = {'May04'; 'May05'};

%% PLOT LN AND PN SPIKE COUNTS

figure(1);clf
% LNs
subplot(221);hold on;h={};
cm = [0 0 1; 1 0 1]%colormap(cool(length(LNlist)));
for iLN = 1:length(LNlist)
    currBl = allBl.LNs.(LNlist{iLN});
    set(gcf,'Color',[1 1 1]);
    meanResponses = zeros(currBl.nStims, 1);
    semVals = zeros(currBl.nStims,1);
    for iStim = 1:currBl.nStims
        currStim = currBl.responses(currBl.responses(:,1) == currBl.stimVals(iStim), 2);
        meanResponses(iStim) = mean(currStim);
        semVals(iStim) = std(currStim)/sqrt(length(currStim));
    end
    plot(currBl.stimVals, meanResponses, 'o', 'Color', cm(iLN, :), 'lineWidth', 2);                    % Plot average responses
    h{iLN} = errorbar(currBl.stimVals, meanResponses, semVals, 'color', cm(iLN,:), 'lineWidth', 2);                          % Add SEM error bars
    meanResponses = (meanResponses(1:2:end) + meanResponses(2:2:end))./2;
    LNResp{iLN} = meanResponses;
    set(gca, 'FontSize', 13, 'linewidth', 2)
end
xlabel('Stimulus intensity (duty cycle)', 'FontSize', 13); ylabel('Response (spikes)', 'FontSize', 13);
title('LNs', 'FontSize', 13)
legend([h{1:length(LNlist)}], LNlist, 'location', 'northwest')

% PNs
subplot(222);hold on;h={};
cm = [1 0 0; 0 1 0];%colormap(hsv(length(PNlist)));
for iPN = 1:length(PNlist)
    currBl = allBl.PNs.(PNlist{iPN}).CurrPN(1);
    set(gcf,'Color',[1 1 1]);
    meanResponses = zeros(currBl.nStims, 1);
    semVals = zeros(currBl.nStims,1);
    for iStim = 1:currBl.nStims
        currStim = currBl.responses(currBl.responses(:,1) == currBl.stimVals(iStim), 2);
        meanResponses(iStim) = mean(currStim);
        semVals(iStim) = std(currStim)/sqrt(length(currStim));
    end
    plot(currBl.stimVals, meanResponses, 'o', 'Color', cm(iPN, :),'linewidth', 2)                    % Plot average responses
    h{iPN} = errorbar(currBl.stimVals, meanResponses, semVals, 'color', cm(iPN,:),'linewidth', 2);                          % Add SEM error bars
    set(gca, 'FontSize', 13, 'linewidth', 2)
end
xlabel('Stimulus intensity (duty cycle)', 'FontSize', 13); ylabel('Response (spikes)', 'FontSize', 13);
title('PNs', 'FontSize', 13)
legend([h{1:length(PNlist)}], PNlist, 'location', 'northwest')

% PNs + Blockers
subplot(223);hold on;h={};
cm = [1 0 0; 0 1 0]; %colormap(hsv(length(PNlist)));
for iPN = 1:length(PNlist)
    currBl = allBl.PNs.(PNlist{iPN}).CurrPN(2);
    set(gcf,'Color',[1 1 1]);
    meanResponses = zeros(currBl.nStims, 1);
    semVals = zeros(currBl.nStims,1);
    for iStim = 1:currBl.nStims
        currStim = currBl.responses(currBl.responses(:,1) == currBl.stimVals(iStim), 2);
        meanResponses(iStim) = mean(currStim);
        semVals(iStim) = std(currStim)/sqrt(length(currStim));
    end
    plot(currBl.stimVals, meanResponses, 'o', 'Color', cm(iPN, :),'linewidth', 2)                    % Plot average responses
    h{iPN} = errorbar(currBl.stimVals, meanResponses, semVals, 'color', cm(iPN,:),'linewidth', 2);                          % Add SEM error bars
    set(gca, 'FontSize', 13, 'linewidth', 2)
end
xlabel('Stimulus intensity (duty cycle)','FontSize', 13); ylabel('Response (spikes)','FontSize', 13);
title('PNs + Blockers','FontSize', 13)
legend([h{1:length(PNlist)}], PNlist, 'location', 'northwest')

% Change in PN Rates
subplot(224);hold on;h={};
cm = [1 0 0; 0 1 0]; %colormap(hsv(length(PNlist)));
for iPN = 1:length(PNlist)
    currBlPre = allBl.PNs.(PNlist{iPN}).CurrPN(1);
    currBlPost = allBl.PNs.(PNlist{iPN}).CurrPN(2);
    set(gcf,'Color',[1 1 1]);
    meanResponses = zeros(currBlPre.nStims, 2);
    for iStim = 1:currBl.nStims
        currStimPre = currBlPre.responses(currBlPre.responses(:,1) == currBlPre.stimVals(iStim), 2);
        currStimPost = currBlPost.responses(currBlPost.responses(:,1) == currBlPost.stimVals(iStim), 2);
        meanResponses(iStim,1) = mean(currStimPre);
        meanResponses(iStim,2) = mean(currStimPost);
        meanDiff{iPN} = meanResponses(:,2) - meanResponses(:,1);
    end
    h{iPN} = plot(currBlPre.stimVals, meanResponses(:,2)-meanResponses(:,1), '-o', 'Color', cm(iPN, :), 'linewidth', 2);               % Plot average responses
    set(gca, 'FontSize', 13, 'linewidth', 2)
end
xlabel('Stimulus intensity (duty cycle)', 'FontSize', 13); ylabel('Change in PN response', 'FontSize', 13);
title('Increase in PN responses with blockers', 'FontSize', 13)
legend([h{1:length(PNlist)}], PNlist, 'location', 'southeast')

figure(2);clf;
%suptitle('LN responses vs. Change in PN responses with blockers')
for iLN = 2%1:length(LNlist)
    h={};
    %subplot(2, ceil(length(LNlist)/2), iLN)
        set(gcf,'Color',[1 1 1]);
    hold on
    for iPN = 1:length(PNlist)
        h{iPN} = plot(LNResp{iLN}, meanDiff{iPN}, '-o', 'color', cm(iPN, :), 'linewidth', 2);
    end
    set(gca, 'FontSize', 13, 'linewidth', 2)
    xlabel('LN Responses (spikes)'); ylabel('Change in PN Responses (spikes)', 'FontSize', 13);
    title(LNlist{iLN}, 'FontSize', 13)
    legend([h{1:length(PNlist)}], PNlist, 'location', 'southeast')
end
%% PLOT PSTH ESTIMATES

% LNs

% PNs

















%%
exp = 'Mar30';
currBl = allBl.PNs.(exp);
currLN = allBl.LNs.Mar12;

%hold all
%set(gcf,'Color',[1 1 1]);
meanResponsesPre = zeros(currBl(1).nStims, 1);
meanResponsesPost = meanResponsesPre;
semVals = zeros(currBl(1).nStims,2);
for iStim = 1:currBl(1).nStims
   currStimPre = currBl(1).responses(currBl(1).responses(:,1) == currBl(1).stimVals(iStim), 2);
   meanResponsesPre(iStim) = mean(currStimPre);
   currStimPost = currBl(2).responses(currBl(2).responses(:,1) == currBl(2).stimVals(iStim), 2);
   meanResponsesPost(iStim) = mean(currStimPost);
   currStimLN = currLN.responses(currLN.responses(:,1) == currLN.stimVals(iStim), 2);
   meanResponsesLN(iStim) = mean(currStimLN);
   
   
   semValsPre(iStim) = std(currStimPre)/sqrt(length(currStimPre));
   semValsPost(iStim) = std(currStimPost)/sqrt(length(currStimPost));
end

figure(5);clf;hold on
cm = colormap(jet(length(meanResponsesPre)));
for iStim = 1:length(meanResponsesPre)
    plot(meanResponsesPre(iStim), meanResponsesPost(iStim), '*', 'color', cm(iStim, :))
end
% plot(meanResponsesPre, meanResponsesPost, currBl(1).stimVals')
xlabel('Regular PN Responses');ylabel('Responses after blocking inhibition');
xlim([0 35]); ylim([0 35]);

dPN = meanResponsesPost-meanResponsesPre;
figure(6); clf; plot(currBl(1).stimVals, dPN, '*')

figure(7);clf;hold on
for iStim = 1:length(meanResponsesPre)
    plot(meanResponsesLN(iStim), dPN(iStim), '*', 'color', cm(iStim,:))
end
xlabel('LN Respnses');ylabel('Effect of inhibition on PNs')

% plot(currBl.stimVals, meanResponses, 'o', 'Color', 'r')                     % Plot average responses 
% errorbar(bl.stimVals, meanResponses, semVals);                          % Add SEM error bars
% xlim([0, max(currBl.responses(:,1))]); ylim([0, max(currBl.responses(:,2))+1])



% title({['Number of spikes in first ' num2str(bl.responseLength) ' ms for each stim intensity'], ...
%     [bl.date '   Trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))], ...
%     ['Stimulus voltage = ' num2str(bl.stimVoltage) 'V     Duration = ' num2str(1000*bl.stimLength) ' ms'], ...
%     ['Duty cycle range: ' num2str(bl.stimVals(1)) '% - ' ...
%     num2str(bl.stimVals(end)) '% (' num2str(bl.nStims) ' total)']});
% xlabel('Stimulus intensity (duty cycle)'); ylabel('Response (spikes)');
