function data = initialPatchingAcq(expNumber)
% ===============================================================================================================
% expnumber = experiment (fly or cell) number
% Raw data sampled at 100 kHz and saved in a single file.
% ===============================================================================================================

% SETUP TRIAL PARAMETERS
    
    % Run initial setup function
    [data, n] = acquisitionSetup(expNumber,[], [], [], [], [], [], []);
    
    % Make sure this is the first trial of the experiment, but give user an out for flexibility
    inputStr = 'initStr';
    if n>1
       while ~strcmp(inputStr, 'y') && ~strcmp(inputStr, 'n')
        inputStr = input([char(10), 'This will not be the first trial of this experiment. Are you sure you want to continue? y/n: '], 's'); 
       end
       if strcmp(inputStr, 'n')
           disp([char(10), 'Initial acquisition abandoned']);
           return
       end
    end
    
    data(n).sampratein = 80000;
    data(n).samprateout = 80000;
    sampRate = data(n).sampratein;
    data(n).acquisition_filename = mfilename('fullpath');       % saves name of mfile that generated data
    
%% SESSION-BASED ACQUISITION CODE
    
%    CHANNEL SET-UP:
%       0  Scaled Out 
%       1  Im  
%       2  10Vm  
%       3  Amplifier Gain (Alpha)
%       4  Amplifier Filter Freq
%       5  Amplifier Mode
    
    % Setup session and input channels
    s = daq.createSession('ni');
    s.Rate = data(n).sampratein;
    s.addAnalogInputChannel('Dev2', 0:5,'Voltage');
    for iChan=1:6
        s.Channels(1,iChan).InputType = 'SingleEnded';
    end
    s.IsContinuous = true;
    lh = addlistener(s,'DataAvailable', @contAcqSave);
    assignin('base', 'x', []);
    startBackground(s);
    
    % Wait for user to end acquisition and ask whether to save or delete the data

    while ~strcmp(inputStr, '') && ~strcmp(inputStr,'d')
    inputStr = input('Press [Enter] to accept initial acquisition data, or enter "d" to delete it: ', 's');
    end
    
    % End acquisition and trim to nearest second
    s.stop();
    x = evalin('base', 'x'); % Pull data in from base workspace
    data(n).trialduration = floor(size(x, 1) / sampRate); % Round duration down to nearest second
    x = x(1:data(n).trialduration*sampRate,:); % Trim to the nearest second
%     x = [x(:,1),zeros(size(x,1),2),x(:,2:4)]; % Pad with empty vectors for I and 10Vm
    s.IsContinuous = false;
    delete(lh)
    
%% RUN POST-PROCESSING AND SAVE DATA
if strcmp(inputStr, 'd')
    disp([char(10), 'Initial acquisition data discarded']);
else
    disp([char(10), 'Saving initial acquisition data...']);
    [data, current, scaledOut, tenVm] = acquisitionPostProcessing(data, x, n);
    disp('Initial acquisition data saved');
% PLOT FIGURES
    
    time = 1/data(n).sampratein:1/data(n).sampratein:data(n).trialduration;
    
    peaks = findpeaks(scaledOut, 'MinPeakHeight', 200);
    assignin('base', 'peaks', peaks)
    
    figure (1);clf; hold on
    set(gcf,'Position',[10 550 1850 400],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    plot(time(.05*sampRate:end), scaledOut(.05*sampRate:end));
    if strcmp(data(n).scaledOutMode, 'V')
        ylabel('Vm (mV)');
    elseif strcmp(data(n).scaledOutMode, 'I')
        ylabel('Im (pA)');
    end
    title(['Trial Number ' num2str(n) ]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    box off
    
end
