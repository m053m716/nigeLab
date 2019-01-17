function [pars,Fields] = Block()
%% defaults.Block  Sets default parameters for BLOCK object
%
%  [pars,Fields] = nigeLab.defaults.Block();
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% Modify all properties here
% Define general values used when parsing metadata from file name and
% structure:
pars             = struct;

pars.RecLocDefault  = 'R:/Rat';

pars.SaveFormat  = 'Hybrid'; % refers to save/load format
pars.AnimalLocDefault = 'P:/Rat';
pars.ForceSaveLoc = true; % create directory if save location doesn't exist

pars.Delimiter   = '_'; % delimiter for variables in BLOCK name

% Bookkeeping for tags to be appended to different FieldTypes. The total
% number of fields of TAG determines the valid entries for FieldTypes.
TAG = struct;
TAG.Channels = ... % Channels: neurophysiological recording channels
   [pars.Delimiter 'P%s',...
   pars.Delimiter 'Ch',...
   pars.Delimiter '%s.mat'];
TAG.Events = ... % Events: asynchronous events with associated values
   [pars.Delimiter '%s', ...
   pars.Delimiter 'Events.mat'];
TAG.Meta = ... % Meta: generic recording metadata (notes, probe configs)
   [pars.Delimiter '%s'];
TAG.Streams = ... % Streams: for example, stream of zeros/ones for event
   [pars.Delimiter '%s', ...
   pars.Delimiter '%s', ...
   pars.Delimiter 'Stream.mat'];


%% Here You can specify the naming format of your block recording
% The block name will be splitted using Delimiter (defined above) and each
% segment will be assigned to the property definied here.
% Using namingConvention you can define to what varible each piece of the
% block name should be assigned to. Use the includeChar and discardChar to
% specify if that piece of info should be kept or discarded when creating
% the BLOCK name from the RECORDING name.
%
% Example 1
% ---------
% The recording name R18-68_2018_07_24_0_180724_141203.rhd, with dynamic
% parsing and naming conventions set as:
%
% pars.DynamicVarExp='$Animal_ID $Year $Month $Day $Rec_ID $Rec_date $Rec_time';
% pars.IncludeChar='$';
% pars.DiscardChar='&';
% pars.NamingConvention={'Animal_ID','Year','Month','Day','Rec_ID'};
%
% Will still extract the Recording_date and Recording_time directly from
% the name (if they are present). However, the block name in the specified
% save location (here, 'path') will be:
%
% ~/path/R18-68_2018_07_24_0
%
% Example 2
% ---------
%
% Alternatively, specifying:
%
% pars.DynamicVarExp='$Animal_ID &Year &Month &Day $Rec_ID $Rec_date $Rec_time';
% pars.IncludeChar='$';
% pars.DischardChar='&';
% pars.NamingConvention={'Animal_ID','Rec_ID','Rec_date','Rec_time'};
%
% Will also extract Recording_date and Recording_time, but will not parse
% variables for 'Year,' 'Month,' or 'Date.'
% The BLOCK will be named:
%
% ~/path/R18-68_0_180724_141203

% pars.DynamicVarExp='&Tag $Animal_ID $Rec_ID'; % IIT
pars.DynamicVarExp='$Animal_ID $Year $Month $Day $Rec_ID $Rec_date $Rec_time'; % KUMC
pars.IncludeChar='$';
pars.DiscardChar='&';
% pars.NamingConvention={'Animal_ID','Rec_ID'}; % IIT
pars.NamingConvention={'Animal_ID','Year','Month','Day','Rec_ID'}; % KUMC

%%
Fields =  { ...
   'Raw';            % 1  - hard-coded for extraction
   'Filt';           % 2
   'CAR';            % 3
   'LFP';            % 4
   'Spikes';         % 5 - hard-coded to match terms from defaults.SD
   'SpikeFeatures';  % 6 - hard-coded to match terms from defaults.SD
   'Clusters';       % 7 - hard-coded to match terms from defaults.SD
   'Sorted';         % 8 - hard-coded to match terms from defaults.SD
   'DigIO';          % 9  - hard-coded for extraction
   'AnalogIO';       % 10 - hard-coded for extraction
   'DigEvents';      % 11
   'Video';          % 12
   'Stim';           % 13
   'DC';             % 14
   'Time';           % 15
   'Notes'           % 16
   'Probes';         % 17
   };

