function flag = initChannels(blockObj)
%% INITCHANNELS   Initialize header information for channels
%
%  flag = INITCHANNELS(blockObj);
%
% By: Max Murphy & Fred Barban 2018 MAECI Collaboration

%% GET HEADER INFO DEPENDING ON RECORDING TYPE
flag = false;
switch blockObj.FileExt
   case '.rhd'
      blockObj.RecType='Intan';
      header=ReadRHDHeader('NAME',blockObj.RecFile,...
                           'VERBOSE',blockObj.Verbose);
      
   case '.rhs'
      blockObj.RecType='Intan';
      header=ReadRHSHeader('NAME',blockObj.RecFile,...
                           'VERBOSE',blockObj.Verbose);                   
      
   case {'', '.Tbk', '.Tdx', '.tev', '.tnt', '.tsq'}
      dName = fileparts(blockObj.RecFile);
      files = dir(fullfile(dName,'*.t*'));
      if ~isempty(files)
         blockObj.RecType='TDT';
         blockObj.RecFile = fullfile(dName);
         header=ReadTDTHeader('NAME',blockObj.RecFile,...
                           'VERBOSE',blockObj.Verbose);
         for ff=fieldnames(blockObj.Meta)'
            if isfield(header.info,ff{:})
               blockObj.Meta.(ff{:}) = header.info.(ff{:});
            end
         end
         
      end
      
   case '.mat'
      blockObj.RecType='Matfile';
      header = blockObj.MatFileWorkflow.ReadFcn(blockObj.RecFile); 
   otherwise
      blockObj.RecType='other';
      warning('Not a recognized file extension: %s',blockObj.FileExt);
      return;
end

%% ASSIGN DATA FIELDS USING HEADER INFO
blockObj.Channels = header.raw_channels;
blockObj.RecSystem = nigeLab.utils.AcqSystem(header.acqsys);
blockObj.Meta.Header = nigeLab.utils.fixNamingConvention(header);

if ~blockObj.parseProbeNumbers % Depends on recording system
   warning('Could not properly parse probe identifiers.');
   return;
end
blockObj.NumChannels = header.num_raw_channels;
blockObj.NumAnalogIO = header.num_analogIO_channels;
blockObj.NumDigIO = header.num_digIO_channels;
blockObj.NumProbes = header.num_probes;
blockObj.SampleRate = header.sample_rate;
blockObj.Samples = header.num_raw_samples;

%% SET CHANNEL MASK (OR IF ALREADY SPECIFIED MAKE SURE IT IS CORRECT)
parseChannelID(blockObj);
if isfield(header,'Mask')
   blockObj.Mask = reshape(find(header.Mask),1,numel(header.Mask));
elseif isempty(blockObj.Mask)
   blockObj.Mask = 1:blockObj.NumChannels;
else
   blockObj.Mask(blockObj.Mask > blockObj.NumChannels) = [];
   blockObj.Mask(blockObj.Mask < 1) = [];
   blockObj.Mask = reshape(blockObj.Mask,1,numel(blockObj.Mask));
end

flag = true;

end