function flag = init(blockObj)
%% INIT Initialize BLOCK object
%
%  b = orgExp.Block();
%
%  Note: INIT is a protected function and will always be called on
%        construction of BLOCK. Returns a "true" flag if executed
%        successfully.
%
%  By: Max Murphy       v1.0  08/25/2017  Original version (R2017a)
%      Federico Barban  v2.0  07/08/2018
%      MAECI 2018       v3.0  11/28/2018

%% PARSE NAME INFO
% Set flag for output if something goes wrong
flag = false; 

% Parse name and extension. "nameParts" contains parsed variable strings:
[~,fName,blockObj.File_extension] = fileparts(blockObj.RecFile);
nameParts=strsplit(fName,{blockObj.Delimiter '.'});

% Parse variables from defaults.Block "template," which match delimited
% elements of block recording name:
regExpStr = sprintf('\\%c\\w*|\\%c\\w*',...
   blockObj.includeChar,...
   blockObj.discardChar);
splitStr = regexp(blockObj.dynamicVarExp,regExpStr,'match');

% Find which delimited elements correspond to variables that should be 
% included by looking at the leading character from the defaults.Block
% template string:
incVarIdx = find(cellfun(@(x) x(1)=='$',splitStr));
incVarIdx = reshape(incVarIdx,1,numel(incVarIdx));
P = properties(blockObj);

% Find which set of variables (the total number available from the name, or
% the number set to be read dynamically from the naming convention) has
% fewer elements, and use that to determine how many loop iterations there
% are:
nMin = min(numel(incVarIdx),numel(nameParts));

% Create a struct to allow creation of dynamic variable name dictionary.
% Make sure to iterate on 'splitStr', and not 'nameParts,' because variable
% assignment should be decided by the string in namingConvention property.
dynamicVars = struct;
for ii=1:nMin 
   splitStrIdx = incVarIdx(ii);
   varName = deblank( splitStr{splitStrIdx}(2:end));
   dynamicVars.(varName) = nameParts{ii};
end

% If Recording_date isn't one of the specified "template" variables from
% namingConvention property, then parse it from Year, Month, and Day. This
% will be helpful for handling file names for TDT recording blocks, which
% don't automatically append the Rec_date and Rec_time strings:
f = fieldnames(dynamicVars);
if sum(ismember(f,{'Rec_date'})) < 1
   if isfield(dynamicVars,'Year') && ...
      isfield(dynamicVars,'Month') && ...
      isfield(dynamicVars,'Day')
      YY = dynamicVars.Year((end-1):end);
      MM = dynamicVars.Month;
      DD = sprintf('%.2d',str2double(dynamicVars.Day));
      dynamicVars.Rec_date = [YY MM DD];
   else
      dynamicVars.Rec_date = 'YYMMDD';
      warning('Unable to parse date from BLOCK name (%s).',fName);
   end
end

% Similarly, if recording_time is empty, still keep it as a field in
% metadata associated with the BLOCK.
if sum(ismember(f,{'Rec_time'})) < 1
   dynamicVars.Rec_time = 'hhmmss';
end

blockObj.Meta = dynamicVars;

%% PARSE BLOCKOBJ.NAME, USING BLOCKOBJ.NAMINGCONVENTION
str = [];
nameCon = blockObj.namingConvention;
for ii = 1:numel(nameCon)
   if isfield(dynamicVars,nameCon{ii})
      str = [str, ...
         dynamicVars.(blockObj.namingConvention{ii}),...
         blockObj.Delimiter]; %#ok<AGROW>
   end
end
blockObj.Name = str(1:(end-1));

%% GET/CREATE SAVE LOCATION FOR BLOCK

% blockObj.SaveLoc is probably empty [] at this point, which will prompt a
% UI to point to the block save directory:
if ~blockObj.setSaveLocation(blockObj.SaveLoc)
   flag = false;
   warning('Save location not set successfully.');
   return;
end

if exist(blockObj.SaveLoc,'dir')==0
   mkdir(fullfile(blockObj.SaveLoc));
   makeLink = false;
else
   makeLink = true;
end

%% EXTRACT HEADER INFORMATION
switch blockObj.File_extension
   case '.rhd'
      blockObj.RecType='Intan';
      header=orgExp.libs.RHD_read_header('NAME',blockObj.RecFile,...
                                         'VERBOSE',blockObj.Verbose);
   case '.rhs'
      blockObj.RecType='Intan';
      header=orgExp.libs.RHS_read_header('NAME',blockObj.RecFile,...
                                         'VERBOSE',blockObj.Verbose);
   otherwise
      blockObj.RecType='other';
end

%% ASSIGN DATA FIELDS USING HEADER INFO
blockObj.Channels = header.amplifier_channels;
blockObj.numChannels = header.num_amplifier_channels;
blockObj.numProbes = header.num_probes;
% blockObj.dcAmpDataSaved = header.dc_amp_data_saved;
blockObj.numADCchannels = header.num_board_adc_channels;
% blockObj.numDACChannels = header.num_board_dac_channels;
blockObj.numDigInChannels = header.num_board_dig_in_channels;
blockObj.numDigOutChannels = header.num_board_dig_out_channels;
blockObj.Sample_rate = header.sample_rate;
blockObj.Samples = header.num_amplifier_samples;
% blockObj.DACChannels = header.board_dac_channels;
blockObj.ADCChannels = header.board_adc_channels;
blockObj.DigInChannels = header.board_dig_in_channels;
blockObj.DigOutChannels = header.board_dig_out_channels;
blockObj.Sample_rate = header.sample_rate;
blockObj.Samples = header.num_amplifier_samples;

blockObj.updateStatus('init');
if makeLink
   fprintf(1,'Extracted files found, linking data...\n');
   blockObj.linkToData(makeLink);
   fprintf(1,'\t->complete.\n');
end

blockObj.save;
flag = true;

end