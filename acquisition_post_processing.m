function [data, current, scaledOut, tenVm] = acquisition_post_processing(data, rawAcqData, trialNum)
% ================================================================================================
% The purpose of this function is to consolidate all the basic post-acquisition steps that are
% common across different types of acquisition functions, to minimize the risk of inconsistencies
% when I make changes to one function.
%   data = the main data structure for the trial
%   rawAcqData = the newly acquired data from the DAQ
% =================================================================================================

strDate = data.date;
expNum = data.expNum;

% Calculate and record "Output Gain" setting on amplifier
gainReading = mean(rawAcqData(:,4));
if gainReading > 0 && gainReading < 2.34
    data.variableGain = 0.5;
elseif gainReading >= 2.34 && gainReading < 2.85
    data.variableGain = 1;
elseif gainReading >= 2.85 && gainReading < 3.34
    data.variableGain = 2;
elseif gainReading >= 3.34 && gainReading < 3.85
    data.variableGain = 5;
elseif gainReading >= 3.85 && gainReading < 4.37
    data.variableGain = 10;
elseif gainReading >= 4.37 && gainReading < 4.85
    data.variableGain = 20;
elseif gainReading >= 4.85 && gainReading < 5.34
    data.variableGain = 50;
elseif gainReading >= 5.34 && gainReading < 5.85
    data.variableGain = 100;
elseif gainReading >= 5.85 && gainReading < 6.37
    data.variableGain = 200;
elseif gainReading >= 6.37 && gainReading < 6.85
    data.variableGain = 500;
end

% Calculate and record amplifier filter setting
filterTelegraph = mean(rawAcqData(:,5));
if filterTelegraph > 0 && filterTelegraph < 3
    data.filterFreq = 1;
elseif filterTelegraph >= 3 && filterTelegraph < 5
    data.filterFreq = 2;
elseif filterTelegraph >=5 && filterTelegraph < 7
    data.filterFreq = 5;
elseif filterTelegraph >=7 && filterTelegraph < 9
    data.filterFreq = 10;
elseif filterTelegraph >=9 && filterTelegraph < 11
    data.filterFreq = 100;
end

% Calculate and record amplifier mode
scaledOutMode = mean(rawAcqData(:,6));
if scaledOutMode > 0 && scaledOutMode < 3.5
    data.scaledOutMode = 'V';
elseif scaledOutMode >= 3.5 && scaledOutMode < 7
    data.scaledOutMode = 'I';
end

% Record camera strobe data
if size(rawAcqData,2) > 6
    data.cameraStrobe = rawAcqData(:,7);
end

% Save recorded data
scaledOut = (rawAcqData(:,1)/data.variableGain)*1000; % mV or pA
current = (rawAcqData(:,2)/data.ImGain)*1000; % pA
tenVm = (rawAcqData(:,3)/data.VmGain)*1000; % mV

% Calculate and record input resistance
if ~isempty(data.Istep)
    data.Rin = calc_Rinput(scaledOut, data.sampratein, data.Istep, data.stepStartTime, data.stepLength, 0.5);
else
    data.Rin = 0; % Trying this instead of NaN to see if it solves problem with Matlab crashing during Rin plotting
end

% Save to running count of input resistances
savePath = fullfile('C:/Users/Wilson Lab/Dropbox (HMS)/Data', strDate);
RinputFile = fullfile(savePath,['*E', num2str(expNum), '_Rinputs*']);
D = dir(RinputFile);
if ~isempty(D)
    % Append to input resistance log
    load(fullfile(savePath, [strDate, '_E', num2str(expNum), '_Rinputs.mat']), 'Rins');
    Rins(end+1) = data.Rin;
    save(fullfile(savePath, [strDate, '_E', num2str(expNum), '_Rinputs']), 'Rins');
else
    % Create input resistance log
    Rins = data.Rin;
    save(fullfile(savePath, [strDate, '_E', num2str(expNum), '_Rinputs']), 'Rins');
end

% Calculate and record pipette resistance
if trialNum == 1
    data.Rpipette = pipette_resistance_calc(current);
else
    data.Rpipette = [];
end

% Save data
warning('error', 'MATLAB:save:sizeTooBigForMATFile');
try
    save(['C:/Users/Wilson Lab/Dropbox (HMS)/Data/', strDate,'/WCwaveform_' strDate,'_E',num2str(expNum), '_T', num2str(trialNum)],'data');
catch
    save(['C:/Users/Wilson Lab/Dropbox (HMS)/Data/', strDate,'/WCwaveform_' strDate,'_E',num2str(expNum), '_T', num2str(trialNum)],'data', '-v7.3');
end
save(['C:/Users/Wilson Lab/Dropbox (HMS)/Data/', strDate,'/Raw_WCwaveform_' strDate,'_E',num2str(expNum),'_',num2str(trialNum)],'current','scaledOut','tenVm');

end