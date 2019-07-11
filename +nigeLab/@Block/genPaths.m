function flag = genPaths(blockObj,animalLoc,useRemote)
%% GENPATHS    Set some useful path variables to file locations
%
%  flag = GENPATHS(blockObj);
%  flag = GENPATHS(blockObj,animalLoc);
%  flag = GENPATHS(blockObj,animalLoc,useRemote);
%
%     Here are defined all the paths where data will be saved.
%     The folder tree is also created here(if not already existing)
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% 
flag = false;
if (nargin > 1)
   blockObj.AnimalLoc = animalLoc;
%    if isempty(blockObj.Paths)
%       paths.Animal_ext = {animalLoc};
%       paths.Animal_idx = 1;
%    else
%       paths.Animal_ext = [blockObj.Paths.Animal_ext; {animalLoc}];
%       paths.Animal_idx = numel(blockObj.Paths.Animal_ext);
%    end
% else
%    paths.Animal     = fullfile(blockObj.AnimalLoc);
%    paths.Animal_ext = {fullfile(blockObj.AnimalLoc)};
%    paths.Animal_idx = 1;
end

if nargin < 3
   useRemote = false;
end

% paths.Animal.dir = blockObj.AnimalLoc;
paths.SaveLoc.dir = fullfile(blockObj.AnimalLoc,blockObj.Name);
paths = blockObj.getFolderTree(paths,useRemote);
F=fields(paths);
for ff=1:numel(F)
   if ~exist(paths.(F{ff}).dir,'dir')
      mkdir(paths.(F{ff}).dir);
   end 
end
blockObj.Paths = paths;
flag = true;

end