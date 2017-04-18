

%% Load next exp

expData = loadExperiment('2017-Apr-14', 1);

%% CREATE MOVIES FROM .TIF FILES
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

%% ZIP RAW VIDEO FRAMES
strDate = expData.expInfo(1).date;
parentDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate);

zipFolders = dir(fullfile(parentDir, '*_T*'));
zipPaths = strcat([parentDir, '\'], {zipFolders.name});
zip(fullfile(parentDir,'rawVidData'), zipPaths); 

% Load next exp

expData = loadExperiment('2017-Apr-13', 1);

% ZIP RAW VIDEO FRAMES
strDate = expData.expInfo(1).date;
parentDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate);

zipFolders = dir(fullfile(parentDir, '*_T*'));
zipPaths = strcat([parentDir, '\'], {zipFolders.name});
zip(fullfile(parentDir,'rawVidData'), zipPaths); 