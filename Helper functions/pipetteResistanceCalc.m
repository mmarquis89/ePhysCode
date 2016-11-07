function [Rpipette] = pipetteResistanceCalc(sealTestCurrent)
% Given a current trace (in pA) recorded with pipette in the bath 
% and seal test on (5 mV step), estimates pipette resistance (in MOhm)

halfPoint = length(sealTestCurrent) / 2;
quart1 = halfPoint / 2;
quart3 = halfPoint + quart1;
currentSort = sort(sealTestCurrent);

Rpipette = 1000 * 5 / (currentSort(quart3) - currentSort(quart1));

end