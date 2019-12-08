function L = list(blockObj)
% LIST  Give list of current files associated with field.
%
%  L = blockObj.LIST;
%
%  --------
%   INPUTS
%  --------
%  blockObj :     nigeLab.Block class object.
%
%  --------
%   OUTPUT
%  --------
%     L     :     Table with information about blockObj.

%% PARSE DATE AND TIME INFO
Format = '';
str='';
if ~strcmp(blockObj.Meta.RecDate,'YYMMDD')
    Format = [Format 'yyMMdd'];
    str = [str blockObj.Meta.RecDate];
end
if ~strcmp(blockObj.Meta.RecTime,'hhmmss')
    Format = [Format 'HHmmss' ];
    str = [str blockObj.Meta.RecTime];
end

try
DateTime=datetime(str,'InputFormat',Format);
catch
   DateTime=NaT;
end
                
info.Recording_date=DateTime;
info.LengthInMinutes=minutes(seconds((blockObj.Samples./blockObj.SampleRate)));

%% PARSE ANIMAL AND RECORDING ID
infoFields={'AnimalID'
            'RecID'};
for jj=1:numel(infoFields)
   if isfield(blockObj.Meta,infoFields{jj})
      info.(infoFields{jj})={blockObj.Meta.(infoFields{jj})};
   else
      info.(infoFields{jj})='Unspecified';
   end
end

%% PARSE RECORDING TYPE AND TOTAL NUMBER OF CHANNELS
infoFields={'RecType'
            'NumChannels'
            };
for jj=1:numel(infoFields)
   if isprop(blockObj,infoFields{jj})
      info.(infoFields{jj})={blockObj.(infoFields{jj})};
   else
      info.(infoFields{jj})='Unspecified';
   end
end

% Update RecType (for example, for Intan .rhd or .rhs; TDT will not have a
% file extension though.
info.RecType={sprintf('%s (%s)',info.RecType{:},blockObj.FileExt)};

%% PARSE CURRENT STATUS OF PROCESSING
St = blockObj.getStatus;
info.Status = sprintf([repmat('%s,',1,numel(St)) '\b'],St{:});


%% CONVERT STRUCT INTO TABLE FORMAT SO IT CAN BE PRINTED TO COMMAND WINDOW
L_=struct2table(info,'AsArray',true);
for ii=1:length(L_.Properties.VariableNames)
    switch L_.Properties.VariableNames{ii}
        case 'Corresponding_animal' % Deprecated I think ? -MM
            L_.Properties.VariableNames{ii}='Animal';
        case 'RecType'
            L_.Properties.VariableNames{ii}='RecordingType';
        case 'numChannels' % Deprecated as well? -MM
            L_.Properties.VariableNames{ii}='NumberOfChannels';
    end
end

%% IF OUTPUT ARGUMENT IS REQUESTED, DO NOT DISPLAY IT
if nargout==0
    disp(L_);
else
    L=L_;
end

end