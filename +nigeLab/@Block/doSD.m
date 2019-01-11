function flag = doSD(blockObj)
%% DOSD   Detects spikes after raw extraction and unit filter
%
%  EXAMPLE USAGE
%  -------------------------------------------------------
%  b = nigeLab.Block();    % point to experiment
%  doRawExtraction(b);    % convert binary data
%  doUnitFilter(b);       % filter the data
%  doSD(b);   % detect extracellular spiking
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% LOAD DEFAULT PARAMETERS FROM HARD-CODED SOURCE FILE
flag = false;
if ~genPaths(blockObj)
   warning('Something went wrong when generating paths for extraction.');
   return;
end
if ~blockObj.updateParams('SD')
   warning('Could not update the spike detection parameters.');
   return;
end

pars = blockObj.SDPars;
pars.FS = blockObj.SampleRate;

%% GO THROUGH EACH CHANNEL AND EXTRACT SPIKE WAVEFORMS AND TIMES
nCh = blockObj.NumChannels;

fprintf(1,'\n000%%\n');
for iCh = 1:nCh
   % Parse file-name information
   pNum  = num2str(blockObj.Channels(iCh).port_number);
   chIdx = regexp(blockObj.Channels(iCh).custom_channel_name, '\d');
   chNum = blockObj.Channels(iCh).custom_channel_name(chIdx);
   fName = sprintf(strrep(blockObj.paths.SDW_N,'\','/'), pNum, chNum);
   
   % Get pointer to the correct data:
   if (blockObj.Status(find(ismember(blockObj.Fields,'CAR'),1,'first')))
      data=blockObj.Channels(iCh).CAR(:);  % Load CAR-filtered data
   elseif (blockObj.Status(find(ismember(blockObj.Fields,'Filt'),1,'first')))
      data=blockObj.Channels(iCh).Filt(:); % Load filtered data
   else
      warning('Must first perform unit filtering and re-referencing.');
      disp('Doing those now...');
      doUnitFilter(blockObj);
      doReReference(blockObj);
      doSD(blockObj);
      return;
   end
   
   % Do the detection:
   if (iCh == 1)
      [spk,blockObj.SDPars] = PerChannelDetection(data,pars);
   else
      spk = PerChannelDetection(data,pars);
   end
   
   % Save using DiskData pointer to the file:
   blockObj.Channels(iCh).Spikes = ...
      nigeLab.libs.DiskData('MatFile',fullfile(fName),spk,'access','w');
   blockObj.Channels(iCh).Spikes = lockData(...
      blockObj.Channels(iCh).Spikes);
   
   % And update the status indicator in Command Window:
   fraction_done = 100 * (iCh / nCh);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
   
end

% Indicate that it is finished at the end
blockObj.updateStatus('Spikes',true);
blockObj.save;
flag = true;

   function [spk,pars] = PerChannelDetection(data, pars)
      %% PERCHANNELDETECTION  Main sub-function for thresholding and detection
      %
      %   spk = PERCHANNELDETECTION(data,pars);
      %   [spk,pars] = PERCHANNELDETECTION(data,pars);
      %
      %   --------
      %    INPUTS
      %   --------
      %     data      :       Filtered and re-referenced data (in micro-volts) of
      %                       a single channel of input data.
      %
      %     pars      :       Parameter structure that contains things like the
      %                       sampling frequency, which will be passed through to
      %                       other sub-functions called from SPIKEDETECTIONARRAY
      %
      %   --------
      %    OUTPUT
      %   --------
      %     spk       :       Structure containing detected spikes as a sparse
      %                       array (peak_train); artifact occurrences as a
      %                       sparse array (artifact); and spike waveforms
      %                       corresponding to each positive entry of peak_train
      %                       (spikes).
      %
      %     pars      :       Updated parameters with new spike-related
      %                       variables.
      %
      % Adapted by: MAECI 2018 Collaboration (Federico Barban & Max Murphy)
      
      %% CONVERT PARAMETERS
      pars.w_pre       =   double(round(pars.W_PRE / 1000 * pars.FS));        % Samples before spike
      pars.w_post      =   double(round(pars.W_POST / 1000 * pars.FS));       % Samples after spike
      pars.ls          =   double(pars.w_pre+pars.w_post);                    % Length of spike
      pars.art_dist    =   double(pars.ART_DIST*pars.FS);                     % Maximum Stimulation frequency
      pars.PLP         =   double(floor(pars.PKDURATION*1e-3*pars.FS));       % Pulse lifetime period [samples]
      pars.RP          =   double(floor(pars.REFRTIME*1e-3*pars.FS));         % Refractory period  [samples]
      pars.nc_artifact =   double(floor(pars.ARTIFACT_SPACE*1e-3*pars.FS));   % PLP [samples]
      pars.npoints     =   double(length(data));                               % Sample length of record
      if pars.PRESCALED
         pars.th_artifact = pars.ARTIFACT_THRESH;
      else
         pars.th_artifact = pars.ARTIFACT_THRESH * 1e-6;
      end
      
      %% REMOVE ARTIFACT
      if ~isempty(pars.STIM_TS)
         data_ART = RemoveStimPeriods(data,pars);
      else
         data_ART = data;
      end
      
      if ~isempty(pars.ARTIFACT)
         [data_ART,art_idx] = RemoveArtifactPeriods(data_ART,pars.ARTIFACT);
      else
         art_idx = [];
      end
      [data_ART,artifact] = HardArtifactRejection(data_ART,pars);
      
      %% COMPUTE SPIKE THRESHOLD AND DO DETECTION
      % SpikeDetection_PTSD_core.cpp;
      if mod(pars.PLP,2)>0
         pars.PLP = pars.PLP + 1; % PLP must be even or doesn't work...
      end
      data_ART = double(data_ART);
      
      switch pars.PKDETECT
         case 'both' % (old, probably not using any more -MM 8/3/2017)
            tmpdata = data_ART;
            tmpdata(art_idx) = [];
            pars.thresh = PreciseTimingThreshold(tmpdata,pars);
            [spkValues, spkTimeStamps] = SpikeDetection_PTSD_core(data_ART, ...
               pars.thresh, ...
               pars.PLP, ...
               pars.RP, ...
               pars.ALIGNFLAG);
            
            % +1 added to accomodate for zero- (c) or one-based (matlab) array indexing
            ts  = 1 + spkTimeStamps( spkTimeStamps > 0);
            p2pamp = spkValues( spkTimeStamps > 0);
            pw = nan(size(p2pamp));
            pp = nan(size(p2pamp));
            
            clear spkValues spkTimeStamps;
            
         case 'neg' % (probably use this in future -MM 8/3/2017)
            
            pars.thresh = pars.FIXED_THRESH;
            
            [p2pamp,ts,pw,pp] = ThresholdDetection(data_ART,pars,-1);
            
         case 'pos'
            
            pars.thresh = pars.FIXED_THRESH;
            
            [p2pamp,ts,pw,pp] = ThresholdDetection(data_ART,pars,1);
            
         case 'adapt' % Use findpeaks in conjunction w/ adaptive thresh -12/13/17
            pars.thresh = pars.MULTCOEFF;
            [p2pamp,ts,pw,pp] = AdaptiveThreshold(data_ART,pars);
            
         case 'sneo' % Use findpeaks in conjunction w/ SNEO - 1/4/17
            pars.thresh = pars.MULTCOEFF;
            [p2pamp,ts,pw,pp,E] = SNEOThreshold(data_ART,pars,art_idx);
         otherwise
            error('Invalid PKDETECT specification.');
      end
      %% ENSURE NO SPIKES REMAIN FROM ARTIFACT PERIODS
      if any(artifact)
         [ts,ia]=setdiff(ts,artifact);
         p2pamp=p2pamp(ia);
         pw = pw(ia);
         pp = pp(ia);
         if exist('E','var')~=0
            E = E(ia);
         end
      end
      
      %% EXCLUDE SPIKES THAT WOULD GO OUTSIDE THE RECORD
      out_of_record = ts <= pars.w_pre+1 | ts >= pars.npoints-pars.w_post-2;
      p2pamp(out_of_record) = [];
      pw(out_of_record) = [];
      pp(out_of_record) = [];
      ts(out_of_record) = [];
      if exist('E','var')~=0
         E(out_of_record) = [];
      end
      
      %% BUILD SPIKE SNIPPET ARRAY AND PEAK_TRAIN
      if (any(ts)) % If there are spikes in the current signal
         
         [peak_train,spikes] = BuildSpikeArray(data,ts,p2pamp,pars);
         
         %No interpolation in this case
         if length(spikes) > 1
            %eliminates borders that were introduced for interpolation
            spikes(:,end-1:end)=[];
            spikes(:,1:2)=[];
         end
         
         % Extract spike features
         if size(spikes,1) > pars.MIN_SPK % Need minimum number of spikes
            features = WaveFeatures(spikes,pars);
            features = features./std(features);
            if ~any(isnan(p2pamp))
               tmp = (reshape(p2pamp,size(features,1),1)./max(p2pamp)-0.5)*3.0;
               features = [features, tmp];
               if ~ismember({'pk-amp'},pars.FEAT_NAMES)
                  pars.FEAT_NAMES = [pars.FEAT_NAMES, {'pk-amp'}];
               end
            end
            if ~any(isnan(pp))
               tmp = (reshape(pp,size(features,1),1)./max(pp)-0.5)*3.0;
               features = [features, tmp];
               if ~ismember({'pk-prom'},pars.FEAT_NAMES)
                  pars.FEAT_NAMES = [pars.FEAT_NAMES, {'pk-prom'}];
               end
            end
            if ~any(isnan(pw))
               tmp = (reshape(pw,size(features,1),1)./max(pw)-0.5)*3.0;
               features = [features, tmp];
               if ~ismember({'pk-width'},pars.FEAT_NAMES)
                  pars.FEAT_NAMES = [pars.FEAT_NAMES, {'pk-width'}];
               end
            end
            if exist('E','var')~=0
               tmp = (reshape(E,size(features,1),1)./max(E)-0.5)*3.0;
               features = [features, tmp];
               if ~ismember({'pk-energy'},pars.FEAT_NAMES)
                  pars.FEAT_NAMES = [pars.FEAT_NAMES, {'pk-energy'}];
               end
            end
         else
            % Just make features reflect poor quality of (small) cluster
            features = randn(size(spikes,1),pars.NINPUT) * 10;
         end
         
      else % If there are no spikes in the current signal
         peak_train = sparse(double(pars.npoints) + double(pars.w_post), double(1));
         spikes = [];
         features = [];
      end
      
      %% ASSIGN OUTPUT
      spk.peak_train = peak_train;      % Spike (neg.) peak times
      spk.artifact = artifact;          % Artifact times
      spk.spikes = spikes;              % Spike snippets
      spk.features = features;          % Wavelet features
      spk.pp = pp;                      % Prominence (peak min. for 'adapt')
      spk.pw = pw;                      % Width (peak max. for 'adapt')
      
   end

end