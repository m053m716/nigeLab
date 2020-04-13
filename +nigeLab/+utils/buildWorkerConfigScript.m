function varargout = buildWorkerConfigScript(queueMode,varargin)
%BUILDWORKERCONFIGSCRIPT  Programmatically creates a worker config file
%
%  configFile = nigeLab.utils.buildWorkerConfigScript();
%  --> defaults to 'fromRemote' queueMode (i.e. FB method)
%     --> Used if running from T:\Scripts_Circuits
%  configFile = nigeLab.utils.buildWorkerConfigScript('fromLocal',varargin);
%     --> Used if running from local repository that is not on same server
%         as the remote location, but the data and a clone of the
%         repository are set up on the remote location. (i.e. MM method)
%     --> varargin{1}: The full file path of the remote repo to add to path
%     --> varargin{2}: Name of the operation
%     --> varargin{3}: "Debug" output location on remote
%                       (Block.Pars.Notifications('DBLoc'))
%
%  configFile  --  Char array that is the full filename (including path) of
%                    the script to attach to the job and run on the worker.

%% Imports and Defaults
import nigeLab.defaults.Tempdir nigeLab.utils.getNigelPath
CONFIG_SCRIPT_NAME = 'configW.m'; % Script that adds path of repo
WRAPPER_FCN_NAME = 'qWrapper.m';  % "Wrapper" for remote queue execution

%%
if nargin < 1
   queueMode = 'fromLocal';
end

if ~ischar(queueMode)
   error(['nigeLab:' mfilename ':BadInputType2'],...
      'Unexpected class for ''queueMode'' input: %s\n',class(queueMode));
end

