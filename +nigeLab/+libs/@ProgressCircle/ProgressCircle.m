classdef ProgressCircle < handle
%PROGRESSCIRCLE   A visual indicator of progress on a loop

   properties (Access = public)
      Figure
      Label
      Function
      BarColor = [1 1 1];
      LineWidth = 26;
      NumPoints = 50;
   end
   
   methods (Access = public)
      function obj = ProgressCircle(func)
         % Set properties
         obj.Function = func;
         
         % Set up progress circle
         obj.Figure = figure('Name','Interpolation Progress',...
            'MenuBar','none',...
            'NumberTitle','off',...
            'ToolBar','none',...
            'GraphicsSmoothing','off',...
            'Units','Normalized',...
            'Position',[0.4 0.4 0.2 0.3]);
         axes('Parent',obj.Figure,...
            'Units','Normalized',...
            'Position',[0 0 1 1],...
            'XLim',[-50 50], ...
            'XTick',[], ...
            'YLim',[-50 50], ...
            'YTick',[],...
            'Color','k',...
            'NextPlot','add');
         obj.Label = text(-20,0,'Interpolating spikes...',...
            'FontSize',16,...
            'FontWeight','bold',...
            'FontName','Arial',...
            'Color','w');
      end
      
      function output = RunLoop(obj,N,M)
         output = nan(N,M);
         prev_prog = 0;
         cur_prog = 0;
         col = obj.BarColor;
         for ii = 1:N
            output(ii,:) = obj.Function(ii);
            cur_prog = ceil(ii/N*100);
            if cur_prog > prev_prog
               figure(obj.Figure); % Ensure focus on this circle fig
               cprog=linspace(0, 2*pi*ii/N, obj.NumPoints);
               plot(40*sin(cprog),40*cos(cprog),'k', ...
                    'LineWidth',obj.LineWidth,...
                    'color',[col(1)*(1-ii/N) ...
                             col(2)*(1-0.4*ii/N) ...
                             max(col(3)*(1-1.5*ii/N),0)]);
               drawnow;
               prev_prog = cur_prog;
            end
         end
         delete(obj.Label);
         delete(obj.Figure);
         delete(obj);
      end
   end
   
end