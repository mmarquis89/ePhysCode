function output = loadExperiment(expDate, expNumber)
    
    % Load the master file
    load(['Data/', expDate,'/WCwaveform_',expDate,'_E',num2str(expNumber),'.mat']','data');
    
    output.expInfo = data;       % Experiment info
    
    for iTrial = 1:length(data)     % Add the raw data from each trial
        load(['Data/', expDate,'/Raw_WCwaveform_',expDate,'_E',num2str(expNumber), '_', num2str(iTrial),'.mat']');  
        output.trialData(iTrial).current = current;
        output.trialData(iTrial).tenVm = tenVm;
        output.trialData(iTrial).scaledOut = scaledOut;
    end
end
