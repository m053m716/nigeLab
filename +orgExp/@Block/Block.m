classdef Block < handle
   %% BLOCK    Creates datastore for an electrophysiology recording.
   %
   %  blockObj = BLOCK();
   %  blockObj = BLOCK('NAME','VALUE',...);
   %
   %  ex:
   %  blockObj = BLOCK('DIR','P:\Your\Recording\Directory\Here');
   %
   %  BLOCK Properties:
   %     Name - Name of recording BLOCK.
   %
   %     Fields - List of property field names that may have files associated
   %              with them.
   %
   %     Graphics - Graphics objects that are associated with BLOCK
   %                object. Currently contains Spikes subfield, which is a
   %                SPIKEIMAGE object that is available after calling the
   %                PLOTSPIKES method. The Waves subfield is only available
   %                after calling the PLOTWAVES method. To recall the
   %                SPIKEIMAGE object once it has been constructed, call as
   %                blockObj.Graphics.Spikes.Build.
   %
   %     Status - Completion status for each element of BLOCK/FIELDS.
   %
   %     Channels - List of channels from board, from probe, and masking.
   %
   %  BLOCK Methods:
   %     Block - Class constructor. Call as blockObj = BLOCK(varargin)
   %
   %     updateID - Update the File or Folder ID for a particular Field, which
   %                is listed in blockObj.Fields. Call as
   %                blockObj.UpdateID(name,type,value); name is the name of the
   %                field, type is the ID type ('File' or 'Folder'), and value
   %                is the new ID. For example:
   %                blockObj.UpdateID('Spikes','Folder','pca-PT_Spikes') would
   %                change where the BLOCK finds its spikes files.
   %
   %     updateContents - Using current information for File and Folder ID
   %                      string identifiers, update the list of files
   %                      associated with a particular information field.
   %
   %     plotWaves -    Make a preview of the filtered waveform for all
   %                    channels, and include any sorted, clustered, or
   %                    detected spikes for those channels as highlighted
   %                    marks at the appropriate time stamp.
   %
   %     plotSpikes -   Display all spikes for a particular channel as a
   %                    SPIKEIMAGE object.
   %
   %     loadSpikes -   Call as x = blockObj.LoadSpikes(channel) to load spikes
   %                    file contents to the structure x.
   %
   %     loadClusters - Call as x = blockObj.LoadClusters(channel) to load
   %                    class file contents to the structure x.
   %
   %     loadSorted -   Call as x = blockObj.LoadSorted(channel) to load class file
   %                    contents to the structure x.
   %
   %     set - Set a specific property of the BLOCK object.
   %
   %     get - Get a specific property of the BLOCK object.
   %
   % Started by: Max Murphy  v1.0  06/13/2018  Original version (R2017b)
   % Expanded by: MAECI 2018 collaboration (Federico Barban & Max Murphy)
   
   %% PUBLIC PROPERTIES
   
   properties (Access = public)
      Name
      Meta
   end
   
   properties (Access = public)
      DACChannels
      ADCChannels
      DigInChannels
      DigOutChannels
      Verbose = true; % Whether to report list of files and fields.
      Channels    % list of channels with various metadata and recording
      % data inside it.
      %
      % [ [ might actually be a better idea to create a
      %     special channel class? ] ]
      
      % Graphics - Graphical objects associated with BLOCK object.
      % -> Spikes : SPIKEIMAGE object. Once constructed, can
      %             call as blockObj.Graphics.Spikes.Build to
      %             recreate the spikes figure.
      % -> Waves : AXES object. Destroyed when figure is
      %            closed.
      Graphics    % Graphical objects associated with block
   end
   
   properties (SetAccess = private)
      
      SampleRate
      Time
      FileExt   % Intan TDT or other
      RecType
      
      NumChannels       = 0
      NumProbes         = 0
      NumADCchannels    = 0
      NumDACChannels    = 0
      NumDigInChannels  = 0
      NumDigOutChannels = 0
      
      RMS
   end
   
   properties (SetAccess = immutable,GetAccess = private)
      DCAmpDataSaved
      Date
      Month
      Day      
   end
   
   properties (SetAccess = immutable,GetAccess = public)
      % Properties for setting up other basic properties
      RecLocDefault
      SaveLocDefault
      ForceSaveLoc
      ProbeChannel
      
      % Properties for parsing name metadata
      Delimiter
      DynamicVarExp
      IncludeChar
      DiscardChar
      NamingConvention
   end
   
   
   %% PRIVATE PROPERTIES
   properties (SetAccess = private,GetAccess = public)
      Fields      % List of property field names
      
      % Parameters structs
      SDPars
      FiltPars
      LFPPars
      SyncPars
      VidPars
      PlotPars
      QueuePars
      
      RecFile       % Raw binary recording file
      SaveLoc       % Saving path for extracted/processed data
      SaveFormat    % saving format (MatFile,HDF5,dat, current: "Hybrid")
      
      Samples % Total number of samples in original record
      Mask  % Whether to include channels or not
   end
   
   properties (Access = private)
      Status      % Completion status for each element of BLOCK/FIELDS
      paths       % Detailed paths specifications for all the saved files
      Notes       % Notes from text file
   end
   
   %% METHODS
   methods (Access = public)
      function blockObj = Block(varargin)
         %% BLOCK Create a datastore object based on CPL data structure
         %
         %  blockObj = BLOCK;
         %  blockObj = BLOCK('NAME',Value,...);
         %
         %  ex:
         %  blockObj = BLOCK('RecLoc','P:\Your\Block\Directory\Here');
         %
         %  List of 'NAME', Value input argument pairs:
         %
         %  -> 'RecLoc' : (def: none) Specify as string with full directory of
         %              recording BLOCK. Specifying this will skip the UI
         %              selection portion, so it's useful if you are
         %              looping the expression.
         %
         %  -> 'Verbose' : (def: true) Setting this to false suppresses
         %                  output list of files and folders associated
         %                  with the CPL_BLOCK object during
         %                  initialization.
         %
         %
         %  -> 'MASK' : (def: []) If specified, use as a nChannels x 1
         %              logical vector of true/false for channels to
         %              include/exclude.
         %
         %  -> 'REMAP' : (def: []) If specified, use as a nChannels x 1
         %               double vector of channel mappings.
         %
         % By: Max Murphy  v1.0  08/25/2017
         %     F. Barban   v2.0  11/2018
         
         %% PARSE VARARGIN
         P = properties(blockObj);
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue;
            end
            % Check to see if it matches any of the listed properties
            idx = ismember(upper(P), upper( deblank( varargin{iV})));
            if sum(idx)==1 % Should only be one match
               Prop = P{idx};
               blockObj.(Prop) = varargin{iV+1};
            end
            
         end
         
         %% LOAD DEFAULT BLOCK PARAMETERS
         [pars,blockObj.Fields] = orgExp.defaults.Block;
         allNames = fieldnames(pars);
         allNames = reshape(allNames,1,numel(allNames));
         for varName = allNames
            str = varName{1}; % remove from cell container
            
            % Check to see if it matches any of the listed properties
            idx = ismember(upper(P), upper( deblank( str)));
            if sum(idx)==1 % Should only be one match
               Prop = P{idx};
               blockObj.(Prop) = pars.(str);
            end
         end
         
         %% LOOK FOR BLOCK DIRECTORY
         if isempty(blockObj.RecFile)
            [file,path]= uigetfile(fullfile(blockObj.RecLocDefault,'*.*'),...
               'Select recording BLOCK');
            blockObj.RecFile = fullfile(path,file);
            if blockObj.RecFile == 0

               error('No block selected. Object not created.');
            end
         else
            if exist(blockObj.RecFile,'file')==0
               error('%s is not a valid block file.',blockObj.RecFile);
            end
         end
         
         %% INITIALIZE BLOCK OBJECT
         if ~blockObj.init()
            error('Block object construction unsuccessful.');
         end
         
      end
      
      function save(blockObj)
         save(blockObj.paths.TW,'blockObj');
      end
      
      function disp(blockObj)
         if blockObj.Verbose
            builtin('disp',blockObj);
         end
      end
      
      % Federico I will let you comment this :) -MM
