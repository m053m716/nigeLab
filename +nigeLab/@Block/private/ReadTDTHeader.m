function header = ReadTDTHeader(name,verbose)
% READTDTHEADER  Uses TDT "Block" data struct to format a header into the
%                nigeLab standardized formats.
%
%  header = ReadTDTHeader;
%  header = ReadTDTHeader(name,verbose);

%%
acqsys = 'TDT';

acqsys = 'TDT';

if nargin < 1
   verbose = false;
elseif nargin < 2
   verbose = true;
end

if exist('FID','var')
   
   [name,~,~,~] = fopen(FID); %#ok<NODEF>
   if isempty(name)
      error('Must provide a valid file pointer.');
   end
elseif exist('NAME', 'var')
   
   % If a pre-specified path exists, must be a valid path.
   if exist(name,'file')==0
      error('Must provide a valid RHD2000 Data File and Path.');
   else
      FID = fopen(name, 'r');
   end
else    % Must select a directory and a file
   
   
   [path] = ...
      uigetdir('Select a TDT block folder', ...
      'MultiSelect', 'off');
   
   if file == 0 % Must select a file
      error('Must select a TDT block folder.');
   end
   
   name = path;
   FID = fopen(name, 'r');
   
   
end

s = dir(name);
filesize = sum([s.bytes]);

heads = TDTbin2mat(name, 'HEADERS', 1,'NODATA',1);
block_fields = fieldnames(heads);

[TDTNaming] = nigeLab.defaults.TDT();
fn = fieldnames(heads.stores);
wav_data = fn(contains(fn,TDTNaming.WaveformName));

dataType = cell(1,numel(fn));
for ii=1:numel(fn)
   dataType{ii} = heads.stores.(fn{ii}).typeStr;
end
dataType = unique(dataType);

data_present = any(contains(block_fields, 'stores')) ;
sample_rate =  heads.stores.(wav_data{1}).fs;

s1 = datenum([1970, 1, 1, 0, 0, heads.startTime]);
s2 = datenum([1970, 1, 1, 0, 0, heads.stopTime]);
info.date = datestr(s1,'yyyy-mmm-dd');
if ~isnan(heads.startTime)
   d = datevec(s1);
   info.Year = d(1);
   info.Month = d(2);
   info.Day = d(3);
   info.RecDate = datestr(s1,'yymmdd');
   info.RecTime = datestr(s1,'hhmmss');
   
   info.utcStartTime = datestr(s1,'HH:MM:SS');
else
   info.utcStartTime = nan;
end
if ~isnan(heads.stopTime)
   info.utcStopTime = datestr(s2,'HH:MM:SS');
else
   info.utcStopTime = nan;
end

if heads.stopTime > 0
   info.duration = datestr(s2-s1,'HH:MM:SS');
end



num_probes = length(wav_data);
probes = char((1:num_probes) -1 + double('A')); % nice
raw_channels = nigeLab.utils.initChannelStruct('Channels',1);
for pb = 1:num_probes
   Chans = unique(heads.stores.(wav_data{pb}).chan);
   for iCh = 1:numel(Chans)
      ind = numel(raw_channels)+1;
      raw_channels(ind).name = sprintf('%c%.3d',probes(pb),iCh);
      raw_channels(ind).custom_channel_name = sprintf('%c%.3d',probes(pb),iCh);
      raw_channels(ind).native_channel_name = sprintf('%c-%.3d',probes(pb),Chans(iCh));
      raw_channels(ind).native_order = iCh;
      raw_channels(ind).custom_order = iCh;
      raw_channels(ind).board_stream = nan;
      raw_channels(ind).chip_channel = nan;
      raw_channels(ind).port_name = ['Port ' probes(pb)];
      raw_channels(ind).port_prefix = probes(pb);
      raw_channels(ind).port_number = pb;
      raw_channels(ind).signal = nigeLab.utils.signal('Raw');
      raw_channels(ind).electrode_impedance_magnitude = nan;
      raw_channels(ind).electrode_impedance_phase = nan;
      [raw_channels(ind).chNum,raw_channels(ind).chStr] = nigeLab.utils.getChannelNum(...
         raw_channels(ind).native_channel_name);
      raw_channels(ind).fs = sample_rate;
   end
end

DFORM_FLOAT		 = 0;
DFORM_LONG		 = 1;
DFORM_SHORT		 = 2;
DFORM_BYTE		 = 3;
DFORM_DOUBLE	 = 4;
DFORM_QWORD		 = 5;
DFORM_TYPE_COUNT = 6;
sz = 4;
switch heads.stores.((wav_data{1})).dform
   case DFORM_FLOAT
      fmt = 'single';
   case DFORM_LONG
      fmt = 'int32';
   case DFORM_SHORT
      fmt = 'int16';
      sz = 2;
   case DFORM_BYTE
      fmt = 'int8';
      sz = 1;
   case DFORM_DOUBLE
      fmt = 'double';
      sz = 8;
   case DFORM_QWORD
      fmt = 'int64';
      sz = 8;
end
num_raw_channels = numel(raw_channels);
npts = (heads.stores.((wav_data{1})).size-10) * 4/sz;
num_raw_samples = double(npts) * numel(heads.stores.((wav_data{1})).data)/num_raw_channels;
for i = 1:numel(raw_channels)
   raw_channels(i).signal.Samples = num_raw_samples;
end

%% --> For JB to update <-- 2019-11-20 (MM)
% Note: 
% channel_struct should follow format of
% --> nigeLab.utils.initChannelStruct('Streams') 
% (Allows extraction from different systems to keep data in common "header"
%  format)
%
% Note: 
%  data.epocs should be parsed using the format of
%  --> nigeLab.utils.initSpikeTriggerStruct('TDT') % for example

% board_adc_channels = channel_struct;
% board_dig_in_channels = channel_struct;
% board_dig_out_channels = channel_struct;
%
num_analogIO_channels = 0;
num_digIO_channels = 0;
% num_board_dig_out_channels
% num_data_blocks
% bytes_per_block
% num_samples_per_data_block
%
% num_board_adc_samples
% num_board_dig_in_samples
% num_board_dig_out_samples

DesiredOutputs = nigeLab.utils.initDesiredHeaderFields('TDT').';
for field = DesiredOutputs %  DesiredOutputs defined in nigeLab.utils
   fieldOut = field{:};
   fieldOutVal = eval(fieldOut);
   header.(fieldOut) = fieldOutVal;
end

return
end



