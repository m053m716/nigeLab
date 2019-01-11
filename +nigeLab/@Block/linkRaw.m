function flag = linkRaw(blockObj)
%% LINKRAW   Connect the raw data saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = LINKRAW(b);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
flag = false;
updateFlag = false(1,blockObj.NumChannels);

fprintf(1,'\nLinking RAW channels...000%%\n');
counter = 0;
for iCh = blockObj.Mask
   
   % Get file name
   pnum  = num2str(blockObj.ChannelID(iCh,1));
   chnum = num2str(blockObj.ChannelID(iCh,2),'%03g');
   fname = sprintf(strrep(blockObj.paths.RW_N,'\','/'), ...
      pnum,chnum);
   fname = fullfile(fname);
   
   % If file is not detected
   if ~exist(fullfile(fname),'file')
      flag = true;
   else
      updateFlag(iCh) = true;
      blockObj.Channels(iCh).Raw = ...
         nigeLab.libs.DiskData(blockObj.SaveFormat,fname);
   end
   
   counter = counter + 1;
   fraction_done = 100 * (counter / numel(blockObj.Mask));
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end
blockObj.updateStatus('Raw',updateFlag);

end