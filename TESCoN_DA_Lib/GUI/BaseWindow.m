classdef BaseWindow < matlab.apps.AppBase
    properties (Access = public)
        UIFigure    matlab.ui.Figure
        BackButton  matlab.ui.control.Button
    end
    
    methods (Access = protected)
        function initializeBaseWindow(app)
            % Create UIFigure if it doesn't exist
            if isempty(app.UIFigure)
                app.UIFigure = uifigure('Visible', 'off');
            end
            app.UIFigure.Position = [100 100 1000 800];
            app.UIFigure.Color = [1 1 1];
            
            % Create back button (hidden by default)
            app.BackButton = uibutton(app.UIFigure, 'push');
            app.BackButton.Position = [20 50 80 30];
            app.BackButton.Text = 'Back';
            app.BackButton.Visible = 'off';
        end
        
        function showBackButton(app, callback)
            app.BackButton.ButtonPushedFcn = callback;
            app.BackButton.Visible = 'on';
        end
        
        function clearWindow(app)
            % Delete all components except the back button
            children = app.UIFigure.Children;
            for i = 1:length(children)
                if children(i) ~= app.BackButton
                    delete(children(i));
                end
            end
        end
    end
end 