%   getCodeStamp(callingFilePath)
%   JSB
%   AVB 2016
%   MM 2017
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
function stampString = get_code_stamp(callingFilePath)  
    
    % Get the name and path of current git repository
%     repDir = char(regexp(callingFilePath,'(?<=GitHub\\)\w*','match'));
%     repPathStem = char(regexp(callingFilePath,'.*(?=GitHub)','match'));
%     repPath = [repPathStem,'GitHub\',repDir];
%     cd(repPath)

    % Hardcoding to only work with MATLAB code repository because mine doesn't have "GitHub" in the path
    repPath = 'C:\Users\Wilson Lab\Documents\MATLAB\ePhysCode\';
    
    % Get the current hash
    [status, shortHash] = system('cd C:\Users\Wilson Lab\Documents\MATLAB\ePhysCode\ & "C:\Users\Wilson Lab\AppData\Local\GitHub\PortableGit_f02737a78695063deace08e96d5042710d3e32db\cmd\git.exe" rev-parse --short HEAD');
    shortHash = regexprep(shortHash,'\n','');
    
    % Find out if the repository is current
    [status, gitStatus] = system('cd C:\Users\Wilson Lab\Documents\MATLAB\ePhysCode\ & "C:\Users\Wilson Lab\AppData\Local\GitHub\PortableGit_f02737a78695063deace08e96d5042710d3e32db\cmd\git.exe" status');
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