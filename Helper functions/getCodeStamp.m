%   getCodeStamp(callingFilePath)
%   JSB
%   AVB 2016
%   MM 2016
%
%       To get the stamp string just insert this line into the code that
%       you want the stamp string of. 
%            stampString = getCodeStamp(mfilename('fullpath'));
%
%       Returns a string with the name and short hash of the git
%       repository housing the calling function. It appends a * if there 
%       are uncommitted changes.
%
%%
function stampString = getCodeStamp(callingFilePath)  
    
    % Get the name and path of current git repository
%     repDir = char(regexp(callingFilePath,'(?<=GitHub\\)\w*','match'));
%     repPathStem = char(regexp(callingFilePath,'.*(?=GitHub)','match'));
%     repPath = [repPathStem,'GitHub\',repDir];
    repPath = 'C:\Users\Wilson Lab\Documents\MATLAB\ePhysCode\';
%     cd(repPath)

    % Get the current hash
    [status, shortHash] = system('git rev-parse --short HEAD');
    shortHash = regexprep(shortHash,'\n','');
    
    % Find out if the repository is current
    [status, gitStatus] = system('git status');
    if isempty(regexp(gitStatus,'working directory clean'))
        % Working directory isn't clean, there are un-committed changes
        currentFlag = '*';
        if ~isempty(regexp(gitStatus,'Not a git repository'))
            shortHash = 'NotAGitRepo';
        end
    else
        currentFlag = '';
    end
    stampString = [repPath,'-',shortHash,currentFlag];