FieldType = { ...
   'Channels'; % 1
   'Channels'; % 2
   'Channels'; % 3
   'Channels'; % 4
   'Channels'; % 5
   'Channels'; % 6
   'Channels'; % 7
   'Channels'; % 8
   'Streams';  % 9
   'Streams';  % 10
   'Events';   % 11
   'Streams';  % 12
   'Events';   % 13
   'Channels'; % 14
   'Meta';     % 15
   'Meta';     % 16
   'Meta'      % 17
   };

OldNames       =  { ...
   {'*Raw*'};                       % 1
   {'*Filt*'};                      % 2
   {'*FiltCAR*'};                   % 3
   {'*LFP*'};                       % 4
   {'*ptrain*'};                    % 5
   {'*SpikeFeatures*'};             % 6
   {'*clus*'};                      % 7
   {'*sort*'};                      % 8
   {'*DIG*'};                       % 9
   {'*ANA*'};                       % 10
   {'*Scoring.mat'};                % 11
   {'*Paw.mat';'*Kinematics.mat'};  % 12
   {'*STIM*'};                      % 13
   {'*DC*'};                        % 14
   {'*Time*'};                      % 15
   {'*probes.xlsx'};                % 16
   {'*experiment.txt'}              % 17
   };

FolderNames     = {  ...
   'RawData';           % 1
   'Filtered';          % 2
   'FilteredCAR';       % 3
   'LFPData';           % 4
   '%s_Spikes';         % 5
   '%s_SpikeFeatures';  % 6
   '%s_Clusters';       % 7
   '%s_Sorted';         % 8
   'Digital';           % 9
   'Digital';           % 10
   'Digital';           % 11
   'Video';             % 12
   'StimData';          % 13
   'StimData';          % 14
   'Digital';           % 15
   'Metadata';          % 16
   'Metadata'           % 17
   };

FileType = { ...
   'Hybrid';   % 1
   'Hybrid';   % 2
   'Hybrid';   % 3
   'Hybrid';   % 4
   'Event';    % 5
   'Event';    % 6
   'Event';    % 7
   'Event';    % 8
   'Hybrid';   % 9
   'Hybrid';   % 10
   'Event';    % 11
   'Hybrid';   % 12
   'Event';    % 13
   'Hybrid';   % 14
   'Hybrid';   % 15
   'Other';    % 16
   'Other';    % 17
   };

%% DO ERROR PARSING
% Check that all have correct number of elements
N = numel(Fields);
if numel(FieldType)~=N
   error('FieldType (%d) must have same # elements as Fields (%d).',...
      numel(FieldType),N);
elseif numel(OldNames)~=N
   error('OldNames (%d) must have same # elements as Fields (%d).',...
      numel(OldNames),N);
elseif numel(FolderNames)~=N
   error('FolderNames (%d) must have same # elements as Fields (%d).',...
      numel(FolderNames),N);
elseif numel(FileType)~=N
   error('FileType (%d) must have same # elements as Fields (%d).',...
      numel(FileType),N);
end
pars.FileType = FileType;
pars.FieldType = FieldType;

% Check that FieldType is viable
VIABLE_FIELDS = fieldnames(TAG);
idx = ~cellfun(@(x)ismember(x,VIABLE_FIELDS),FieldType);
if sum(idx)>0
   idx = find(idx);
   warning('\nInvalid: FieldType{%d} (%s)\n',idx,FieldType{idx});
   pars = [];
   Fields = [];
   return;
end

%% MAKE DIRECTORY PARAMETERS STRUCT
% Concatenate identifier for each file-type:
Del = pars.Delimiter;
pars.BlockPars = struct;
for ii=1:numel(Fields)
   pars.BlockPars.(Fields{ii}).Folder     = FolderNames{ii};
   pars.BlockPars.(Fields{ii}).OldFile    = OldNames{ii};
   pars.BlockPars.(Fields{ii}).File = [Del Fields{ii} TAG.(FieldType{ii})];
   pars.BlockPars.(Fields{ii}).Info = [Del Fields{ii} '-Info.mat'];
end

end