configFile = fullfile(Tempdir,CONFIG_SCRIPT_NAME);
switch lower(queueMode)
   case {'remote','fromremote'}
      % Just makes sure nigeLab is added to path (didn't work for MM)
      % This works if the method is queued FROM repo on remote location:
      p =  varargin{1};
      if ~iscell(p)
         p = {p};
      end
      makeConfigScript(configFile,p);
      varargout = {configFile};
   case {'local','fromlocal'}
      % "Wrap" everything in a script that is executed by the worker,
      % instead of the `doAction`
      p = getNigelPath('UNC');
      if ~iscell(p)
         p = {p};
      end
      operation = varargin{2};
      if numel(varargin) > 2
         db_p = varargin{3};
      end
      if numel(varargin) > 3
         add_debug_outputs = varargin{4};
      else
         add_debug_outputs = false;
      end
      
      makeConfigScript(configFile,p);
      
      wrapperFile = fullfile(Tempdir,WRAPPER_FCN_NAME);
      if numel(varargin) > 2
         if add_debug_outputs
            makeWrapperFunction_debug(wrapperFile,operation,p,db_p);
         else
            makeWrapperFunction(wrapperFile,operation,p);
         end
      else
         makeWrapperFunction(wrapperFile,operation,p);
      end
      
      varargout = cell(1,2);
      varargout{1} = configFile;
      varargout{2} = wrapperFile;
   otherwise
      error(['nigeLab:' mfilename ':UnexpectedString'],...
         ['Unexpected case: %s\n' ...
          '(should be ''fromRemote'' or ''fromLocal'')\n'],...
         queueMode);
end

   % Add generator function name and date/time of creation to
   % programmatically-generated function or script
   function addAutoSignature(fid,fname)
      %ADDAUTOSIGNATURE  Helper function to add generator name & datetime
      %
      %  addAutoSignature(fid,fname);
      
      fprintf(fid,'%%\n');
      fprintf(fid,'%% Auto-generated by %s:\n',fname);
      fprintf(fid,'%%\t\t%s\n\n',char(datetime));
   end

   % Helper-function to make "configW.m" configuration script
   function makeConfigScript(configFile,p)
      %MAKECONFIGSCRIPT  Makes "configW.m" worker configuration script
      %
      %  makeConfigScript(configFile);
      
      if exist(configFile,'file')~=0
         delete(configFile);
      end
      fid = fopen(configFile,'w');
      fprintf(fid,'%%CONFIGW  Programmatically-generated path adder\n');
      fprintf(fid,'%%\n');
      fprintf(fid,'%%\tconfigW; Add nigeLab remote repo to worker path\n');
      addAutoSignature(fid,sprintf('nigeLab.utils.%s',mfilename));

      for i = 1:numel(p)
         fprintf(fid,'if exist(''%s'',''dir'')==0 %% check if good\n\t',p{i});
         fprintf(fid,'error([''nigeLab:'' mfilename '':Debug''],...%%dbug\n');
         fprintf(fid,'\t\t''Worker (%%s) does not see nigeLab (%%s)'',...\n');
         fprintf(fid,'\t\tpwd,''%s'');\n',p{i});
         fprintf(fid,'end %% error check for remote repo path\n');
      end
      % Add path to remote repository
      fprintf(fid,'%%%% Add remote nigeLab repository.\n');
      for i = 1:numel(p)
         fprintf(fid,'addpath(''%s''); %% Parsed repo location\n',p{i});
      end
      
%       % Attempt to add `import` packages (doesn't work)
%       fprintf(fid,'addpath(''%s''); %% Parsed repo location\n\n',p);
%       fprintf(fid,'%%%% Import getNigelPath to make sure we add path\n');
%       fprintf(fid,'import nigeLab.utils.getNigelPath\n'); 
%       fprintf(fid,'p = getNigelPath(''UNC''); %% Return worker path\n');
%       fprintf(fid,'addpath(p); %% Add "imported" path');
      fclose(fid);
   end

   % Helper-function to make wrapper function for running qOperation. This
   % version is faster than debug version.
   function makeWrapperFunction(wrapperFile,operation,p)
      %MAKEWRAPPERFUNCTION  Make wrapper function for running qOperation
      %
      %  makeWrapperFunction(wrapperFile,operation,p);
      
      if exist(wrapperFile,'file')~=0
         delete(wrapperFile);
      end
      fid = fopen(wrapperFile,'w');
      fprintf(fid,'function qWrapper(targetFile)\n');
      fprintf(fid,'%%QWRAPPER  Programmatically-generated fcn wrapper\n');
      fprintf(fid,'%%\n');
      fprintf(fid,'%%\tqWrapper(targetFile); Run nigelLab on target\n');
      fprintf(fid,'%%\n');
      fprintf(fid,'%%\t\t--> NON-DEBUG VERSION <--\n');
      addAutoSignature(fid,sprintf('nigeLab.utils.%s',mfilename));
      
      fprintf(fid,'%%%% Add paths to this location\n');
      for i = 1:numel(p)
         fprintf(fid,'addpath(''%s''); %% Fixed repo location\n',p{i});
      end

      fprintf(fid,'\n%%%% Get handle to current job\n');
      fprintf(fid,'curJob = getCurrentJob;\n\n');
      fprintf(fid,'if numel(curJob) > 1 %% Just in case\n\t');
      fprintf(fid,'curJob = curJob(1);\n');
      fprintf(fid,'elseif numel(curJob) < 1 %% Should never happen\n\t');
      fprintf(fid,'error([''nigeLab:'' mfilename '':BadJobInit''],...\n');
      fprintf(fid,'\t\t\t''Could not find current job.'');\n');
      fprintf(fid,'end\n');
      
      fprintf(fid,'[~,tag]=nigeLab.utils.jobTag2Pct(curJob.Tag);\n');
      fprintf(fid,'curJob.Tag=strrep(curJob(1).Tag,tag,''Loading'');\n');
      
      fprintf(fid,'%%%% Attempt to load target Block.\n');
      fprintf(fid,'blockObj = nigeLab.Block.loadRemote(targetFile);\n\n');
      fprintf(fid,'delim = blockObj.Pars.Notifications.TagDelim;\n');
      fprintf(fid,'[~,tag,name]=nigeLab.utils.jobTag2Pct(curJob.Tag,delim);\n');
      fprintf(fid,'curJob.Tag=strrep(curJob.Tag,tag,''Updating'');\n');
      
      fprintf(fid,'%%%% Now Block is successfully loaded. Update properties\n');
      fprintf(fid,'blockObj.OnRemote = true; %% Currently on REMOTE\n');
      fprintf(fid,'blockObj.CurrentJob = curJob; %% Assign JOB\n');
      
      fprintf(fid,'%%%% Finally, we run the queued `doAction`\n');
      fprintf(fid,'%s(blockObj); %% Runs queued `doAction (%s)`\n',...
         operation,operation);
      fprintf(fid,'field = blockObj.getOperationField(''%s'');\n',...
         operation);
      fprintf(fid,'blockObj.linkToData(field); %% Link\n');
      fprintf(fid,'save(blockObj);\n\n');
      fprintf(fid,'curJob.Tag=sprintf(''%%s %%s||%%g%%%%'',name,''Done'',100);\n');
      fprintf(fid,'end');
      fclose(fid);
   end

   % Helper-function to make wrapper function for running qOperation. This
   % version puts outputs helpful for debugging or optimizing code run on
   % the remote workers, but takes longer to run.
   function makeWrapperFunction_debug(wrapperFile,operation,p,db_p)
      %MAKEWRAPPERFUNCTION_DEBUG  Debug function for running qWrapper
      %
      %  makeWrapperFunction_debug(wrapperFile,operation,p,db_p);
      
      if nargin < 3
         db_p = 'C:/Remote_Matlab_Debug_Logs';
      end
      
      if exist(wrapperFile,'file')~=0
         delete(wrapperFile);
      end
      fid = fopen(wrapperFile,'w');
      fprintf(fid,'function qWrapper(targetFile)\n');
      fprintf(fid,'%%QWRAPPER  Programmatically-generated fcn wrapper\n');
      fprintf(fid,'%%\n');
      fprintf(fid,'%%\tqWrapper(targetFile); Run nigelLab on target\n');
      fprintf(fid,'%%\n');
      fprintf(fid,'%%\t\t--> DEBUG VERSION <--\n');
      addAutoSignature(fid,sprintf('nigeLab.utils.%s',mfilename));
      
      % DEBUG
      fprintf(fid,'%%%% Make a debug log for troubleshooting remote\n');
      fprintf(fid,'profile on; %% Turn on Matlab Profiler\n');
      fprintf(fid,'db_p = ''%s''; %% Debug filepath\n',db_p);
      fprintf(fid,'logName = fullfile(db_p,''logs.txt'');\n');
      fprintf(fid,'if exist(db_p,''dir'')==0\n\t');
      fprintf(fid,'mkdir(db_p); %% Make sure debug path is good\n');
      fprintf(fid,'end %% if folder does not exist make debug folder\n\n');
      fprintf(fid,'db_id = fopen(logName,''w''); %% Make debug logs\n');
      fprintf(fid,'iCount = 0;\n');
      fprintf(fid,'while (db_id == -1) && (iCount < 10) %% Make sure it opens\n\t');
      fprintf(fid,'iCount = iCount + 1;\n\t');
      fprintf(fid,'db_id = fopen(logName,''a''); %% Retry fopen\n\t');
      fprintf(fid,'pause(20); %% Give it a few before retry\n');
      fprintf(fid,'end %% end while\n\n');
      
      fprintf(fid,'if db_id == -1 %% Throw error if not opened\n\t');
      fprintf(fid,['error([''nigeLab:'' mfilename '':DebugLogOpen''],' ...
                  ' ...\n\t\t' ...
                  '''Could not open debug file (logs.txt)'');\n']);
      fprintf(fid,'end %% if db == -1\n\n');
      fprintf(fid,['fprintf(db_id,''\\n(%%s) Worker path: %%s\\n' ...
                   '(%%s) Target: %%s\\n'', ...\n\t\t' ...
                   'char(datetime),pwd,' ...
                   'char(datetime),targetFile);\n\n']);
      
      fprintf(fid,'%%%% Add paths to this location\n');
      for i = 1:numel(p)
         fprintf(fid,'addpath(''%s''); %% Fixed repo location\n',p{i});
      end

      fprintf(fid,'\n%%%% Get handle to current job\n');
      fprintf(fid,'pause(15);\n');
      fprintf(fid,'curJob = getCurrentJob;\n');
      fprintf(fid,'fprintf(db_id,''(%%s) Current Job: '',char(datetime));\n');
      fprintf(fid,'if isempty(curJob)\n');
      fprintf(fid,'\tfprintf(db_id,''EMPTY\\n'');\n');
      fprintf(fid,'else\n');
      fprintf(fid,'\tfprintf(db_id,'' (%%s) '',class(curJob));\n');
      fprintf(fid,'\tif isvalid(curJob)\n');
      fprintf(fid,'\t\tfprintf(db_id,''%%s\\n'',curJob(1).Tag);\n');
      fprintf(fid,['\t\tfprintf(db_id,''(%%s) ' ...
         '%%g element(s) in curJob array\\n'', ...\n\t\t\t' ...
         'char(datetime),numel(curJob));\n']);
      fprintf(fid,'\t\t[~,tag]=nigeLab.utils.jobTag2Pct(curJob(1).Tag);\n');
      fprintf(fid,'\t\tcurJob(1).Tag = strrep(curJob(1).Tag,tag,''Loading'');\n');
      fprintf(fid,'\telse\n');
      fprintf(fid,'\t\tfprintf(db_id,''(%%s) INVALID\\n'',char(datetime));\n');
      fprintf(fid,'\tend %% end isvalid\n');
      fprintf(fid,'end %% end isempty\n\n');

      fprintf(fid,'%%%% Attempt to load target Block.\n');
      fprintf(fid,'%% Do some error-checking\n');
      fprintf(fid,'try\n\t');
      fprintf(fid,'blockObj = nigeLab.Block.loadRemote(targetFile);\n');
      fprintf(fid,'catch me\n\t');
      fprintf(fid,['if strcmp(me.identifier,' ...
                   '''nigeLab:loadRemote:ObjectNotFound'')\n\t\t']);
      fprintf(fid,'error([''nigeLab:'' mfilename '':BadLoad''],...\n\t\t');
      fprintf(fid,'\t''nigeLab not found (@ %%s)\\n'',pwd);\n\t');
      fprintf(fid,'else\n\t\t');
      fprintf(fid,'rethrow(me);\n\t');
      fprintf(fid,'end %% end compare identifier\n');
      fprintf(fid,'end %% end try load ... catch\n\n');
      fprintf(fid,'%%%% Print to remote Command Window for debugging\n');
      
      fprintf(fid,'if ~isempty(curJob)\n');
      fprintf(fid,'\tif isvalid(curJob)\n');
      fprintf(fid,'\t\tcurJob(1).Tag = strrep(curJob(1).Tag,''Loading'',''Running'');\n');
      fprintf(fid,'\tend %% end isvalid\n');
      fprintf(fid,'end %% end ~isempty\n\n');
      
      fprintf(fid,['fprintf(db_id,''(%%s) ->\\tLoaded %%s successfully!\\n'','...
       ' ...\n\t' ...
       'char(datetime),blockObj.Name); %% Update logs\n']);
      fprintf(fid,['fprintf(db_id,''(%%s) \\t->\\t(Class: %%s)\\n'','...
       ' ...\n\t' ...
       'char(datetime),class(blockObj)); %% For debugging \n\n']);
      
      fprintf(fid,'%%%% Check that this is a valid method of blockObj\n');
      fprintf(fid,'if ~ismethod(blockObj,''%s'')\n',operation);
      fprintf(fid,['\terror([''nigelab:'' mfilename '':InvalidMethodName''], '...
                   '...\n\t\t' ...
                   '''%s is not a valid doAction.'');\n'],operation);
      fprintf(fid,'end\n\n');
      
      fprintf(fid,'%%%% Now Block is successfully loaded. Update props.\n');
      fprintf(fid,'blockObj.OnRemote = true; %% Currently on REMOTE\n');
      fprintf(fid,'blockObj.CurrentJob = curJob(1); %% Assign JOB\n');
      fprintf(fid,'blockObj.updateParams(''Notifications'');\n');
      fprintf(fid,['fprintf(db_id,''(%%s) \\t->\\t(Updated Pars.Notifications)\\n'','...
       ' ...\n\t' ...
       'char(datetime)); %% For debugging \n']);
      fprintf(fid,'blockObj.updateParams(''Queue'');\n');
      fprintf(fid,['fprintf(db_id,''(%%s) \\t->\\t(Updated Pars.Queue)\\n'','...
       ' ...\n\t' ...
       'char(datetime)); %% For debugging \n']);
      fprintf(fid,['fprintf(db_id,''(%%s) \\t->\\t(Running %s...)\\n'','...
         ' ...\n\t' ...
         'char(datetime)); %% For debugging \n'],operation);
      fprintf(fid,'fclose(db_id); %% End debug logging\n\n');
      
      fprintf(fid,'%%%% Finally, we run the queued `doAction`\n');
      fprintf(fid,'%s(blockObj); %% Runs queued `doAction (%s)`\n',...
         operation,operation);
      fprintf(fid,'blockObj.OnRemote = false; %% Turn off REMOTE\n');
      fprintf(fid,'blockObj.CurrentJob = []; %% Remove JOB\n');
      fprintf(fid,'save(blockObj);\n\n');
      
      fprintf(fid,'%%%% Indicate complete in debug logs and save profiler\n');
      fprintf(fid,'blockObj.reportProgress(''Saving-Logs'',100,''toWindow'',''Saving-Logs'');\n');
      fprintf(fid,'db_id = fopen(logName,''a''); %% Add to logs\n');
      fprintf(fid,'fprintf(db_id,''(%%s) %s complete.\\n'',char(datetime));\n',...
         operation);
      
      fprintf(fid,'profiler_results = profile(''info''); %% Return Profiler struct\n');
      fprintf(fid,'prof_dir = ''ProfileResults_%04g''; %% Random ID\n',...
         randi(9999,1));
      fprintf(fid,'out_dir = fullfile(db_p,prof_dir);\n');
      fprintf(fid,'if exist(out_dir,''dir'')==0\n\t');
      fprintf(fid,'mkdir(out_dir);\n');
      fprintf(fid,'else\n\t');
      fprintf(fid,'rmdir(out_dir); %% First, clear output path \n\t');
      fprintf(fid,'mkdir(out_dir); %% Then make new one \n');
      fprintf(fid,'end\n\n');
      
      fprintf(fid,'fprintf(db_id,''--> IN: %%s <--'',out_dir);\n');
      fprintf(fid,'fclose(db_id);\n\n');
      
      fprintf(fid,['save(fullfile(out_dir,''Results.mat''),...\n\t' ...
         '''profiler_results'',''-v7.3'');\n']);
      fprintf(fid,'profsave(profiler_results,out_dir);\n\n');
      
      fprintf(fid,'blockObj.reportProgress(''Done'',100,''toWindow'',''Done'');\n');
      fprintf(fid,'end');
      fclose(fid);
   end
end