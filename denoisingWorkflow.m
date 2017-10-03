

%% ACQUIRE DENOISING TRACE
traceDuration = 5; % Time to acquire in seconds


for iTrial = 1                 
denoising_acquisition(1, traceDuration);
% disp(num2str(iTrial));
end
