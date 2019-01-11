classdef Tank < handle
%% TANK  Class to handle each nigeLab.Animal for a whole experiment
%
%  tankObj = TANK;
%  tankObj = TANK('NAME','VALUE',...);   
%
%  ex: 
%  tankObj = TANK('RecDir','P:\Your\Recording\Directory\Here');
%
%  TANK Properties:
%     Name - Name of experimental TANK.
%
%  TANK Methods:
%     Tank - TANK Class object constructor.
%
%     convert - Convert raw data files to Matlab BLOCK hierarchical format.
%
%     createMetadata - Creates metadata file in Processed TANK parent
%                      folder.
%
%     list - List Block objects in the TANK.
%
%     tankGet - Get a specific property from the TANK object.
%
%     tankSet - Set a property of the TANK object. Returns a boolean
%               flag as true if property is set successfully.
%
% By: Max Murphy  v1.0  06/14/2018

   %% PUBLIC PROPERTIES
   properties (Access = public)
      Name	% Name of experiment (TANK)
      Animals                 % Children (ANIMAL)
   end
   %% PRIVATE PROPERTIES
   properties (Access = public) %debugging purposes, is private
      RecDir                     % Directory of the TANK

      BlockNameVars           % Metadata variables from BLOCK names
      BlockStatusFlag         % Flag to indicate if blocks are at same step
      CheckBeforeConversion   % Flag to ask for confirmation before convert
      DefaultSaveLoc          % Default for save location
      DefaultTankLoc          % Default for UI TANK selection
      Delimiter               % Filename metadata delimiter
      ExtractFlag             % Flag to indicate if extraction is needed
      RecType                 % Acquisition system used for this Tank
                              % Currently supported formats
                              % ---------------------------
                              % Intan  ('Intan')
                              % TDT    ('TDT')                              
      SaveLoc                % Directory of BLOCK hierarchy parent folder
      ParallelFlag
   end
   
   %% PUBLIC METHODS
   methods (Access = public)
      function tankObj = Tank(varargin)
         %% TANK  Construct Tank Class object
         %
         %  tankObj = TANK;
         %  tankObj = TANK('NAME',Value,...);
         %
         %  ex: 
         %  tankObj = TANK('RecDir','P:\Your\Block\Directory\Here');
         %
         %  List of 'NAME', Value input argument pairs:
         %
         %  -> 'RecDir' : (def: none) Specify as string with full directory of
         %              recording BLOCK. Specifying this will skip the UI
         %              selection portion, so it's useful if you are
         %              looping the expression.
         %
         % By: Max Murphy  v1.0  06/14/2018
         
         %% LOAD OTHER PRIVATE DEFAULT SETTINGS
         tankObj = def_params(tankObj);
         
         %% PARSE VARARGIN
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue
            end
            p = findprop(tankObj,varargin{iV});
            if isempty(p)
               continue
            end
            tankObj.(varargin{iV}) = varargin{iV+1};
         end
         
         %% LOOK FOR BLOCK DIRECTORY
         if isempty(tankObj.RecDir)
            tankObj.RecDir = uigetdir(tankObj.DefaultTankLoc,...
                                   'Select TANK folder');
            if tankObj.RecDir == 0
               error('No block selected. Object not created.');
            end
         else
            if exist(tankObj.RecDir,'dir')==0
               error('%s is not a valid block directory.',tankObj.RecDir);
            end
         end
         
         %% INITIALIZE TANK OBJECT
         tankObj.init;
         
      end
      
      function addAnimal(tankObj,AnimalFolder)
          if nargin<2
              AnimalFolder=[];
          end
          if isempty(AnimalFolder)
            AnimalFolder = uigetdir(tankObj.RecDir,...
                                   'Select animal folder');
            if AnimalFolder == 0
               error('No animal selected. Object not created.');
            end
         else
            if exist(AnimalFolder,'dir')==0
               error('%s is not a valid block directory.',AnimalFolder);
            end
         end
          
         newAnimal= nigeLab.Animal('RecDir',AnimalFolder,...
             'SaveLoc',tankObj.SaveLoc);
         tankObj.Animals = [tankObj.Animals newAnimal];
      end
      
      function save(tankObj)
          A=tankObj.Animals;
          for ii=1:numel(A)
              A(ii).save;
          end
         save(fullfile([tankObj.SaveLoc '_Tank.mat']),'tankObj','-v7.3') 
      end
      
      % Extraction methods
      flag = doRawExtraction(tankObj)    % Convert raw data to Matlab BLOCK
      flag = doReReference(tankObj)
      flag = doLFPExtraction(tankObj)
      flag = doSD(tankObj)
      flag = clearSpace(tankObj,ask)
      
      % Utility
      linkToData(tankObj)
      blockList = list(tankObj)       % List Blocks in TANK
      out = tankGet(tankObj,prop)     % Get a specific TANK property
      flag = tankSet(tankObj,prop)    % Set a specific TANK property      
      
   end
   %% PRIVATE METHODS
   methods (Access = public)
      init(tankObj)                 % Initializes the TANK object.
      intan2Block(tankObj,varargin) % Does the actual data conversion
      setSaveLocation(tankObj,saveloc)      % Set save location for processed TANK.
      ClusterConvert(tankObj)
      LocalConvert(tankObj)
      SlowConvert(tankObj)
      
   end
end