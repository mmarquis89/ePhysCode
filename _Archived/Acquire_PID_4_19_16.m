function data = Acquire_PID(expNumber, trialDuration, odorNum)

% expnumber = experiment (fly or cell) number
% trialDuration = [pre-stim, pinch valve acclimation, clean valve open, post-stim] in seconds
% odorNum = integer from 1-4 specifying which odor vial to use for this trial
tic
%%  make a directory if one does not exist
    strDate = datestr(now, 'yyyy-mmm-dd');
    if ~isdir(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate])
        mkdir(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate]);
    end
    if ~isdir(['U:/Data Backup/', strDate])
        mkdir(['U:/Data Backup/', strDate]);
    end
    
    %% access data structure and count trials check whether a saved data file exists with today's date
    D = dir(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate,'/WCwaveform_',strDate,'_E',num2str(expNumber),'.mat']);
    if isempty(D)           % if no saved data exists then this is the first trial
        n=1 ;
    else                    %load current data file
        load(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate,'/WCwaveform_',strDate,'_E',num2str(expNumber),'.mat']','data');
        n = length(data)+1;
    end
    
%% set trial parameters     
    % Process time and stimulus info
    stimVolts = 5;
    sampRate = 10000;
    
    data(n).trialduration = trialDuration;                      % Trial duration (pre-stim, pinch valve, clean valve, post-stim)
    data(n).odorNum = odorNum; 
    
    % Create output commands
    outputData = zeros(sampRate * sum(trialDuration), 10);
    preStimOut = zeros(sampRate * trialDuration(1), 1);         % Make pre-stim output vector
    postStimOut = zeros(sampRate * trialDuration(4), 1);        % Make post-stim output vector
    pvStim = [preStimOut; ones(sampRate * (trialDuration(2) + trialDuration(3) + 1), 1); postStimOut(1:length(postStimOut)-sampRate)]; %(1:end-.002*sampRate)
    ivStim = [preStimOut; zeros(sampRate * trialDuration(2),1); ones(sampRate*trialDuration(3),1); postStimOut] * stimVolts;
           
    outputData(:, [1, odorNum + 1]) = [ivStim, ivStim];         % 3-way and active channel odor valves
    outputData(2:end-1, 6) = 1;                                 % Clean channel 2-way valve
    outputData(:, odorNum + 6) = [pvStim];                      % Active channel pinch valve
    outputData(end, :) = 0;

%     threeWayStim = [preStimOut; zeros(sampRate * trialDuration(2),1); ones(sampRate*trialDuration(3)/3,1); zeros(sampRate*trialDuration(3)*2/3,1); postStimOut];
%     outputData(:,1) = threeWayStim.*stimVolts;
   



    % experiment information
    data(n).date = strDate;                                     % experiment date
    data(n).expnumber = expNumber;                              % experiment number
    data(n).trial = n;                                          % trial number
    data(n).sampleTime = clock;
    data(n).acquisition_filename = mfilename('fullpath');       % saves name of mfile that generated data
    
    % sampling rates
    data(n).sampratein = sampRate;                                 % input sample rate
    data(n).samprateout = sampRate;                                % output sample rate becomes input rate as well when both input and output present    
    %% Session based acquisition code for inputs  
    
    %   CHANNEL SET-UP 
%    0  AMP 2 VAR OUT  2
%    1  AMP 2 Im  2
%    2  AMP 2 10Vm  2
%    3  AMP 2 GAIN  2   
    s = daq.createSession('ni');
 
    % Setup input channels
    s.addAnalogInputChannel('Dev1',0,'Voltage');
    s.Channels(1,1).InputType = 'SingleEnded';
    s.DurationInSeconds = sum(data(n).trialduration);
    s.Rate = data(n).sampratein;  
    
    % Setup output channels
    s.addAnalogOutputChannel('Dev1', 0 , 'Voltage');                % 3-way valve output channel
    s.addAnalogOutputChannel('Dev2', 0:3, 'Voltage');               % Odor valve output channels
    s.addDigitalChannel('Dev2', 'port0/line28:31', 'OutputOnly');   % Pinch valve and clean 2-way valve digital output
    
    % Queue output data and start scan
    s.Rate = data(n).samprateout;
    s.queueOutputData(outputData);
t(1) = toc; tL{1} = 'Trial start';
    x = s.startForeground();
t(2) = toc; tL{2} = 'Trial end';
    pid = x(:,1);      
    %data(n).rawOutput = x;
    
    %% PLOTS
    
    time = [1/data(n).sampratein:1/data(n).sampratein:sum(data(n).trialduration)];
    
    figure (1);clf; hold on
    set(gcf,'Position',[10 150 1650 800],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    plot(time, pid); %scaledOut) ;
    plot([(trialDuration(1)),(trialDuration(1))],ylim, 'Color', 'g')
    plot([(trialDuration(1)+trialDuration(2)),(trialDuration(1)+trialDuration(2))],ylim, 'Color', 'r')
    plot([sum(trialDuration(1:3)),sum(trialDuration(1:3))],ylim, 'Color', 'r')
    xlim([0, sum(trialDuration)]);
    ylim([-3.3, -2.3]);
    title(['Trial Number ' num2str(n) ]);
    ylabel('V');
    set(gca,'LooseInset',get(gca,'TightInset'))
    box off

    %% save data(n) to hard drive and to server
    save(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate,'/WCwaveform_' data(n).date,'_E',num2str(expNumber)],'data');
    save(['U:/Data Backup/', strDate,'/WCwaveform_' data(n).date,'_E',num2str(expNumber)],'data');
    save(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expNumber),'_',num2str(n)],'pid'); %, 'odor');   
    save(['U:/Data Backup/', strDate,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expNumber),'_',num2str(n)],'pid');
t(3) = toc; tL{3} = 'Finish saving';

dispStr = '';
for iToc = 1:length(t)
   dispStr = [dispStr, tL{iToc}, ': ', num2str(t(iToc), 2), '  ']; 
end
disp(dispStr)
