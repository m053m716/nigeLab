function flag = doUnitFilter(blockObj,varargin)
%% DOUNITFILTER   Filter raw data using spike bandpass filter
%
%  blockObj = orgExp.Block;
%  doUnitFilter(blockObj);
%
%  Note: added varargin so you can pass <'NAME', value> input argument
%        pairs to specify adhoc filter parameters if desired, rather than
%        modifying the defaults.Filt source code.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% GET DEFAULT PARAMETERS
flag = false;
pars = orgExp.defaults.Filt(varargin);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Filtering

% DESIGN FILTER
bp_Filt = designfilt('bandpassiir', 'StopbandFrequency1', pars.FSTOP1, ...
   'PassbandFrequency1', pars.FPASS1, ...
   'PassbandFrequency2', pars.FPASS2, ...
   'StopbandFrequency2', pars.FSTOP2, ...
   'StopbandAttenuation1', pars.ASTOP1, ...
   'PassbandRipple', pars.APASS, ...
   'StopbandAttenuation2', pars.ASTOP2, ...
   'SampleRate', blockObj.SampleRate, ...
   'DesignMethod', pars.METHOD);

blockObj.FiltPars = pars;

%% Save amplifier_data by probe/channel
fprintf(1,'\nApplying bandpass filtering... ');
fprintf(1,'%.3d%%',0)
for iCh = 1:blockObj.NumChannels
   if ~pars.STIM_SUPPRESS
      % Filter and and save amplifier_data by probe/channel
      pnum  = num2str(blockObj.Channels(iCh).port_number);
      chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
      data = single(filtfilt(bp_Filt,blockObj.Channels(iCh).Raw.double));
      iPb = blockObj.Channels(iCh).port_number;
      %             data = single(filtfilt(b,a,double(data)));
      fname = sprintf(strrep(blockObj.paths.FW_N,'\','/'), pnum, chnum);
      blockObj.Channels(iCh).Filt = orgExp.libs.DiskData(blockObj.SaveFormat,fname,data,'access','w');
	  blockObj.Channels(iCh).Filt = lockData(blockObj.Channels(iCh).Filt);
   end
   clear data
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   if ~floor(mod(fraction_done,5)) % only increment counter by 5%
      fprintf(1,'\b\b\b\b%.3d%%',floor(fraction_done))
   end
end
fprintf(1,'\b\b\b\bDone.\n');
blockObj.updateStatus('Filt',true);
flag = true;
blockObj.save;
end