%       function varargout=subsref(blockObj,S) 
%          %% overrrides builtin subsref to allow shortcuts
%          % Only explicetly handles operator () called as first argoument
%          % Ohter cases are handled by builtin subsref directly.
% 
%          nOper = numel(S);
%          
%          if nOper == 1 && strcmp(S(1).type,'()') && numel(S(1).subs) > 2
%             nargs=numel(S(1).subs);
%             for jj=3:nargs
%                ind=numel(S)+1;
%                S(ind).subs{1}=S(1).subs{jj};
%                S(ind).type = '()';
%             end
%             Shrt = orgExp.defaults.Shortcuts();
%             if ischar( S(1).subs{1} )
%                longCommand = sprintf(Shrt{strcmp(Shrt(:,1),S(1).subs{1}),2},S(1).subs{2});
%             elseif isnumeric( S(1).subs{1} )
%                longCommand = sprintf(Shrt{S(1).subs{1},2},S(1).subs{2});
%             end
%             Out = sprintf('blockObj.%s',longCommand);
%             Out = eval(Out);
%             varargout = {Out};
%          else
%             [varargout{1:nargout}] = builtin('subsref',blockObj,S);
%          end
%             
%          
% %          
% %          ii=1;
% %           while ii<=numel(S)
% %               switch S(ii).type
% %                   case '()'
% %                       if ii==1
% %                           nargs=numel(S(ii).subs);
% %                           switch nargs
% %                              case 1
% %                                 Out = blockObj(S(ii).subs{:});
% %                                 varargout = {Out};
% %                                 ii=ii+1;
% %                                 continue;
% %                              case 2
% %                              otherwise
% %                           
% %                           for jj=3:nargs
% %                               ind=numel(S)+1;
% %                              S(ind).subs{1}=S(ii).subs{jj};
% %                              S(ind).type = '()';
% %                           end
% %                           Shrt = orgExp.defaults.Shortcuts();
% %                           if ischar( S(ii).subs{1} )
% %                               longCommand = sprintf(Shrt{strcmp(Shrt(:,1),S(ii).subs{1}),2},S(ii).subs{2});
% %                           elseif isnumeric( S(ii).subs{1} )
% %                               longCommand = sprintf(Shrt{S(ii).subs{1},2},S(ii).subs{2});
% %                           end
% %                           Out = sprintf('%s.%s',Out,longCommand);
% %                           Out = eval(Out);
% %                           varargout = {Out};
% %                           end
% %                       else
% %                          % retrieve methods output info
% %                          finfo = functions(eval(sprintf('@blockObj.%s',S.subs)));
% %                          fwspace = finfo.workspace{1};
% %                          wspacefields = fieldnames(fwspace);
% %                          mc = metaclass(fwspace.(wspacefields{1}));
% %                          methodsIndx=strcmp({mc.MethodList.Name},S.subs);
% %                          nout = numel(mc.MethodList(methodsIndx).OutputNames);
% %                          
% %                          % call builtin subsref with appropiate number of nouts
% %                          if nout
% %                             varargout = {builtin('subsref',blockObj,S)};
% %                          else
% %                             builtin('subsref',blockObj,S);
% %                          end
% %                          break;
% %                       end
% %                   case '.'                     
% %                     % retrieve method's output info 
% %                      finfo = functions(eval(sprintf('@blockObj.%s',S(ii).subs)));
% %                      fwspace = finfo.workspace{1};
% %                      wspacefields = fieldnames(fwspace);
% %                      mc = metaclass(fwspace.(wspacefields{1}));
% %                      methodsIndx=strcmp({mc.MethodList.Name},S(ii).subs);
% %                      nout = numel(mc.MethodList(methodsIndx).OutputNames);
% %                      
% %                      % call builtin subsref with appropiate number of nouts
% %                      if nout
% %                         varargout = {builtin('subsref',blockObj,S)};
% %                      else 
% %                         builtin('subsref',blockObj,S);                        
% %                      end
% %                       break;
% %                  case '{}'
% %                  case '[]'
% %                end
% %               ii=ii+1;
% %           end
%       end
      
      function varargout = subsref(blockObj,s)
         switch s(1).type
            case '.'
               [varargout{1:nargout}] = builtin('subsref',blockObj,s);
               
            case '()'
               if isscalar(blockObj) && ~isnumeric(s(1).subs{1})
                  s(1).subs=[{1} s(1).subs];
               end
               if length(s) == 1                  
                  nargsi=numel(s(1).subs);
                  nargo = 1;
                  
                  if nargsi > 0
                  Out = sprintf('blockObj(%d)',s.subs{1});
                  end
                  if nargsi > 1
                  end
                  if nargsi > 2
                     Shrt = orgExp.defaults.Shortcuts();
                     
                     if ischar( s(1).subs{2} )
                        longCommand = sprintf(Shrt{strcmp(Shrt(:,1),s(1).subs{2}),2},s(1).subs{3});
                     
                     elseif isnumeric( s(1).subs{1} )
                        longCommand = sprintf(Shrt{s(1).subs{1},2},s(1).subs{2});
                     end
                     
                     Out = sprintf('%s.%s',Out,longCommand);
                     indx = ':';
                     
                     if nargsi > 3
                        indx = sprintf('[%s]',num2str(s(1).subs{4}));                        
                     end
                     Out = sprintf('%s(%s)',Out,indx);
                  end
                  
                  [varargout{1:nargo}] = eval(Out);
                  
                  
