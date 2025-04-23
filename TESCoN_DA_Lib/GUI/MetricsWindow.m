classdef MetricsWindow < matlab.apps.AppBase
    properties (Access = public)
        UIFigure  matlab.ui.Figure
    end
    
    methods (Access = private)
        function createComponents(app)
            % Create UIFigure
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'Calculate Metrics';
            app.UIFigure.Color = [1 1 1];
        end
    end
    
    methods (Access = public)
        function app = MetricsWindow
            createComponents(app)
            app.UIFigure.Visible = 'on';
        end
    end
end 