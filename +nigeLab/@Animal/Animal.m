classdef Animal < handle
%% ANIMAL   Class for handling each nigeLab.Block for one animal

%% PUBLIC PROPERTIES
   properties (Access = public)
      Name         % Animal identification code
      ElecConfig   %Electrode configuration structure
      RecType      % Intan TDT or other
     
   end
   
   properties (Access = public) %debugging purpose, is private
      RecDir         % directory with raw binary data in intan format
      Blocks       % Children (BLOCK)
      SaveLoc
      ExtractFlag
      DEF = 'P:/Rat'
   end
%% PUBLIC METHODS
   methods (Access = public)
      function animalObj = Animal(varargin)
         %% Creates an animal object with the related Blocks

         
         %% LOAD DEFAULT ID SETTINGS
         animalObj = def_params(animalObj);
         
         %% PARSE VARARGIN
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue
            end
            p = findprop(animalObj,varargin{iV});
            if isempty(p)
               continue
            end
            animalObj.(varargin{iV}) = varargin{iV+1};
         end
         
         %% LOOK FOR ANIMAL DIRECTORY
         if isempty(animalObj.RecDir)
            animalObj.RecDir = uigetdir(animalObj.DEF,'Select directory with the the recordings');
            if animalObj.RecDir == 0
               error('No animal selected. Object not created.');
            end
         else
            if exist(animalObj.RecDir,'dir')==0
               error('%s is not a valid block directory.',animalObj.RecDir);
            end
         end
         
         %% INITIALIZE ANIMAL OBJECT
         animalObj.init;
         
      end
      
      function addBlock(animalObj,BlockPath)

         newBlock= nigeLab.Block('RecFile',BlockPath,...
             'SaveLoc',animalObj.SaveLoc);
         animalObj.Blocks = [animalObj.Blocks newBlock];
      end
      
      function save(animalObj)
          B=animalObj.Blocks;
          for ii=1:numel(B)
              B(ii).save;
          end
          save(fullfile([animalObj.SaveLoc '_Animal.mat']),'animalObj','-v7.3');
      end
      
%       updateID(blockObj,name,type,value)    % Update the file or folder identifier
      table = list(animalObj)         % List of recordings currently associated with the animal
      updateContents(blockObj,fieldname)    % Update files for specific field
      out = animalGet(animalObj,prop)       % Get a specific BLOCK property
      flag = animalSet(animalObj,prop)      % Set a specific BLOCK property
                  % Convert raw data to Matlab BLOCK
      
      mergeBlocks(animalObj,ind,varargin)
      removeBlocks(animalObj,ind)
      
      % Extraction methods
      flag = doUnitFilter(animalObj)
      flag = doReReference(animalObj)
      flag = doRawExtraction(animalObj)    
      flag = doLFPExtraction(animalObj)
      flag = doSD(animalObj)
      
      % Utility
      flag = clearSpace(animalObj,ask)
      linkToData(animalObj)
   end
   
   methods (Access = public, Hidden = true)
      updateNotes(blockObj,str) % Update notes for a recording
   end

%% PRIVATE METHODS
   methods (Access = 'private')
      init(animalObj) % Initializes the ANIMAL object
      def_params(animalObj)
   end
end