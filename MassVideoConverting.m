
parentDir = 'C:\Users\Wilson Lab\Documents\MATLAB\Data\_Movies\';
allMovies = dir([parentDir, '*20*']);

for iDate = 1:length(allMovies)
    myTrials = dir(fullfile(parentDir, allMovies(iDate).name, '*E*'));
    for iTrial = 1:length(myTrials)
        disp([fullfile(allMovies(iDate).name, myTrials(iTrial).name), '  t = ', toc]);
        tic
        myFrames = dir(fullfile(parentDir, allMovies(iDate).name, myTrials(iTrial).name, '*.tif'));
        myFrames = {myFrames.name}';
        outputVid = VideoWriter(fullfile(parentDir, allMovies(iDate).name, myTrials(iTrial).name, [myTrials(iTrial).name, '.avi']));
        outputVid.FrameRate = 30;
        open(outputVid)
        for iFrame = 1:length(myFrames)
            img = imread(fullfile(parentDir, allMovies(iDate).name, myTrials(iTrial).name, myFrames{iFrame}));
            writeVideo(outputVid, img);
        end
        close(outputVid)
    end
end
