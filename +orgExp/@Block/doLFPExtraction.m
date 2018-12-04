function doLFPExtraction(blockObj)
%% DOLFPEXTRACTION   Decimates files to retrieve LFPs.
%
% Sampling frequency chosen for the downsampled files is 1000Hz
% Band of interest in LFPs is up to 250Hz.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)


%% INITIALIZE PARAMETERS

blockObj.LFPPars = orgExp.defaults.LFP;

DecimateCascadeM = blockObj.LFPPars.DecimateCascadeM;
DecimateCascadeN = blockObj.LFPPars.DecimateCascadeN;
DecimationFactor =   blockObj.LFPPars.DecimationFactor;
blockObj.LFPPars.DownSampledRate = blockObj.SampleRate / DecimationFactor;

%% DECIMATE DATA AND SAVE IT
fprintf(1,'Decimating raw data... %.3d%%\n',0);
for iCh=1:blockObj.NumChannels
   % Get the values from Raw DiskData, and decimate:
   data=double(blockObj.Channels(iCh).Raw(:));
   for jj=1:numel(DecimateCascadeM)
      data=decimate(data,DecimateCascadeM(jj),DecimateCascadeN(jj));
   end
   
   % Get the file name:
   fName = parseFileName(blockObj,iCh);
   
   % Assign to diskData and protect it:
   blockObj.Channels(iCh).LFP=orgExp.libs.DiskData(blockObj.SaveFormat,...
      fName,data,'access','w');
   blockObj.Channels(iCh).LFP = lockData(blockObj.Channels(iCh).LFP);
   
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
   
end
blockObj.updateStatus('LFP',true);
blockObj.save;

   function fName = parseFileName(blockObj,channel)
      pNum  = num2str(blockObj.Channels(channel).port_number);
      chIdx = regexp(blockObj.Channels(channel).custom_channel_name, '\d');
      chNum = blockObj.Channels(channel).custom_channel_name(chIdx);
      fName = sprintf(strrep(blockObj.paths.LW_N,'\','/'), pNum, chNum);
   end

end
