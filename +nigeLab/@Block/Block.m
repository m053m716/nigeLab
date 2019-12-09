
classdef Block < matlab.mixin.Copyable
% BLOCK    Creates datastore for an electrophysiology recording.
%
%  blockObj = nigeLab.Block();
%     --> select Block path information from UI
%  blockObj = nigeLab.Block(blockPath); 
%     --> blockPath can be set as [] or char array with location
%  blockObj = nigeLab.Block(blockPath,animalPath);
%     --> animalPath can be [] or char array with location
%  blockObj = nigeLab.Block(__,'PropName1',propVal1,...);
%     --> allows specification of properties in constructor
%
%  ex:
%  blockObj = nigeLab.Block([],'P:\Your\Recording\Directory\Here');
%
%  BLOCK Properties:
%     Name - Name of recording BLOCK.
%
%     Animal - "Parent" nigeLab.Animal object
%
%     Graphics - Struct that contains pointers to graphics files.
%
%     Status - Completion status for each element of BLOCK/FIELDS.
%
%     Channels - Struct that contains data fields.
%                 -> blockObj.Channels(7).Raw(1:10) First 10 samples of
%                                                    channel 7 from the
%                                                    raw waveform.
%                 -> blockObj.Channels(1).Spikes.peak_train  Spike
%                                                           peak_train
%                                                           for chan 1.
%
%     Meta - Struct containing metadata info about recording BLOCK.
%
%  BLOCK Methods:
%     Block - Class constructor. Call as blockObj = BLOCK(varargin)
%
%     doRawExtraction - Convert from raw data binaries to BLOCK format.
%
%     doUnitFilter - Apply bandpass filter for unit activity.
%
%     doReReference - Apply common average re-reference for de-noising.
%
%     doSD - Run spike detection and feature extraction.
%
%     doLFPExtraction - Use cascaded lowpass filter to decimate raw data
%                       to a rate more suitable for LFP analyses.
%
%     doVidInfoExtraction - Get video metadata if there are related
%                           behavioral videos associated with a
%                           recording.
%
%     doVidSyncExtraction - Get time-series of "digital HIGH" times
%                           based on detection of ON/OFF state of a
%                           video element, such as a flashing LED.
%
%     doBehaviorSync - Get synchronization signal from digital inputs.
%
%     plotWaves -    Make a preview of the filtered waveform for all
%                    channels, and include any sorted, clustered, or
%                    detected spikes for those channels as highlighted
%                    marks at the appropriate time stamp.
%
%     plotSpikes -   Display all spikes for a particular channel as a
%                    SPIKEIMAGE object.
%
%     linkToData - Link block object to existing data structure.
%
%     clearSpace - Remove extracted RAW data, and extracted FILTERED
%                  data if CAR channels are present.
%
%     analyzeRMS - Get RMS for all channels of a desired type of stream.
%
%     Empty - Create an Empty BLOCK object or array
   
   %% PROPERTIES
   % Public properties that are SetObservable
   properties (Access = public, SetObservable = true)
      Name     char            % Name of the recording block
   end
   
   % Public properties that can be modified externally
   properties (SetAccess = public, GetAccess = public)
      Meta     struct      % Metadata struct with info about the recording
      

      Channels struct                             % Struct array of neurophysiological stream data
      Events   struct                             % Struct array of asynchronous events
      Streams  struct                             % Struct array of non-electrode data streams
      Videos   nigeLab.libs.VidStreamsType        % Array of nigeLab.libs.VidStreamsType
      
      Graphics struct  % Struct for associated graphics objects
      
      Pars     struct  % Parameters struct
   end
   
   % Public properties that can be modified externally but don't show up in
   % the list of fields that you see in the Matlab editor
   properties (SetAccess = public, Hidden = true, GetAccess = public)
      UserData % Allow UserData property to exist
   end
   
   % Properties that can be obtained externally, but must be set by a
   % method of the class object.
   properties (SetAccess = private, GetAccess = public)
      Scoring     struct   % Metadata about any scoring done
      SampleRate  double   % Recording sample rate
      Samples     double   % Total number of samples in original record
      Time        char     % Points to Time File
      
      RMS         table    % RMS noise table for different waveforms
      Fields      cell     % List of property field names
      
      Mask        double   % Vector of indices of included elements of Channels
      
      NumProbes         = 0   % Number of electrode arrays
      NumChannels       = 0   % Number of electrodes on all arrays
      
      
      Status      struct  % Completion status for each element of BLOCK/FIELDS
      PathExpr    struct  % Path expressions for creating file hierarchy
      Paths       struct  % Detailed paths specifications for all the saved files
      Probes      struct  % Probe configurations associated with saved recording
      Notes       struct  % Notes from text file
      
      RecSystem  nigeLab.utils.AcqSystem  % 'RHS', 'RHD', or 'TDT' (must be one of those)
      RecType    char                     % Intan / TDT / other
      FileExt    char                     % .rhd, .rhs, or other
   end
   
   % Properties that can be obtained externally, but must be set by a
   % method of the class object, and don't populate in the editor window or
   % in the tab-completion window
   properties (SetAccess = private, GetAccess = public, Hidden = true)      
      FieldType         % Indicates types for each element of Field
      FileType          % Indicates DiskData file type for each Field
      
      RecFile       % Raw binary recording file
      AnimalLoc     % Saving path for extracted/processed data
      SaveFormat    % saving format (MatFile,HDF5,dat, current: "Hybrid")
   end
  
   % Properties that must be both set and accessed by methods of the BLOCK
   % class only.
   properties (SetAccess = private, GetAccess = private)      
      ForceSaveLoc            logical     % Flag to force make non-existent directory      
      RecLocDefault           char        % Default location of raw binary recording
      AnimalLocDefault        char        % Default location of BLOCK
      ChannelID                           % Unique channel ID for BLOCK
      Verbose = true;                     % Whether to report list of files and fields.
      
      FolderIdentifier        char        % ID '.nigelBlock' to denote a folder is a BLOCK
      Delimiter               char        % Delimiter for name metadata for dynamic variables
      DynamicVarExp           char        % Expression for parsing BLOCK names from raw file
      IncludeChar             char        % Character indicating included name elements
      DiscardChar             char        % Character indicating discarded name elements
      
      MultiAnimalsChar  % Character indicating the presence of many animals in the recording
      MultiAnimals = 0; % flag for many animals contained in one block
      MultiAnimalsLinkedBlocks % Pointer to the splitted blocks. 
