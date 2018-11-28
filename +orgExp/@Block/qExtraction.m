function flag = qExtraction()
%% QEXTRACTION  Extract raw data files to Matlab BLOCK format using Isilon
%
%  flag = tankObj.QEXTRACTION
%
%  --------
%   OUTPUT
%  --------
%   flag       :     Returns true if conversion was successful.
%
%  By: Max Murphy v1.0  06/15/2018 Original version (R2017b)

%% DEFAULT CONVERSION CONSTANTS
% For filtering (these should be detected by TANK)
STIM_SUPPRESS = false;      % set true to do stimulus suppression (must change STIM_P_CH also)
STIM_P_CH = [nan nan];      % [probe, channel] for stimulation channel
STIM_BLANK = [0.2 1.75];    % [pre stim ms, post stim ms] for offline suppress
STATE_FILTER = true;

%% GET GENERIC INFO
% DIR = [UNC_PATH{1}, ...
%     tankObj.DIR((find(tankObj.DIR == filesep,1,'first')+1):end)];
% SAVELOC = [UNC_PATH{2}, ...
%     tankObj.SaveLoc((find(tankObj.SaveLoc == filesep,1,'first')+1):end)];

%% GET CURRENT VERSION INFORMATION WIP
% [repoPath, ~] = fileparts(mfilename('fullpath'));
% gitInfo = getGitInfo(repoPath);
% attach_files = dir(fullfile(repoPath,'**'));
% attach_files = attach_files((~contains({attach_files(:).folder},'.git')))';
% dir_files = ~cell2mat({attach_files(:).isdir})';
% ATTACHED_FILES = fullfile({attach_files(dir_files).folder},...
%     {attach_files(dir_files).name})';

%% PARSE NAME DEPENDING ON RECORDING TYPE

flag = false; % if returns before completion, indicate failure to complete.

switch blockObj.RecType
   case 'Intan'
      
      switch blockObj.File_extension
         case '.rhs'
            blockObj.RHS2Block();
         case '.rhd'
            blockObj.RHD2Block();
         otherwise
            warning('Invalid file type (%s).',blockObj.File_extension);
            return;
      end
      
   case 'TDT'
      warning('%s is not yet supported, but will be added.',blockObj.RecType);
      return;
      
   case 'mat'
      warning('%s is not yet supported, but will be added.',blockObj.RecType);
      return;
      
   otherwise
      warning('%s is not a supported acquisition system (case-sensitive).',blockObj.RecType);
      return;
end

fprintf(1,'complete.\n');
blockObj.updateStatus('Raw',true);
flag = true;

end