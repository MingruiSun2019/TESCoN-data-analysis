classdef WelcomeWindow < BaseWindow

    % Properties that correspond to app components
    properties (Access = public)
        TitleLabel         matlab.ui.control.Label
        DataExtractionBtn  matlab.ui.control.Button
        NormalisationBtn   matlab.ui.control.Button
        MetricsBtn         matlab.ui.control.Button
    end

    methods (Access = private)
        function dataExtractionButtonPushed(app, ~)
            app.clearWindow();
            DataExtractionWindow(app.UIFigure);
        end

        function normalisationButtonPushed(app, ~)
            % Create and show the Normalisation window
            NormalisationWindow;
        end

        function metricsButtonPushed(app, ~)
            % Create and show the Metrics window
            MetricsWindow;
        end

        function createComponents(app)
            initializeBaseWindow(app);
            app.UIFigure.Name = 'TESCoN Data Analysis';
            
            % Create Title Label
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 24;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [180 380 300 40];
            app.TitleLabel.Text = 'TESCoN Data Analysis';

            % Create Data Extraction Button
            app.DataExtractionBtn = uibutton(app.UIFigure, 'push');
            app.DataExtractionBtn.ButtonPushedFcn = createCallbackFcn(app, @dataExtractionButtonPushed, true);
            app.DataExtractionBtn.Position = [220 280 200 40];
            app.DataExtractionBtn.Text = 'Data Extraction';
            app.DataExtractionBtn.FontSize = 14;

            % Create Normalisation Button
            app.NormalisationBtn = uibutton(app.UIFigure, 'push');
            app.NormalisationBtn.ButtonPushedFcn = createCallbackFcn(app, @normalisationButtonPushed, true);
            app.NormalisationBtn.Position = [220 210 200 40];
            app.NormalisationBtn.Text = 'Data Normalisation';
            app.NormalisationBtn.FontSize = 14;

            % Create Metrics Button
            app.MetricsBtn = uibutton(app.UIFigure, 'push');
            app.MetricsBtn.ButtonPushedFcn = createCallbackFcn(app, @metricsButtonPushed, true);
            app.MetricsBtn.Position = [220 140 200 40];
            app.MetricsBtn.Text = 'Calculate Metrics';
            app.MetricsBtn.FontSize = 14;
        end
    end

    methods (Access = public)
        % Construct app
        function app = WelcomeWindow
            % Create UIFigure and components
            disp("WelcomeWindow created1 ");
            createComponents(app)
            disp("WelcomeWindow created2 ");
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end
end 