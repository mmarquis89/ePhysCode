function output = getTrials(expData, trialNums)

% Pulls out data and information about a specified block of trials
for iTrial = 1:length(trialNums)
    try
        output.data.current(:,iTrial) = expData.trialData(trialNums(iTrial)).current;
    catch
        disp('ERROR: exceeds number of trials in experiment');
        output = [];
        break
    end
    output.data.tenVm(:,iTrial) = expData.trialData(trialNums(iTrial)).tenVm;
    output.data.scaledOut(:,iTrial) = expData.trialData(trialNums(iTrial)).scaledOut;
    output.trialInfo(iTrial) = expData.expInfo(trialNums(iTrial));
    output.trialInfo(iTrial).Rpipette = pipetteResistanceCalc(expData.trialData(1).scaledOut);
end

end

