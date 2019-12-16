classdef nigelButton < handle
%NIGELBUTTON   Buttons in format of nigeLab interface
%
%  NIGELBUTTON Properties:
%     ButtonDownFcn - Function executed by button.
%        This can be set publically and will change the button down
%        function for any child objects associated with the nigelButton
%
%     Parent - Handle to parent axes object.
%
%     Button - Handle to Rectangle object with curved corners.
%
%     Label - Handle to Text object displaying some label string.
%
%  NIGELBUTTON Methods:
%     nigelButton - Class constructor.
%           b = nigeLab.libs.nigelButton(); Add to current axes
%           b = nigeLab.libs.nigelButton(nigelPanelObj); Add to nigelPanel
%           b = nigeLab.libs.nigelButton(ax);  Add to axes
%           b = nigeLab.libs.nigelButton(__,buttonPropPairs,labPropPairs);
%           b = nigeLab.libs.nigelButton(__,pos,string,buttonDownFcn);
% 
%           container can be:
%           -> nigeLab.libs.nigelPanel
%           -> axes
%           -> uipanel
% 
%           buttonPropPairs & labPropPairs are {'propName', value}
%           argument pairs, each given as a [1 x 2*k] cell arrays of pairs
%           for k properties to set.
% 
%           Alternatively, buttonPropPairs can be given as the position of
%           the button rectangle, and labPropPairs can be given as the
%           string to go into the button. In this case, the fourth input
%           (fcn) should be provided as a function handle for ButtonDownFcn
   
   properties (Access = public,SetObservable = true)
      Enable = 'on'  % Is the button enabled
   end

   properties (Access = public, SetObservable = false)
      Fcn     function_handle  % Function to be executed
      Fcn_Args    cell         % (Optional) function arguments
   end
   
   properties (GetAccess = public,SetAccess = private,SetObservable = true)
      Selected = 'off'   % Is this button currently clicked
      Button  matlab.graphics.primitive.Rectangle  % Curved rectangle
      Label   matlab.graphics.primitive.Text  % Text to display
   end
   
   properties (GetAccess = public, SetAccess = immutable)
      Figure  matlab.ui.Figure           % Figure containing the object
      Group   matlab.graphics.primitive.Group  % "Container" object
      Parent  matlab.graphics.axis.Axes  % Axes container
   end
   
   properties (Access = private)
      Border    matlab.graphics.primitive.Rectangle  % Border of "button"
      Listener  event.listener                   % Property event listener
   end
   
   % PUBLIC
   % Class constructor and overloaded methods
   methods (Access = public)
      % Class constructor
      function b = nigelButton(container,buttonPropPairs,labPropPairs,varargin)
         %NIGELBUTTON   Buttons in format of nigeLab interface
         %
         %  b = nigeLab.libs.nigelButton(); Add to current axes
         %  b = nigeLab.libs.nigelButton(nigelPanelObj); Add to nigelPanel
         %  b = nigeLab.libs.nigelButton(ax);  Add to axes
         %  b = nigeLab.libs.nigelButton(__,buttonPropPairs,labPropPairs);
         %  b = nigeLab.libs.nigelButton(__,pos,string,@ButtonDownFcn);
         %  b = nigeLab.libs.nigelButton(__,@ButtonDownFcn,{arg1,...,argk});
         %
         %  container can be:
         %  -> nigeLab.libs.nigelPanel
         %  -> axes
         %  -> uipanel
         %
         %  buttonPropPairs & labPropPairs are {'propName', value}
         %  argument pairs, each given as a [1 x 2*k] cell arrays of pairs
         %  for k properties to set.
         %
         %  Alternatively, buttonPropPairs can be given as the position of
         %  the button rectangle, and labPropPairs can be given as the
         %  string to go into the button. In this case, the fourth input
         %  (fcn) should be provided as a function handle for ButtonDownFcn
         %
         %  Example syntax:
         %  >> fig = figure; % Test 1
         %  >> p = nigeLab.libs.nigelPanel(fig);
         %  >> b = nigeLab.libs.nigelButton(p,...
         %         {'FaceColor',[1 0 0],...
         %          'ButtonDownFcn',@(src,~)disp(class(src))},...
         %         {'String','test'});
         %
         %  >> fig = figure; % Test 2
         %  >> ax = axes(fig);
         %  >> bPos = [-0.35 0.2 0.45 0.15];
         %  >> b = nigeLab.libs.nigelButton(ax,bPos,'test2',...
         %           @(~,~)disp('test2'));
         
         if nargin < 3
            labPropPairs = {};
         end
         
         if nargin < 2
            buttonPropPairs = {};
         end
         
         if nargin < 1
            container = gca;
         end
         
         % Set immutable properties in constructor
         b.Parent = nigeLab.libs.nigelButton.parseContainer(container);
         b.Group = hggroup(b.Parent);
         b.Figure = b.parseFigure(); 
         
         % Set Function handle and input arguments
         if nargin > 3
            b.Fcn = varargin{1};
         end
         
         if nargin > 4
            b.Fcn_Args = varargin(2:end);
         end
         
         % Initialize rest of graphics
         b.buildGraphic(buttonPropPairs,'Button');
         b.buildGraphic(labPropPairs,'Label');
         b.completeGroup();
         b.addListeners();
         
      end
      
      % Overloaded delete ensures Listener is destroyed
      function delete(b)
         % DELETE  Overloaded delete ensures Listener property is destroyed
         %
         %  delete(b);
         
         % Handle array elements individually
         if numel(b) > 1
            for i = 1:numel(b)
               delete(b(i));
            end
            return;
         end
         
         if ~isempty(b.Listener)
            for lh = b.Listener
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
         if ~isempty(b.Group)
            if isvalid(b.Group)
               delete(b.Group);
            end
         end
      end
      
      % Return the correct button from an array
      function b = getButton(bArray,name)
         % GETBUTTON  Return the correct button from an array by specifying
         %            its name, which is the char array on the text label
         %
         %  b = getButton(bArray,'labelString');  Returns the button with
         %                                        'labelString' on it, or
         %                                        else returns empty array
         
         idx = ismember(lower(get([bArray.Label],'String')),lower(name));
         b = bArray(idx);
      end
      
      % Return the correct button from an array
      function setButton(bArray,name,propName,propval)
         % GETBUTTON  Return the correct button from an array by specifying
         %            its name, which is the char array on the text label
         %
         %  setButton(bArray,'labelString','propName',propVal);  
         %  
         %  Set the value of the button in array with label 'labelString'
         %  for 'propName' to propVal.
         %
         %  setButton(bArray,[],...); Sets all elements of bArray
         %
         %  setButton(bArray,logical(ones(size(bArray)))); Can use logical
         %           or numeric indexing
         
         if ischar(name)
            idx = ismember(lower(get([bArray.Label],'String')),lower(name));
         elseif isnumeric(name)
            if ~isempty(name)
               idx = name;
            else
               idx = 1:numel(bArray);
            end
         elseif islogical(name)
            idx = name;
         else
            error(['nigeLab:' mfilename ':badInputType2'],...
               'Unexpected input class for "name" (%s)',class(name));
         end
            
         B = bArray(idx);
         for i = 1:numel(B)
            B.(propName) = propval;
         end
      end
   end
   
   % PRIVATE
   % Initialization methods
   methods (Access = private, Hidden = true)
      function addListeners(b)
         % ADDLISTENERS  Adds all listeners to propertly .Listener
         %
         %  b.addListeners();
         
         % Make the border follow select property values of Button
         b.Listener = [b.Listener, ...
            addlistener(b.Button,'Position','PostSet',...
               @(~,evt)set(b.Border,'Position',...
                  evt.AffectedObject.Position))];
         b.Listener = [b.Listener, ...
            addlistener(b.Button,'LineWidth','PostSet',...
               @(~,evt)set(b.Border,'LineWidth',...
                  evt.AffectedObject.LineWidth))];
         b.Border.Position = b.Button.Position;
         b.Border.LineWidth = b.Button.LineWidth;

         % Figure UserData will be set on Figure ButtonUpFcn
         b.Listener = [b.Listener, addlistener(b.Figure,...
            'UserData','PostSet',...
            @(~,evt)b.ButtonUpFcn(evt.AffectedObject.UserData))];
         
         % Add listener so text label stays in middle of button
         b.Listener = [b.Listener, ...
            addlistener(b.Button,'Position','PostSet',...
             @(~,evt)set(b.Label,'Position',...
                        b.getCenter(evt.AffectedObject.Position)))];
                     
         % Add listeners for SetObservable properties
         b.Listener = [b.Listener, ...
            addlistener(b,'Enable','PostSet',...
            @(~,evt)b.setEnable(evt.AffectedObject.Enable))];
      end
      
      % Button click graphic
      function ButtonClickGraphic(b)
         % BUTTONCLICKGRAPHIC  Crude method to show the highlight border of
         %                       button that was clicked.
         
         if numel(b) > 1
            for i = 1:numel(b)
               ButtonClickGraphic(b(i));
            end
            return;
         end
         
         if strcmpi(b.Enable,'off')
            return;
         end
         
         b.Border.Visible = 'on';
         b.Selected = 'on';
         b.Label.FontWeight = 'bold';
      end
      
      % Button click graphic
      function ButtonUpFcn(b,UserData)
         % BUTTONUPFCN  Crude method to show the highlight border of
         %                       button that was clicked on a left-click,
         %                       and then execute current button callback.
         
         if numel(b) > 1
            for i = 1:numel(b)
               ButtonUpFcn(b(i),UserData);
            end
            return;
         end
         
         if strcmpi(b.Selected,'off')
            return;
         elseif strcmpi(b.Enable,'off')
            return;
         end
         % If button is released, turn off "highlight border"
         b.Border.Visible = 'off';
         b.Selected = 'off';
         b.Label.FontWeight = 'normal';
         switch lower(UserData)
            case 'normal'
               if ~isempty(b.Fcn)
                  feval(b.Fcn,b.Fcn_Args{:});
               end
               
            otherwise 
               ... % nothing
         end
      end
      
      % Initialize a given graphic property object
      function buildGraphic(b,propPairsIn,propName)
         % BUILDGRAPHIC  Builds the specified graphic
         %
         %  b.buildGraphic(propPairsIn,'propName');
         %
         %  Builds the graphic property specified by 'propName' using the
         %  optional input property pairs list.
         
         % Check input
         if ~isprop(b,propName)
            error(['nigeLab:' mfilename ':badInputType3'],...
               'Invalid property name: %s',propName);
         end
         
         switch propName
            case 'Button'
               % Do not make additional button graphics
               if ~isempty(b.Button)
                  if isvalid(b.Button)
                     return;
                  end
               end
               
               b.Button = rectangle(b.Group,...
                  'Position',[0.15 0.10 0.70 0.275],...
                  'Curvature',[.2 .6],...
                  'FaceColor',nigeLab.defaults.nigelColors('button'),...
                  'EdgeColor','none',...
                  'LineWidth',3,...
                  'Tag','Button',...
                  'ButtonDownFcn',@(~,~)b.ButtonClickGraphic);
               b.Border = rectangle(b.Group,...
                  'Position',[0.15 0.10 0.70 0.275],...
                  'Curvature',[.2 .6],...
                  'FaceColor','none',...
                  'EdgeColor',nigeLab.defaults.nigelColors('highlight'),...
                  'LineWidth',3,...
                  'Tag','Border',...
                  'Visible','off',...
                  'HitTest','off');

               
            case 'Label'
               % Do not make additional label graphics
               if ~isempty(b.Label)
                  if isvalid(b.Label)
                     return;
                  end
               end
               
               % By default put it in the middle of the button
               pos = b.getCenter(b.Button.Position);
               b.Label = text(b.Group,pos(1),pos(2),'',...
                  'Color',nigeLab.defaults.nigelColors('onbutton'),...
                  'FontName','Droid Sans',...
                  'Units','normalized',...
                  'FontUnits','normalized',...
                  'FontSize',0.8 * b.Button.Position(4),...
                  'Tag','Label',...
                  'HorizontalAlignment','center',...
                  'VerticalAlignment','middle',...
                  'ButtonDownFcn',@(~,~)b.ButtonClickGraphic);
               
            otherwise
               error(['nigeLab:' mfilename ':badInputType4'],...
                'Unexpected graphics property name: %s',propName);
         end
         
         % If no property pairs specified, skip next part
         if isempty(propPairsIn)
            return;
         end
         
         switch class(propPairsIn)
            case 'cell'
               % Cycle through all valid name-value pairs and add them
               ob = metaclass(b.(propName));
               allPropList = {ob.PropertyList.Name};
               allPropList = allPropList(~[ob.PropertyList.Hidden]);
               
               % Don't let the ButtonDownFcn be set (it should be fixed)
               allPropList = setdiff(allPropList,'ButtonDownFcn'); 
               for i = 1:2:numel(propPairsIn)
                  % Do it this way to allow mismatch on case syntax
                  idx = find(...
                     ismember(lower(allPropList),lower(propPairsIn{i})),...
                     1,'first');
                  if ~isempty(idx)
                     b.(propName).(allPropList{idx}) = propPairsIn{i+1};
                  end
               end
               
            case 'double'
               % If this was associated with the wrong set of pairs, redo
               % the button.
               if strcmp(propName,'Label')
                  error(['nigeLab:' mfilename ':badInputType3'],...
                     'Check order of position and label text inputs.');
               end
               
               % Can set position directly
               b.Button.Position = propPairsIn;
            case 'char'
               % If this was associated with the wrong set of pairs, redo
               % the label
               if strcmp(propName,'Button')
                  error(['nigeLab:' mfilename ':badInputType3'],...
                     'Check order of position and label text inputs.');
               end
               
               % Can set label text directly
               b.Label.String = propPairsIn;
               
            otherwise
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Bad input type for %s propPairs: %s',...
                  propName,class(propPairsIn));
         end
         
      end
      
      % Complete the 'Group' hggroup property
      function completeGroup(b)
         % COMPLETEGROUP  Complete the 'Group' hggroup property
         %
         %  lh = b.completeGroup();
         %
         %  fcn  --  Function handle
         %  lh  --  Property 'ButtonDownFcn' PostSet listener object
         
         b.Group.Tag = b.Label.String;
         b.Group.DisplayName = b.Label.String;
         
         % Make it not show up in legends:
         b.Group.Annotation.LegendInformation.IconDisplayStyle = 'off';

      end
      
      % Parses "parent figure" from parent
      function fig = parseFigure(b)
         % PARSEFIGURE Parses "parent figure" from parent container
         %
         %  fig = b.parseFigure();
         
         fig = b.Parent.Parent;
         while ~isa(fig,'matlab.ui.Figure')
            fig = fig.Parent;
         end
         set(fig,'WindowButtonUpFcn',...
            @(src,~)set(fig,'UserData',src.SelectionType));
      end
      
      % Toggles enable status
      function setEnable(b,enable)
         
         switch lower(enable)
            case 'on'
               b.Button.FaceColor = nigeLab.defaults.nigelColors('enable');
               b.Label.Color = nigeLab.defaults.nigelColors('enabletext');
            case 'off'
               b.Button.FaceColor = nigeLab.defaults.nigelColors('disable');
               b.Label.Color = nigeLab.defaults.nigelColors('disabletext');
         end
      end
   end
   
   % STATIC methods
   % PRIVATE
   methods (Access = private, Static = true)
      % Return the center coordinates based on position
      function txt_pos = getCenter(pos,xoff,yoff)
         % GETTEXTPOS  Returns the coordinates for text to go in center
         %
         %  txt_pos = nigeLab.libs.nigelButton.getCenter(pos);
         %
         %  txt_pos = nigeLab.libs.nigelButton.getCenter(pos,xoff,yoff);
         %  --> add x offset and y offset (defaults for both are zero)
         %
         %  pos -- 4-element position vector for object in 2D axes
         %  txt_pos  -- 3-element position vector for text annotation
         
         if nargin < 2
            xoff = 0;
         end
         
         if nargin < 3
            yoff = 0;
         end
         
         x = pos(1) + pos(3)/2 + xoff;
         y = pos(2) + pos(4)/2 + yoff;
         txt_pos = [x,y,0];
         
      end
      
      % Parse first input argument and provide appropriate axes object
      function ax = parseContainer(container)
         % PARSECONTAINER  Parses first input argument and returns the
         %                 correct container for the nigelButton.
         %
         %  ax = nigeLab.libs.nigelButton.parseContainer(container);
         %
         %  ax is always output as a matlab.graphics.axis.Axes class
         %  object.
         
         switch builtin('class',container)
            case 'nigeLab.libs.nigelPanel'
               %% If containerObj is nigelPanel, then use ButtonAxes
               ax = getChild(container,'ButtonAxes',true);
               if isempty(ax)
                  pos = container.InnerPosition;
                  pos = [pos(1) + pos(3) / 2, ...
                     pos(2) + 0.05, ...
                     pos(3) / 2, ...
                     pos(4) * 0.15];
                  ax = axes('Units','normalized', ...
                     'Tag','ButtonAxes',...
                     'Position', pos,...
                     'Color','none',...
                     'XColor','none',...
                     'YColor','none',...
                     'NextPlot','add',...
                     'XLimMode','manual',...
                     'XLimMode','manual',...
                     'XLim',[0 1],...
                     'YLimMode','manual',...
                     'YLim',[0 1],...
                     'FontName',container.FontName);
                  container.nestObj(ax,'ButtonAxes');
               end
               
            case 'matlab.graphics.axis.Axes'
               %% If axes, just use axes as provided
               ax = container;
               
            case 'matlab.ui.container.Panel'
               %% If uiPanel, get top axes in the panel or make new axes
               ax = [];
               for i = 1:numel(container.Children)
                  ax = container.Children(i);
                  if isa(ax,'matlab.graphics.axis.Axes')
                     break;
                  end
               end
               if isempty(ax)
                  pos = container.InnerPosition;
                  pos = [pos(1) + pos(3) / 2, ...
                     pos(2) + 0.05, ...
                     pos(3) / 2, ...
                     pos(4) * 0.15];
                  ax = axes(container,...
                     'Units','normalized', ...
                     'Tag','ButtonAxes',...
                     'Position', pos,...
                     'Color','none',...
                     'XColor','none',...
                     'YColor','none',...
                     'NextPlot','add',...
                     'XLimMode','manual',...
                     'XLim',[0 1],...
                     'YLimMode','manual',...
                     'YLim',[0 1],...
                     'FontName',container.FontName);
               end
            otherwise
               %% Current support only for axes, nigelPanel, panel
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Bad input type for containerObj: %s',...
                  class(container));
         end
      end
   end
   
end
