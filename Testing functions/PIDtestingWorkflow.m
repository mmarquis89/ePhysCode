

expNum = 1;
trialDuration = [7 2 5]; 


%% FOR MY OLFACTOMETER
valveID = 3;

for iTrial = 1:4
    Acquire_PID_Trial(expNum, trialDuration, valveID);
end


%% FOR ALLIE'S OLFACTOMETER
valveID = 2;
trialDuration = [5 2 2 5]; 

for iTrial = 1:4
    Acquire_PID_Trial_Allie(expNum, trialDuration, valveID);
end