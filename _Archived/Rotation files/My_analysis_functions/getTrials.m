function output = getTrials(expData, trialNums)

    % Pulls out data and information about a specified block of trials
    for iTrial = 1:length(trialNums)
        output.data(:,iTrial,1) = expData.trialData(trialNums(iTrial)).current;
        output.data(:,iTrial,2) = expData.trialData(trialNums(iTrial)).tenVm;
        output.data(:,iTrial,3) = expData.trialData(trialNums(iTrial)).scaledOut;
        output.trialInfo(iTrial) = expData.expInfo(trialNums(iTrial));
    end
    
end

