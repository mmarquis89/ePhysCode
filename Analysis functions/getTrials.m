function output = getTrials(expData, trialNums)

% Pulls out data and information about a specified block of trials
    for iTrial = 1:length(trialNums)
        output.data.current(:,iTrial) = expData.trialData(trialNums(iTrial)).current;
        output.data.tenVm(:,iTrial) = expData.trialData(trialNums(iTrial)).tenVm;
        output.data.scaledOut(:,iTrial) = expData.trialData(trialNums(iTrial)).scaledOut;
        output.trialInfo(iTrial) = expData.expInfo(trialNums(iTrial));
    end
    
end