%                 In conjuction with the multianimals flag keeps track of
%                 where the data is temporary saved.
      
      NamingConvention        cell        % How to parse dynamic name variables for Block
      DCAmpDataSaved          logical     % Flag indicating whether DC amplifier data saved
      
      MatFileWorkflow         struct      % Struct with fields below:
%                            --> ReadFcn     function handle to external 
%                                            matfile header loading function
%                            --> ConvertFcn  function handle to "convert" 
%                                            old (pre-extracted) blocks to 
%                                            nigeLab format
%                            --> ExtractFcn  function handle to use for
%                                            'do' extraction methods
                          
      ViableFieldTypes       cell         % List of 'Viable' possible field types

   end

   events
      channelCompleteEvent
      processCompleteEvent
   end
   
   %% METHODS
   % BLOCK class constructor
   methods (Access = public)
      % BLOCK class constructor
      function blockObj = Block(blockPath,animalPath,varargin)
         % BLOCK    Creates datastore for an electrophysiology recording.
         %
         %  blockObj = nigeLab.Block();
         %     --> select Block path information from UI
         %  blockObj = nigeLab.Block(blockPath); 
         %     --> blockPath can be set as [] or char array with location
         %  blockObj = nigeLab.Block(blockPath,animalPath);
         %     --> animalPath can be [] or char array with location
         %  blockObj = nigeLab.Block(__,'PropName1',propVal1,...);
         %     --> allows specification of properties in constructor
         %
         %  ex:
         %  blockObj = nigeLab.Block([],'P:\Your\Rec\Directory\Here');
         
         % Parse Inputs
         if nargin < 1
            blockObj.RecFile = [];
         else
            if isempty(blockPath)
               blockObj.RecFile = [];
            elseif isnumeric(blockPath)
               % Create empty object array and return
               dims = blockPath;
               blockObj = repmat(blockObj,dims);
               for i = 1:dims(1)
                  for k = 1:dims(2)
                     % Make sure they aren't just all the same handle
                     blockObj(i,k) = copy(blockObj(1,1));
                  end
               end
               return;
            elseif ischar(blockPath)
               blockObj.RecFile = blockPath;
            else
               error(['nigeLab:' mfilename ':badInputType1'],...
                  'Bad blockPath input type: %s',class(blockPath));
            end
         end
         
         if nargin < 2
            blockObj.AnimalLoc = [];
         else
            blockObj.AnimalLoc = animalPath;
         end
         
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue;
            end
            % Check to see if it matches any of the listed properties
            if isprop(blockObj,varargin{iV})
               blockObj.(varargin{iV}) = varargin{iV+1};
            end            
         end
         
         % Load default parameters
         [pars,blockObj.Fields] = nigeLab.defaults.Block;
         allNames = fieldnames(pars);
         allNames = reshape(allNames,1,numel(allNames));
         for name_ = allNames
            % Check to see if it matches any of the listed properties
            if isprop(blockObj,name_{:})
               blockObj.(name_{:}) = pars.(name_{:});
            end
         end
         
         % Look for "Block" directory
         if isempty(blockObj.RecFile)
            [file,path]= uigetfile(fullfile(blockObj.RecLocDefault,'*.*'),...
               'Select recording BLOCK');
            if file == 0
               error('No block selected. Object not created.');
            end
            blockObj.RecFile =(fullfile(path,file));
         else
            if isdir(blockObj.RecFile)
               if isempty(blockObj.AnimalLoc)
                  tmp = strsplit(blockObj.RecFile,filesep);
                  tmp = strjoin(tmp(1:(end-1)),filesep);
                  tmp = nigeLab.utils.getUNCPath(tmp);
                  blockObj.AnimalLoc = tmp;
               end
            elseif exist(blockObj.RecFile,'file')==0
               error('%s is not a valid block file.',blockObj.RecFile);
            end
         end
         blockObj.RecFile =nigeLab.utils.getUNCPath(blockObj.RecFile);
         if ~blockObj.init()
            error('Block object construction unsuccessful.');
         end
         
      end
      
      function flag = save(blockObj)
         % SAVE  Overloaded SAVE method for BLOCK
         %
         %  blockObj.save;          This works
         %  flag = save(blockObj);  This also works
         %
         %  flag returns true if the save did not throw an error.
         
         % Make sure array isn't saved to same file
         if numel(blockObj) > 1
            flag = false(size(blockObj));
            for i = 1:numel(blockObj)
               flag(i) = blockObj(i).save;
            end
            return;
         end
         
         flag = false;
         
         blockObj.updateParams('Block');
         % Handles the case of MultiAnimals. Avoids infinite save loop

          % Save blockObj
          blockFile = nigeLab.utils.getUNCPath(...
             [blockObj.Paths.SaveLoc.dir '_Block.mat']);
          save(blockFile,'blockObj','-v7');
          
          % Save "nigelBlock" file for convenience of identifying this
          % folder as a "BLOCK" folder in the future
          blockIDFile = nigeLab.utils.getUNCPath(blockObj.Paths.SaveLoc.dir,...
                                                blockObj.FolderIdentifier);

          fid = fopen(blockIDFile,'w+');
          fwrite(fid,['BLOCK|' blockObj.Name]);
          fclose(fid);

          % save multianimals if present
          if blockObj.ManyAnimals
             for bl = blockObj.ManyAnimalsLinkedBlocks 
                  bl.ManyAnimalsLinkedBlocks(:) = [];
                  bl.ManyAnimals = false;
                  bl.save();
             end
          end
          
          flag = true;

      end

      % Overloaded SUBSREF method for indexing shortcuts on BLOCK
      function varargout = subsref(blockObj,s)
         % SUBSREF  Overload indexing operators for BLOCK
         %
         %  varargout = subsref(blockObj,s); 
         %
         %  s: Struct returned by SUBSTRUCT function
         
         Shrt = nigeLab.defaults.Shortcuts();
         switch s(1).type
            case '.'
               
               idx = find(ismember(Shrt(:,1),s(1).subs),1,'first');
               if ~isempty(idx)
                  varargout = {};
                  iRow = blockObj.subs2idx(s(2).subs{1},blockObj.NumChannels); 
                  iCol = blockObj.subs2idx(s(2).subs{2},blockObj.Samples);
                  
                  out = nan(numel(s(2).subs{1}),numel(s(2).subs{2}));
                  expr = sprintf('blockObj.%s;',Shrt{idx,2});
                  
                  for i = 1:numel(iRow)
                     tmp = eval(sprintf(expr,iRow(i)));
                     out(i,:) = tmp(iCol);
                  end                  
                  
                  varargout{1} = out;
                  return;
               else
                  if numel(blockObj) > 1
                     varargout = cell(1,nargout);
                     for i = 1:numel(blockObj)
                        varargout{1} = [varargout{1}; ...
                           subsref(blockObj(i),s)];
                     end
                     return;
                  end
                  
                  [varargout{1:nargout}] = builtin('subsref',blockObj,s);
                  return;
               end
            case '()'

               [varargout{1:nargout}] = builtin('subsref',blockObj,s);
               return;
               
            % Move "shortcut" referencing onto {} indexing, since it isn't
            % being used anyways. Simplifies everything.
            case '{}'
               if isscalar(blockObj) && ~isnumeric(s(1).subs{1})
                  s(1).subs=[{1} s(1).subs];
               end
               if length(s) == 1                  
                  nargsi=numel(s(1).subs);
                  nargo = 1;
                  
                  
                  iAll = 1:blockObj.NumChannels;
                  if nargsi == 1
                     if isnumeric(s.subs{1})
                        Out = sprintf('blockObj.Channels(%d).Raw;\n',s.subs{1});
                     elseif ismember(s.subs{1},Shrt(:,1))
                        Out = sprintf('blockObj.Channels(%d).%s;\n',iAll,s.subs{1});
                     else
                        Out = sprintf('blockObj.Channels(%d).Raw;\n',iAll);                        
                     end
                  end
                  
