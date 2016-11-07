function data = AcquisitionCode_MM(expnumber,trialduration)

% expnumber = experiment (fly or cell) number
% Raw data sampled at 10kHz and saved as separate waveforms for each trial
% Odor always on from 8 to 8.5 seconds, will have to pass in more inputs to
% change that. Telegraphed variable gain outputs are interpreted as if the
% A-M systems 2400 amplifier is in current clamp.
% 
   
%     %%load stimulus: if stim is complicated, save a vector to be used as stim output waveform as mat file then load it
%     load(['C:\Quentin\ChRd_stim\' stimloc],'stim','samprate');
%     stim = stim';  % make sure stim is a column vector 

%%  make a directory if one does not exist
    if ~isdir(date)
        mkdir(date);
    end  

    %% access data structure and count trials check whether a saved data file exists with today's date
    D = dir([date,'/WCwaveform_',date,'_E',num2str(expnumber),'.mat']);
    if isempty(D)           % if no saved data exists then this is the first trial
        n=1 ;
    else                    %load current data file
        load([date,'/WCwaveform_',date,'_E',num2str(expnumber),'.mat']','data');
        n = length(data)+1;
    end
   
    %% set trial parameters  
    % experiment information
    data(n).date = date;                                 % experiment date
    data(n).expnumber = expnumber;                          % experiment number
    data(n).trial = n;                                        % trial number
    data(n).sampleTime = clock;
    data(n).acquisition_filename = mfilename('fullpath');    %saves name of mfile that generated data
    % sampling rates
    data(n).sampratein = 10000;                              % input sample rate
    data(n).samprateout = 10000;                           % output sample rate becomes input rate as well when both input and output present
    data(n).trialduration = trialduration;                            % trial duration

        % to pass in odor pulse parameters and manipulate them across
        % trials include these in the function definition line
        % data(n).odoronset = odoronset;                   % odor on time to
        % data(n).odorduration = odorduration;             % odor duration

    % amplifier gains to be read or used
    data(n).variableGain1 = NaN;                             %Amplifier 1 alpha
    data(n).variableOffset1 = NaN;                          %Amplifier 1 variable output offset. Determined emperically.
    data(n).ImGain1 = 10;                              
    data(n).ImOffset1 = 0;                             
%     data(n).variableGain2 = NaN;                            %Amplifier 2 alpha.
%     data(n).variableOffset2 = NaN;                          %Amplifier 2 variable output offset. Determined emperically.
%     data(n).ImGain2 = 10;                             
%     data(n).ImOffset2 = 0;                            %Amplifier 2 fixed output offset. Determined emperically.
%   
    %     %make column vector for odor command signal odor always comes on at 8s
    %     data(n).nsampout = data(n).samprateout*data(n).trialduration;
    %     data(n).odoronsetsamp = 8*data(n).samprateout+1; % odor onset sample
    %     data(n).odoroffsetsamp = data(n).odoronsetsamp+(data(n).odorduration*data(n).samprateout)-1; % odor offset sample
    %     data(n).OdorCommand = zeros(data(n).nsampout,1); % make zeros vector
    %     data(n).OdorCommand(data(n).odoronsetsamp:data(n).odoroffsetsamp) = (5*ones((data(n).odorduration*data(n).samprateout),1)) ; % make 5V during odor pulse. 
    %     data(n).OdorCommand = data(n).OdorCommand';
   
    
    %make column vector for use as master8 trigger
%    data(n).Master8Trigger = [ (6*ones(100,1)) ; (zeros(((data(n).trialduration*data(n).samprateout)-100),1)) ] ;                          
%    data(n).sampleTimeinexp = round(etime(data(n).sampleTime, data(1).sampleTime));
   
   

    %% Session based acquisition code for inputs  
    %   CHANNEL SET-UP 
%    0  AMP 2 VAR OUT  2
%    1  AMP 2 Im  2
%    2  AMP 2 10Vm  2
%    3  AMP 2 GAIN  2   

    s = daq.createSession('ni');
    
    s.addAnalogInputChannel('Dev1',[0:3],'Voltage');
    
    for i=1:4
        s.Channels(1,i).InputType = 'SingleEnded';
    end
    
     s.DurationInSeconds = data(n).trialduration;
     s.Rate = data(n).sampratein;
 
    s.addAnalogOutputChannel('Dev1', [0] , 'Voltage');  
    s.Rate = data(n).samprateout;
    
    td = ones(40000,1);
    
    %td = repmat([0 0 0 1]', 10000, 1);
    testData = [td*0; td*10; td*0; td*10;];% td*0; td*2; td*0; td*2];
    testData(end) = 0;
    s.queueOutputData(testData);       
    x = s.startForeground();
    
       Gain1reading = mean(x(:,4));
    if Gain1reading > 0 && Gain1reading < 2.34
        data(n).variableGain1 = 0.5;
    elseif Gain1reading > 2.34 && Gain1reading < 2.85
        data(n).variableGain1 = 1;
    elseif Gain1reading > 2.85 && Gain1reading < 3.34
        data(n).variableGain1 = 2;
    elseif Gain1reading > 3.34 && Gain1reading < 3.85
        data(n).variableGain1 = 5;
    elseif Gain1reading > 3.85 && Gain1reading < 4.37
        data(n).variableGain1 = 10;
    elseif Gain1reading > 4.37 && Gain1reading < 4.85
        data(n).variableGain1 = 20;
    elseif Gain1reading > 4.85 && Gain1reading < 5.34
        data(n).variableGain1 = 50;
   elseif Gain1reading > 5.34 && Gain1reading < 5.85
        data(n).variableGain1 = 100;
    elseif Gain1reading > 5.85 && Gain1reading < 6.37
        data(n).variableGain1 = 200;
    elseif Gain1reading > 6.37 && Gain1reading < 6.85
        data(n).variableGain1 = 500;
    end
 
    
data(n).variableGain1
 
    
    scaledOut = (x(:,1)/data(n).variableGain1)*1000; % mV   %+data(n).variableOffset1;
    current1 = (x(:,2)/data(n).ImGain1)*1000; % pA  %+data(n).ImOffset1; 
  
    tenVm1 = x(:,3)*1000/10; 
    
   % data(n).odorpulse = x(:,7); 
   % odor = data(n).odorpulse - mean(data(n).odorpulse(1:1000));
    
      
    %% Calculate input resistance and membrane potential 

    
%     data(n).Rin1 =1000*(((mean(scaledOut(100:1900)))- mean(scaledOut(5100:6900)))/...
%         ((mean(current1(100:1900))-mean(current1(5100:6900)))));
%     
%     if isnan(data(n).Rin1)
%         data(n).Rin1 = 0;
%     end
%        
% %     data(n).Rin2 =1000*(((mean(voltage2(100:1900)))- mean(voltage2(5100:6900)))/...
% %         ((mean(current2(100:1900))-mean(current2(5100:6900)))));
% %     if isnan(data(n).Rin2)
% %         data(n).Rin2 = 0;
% %     end
% %          
%     data(n).Vrest1 =  mean(scaledOut(1:200));
% %     data(n).Vrest2 =  mean(voltage2(1:200));
%     
%     sampletimes = NaN(length(data),1); IR1 = NaN(length(data),1);% IR2 = NaN(length(data),1);
%     
%     VR1 = NaN(length(data),1);% VR2 = NaN(length(data),1);
%     
%     for i=1:length(data); 
%         sampletimes(i) = data(i).sampleTimeinexp;
%         IR1(i)=data(i).Rin1; 
%         VR1(i)=data(i).Vrest1; 
%     end % IR2(i)=data(i).Rin2; VR2(i)=data(i).Vrest2; end
        
        

    %% PLOTS
    
    time = [1/data(n).sampratein:1/data(n).sampratein:data(n).trialduration];
    
    figure (1); 
    set(gcf,'Position',[25 350 1250 550],'Color',[1 1 1]);
    plot(time, scaledOut) ;
    title(['Trial Number ' num2str(n) ]);
    ylabel('Vm (mV)');
   % set(gca, 'Xlim',[0 data(n).trialduration*data(n).sampratein]);
    %set(gca, 'XTick', 0:((data(n).trialduration*data(n).sampratein)/4):(data(n).trialduration*data(n).sampratein))
   % set(gca, 'XTickLabel', {0 , num2str((data(n).trialduration/4)), num2str((data(n).trialduration/2)),num2str((data(n).trialduration*0.75)),num2str((data(n).trialduration))}) ;
   % set(gca, 'Ylim' , [-70 0]);

    box off
    
    figure (2);
    plot(time, current1); 
    set(gcf,'Position',[25 50 1250 200],'Color',[1 1 1]);
    ylabel('Im (pA)');
   % set(gca,'Xlim',[0 data(n).trialduration*data(n).sampratein]);
   % set(gca,'XTick', 0:((data(n).trialduration*data(n).sampratein)/4):(data(n).trialduration*data(n).sampratein))
   % set(gca, 'XTickLabel', {0 , num2str((data(n).trialduration/4)), num2str((data(n).trialduration/2)),num2str((data(n).trialduration*0.75)),num2str((data(n).trialduration))}) ;
    box off;
    
   
    
%     figure(3);
%     subplot(2,1,1), plot(sampletimes, IR1,'LineStyle','none','Marker','o',...
%         'MarkerSize',7,'MarkerFaceColor', [0 0.4 0], 'MarkerEdgeColor', 'none' );
%     ylabel('Rin (MOhm)');
%     set(gca, 'Ylim' , [0 6000]);
%     subplot(2,1,2), plot(sampletimes, VR1, 'LineStyle','none','Marker','o',...
%         'markersize',7,'markerfacecolor', [0.6 0 0.4], 'markeredgecolor', 'none');
%     set(gcf,'Position',[875 700 400 250],'Color',[0.8 0.4 0]);
%     ylabel('Vrest (mV)');


%     figure (4);
%     set(gcf,'Position',[1300 400 1250 550],'Color',[1 1 1]);
%     plot(voltage2) ;
%     title(['Trial Number ' num2str(n) ]);
%     ylabel('Vm (mV)');
%     set(gca,'Xlim',[0 data(n).trialduration*data(n).sampratein]);
%     set(gca,'XTick', 0:((data(n).trialduration*data(n).sampratein)/4):(data(n).trialduration*data(n).sampratein))
%     set(gca, 'XTickLabel', {0 , num2str((data(n).trialduration/4)), num2str((data(n).trialduration/2)),num2str((data(n).trialduration*0.75)),num2str((data(n).trialduration))}) ;
%     set(gca, 'Ylim' , [-80 0]);
%     box off
%     
%     figure (5);
%     plot(current2); 
%     set(gcf,'Position',[1300 100 1250 200],'Color',[1 1 1]);
%     ylabel('Im (pA)');
%     set(gca,'Xlim',[0 data(n).trialduration*data(n).sampratein]);
%     set(gca,'XTick', 0:((data(n).trialduration*data(n).sampratein)/4):(data(n).trialduration*data(n).sampratein))
%     set(gca, 'XTickLabel', {0 , num2str((data(n).trialduration/4)), num2str((data(n).trialduration/2)),num2str((data(n).trialduration*0.75)),num2str((data(n).trialduration))}) ;
%     box off;
%     
%     figure(6);
%     subplot(2,1,1), plot(sampletimes, IR2,'LineStyle','none','Marker','o',...
%         'MarkerSize',7,'MarkerFaceColor', [0 0.4 0], 'MarkerEdgeColor', 'none' );
%     title('Input Resistance and Resting Potential');
%     ylabel('Rin (MOhm)');
%     subplot(2,1,2), plot(sampletimes, VR2, 'LineStyle','none','Marker','o',...
%         'markersize',7,'markerfacecolor', [0.6 0 0.4], 'markeredgecolor', 'none');
%     set(gcf,'Position',[2125 100 450 300],'Color',[0.8 0.4 0]);
%     ylabel('Vrest (mV)');
%     
    
    
    %% save data(n)
    save([date,'/WCwaveform_' data(n).date,'_E',num2str(expnumber)],'data');
    save([date,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expnumber),'_',num2str(n)],'current1','scaledOut','tenVm1') %, 'odor');
    

