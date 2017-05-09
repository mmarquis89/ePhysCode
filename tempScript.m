   
    %% LOAD EXPERIMENT
disp('Loading experiment...');
expData = loadExperiment('2017-May-08', 1);
disp('Experiment loaded');

%% VIDEO PROCESSING
    % CREATE MOVIES FROM .TIF FILES
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    msg = makeVids(expData, parentDir);
    disp(msg);

    % CALCULATE OR LOAD MEAN OPTICAL FLOW
    strDate = expData.expInfo(1).date;
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    savePath = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']);

    if isempty(dir(savePath))
        disp('Calculating optic flow...')
        allFlow = opticFlowCalc(expData, parentDir, savePath);
        disp('Optic flow calculated successfully')
    else
        disp('Loading optic flow...')
        load(savePath);
        disp('Optic flow data loaded')
    end
    
    % CREATE COMBINED PLOTTING VIDEOS
    strDate = expData.expInfo(1).date;
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    flowDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']);
    savePath = fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots']);

    msg = makePlottingVids(expData, parentDir, flowDir, savePath);
    disp(msg);

    % CONCATENATE ALL MOVIES+PLOTS FOR THE EXPERIMENT
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    msg = concatenateVids(expData, parentDir);
    disp(msg);

    % ZIP RAW VIDEO FRAMES
    strDate = expData.expInfo(1).date;
    parentDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate);

    zipFolders = dir(fullfile(parentDir, ['*', num2str(expData.expInfo(1).expNum), '_T*']));
    zipPaths = strcat([parentDir, '\'], {zipFolders.name});
    disp('Zipping raw video data...');
    zip(fullfile(parentDir,['rawVidData_E', num2str(expData.expInfo(1).expNum)]), zipPaths); 
    disp('Zipping completed');
    
    % DELETE RAW VIDEO DATA AFTER ARCHIVING
    strDate = expData.expInfo(1).date;
    parentDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate);
    delFolders = dir(fullfile(parentDir, ['*', num2str(expData.expInfo(1).expNum), '_T*']));
    zipDir = dir(fullfile(parentDir,['rawVidData_E', num2str(expData.expInfo(1).expNum), '.zip']));
    if isempty(zipDir)
        disp('Error — no zipped folder was found for this experiment');
    else
        disp('Deleting raw video frames...');
        for iFolder = 1:length(delFolders)
            disp(delFolders(iFolder).name);
            rmdir(fullfile(parentDir, delFolders(iFolder).name), 's');
        end
        disp('Raw video frames deleted');  
    end%if
    
    %% LOAD EXPERIMENT
disp('Loading experiment...');
expData = loadExperiment('2017-May-08', 2);
disp('Experiment loaded');

%% VIDEO PROCESSING
    % CREATE MOVIES FROM .TIF FILES
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    msg = makeVids(expData, parentDir);
    disp(msg);

    % CALCULATE OR LOAD MEAN OPTICAL FLOW
    strDate = expData.expInfo(1).date;
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    savePath = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']);

    if isempty(dir(savePath))
        disp('Calculating optic flow...')
        allFlow = opticFlowCalc(expData, parentDir, savePath);
        disp('Optic flow calculated successfully')
    else
        disp('Loading optic flow...')
        load(savePath);
        disp('Optic flow data loaded')
    end
    
    % CREATE COMBINED PLOTTING VIDEOS
    strDate = expData.expInfo(1).date;
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    flowDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']);
    savePath = fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots']);

    msg = makePlottingVids(expData, parentDir, flowDir, savePath);
    disp(msg);

    % CONCATENATE ALL MOVIES+PLOTS FOR THE EXPERIMENT
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    msg = concatenateVids(expData, parentDir);
    disp(msg);

    % ZIP RAW VIDEO FRAMES
    strDate = expData.expInfo(1).date;
    parentDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate);

    zipFolders = dir(fullfile(parentDir, ['*', num2str(expData.expInfo(1).expNum), '_T*']));
    zipPaths = strcat([parentDir, '\'], {zipFolders.name});
    disp('Zipping raw video data...');
    zip(fullfile(parentDir,['rawVidData_E', num2str(expData.expInfo(1).expNum)]), zipPaths); 
    disp('Zipping completed');
    
    % DELETE RAW VIDEO DATA AFTER ARCHIVING
    strDate = expData.expInfo(1).date;
    parentDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate);
    delFolders = dir(fullfile(parentDir, ['*', num2str(expData.expInfo(1).expNum), '_T*']));
    zipDir = dir(fullfile(parentDir,['rawVidData_E', num2str(expData.expInfo(1).expNum), '.zip']));
    if isempty(zipDir)
        disp('Error — no zipped folder was found for this experiment');
    else
        disp('Deleting raw video frames...');
        for iFolder = 1:length(delFolders)
            disp(delFolders(iFolder).name);
            rmdir(fullfile(parentDir, delFolders(iFolder).name), 's');
        end
        disp('Raw video frames deleted');  
    end%if