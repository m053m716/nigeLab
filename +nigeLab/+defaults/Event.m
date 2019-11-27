function pars = Event(paramName)
%% EVENT    Template for initializing parameters related to EVENTS
%
%  pars = nigeLab.defaults.Event(); Return full pars struct
%  --> Returns pars, a struct with the following fields:
%     * Name : Cell array of Event Names
%     * Fields : Cell array of Field names corresponding to pars.Name
%     * EventType : Struct "key" defining 'manual' and 'auto' Events
%
%  paramVal = nigeLab.defaults.Event('paramName'); % Return specific value
%
% By: MAECI 2018 collaboration (MM, FB)

%% Change values here
pars = struct;
% "Name" of Events
% pars.Name = {...    % Example A (RHS)
%    'Stim';            % 1)  Stimulation times and data
%    'Sync';            % 2)  Sync LED times
%    'User';            % 3)  User digital marker onsets
%    'LPellet';         % 4)  Left pellet beam break onsets
%    'LButtonDown';     % 5)  Left-button press onset
%    'LButtonUp';       % 6)  Left-button press offset
%    'RPellet';         % 7)  Right pellet beam break onsets
%    'RButtonDown';     % 8)  Right-button press onset
%    'RButtonUp';       % 9)  Right-button press offset
%    'Beam';            % 10) Reach beam break
%    'Nose';            % 11) Nose-poke beam break
%    'Epoch';           % 12) Onsets mid-trial epochs
%    };           
pars.Name = {... % Example B (KUMC: "RC" project -- MM) Note: each 'Event' with different timestamps needs its own 'Events' element
   'Reach';       % 1)
   'Grasp';       % 2)
   'Support';     % 3)
   'Complete';    % 4)
   };            
   
% This should match number of elements of Events:
% pars.Fields = {...    % Example A (RHS)
%    'Stim';            % 1) 
%    'DigEvents';       % 2)
%    'DigEvents';       % 3)
%    'DigEvents';       % 4)
%    'DigEvents';       % 5)
%    'DigEvents';       % 6)
%    'DigEvents';       % 7)
%    'DigEvents';       % 8)
%    'DigEvents';       % 9)
%    'DigEvents';       % 10) All beam breaks (Pellets, Beam, Nose) could be 
%    'DigEvents';       % 11) 'AnalogIO' as well?
%    'DigEvents';       % 12) Could be 'Notes' ?
%    };

pars.Fields = {...   % KUMC: "RC" project (MM)
   'ScoredEvents';   % 1) % Should match one of the elements from
   'ScoredEvents';   % 2) % defaults.Block cell array "Fields"
   'ScoredEvents';   % 3)
   'ScoredEvents';   % 4)
   };

% Key that defines whether events are 'manual' (e.g. video scoring) or 
% 'auto' (e.g. parsed from stream in some way). Should have one entry for
% any unique entry to 'pars.Fields'; "extra" keys are okay. Any data that
% will have video scoring must have at least one key with the 'manual' type
% included in 'pars.Fields'.
pars.EventType = struct(...
   'ScoredEvents','manual',...
   'DigEvents','auto');

%% Error parsing (do not change)
% Check that number of elements of Name matches that of Fields
if numel(pars.Name) ~= numel(pars.Fields)
   error('Dimension mismatch for pars.Events (%d) and pars.Fields (%d).',...
      numel(pars.Name), numel(pars.Fields));
end

% Check that the appropriate event "keys" exist
u = unique(pars.Fields);
f = fieldnames(pars.EventType);
idx = find(~ismember(u,f),1,'first');
if ~isempty(idx)
   error('Missing %s EventType key (should be ''manual'' or ''auto'')', u{idx});
end

% Check that entries of pars.EventType are valid
for iF = 1:numel(f)
   if ~ismember(lower(pars.EventType.(f{iF})),{'manual','auto'})
      error('Bad EventType (%s): ''%s''. Must be ''manual'' or ''auto''.',...
         f{iF},pars.EventType.(f{iF}));
   end
end

%% If a specific parameter was requested, return only that parameter
if nargin > 0
   pars = pars.(paramName);
end
                              
end