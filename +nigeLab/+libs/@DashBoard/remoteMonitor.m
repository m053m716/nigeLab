function remoteMonitor(obj,jobName,idx)
%% REMOTEMONITOR  Set up a monitor to update GUI with remote process
%
%  REMOTEMONITOR(obj,jobName,idx);
%
%  --------
%   INPUTS
%  --------
%     obj      :     DASHBOARD class object
%
%   jobName    :     (Char array) Name of job underway (e.g. doSD)
%
%     idx      :     Indexed element to set bar for
%
% By: Max Murphy & Fred Barban v1.0    2019-07-09  Original version
%                                      (R2017a)

%% Get parent panel
qPanel = obj.getChildPanel('Queue');

% Define figure size and axes padding for the single bar case
height = 20;
qPanel.Units = 'pixels';
width = qPanel.InnerPosition(3)*0.6;
hoff = qPanel.InnerPosition(3)*0.05;
voff = qPanel.InnerPosition(4)*0.88;

% Create axes, patch, and text
progdata.progaxes = axes( ...
   'Units','pixels',...
   'Position', [0 0 width height], ...
   'XLim', [0 1], ...
   'YLim', [0 1], ...
   'Box', 'off', ...
   'ytick', [], ...
   'xtick', [],...
   'UserData',idx);

progdata.progpatch = patch(progdata.progaxes, ...
   'XData', [0.3 0.3 0.3 0.3], ...
   'YData', [0   0   1   1  ],...
   'FaceColor',nigeLab.defaults.nigelColors(1));
patch(progdata.progaxes, ...
   'XData', [0 0.3 0.3 0], ...
   'YData', [0 0   1   1],...
   'FaceColor',nigeLab.defaults.nigelColors('surface'),...
   'EdgeColor',nigeLab.defaults.nigelColors('surface'));
progdata.progtext = text(progdata.progaxes,0.99, 0.5, '', ...
   'HorizontalAlignment', 'Right', ...
   'FontUnits', 'Normalized', ...
   'FontSize', 0.7,...
   'FontName','Droid Sans');
set(progdata.progtext, 'String', sprintf('%s: 0%',jobName));
progdata.proglabel = text(progdata.progaxes,0.01, 0.5, '', ...
   'HorizontalAlignment', 'Left', ...
   'FontUnits', 'Normalized', ...
   'FontSize', 0.7,...
   'Color',nigeLab.defaults.nigelColors('onsurface'),...
   'FontName','Droid Sans');

ax = axes( ...
   'Units','pixels',...
   'Position', [width + 5 0 height height]);
set(ax, ...
   'XLim', [0 1], ...
   'YLim', [0 1], ...
   'Box', 'off', ...
   'Color',nigeLab.defaults.nigelColors(0.1),...
   'ytick', [], ...
   'xtick', [],...
   'UserData',idx);
ax.XAxis.Visible='off';
ax.YAxis.Visible='off';
progdata.X = ax;

pos = [hoff voff-height*4/3*(idx-1) width + 5 + height height];
pp = uipanel('BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
    'Units','pixels','Position',pos,'BorderType','none');
progdata.progaxes.Parent=pp;
ax.Parent=pp;
qPanel.nestObj(pp);

obj.jobProgressBar{idx}=pp;


% Set starting time reference
if ~isfield(progdata, 'starttime') || isempty(progdata.starttime)
   progdata.starttime = clock;
end

end
