 


    % Setup session and input channels
    s = daq.createSession('ni');
    
    duration = 5;
    s.Rate = 10000;
    frameRate = 30;
    
    triggerInterval = round(s.Rate / frameRate);
    
    s.addAnalogInputChannel('Dev2', 0,'Voltage');
    for iChan=1
        s.Channels(1,iChan).InputType = 'SingleEnded';
    end
    
    % Setup output channels
    s.addDigitalChannel('Dev2', 'port0/line28', 'OutputOnly');         

    % Setup strobe input channel
%     s.addCounterInputChannel('Dev2', 'ctr0', 'EdgeCount');
    s.addDigitalChannel('Dev2', 'port0/line29', 'InputOnly');      
    
    % Load output data for each channel
    outputData = zeros(duration * s.Rate, 1);
    outputData(1:triggerInterval:end) = 1;
    sum(outputData)
    s.queueOutputData(outputData); 
        

    rawAcqData = s.startForeground();
    s.stop()
