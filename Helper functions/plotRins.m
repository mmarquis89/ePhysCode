function plotRins(data)
% ==============================================================================================
% Plots input resistances across an experiment
%     data = a data structure with input resistance values in field Rin (NaN for skipped trials)
% ==============================================================================================
    
set(gcf, 'Position', [1250 40 620 400], 'Color', [1 1 1]);
set(gca, 'LooseInset', get(gca, 'TightInset'));
Rins = [data.Rin];
plot(1:length(Rins), Rins, 'LineStyle', 'none', 'Marker', 'o');
xlim([0, length(Rins)+1]);
xlabel('Trial');
ylabel('Rin (GOhm)'); % Not using tex markup to troubleshoot crashing issue: ylabel('R_{input}  (G\Omega)');

end