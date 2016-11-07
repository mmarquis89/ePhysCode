function [data, current, scaledOut, tenVm] = acquisitionPostProcessing(data, x, n)
% The purpose of this function is to consolidate all the basic post-acquisition steps that are common across different types 
% of acquisition functions, to minimize the risk of inconsistencies when I change one function.
    % data = the main data structure for the trial
    % x = the newly acquired data from the DAQ

strDate = data(n).date;
expNumber = data(n).expnumber;

    % Calculate and record "Output Gain" setting on amplifier
       gainReading = mean(x(:,4));
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
    filterTelegraph = mean(x(:,5));
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
    scaledOutMode = mean(x(:,6));
    if scaledOutMode > 0 && scaledOutMode < 3.5
        data(n).scaledOutMode = 'V';
    elseif scaledOutMode >= 3.5 && scaledOutMode < 7
        data(n).scaledOutMode = 'I';
    end 
        
    % Save recorded data
    scaledOut = (x(:,1)/data(n).variableGain)*1000; % mV or pA
    current = (x(:,2)/data(n).ImGain)*1000; % pA 
    tenVm = (x(:,3)/data(n).VmGain)*1000; % mV   

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
    
    %% save data(n)
    save(['C:/Users/Wilson Lab/Documents/MATLAB/Data/', strDate,'/WCwaveform_' data(n).date,'_E',num2str(expNumber)],'data');
    save(['U:/Data Backup/', strDate,'/WCwaveform_' data(n).date,'_E',num2str(expNumber)],'data');
    save(['C:/Users/Wilson Lab/Documents/MATLAB/Data/', strDate,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expNumber),'_',num2str(n)],'current','scaledOut','tenVm'); %, 'odor');
    save(['U:/Data Backup/', strDate,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expNumber),'_',num2str(n)],'current','scaledOut','tenVm');


end