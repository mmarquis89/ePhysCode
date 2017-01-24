function [data, current, scaledOut, tenVm] = acquisitionPostProcessing(data, rawAcqData, n)
% ================================================================================================
% The purpose of this function is to consolidate all the basic post-acquisition steps that are
% common across different types of acquisition functions, to minimize the risk of inconsistencies
% when I make changes to one function.
% data = the main data structure for the trial
% rawAcqData = the newly acquired data from the DAQ
% =================================================================================================

strDate = data(n).date;
expNum = data(n).expNum;

% Calculate and record "Output Gain" setting on amplifier
gainReading = mean(rawAcqData(:,4));
if gainReading > 0 && gainReading < 2.34
    data(n).variableGain = 0.5;
elseif gainReading >= 2.34 && gainReading < 2.85
    data(n).variableGain = 1;
elseif gainReading >= 2.85 && gainReading < 3.34
    data(n).variableGain = 2;
elseif gainReading >= 3.34 && gainReading < 3.85
    data(n).variableGain = 5;
elseif gainReading >= 3.85 && gainReading < 4.37
    data(n).variableGain = 10;
elseif gainReading >= 4.37 && gainReading < 4.85
    data(n).variableGain = 20;
elseif gainReading >= 4.85 && gainReading < 5.34
    data(n).variableGain = 50;
elseif gainReading >= 5.34 && gainReading < 5.85
    data(n).variableGain = 100;
elseif gainReading >= 5.85 && gainReading < 6.37
    data(n).variableGain = 200;
elseif gainReading >= 6.37 && gainReading < 6.85
    data(n).variableGain = 500;
end

% Calculate and record amplifier filter setting
filterTelegraph = mean(rawAcqData(:,5));
if filterTelegraph > 0 && filterTelegraph < 3
    data(n).filterFreq = 1;
elseif filterTelegraph >= 3 && filterTelegraph < 5
    data(n).filterFreq = 2;
elseif filterTelegraph >=5 && filterTelegraph < 7
    data(n).filterFreq = 5;
elseif filterTelegraph >=7 && filterTelegraph < 9
    data(n).filterFreq = 10;
elseif filterTelegraph >=9 && filterTelegraph < 11
    data(n).filterFreq = 100;
end

% Calculate and record amplifier mode
scaledOutMode = mean(rawAcqData(:,6));
if scaledOutMode > 0 && scaledOutMode < 3.5
    data(n).scaledOutMode = 'V';
elseif scaledOutMode >= 3.5 && scaledOutMode < 7
    data(n).scaledOutMode = 'I';
end

% Record camera strobe data
data(n).cameraStrobe = rawAcqData(:,7);

% Save recorded data
scaledOut = (rawAcqData(:,1)/data(n).variableGain)*1000; % mV or pA
current = (rawAcqData(:,2)/data(n).ImGain)*1000; % pA
tenVm = (rawAcqData(:,3)/data(n).VmGain)*1000; % mV

% Calculate and record input resistance
if ~isempty(data(n).Istep)
    data(n).Rin = calcRinput(scaledOut, data(n).sampratein, data(n).Istep, data(n).stepStartTime, data(n).stepLength, 0.5);
else
    data(n).Rin = 0; % Trying this instead of NaN to see if it solves problem with Matlab crashing during Rin plotting
end

% Calculate and record pipette resistance
if n == 1
    data(n).Rpipette = pipetteResistanceCalc(current);
else
    data(n).Rpipette = [];
end

% Save data(n)
save(['C:/Users/Wilson Lab/Documents/MATLAB/Data/', strDate,'/WCwaveform_' data(n).date,'_E',num2str(expNum)],'data');
save(['C:/Users/Wilson Lab/Documents/MATLAB/Data/', strDate,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expNum),'_',num2str(n)],'current','scaledOut','tenVm');
%save(['U:/Data Backup/', strDate,'/WCwaveform_' data(n).date,'_E',num2str(expNumber)],'data');
%save(['U:/Data Backup/', strDate,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expNumber),'_',num2str(n)],'current','scaledOut','tenVm');




end