%                elseif length(s) == 2 && strcmp(s(2).type,'.')
%                % Implement obj(ind).PropertyName
%                ...
%                elseif length(s) == 3 && strcmp(s(2).type,'.') && strcmp(s(3).type,'()')
%                % Implement obj(indices).PropertyName(indices)
%                ...
               else
               % Use built-in for any other expression
               [varargout{1:nargout}] = builtin('subsref',blockObj,s);
               end
            case '{}'
              warning('{} indexing not supported')
            otherwise
               error('Not a valid indexing expression')
         end
      end
      
      function n = numArgumentsFromSubscript(blockObj,s,indexingContext)
         dot = strcmp({s(1:2).type}, '.');
         if indexingContext == matlab.mixin.util.IndexingContext.Statement &&...
               any(dot) && any(strcmp(s(dot).subs,methods(blockObj)))
            
            mc = metaclass(blockObj);
            calledmethod=(strcmp(s(dot).subs,{mc.MethodList.Name}));
            n = numel(mc.MethodList(calledmethod).OutputNames);
         else
            n = builtin('numArgumentsFromSubscript',blockObj,s,indexingContext);
         end
      end
      
      % Methods for data processing:
      flag = doRawExtraction(blockObj)  % Extract raw data to Matlab BLOCK
      flag = qRawExtraction(blockObj)   % Queue extraction to Isilon
      flag = doUnitFilter(blockObj)     % Apply multi-unit activity bandpass filter
      flag = qUnitFilter(blockObj)      % Queue filter to Isilon
      flag = doReReference(blockObj)    % Do virtual common-average re-reference
      flag = qReReference(blockObj)     % Queue CAR to Isilon
      flag = doSD(blockObj)             % Do spike detection for extracellular field
      flag = qSD(blockObj)              % Queue SD to Isilon
      flag = doLFPExtraction(blockObj)  % Extract LFP decimated streams
      flag = qLFPExtraction(blockObj)   % Queue LFP decimation to Isilon
      flag = doVidInfoExtraction(blockObj,vidFileName) % Get video information
      flag = doBehaviorSync(blockObj)   % Get sync from neural data for external triggers
      flag = doVidSyncExtraction(blockObj) % Get sync info from video
      
      
      % Methods for data analysis:
      [tf_map,times_in_ms] = analyzeERS(blockObj,options) % Event-related synchronization (ERS)
      analyzeLFPSyncIndex(blockObj)                       % LFP synchronization index
      analyzeRMS(blockObj,type)
      
      % Methods for data visualization:
      flag = plotWaves(blockObj,WAV,SPK)  % Plot stream snippets
      flag = plotSpikes(blockObj,ch)      % Show spike clusters for a single channel
      
      % Methods for quickly accessing data [deprecated?]:
      out = loadSpikes(blockObj,ch)       % Load spikes for a given channel
      out = loadClusters(blockObj,ch)     % Load clusters file for a given channel
      out = loadSorted(blockObj,ch)       % Load sorting file for a given channel
      L = list(blockObj) % List of current associated files for field or fields
      
      % Utility methods for path stuff
      flag = linkToData(blockObj,preExtractedFlag) % Link to existing data
      flag = updatePaths(blockObj,tankPath) % Update associated paths
      flag = updateVidInfo(blockObj) % Update video info
      
   end
   methods (Access = public, Hidden = true)
      % Other utility methods:
      flag = setSaveLocation(blockObj,saveLoc)   % Set the BLOCK location
      flag = RHD2Block(blockObj,recFile,saveLoc) % Convert *.rhd to BLOCK format
      flag = RHS2Block(blockObj,recFile,saveLoc) % Convert *.rhs to BLOCK format
      
      flag = genPaths(blockObj,tankPath)
      flag = findCorrectPath(blockObj)
      
      operations = updateStatus(blockObj,operation,value)
      Status = getStatus(blockObj,stage)
      
      flag = clearSpace(blockObj,ask)  % Clear space on disk
      
      
      updateID(blockObj,name,type,value)  % Update the file or folder identifier
      updateContents(blockObj,fieldname)  % Update files for specific field
      
      
      % For future expansion?
      takeNotes(blockObj)                 % View or update notes on current recording
      updateNotes(blockObj,str) % Update notes for a recording
      varargout = blockGet(blockObj,prop) % Get a specific BLOCK property
      flag = blockSet(blockObj,prop,val)  % Set a specific BLOCK property
   end
   
   %% PRIVATE METHODS
   methods (Access = 'private') % debugging purpose, is private
      flag = init(blockObj) % Initializes the BLOCK object
      
   end
end