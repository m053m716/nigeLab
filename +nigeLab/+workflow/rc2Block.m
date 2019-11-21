function rc2Block(recFile,animalLoc,p)
%% RC2BLOCK    Convert from RC format to BLOCK format
%
%  RC2BLOCK(recFile,animalLoc,p);
%
%  Note: This converison function checks if files exist in each of the
%           folders to which "converted" data is to be moved. If those
%           folders have any *.mat files in them, then the corresponding
%           folder datatype "conversion" is skipped.
%
%  --------
%   INPUTS
%  --------
%  recFile  :  Full filename of "recording file" (here, '_ChannelInfo.mat'
%                 that is known to reside in the base folder of a Block
%                 hierarchy that is similar, but not identical, to the
%                 nigeLab Block hierarchy). 
%
%  animalLoc : Full path to where the output animal folder will go
%                 (including name of the animal).
%
%  p        : BlockPars Parameters property struct with path info

%% Parse input
% Make sure that input file exists
if exist(recFile,'file')==0
   error('No file: %s\n',recFile);
end

% Make sure that output location exists
if exist(animalLoc,'dir')==0
   fprintf(1,'%s does not exist. New save location created.\n',animalLoc);
   mkdir(animalLoc);
end

nigeLab.utils.cprintf('SystemCommands','-->\tConverting %s\n',recFile);
nigeLab.utils.cprintf('SystemCommands','\t-->\tAt: %s\n',animalLoc);

%% Get file structure from file name basically
[path,fname,~] = fileparts(recFile);
blockName = strsplit(fname,'_');
blockName = strjoin(blockName(1:4),'_');
block_in = fullfile(path);
block_out = fullfile(animalLoc,blockName);
if exist(block_out,'dir')==0
   mkdir(block_out);
end

%% Move digital streams
% Make the new '_Digital' folder and move files
f_in = fullfile(block_in,[blockName '_Digital']);
f_out = fullfile(block_out,p.DigIO.Folder);

F = dir(fullfile(f_in,[blockName '*.mat']));
for iF = 1:numel(F)
   str_info = strsplit(F(iF).name(1:(end-4)),'_');
   dtype = str_info{end};
   if ismember(dtype,{'Beam','Press','Paw'})
      in = load(fullfile(F(iF).folder,F(iF).name),'data');
      data = in.data;
      save(fullfile(f_out,sprintf(p.DigIO.File,'DigIn',dtype)),'data','-v7.3');
   elseif ismember(dtype,{'Scoring','VideoAlignment'})
      copyfile(fullfile(F(iF).folder,F(iF).name),...
         fullfile(f_out,sprintf(p.DigEvents.File,dtype)));
   end
end

%% Move filtered and raw streams
% Raw
f_in = fullfile(block_in,[blockName '_RawData']);
f_out = fullfile(block_out,p.Raw.Folder);
Fout = dir(fullfile(f_out,'*.mat'));
if isempty(Fout)
   F = dir(fullfile(f_in,[blockName '*.mat']));
   for iF = 1:numel(F)
      str_info = strsplit(F(iF).name(1:(end-4)),'_');
      ch = str_info{end};
      probe = str_info{end-2}(2);

      in = load(fullfile(F(iF).folder,F(iF).name),'data');
      data = in.data;
      save(fullfile(f_out,sprintf(p.Raw.File,probe,ch)),'data','-v7.3');
   end
end


% Filtered
f_in = fullfile(block_in,[blockName '_FilteredCAR']);
f_out = fullfile(block_out,p.CAR.Folder);

Fout = dir(fullfile(f_out,'*.mat'));
if isempty(Fout)
   F = dir(fullfile(f_in,[blockName '*.mat']));
   for iF = 1:numel(F)
      str_info = strsplit(F(iF).name(1:(end-4)),'_');
      ch = str_info{end};
      probe = str_info{end-2}(2);

      in = load(fullfile(F(iF).folder,F(iF).name),'data');
      data = in.data;
      save(fullfile(f_out,sprintf(p.CAR.File,probe,ch)),'data','-v7.3');
   end
end

%% Move Spikes & Clusters (those will have to be converted in a different way, later)
% Spikes
f_in = fullfile(block_in,[blockName '_wav-sneo_Car_Spikes']);
f_out = fullfile(block_out,sprintf(p.Spikes.Folder,'wav-sneo_CAR'));

Fout = dir(fullfile(f_out,'*.mat'));
if isempty(Fout)
F = dir(fullfile(f_in,[blockName '*.mat']));
   for iF = 1:numel(F)
      str_info = strsplit(F(iF).name(1:(end-4)),'_');
      ch = str_info{end};
      probe = str_info{end-2}(2);

      copyfile(fullfile(F(iF).folder,F(iF).name),...
         fullfile(f_out,sprintf(p.Spikes.File,probe,ch)));
   end
end

% Clusters
f_in = fullfile(block_in,[blockName '_wav-sneo_SPC_Car_Clusters']);
f_out = fullfile(block_out,sprintf(p.Clusters.Folder,'wav-sneo_SPC_CAR'));

Fout = dir(fullfile(f_out,'*.mat'));
if isempty(Fout)
F = dir(fullfile(f_in,[blockName '*.mat']));
   for iF = 1:numel(F)
      str_info = strsplit(F(iF).name(1:(end-4)),'_');
      ch = str_info{end};
      probe = str_info{end-2}(2);

      copyfile(fullfile(F(iF).folder,F(iF).name),...
         fullfile(f_out,sprintf(p.Clusters.File,probe,ch)));
   end
end

end