function backupLogTransfer()
% Copy any paths that are not from today from "PendingBackup" to 
% "BackupQueueFile", then start the backup script in the background.

transferPaths = {};
pendingPaths = {};
strDate = datestr(now, 'yyyy-mmm-dd');

% Pull out all paths from the pending file
pending = fopen('C:/Users/Wilson Lab/Documents/MATLAB/Data/_Server backup logs/PendingBackup.txt', 'rt');
while true
    myLine = fgetl(pending);
    if ~ischar(myLine)
        break
    end 
    
    % Sort them into two categories based on whether they contain today's date
    if ~isempty(strfind(myLine,strDate))
        pendingPaths{end+1} = myLine;
    else
        transferPaths{end+1} = myLine;
    end
end
fclose('all');

% Append older paths to backupQueueFile
backupFile = fopen('C:/Users/Wilson Lab/Documents/MATLAB/Data/_Server backup logs/BackupQueueFile.txt', 'a');
if ~isempty(transferPaths)
    fprintf(backupFile, [transferPaths{1}]);
    if length(transferPaths) > 1
        for iLine = 2:length(transferPaths)
            fprintf(backupFile, ['\r\n', transferPaths{iLine}]);
        end
    end
end
fclose('all');

% Clear and re-write pending paths file as necessary
newPending = fopen('C:/Users/Wilson Lab/Documents/MATLAB/Data/_Server backup logs/PendingBackup.txt', 'w');
if ~isempty(pendingPaths)  
    fprintf(newPending, [pendingPaths{1}]);
    if length(pendingPaths) > 1
        for iLine = 1:length(pendingPaths)
            fprintf(newPending, ['\r\n', pendingPaths{iLine}]);
        end
    end
end
fclose('all');

% If necessary, start a background process to actually back data up to the server
if ~isempty(transferPaths)
    !set PATH=C:\Program Files\Anaconda3\;%PATH%&python "C:\Users\Wilson Lab\Documents\Python\dataBackupScript.py" &
end

end