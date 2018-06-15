function init(tankObj)
%% INIT Initialize TANK object
%
%  tankObj.INIT;
%
%  By: Max Murphy v1.0  06/14/2018 Original version (R2017b)
 
%% PARSE NAME AND SAVE LOCATION
tankObj.Name = strsplit(tankObj.DIR,filesep);
tankObj.Name = tankObj.Name{end};

if isempty(tankObj.Save_Loc)
   tankObj.Save_Loc = fullfile('P:\Extracted_Data_To_Move\Rat',...
                              tankObj.RecType,tankObj.Name);
   if exist(tankObj.Save_Loc,'dir')==0
      mkdir(tankObj.Save_Loc);
      tankObj.ExtractFlag = true;
   else
      tankObj.ExtractFlag = false;
   end
end

%% PARSING NAME METADATA DEPENDS ON RECORDING SYSTEM
switch tankObj.RecType
   case 'Intan'
      
   case 'TDT'
      
   otherwise
      error('Invalid recording system type. Case sensitive.');
end

end