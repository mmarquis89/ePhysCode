function out = plotVoltage(trialNum, expNum, expDate)

    load([expDate,'/Raw_WCwaveform_',expDate,'_E',num2str(expNum), '_', num2str(trialNum),'.mat']');
    load([expDate,'/WCwaveform_',expDate,'_E',num2str(expNum),'.mat']','data');
    
    time = [1/data(trialNum).sampratein:1/data(trialNum).sampratein:sum(data(trialNum).trialduration)];
    
    figure (1);clf; hold on
    set(gcf,'Position',[25 350 1250 550],'Color',[1 1 1]);
    plot(time, scaledOut) ;
    plot([(data(trialNum).trialduration(1)),(data(trialNum).trialduration(1))],ylim, 'Color', 'red')
    
    title(['Trial Number ' num2str(trialNum) ]);
    ylabel('Vm (mV)');
   % set(gca, 'Xlim',[0 data(n).trialduration*data(n).sampratein]);
    %set(gca, 'XTick', 0:((data(n).trialduration*data(n).sampratein)/4):(data(n).trialduration*data(n).sampratein))
   % set(gca, 'XTickLabel', {0 , num2str((data(n).trialduration/4)), num2str((data(n).trialduration/2)),num2str((data(n).trialduration*0.75)),num2str((data(n).trialduration))}) ;
   % set(gca, 'Ylim' , [-70 0]);

    box off
end