function output = load_experiment(expDate, expNumber, parentDir)
%===========================================================================================================================
% Loads all the raw recording data and metadata from a given experiment and returns a structure containing all data for 
% further analysis. This function is compatible with either the old or new ways of storing metadata (i.e. as a single struct
% for the entire experiment vs. as individual structs for each trial). The final experiment using the old metadata storage
% format is from 2017-Mar-09.
    % expDate: the date of the experiment in 'yyyy-MMM-dd' format
    % expNumber: the number of the experiment
    % parentDir: recording data directory with data located  in parentdir>expDate (e.g. 'D:/Dropbox (HMS)/Data/')
%===========================================================================================================================
    
    % Check date to maintain backwards-compatibility with older data
    formattedDate = datetime(expDate, 'InputFormat', 'yyyy-MMM-dd');
    
    if formattedDate < datetime('2017-Mar-12')    
  	%  ***Metadata is already stored in a single struct for all trials***
        
        % Load data and get total number of trials
        load(fullfile(parentDir, expDate,['WCwaveform_',expDate,'_E',num2str(expNumber), '.mat']),'data');
        nTrials = length(data);
        output.expInfo = data;
    else
    %  ***Metadata is stored in individual structs for each trial***
  
        % Get total number of trials
        D = dir(fullfile(parentDir, expDate,['WCwaveform_', expDate,'_E',num2str(expNumber),'*.mat']));
        nTrials = length(D); 
        
        % Concatenate metadata for all trials into single structure
        for iTrial = 1:nTrials       
            load(fullfile(parentDir, expDate, ['WCwaveform_',expDate,'_E',num2str(expNumber),'_T', num2str(iTrial), '.mat']),'data');
            output.expInfo(iTrial) = data; 
        end
    end
    
    % Add the raw data from each trial
    for iTrial = 1:nTrials
        load(fullfile(parentDir, expDate, ['Raw_WCwaveform_',expDate,'_E',num2str(expNumber), '_', num2str(iTrial),'.mat']));
        output.trialData(iTrial).current = current;
        output.trialData(iTrial).tenVm = tenVm;
        output.trialData(iTrial).scaledOut = scaledOut;
    end
end
