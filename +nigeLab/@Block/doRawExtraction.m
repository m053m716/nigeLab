function flag = doRawExtraction(blockObj)
%% CONVERT  Convert raw data files to Matlab TANK-BLOCK structure object
%
%  b = nigeLab.Block;
%  flag = doRawExtraction(b);
%
%  --------
%   OUTPUT
%  --------
%   flag       :     Returns true if conversion was successful.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE EXTRACTION DEPENDING ON RECORDING TYPE AND FILE EXTENSION
% If returns before completion, indicate failure to complete with flag
flag = false; 
if ~genPaths(blockObj)
   warning('Something went wrong when generating paths for extraction.');
   return;
end

%% Check for MultiAnimals
% More than one animal can be recorded simultaneously in one single file. 
% Thi eventuality is explicitely handled here. The init process looks for a
% special char string in the block ID (defined in defaults), if detected
% the flag ManyAnimalsLinkedBlocks is set true. 
% The function splitMultiAnimals prompts the user to assign channels and
% other inputs to the different animals. When this is done two or ore child
% blocks are initialized and stored in the ManyAnimalsLinkedBlocks field.
 
% flag = [blockObj.ManyAnimals ~isempty(blockObj.ManyAnimalsLinkedBlocks)];
% if all(flag == [false true]) % child block. Call rawExtraction on father
%     blockObj.ManyAnimalsLinkedBlocks.doRawExtraction;
% elseif all(flag == [true false]) % father block without childern. Call splitMultiAnimals
%     blockObj.splitMultiAnimals;
% elseif all(flag == [true true])  % father block with children. Go on with extraction and move files at the end
%     ManyAnimals = true;
% else
% end
%% extraction
switch blockObj.RecType
   case 'Intan'
      flag = blockObj.intan2Block;
      
%       % Two types of Intan binary files: rhd and rhs
%       switch blockObj.FileExt
%          case '.rhs'
%             flag = rhs2Block(blockObj);
%          case '.rhd'
%             flag = rhd2Block(blockObj);
%          otherwise
%             warning('Invalid file type (%s).',blockObj.FileExt);
%             return;
%       end
      
   case 'TDT'
      % TDT raw data already has a sort of "BLOCK" structure that should be
      % parsed to get this information.
      nigeLab.utils.cprintf('UnterminatedStrings','%s extraction is still WIP. It might take a while.',...
         blockObj.RecType);
      flag = tdt2Block(blockObj);
      
   case 'mat'
      % Federico did you add this? I don't think there are plans to add
      % support for acquisition that streams to Matlab files...? -MM
      warning('%s is not yet supported, but will be added.',...
         blockObj.RecType);
      return;
      
   otherwise
      % Currently only working with TDT and Intan, the two types of
      % acquisition hardware that are in place at Nudo Lab at KUMC, and at
      % Chiappalone Lab at IIT.
      warning('%s is not a supported (case-sensitive).',...
         blockObj.RecType);
      return;
end

%%
blockObj.updateStatus('Raw',true);
blockObj.save;
notify(blockObj,processCompleteEvent);
end