%                   if nargsi == 2
%                      if isnumeric(s.subs{1
%                   end
                  
                  if nargsi > 2
                     
                     
                     if ischar( s(1).subs{2} )
                        longCommand = sprintf(Shrt{strcmp(Shrt(:,1),s(1).subs{2}),2},s(1).subs{3});
                     
                     elseif isnumeric( s(1).subs{1} )
                        if s(1).subs{1} > size(Shrt,1)
                           warning('Possible reference error.');
                           varargout{1} = builtin('subsref',blockObj,s);
                           return;
                        end
                        longCommand = sprintf(Shrt{s(1).subs{1},2},s(1).subs{2});
                     end
                     
                     Out = sprintf('%s.%s',Out,longCommand);
                     indx = ':';
                     
                     if nargsi > 3
                        indx = sprintf('[%s]',num2str(s(1).subs{4}));                        
                     end
                     Out = sprintf('%s(%s)',Out,indx);
                  end
                  
                  if size(Out,1) > 1
                     varargout = cell(1,size(Out,1));
                     for i = 1:size(Out,1)
                        varargout{i} = eval(Out(i,:));
                     end
                  else
                     [varargout{1:nargo}] = eval(Out);
                  end
                  
                  
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
            otherwise
               error('Not a valid indexing expression')
         end
      end
      
      % Overloaded NUMARGUMENTSFROMSUBSCRIPT method for parsing indexing.
      function n = numArgumentsFromSubscript(blockObj,s,indexingContext)
         % NUMARGUMENTSFROMSUBSCRIPT  Parse # args based on subscript type
         %
         %  n = blockObj.numArgumentsFromSubscript(s,indexingContext);
         %
         %  s  --  struct from SUBSTRUCT method for indexing
         %  indexingContext  --  matlab.mixin.util.IndexingContext Context
         %                       in which the result applies.
         
         dot = strcmp({s(1:min(length(s),2)).type}, '.');
         if sum(dot) < 2
            if indexingContext == matlab.mixin.util.IndexingContext.Statement &&...
                  any(dot) && any(strcmp(s(dot).subs,methods(blockObj)))

               mc = metaclass(blockObj);
               calledmethod=(strcmp(s(dot).subs,{mc.MethodList.Name}));
               n = numel(mc.MethodList(calledmethod).OutputNames);
            else
               n = builtin('numArgumentsFromSubscript',blockObj,s,indexingContext);
            end
         else
            n = builtin('numArgumentsFromSubscript',blockObj,s,indexingContext);
         end
      end
   end
   
   % Methods to be catalogued in CONTENTS.M
   methods (Access = public)
      % Scoring videos
      fig = scoreVideo(blockObj) % Score videos manually to get behavioral alignment points
      fig = alignVideoManual(blockObj,digStreams,vidStreams); % Manually obtain alignment offset between video and digital records
      fieldIdx = checkCompatibility(blockObj,requiredFields) % Checks if this block is compatible with required field names
      offset = guessVidStreamAlignment(blockObj,digStreamInfo,vidStreamInfo);
      
      addScoringMetadata(blockObj,fieldName,info); % Add scoring metadata to table for tracking scoring on a video for example
      info = getScoringMetadata(blockObj,fieldName,hashID); % Retrieve row of metadata scoring
      
      % Methods for data extraction:
      flag = doRawExtraction(blockObj)  % Extract raw data to Matlab BLOCK
      flag = doEventDetection(blockObj,behaviorData,vidOffset) % Detect "Trials" for candidate behavioral Events
      flag = doEventHeaderExtraction(blockObj,behaviorData,vidOffset)  % Create "Header" for behavioral Events
      flag = doUnitFilter(blockObj)     % Apply multi-unit activity bandpass filter
      flag = doReReference(blockObj)    % Do virtual common-average re-reference
      flag = doSD(blockObj)             % Do spike detection for extracellular field
      flag = doLFPExtraction(blockObj)  % Extract LFP decimated streams
      flag = doVidInfoExtraction(blockObj,vidFileName) % Get video information
      flag = doBehaviorSync(blockObj)      % Get sync from neural data for external triggers
      flag = doVidSyncExtraction(blockObj) % Get sync info from video
      flag = doAutoClustering(blockObj,chan,unit) % Do automatic spike clustiring

      % Methods for streams info
      stream = getStream(blockObj,streamName,source,scaleOpts); % Returns stream data corresponding to streamName
      
      % Methods for parsing channel info
      flag = parseProbeNumbers(blockObj) % Get numeric probe identifier
      flag = setChannelMask(blockObj,includedChannelIndices) % Set "mask" to look at
      
      % Methods for parsing spike info:
      tagIdx = parseSpikeTagIdx(blockObj,tagArray) % Get tag ID vector
      ts = getSpikeTimes(blockObj,ch,class)    % Get spike times (sec)
      idx = getSpikeTrain(blockObj,ch,class)   % Get spike sample indices
      spikes = getSpikes(blockObj,ch,class,type)   % Get spike waveforms
      sortIdx = getSort(blockObj,ch,suppress)  % Get spike sorted classes
      clusIdx = getClus(blockObj,ch,suppress)  % Get spike cluster classes
      [tag,str] = getTag(blockObj,ch)          % Get spike sorted tags
      flag = saveChannelSpikingEvents(blockObj,ch,spk,feat,art) % Save spikes for a channel
      flag = checkSpikeFile(blockObj,ch) % Check a spike file for compatibility
      
      % Method for accessing event info:
      idx = getEventsIndex(blockObj,field,eventName);
      [data,blockIdx] = getEventData(blockObj,field,prop,ch,matchValue,matchField) % Retrieve event data
      flag = setEventData(blockObj,fieldName,eventName,propName,value,rowIdx,colIdx);
      
      % Computational methods:
      [tf_map,times_in_ms] = analyzeERS(blockObj,options) % Event-related synchronization (ERS)
      analyzeLFPSyncIndex(blockObj)  % LFP synchronization index
      rms_out = analyzeRMS(blockObj,type,sampleIndices)  % Compute RMS for channels
      
      % Methods for producing graphics:
      flag = plotWaves(blockObj)          % Plot stream snippets
      flag = plotSpikes(blockObj,ch)      % Show spike clusters for a single channel
      flag = plotOverlay(blockObj)        % Plot overlay of values on skull
      
      % Methods for associating/displaying info about blocks:
      L = list(blockObj) % List of current associated files for field or fields
      flag = updateVidInfo(blockObj) % Update video info
      flag = linkToData(blockObj,suppressWarning) % Link to existing data
      flag = linkField(blockObj,fieldIndex)     % Link field to data
      flag = linkChannelsField(blockObj,field,fType)  % Link Channels field data
      flag = linkEventsField(blockObj,field)    % Link Events field data
      flag = linkStreamsField(blockObj,field)   % Link Streams field data
      flag = linkVideosField(blockObj,field)    % Link Videos field data
      flag = linkTime(blockObj)     % Link Time stream
      flag = linkNotes(blockObj)    % Link notes metadata
      flag = linkProbe(blockObj)    % Link probe metadata
      
      % Methods for storing & parsing metadata:
      h = takeNotes(blockObj)             % View or update notes on current recording
      parseNotes(blockObj,str)            % Update notes for a recording
      header = parseHeader(blockObj)      % Parse header depending on structure
      
      % Methods for parsing Fields info:
      fileType = getFileType(blockObj,field) % Get file type corresponding to field  
      [fieldType,n] = getFieldType(blockObj,field) % Get type corresponding to field
      [fieldIdx,n] = getFieldTypeIndex(blockObj,fieldType) % Get index of all fields of a given type
      [fieldIdx,n] = getStreamsFieldIndex(blockObj,field,type) % Get index into Streams for a given Field
      opOut = updateStatus(blockObj,operation,value,channel) % Indicate completion of phase
      flag = updatePaths(blockObj,SaveLoc)     % updates the path tree and moves all the files
      [flag,p] = updateParams(blockObj,paramType) % Update parameters
      status = getStatus(blockObj,operation,channel)  % Retrieve task/phase status
      
      % Miscellaneous utilities:
      N = getNumBlocks(blockObj) % This is just to make it easier to count total # blocks
      notifyUser(blockObj,op,stage,curIdx,totIdx) % Update the user of progress
      str = reportProgress(blockObj, string, pct ) % Update the user of progress
      checkMask(blockObj) % Just to double-check that empty channels are masked appropriately
      idx = matchProbeChannel(blockObj,channel,probe); % Match Channels struct index to channel/probe combo
   end
   
   % "PRIVATE" methods
   methods (Access = public, Hidden = true) % Can make things PRIVATE later
      flag = intan2Block(blockObj,fields,paths) % Convert Intan to BLOCK
      flag = tdt2Block(blockObj) % Convert TDT to BLOCK
      
      flag = rhd2Block(blockObj,recFile,saveLoc) % Convert *.rhd to BLOCK
      flag = rhs2Block(blockObj,recFile,saveLoc) % Convert *.rhs to BLOCK
      
      flag = genPaths(blockObj,tankPath,useRemote) % Generate paths property struct
%       flag = findCorrectPath(blockObj,paths)   % (DEPRECATED)
      flag = getSaveLocation(blockObj,saveLoc) % Prompt to set save dir
      paths = getFolderTree(blockObj,paths,useRemote) % returns a populated path struct
      
      clearSpace(blockObj,ask,usrchoice)     % Clear space on disk      

      flag = init(blockObj) % Initializes the BLOCK object
      flag = initChannels(blockObj,header);   % Initialize Channels property
      flag = initEvents(blockObj);     % Initialize Events property 
      flag = initStreams(blockObj);    % Initialize Streams property
      flag = initVideos(blockObj);     % Initialize Videos property
      
      meta = parseNamingMetadata(blockObj); % Get metadata struct from recording name
      channelID = parseChannelID(blockObj); % Get unique ID for a channel
      masterIdx = matchChannelID(blockObj,masterID); % Match unique channel ID
      
      parseRecType(blockObj)              % Parse the recording type
      header = parseHierarchy(blockObj)   % Parse header from file hierarchy
      blocks = splitMultiAnimals(blockObj,varargin)  % splits block with multiple animals in it
   end
   
   % Static methods for multiple animals
   methods (Static)
      % Method to instantiate "Empty" Blocks from constructor
      function blockObj = Empty(n)
         % EMPTY  Creates "empty" block or block array
         %
         %  blockObj = nigeLab.Block.Empty();  % Makes a scalar
         %  blockObj = nigeLab.Block.Empty(n); % Make n-element array Block
         
         if nargin < 1
            n = 1;
         else
            n = nanmax(n,1);
            if isscalar(n)
               n = [1, n];
            end
         end
         
         blockObj = nigeLab.Block(n);
      end
      
      % Overloaded method for loading objects (for many blocks case)
      function b = loadobj(a)
         % LOADOBJ  Overloaded method called when loading BLOCK.
         %
         %  Has to be called when there ManyAnimals is true because the
         %  BLOCKS are removed from parent objects in that case during
         %  saving.
         %
         %  blockObj = loadobj(blockObj);
         
         if ~a.ManyAnimals
            b = a;
            return;
         end

         % blockObj has "pointer" to 'ManyAnimalsLinkedBlocks' but until
         % they are "reloaded" the "pointer" is bad (references bl in
         % the wrong place, essentially?)
         for bl=a.ManyAnimalsLinkedBlocks
            bl.reload();
         end
         b = a;
      end
      
      % Static method for converting subs to index
      function idx = subs2idx(subs,n)
         % SUBS2IDX  Converts subscripts to indices
         
         if ischar(subs)
            switch subs
               case ':'
                  idx = 1:n;
               case 'end'
                  idx = n;
               otherwise
                  idx = [];
            end
         else
            idx = subs;
         end
      end
   end
end