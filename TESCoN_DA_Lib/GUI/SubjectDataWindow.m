classdef SubjectDataWindow < BaseWindow
    properties (Access = private)
        SubjectID string
        TitleLabel matlab.ui.control.Label
        RestButton matlab.ui.control.Button
        ISNCSCIButton matlab.ui.control.Button
        CoordButton matlab.ui.control.Button
        NoDataLabel matlab.ui.control.Label
    end
    
    methods (Access = private)
        function backButtonPushed(app)
            app.clearWindow();
            DataExtractionWindow(app.UIFigure);
        end
        
        function createComponents(app)
            initializeBaseWindow(app);
            app.UIFigure.Name = ['Subject: ' char(app.SubjectID)];
            
            % Show back button
            showBackButton(app, @(~,~) backButtonPushed(app));
            
            % Create title label
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [20 550 360 30];
            app.TitleLabel.Text = ['Data Extraction - Subject: ' char(app.SubjectID)];

            % Check which data types exist
            dataPath = './Data_Source/';
            hasRest = exist(fullfile(dataPath, app.SubjectID, 'Rest'), 'dir');
            hasISNCSCI = exist(fullfile(dataPath, app.SubjectID, 'ISNCSCI'), 'dir');
            hasCoord = exist(fullfile(dataPath, app.SubjectID, 'Coordination'), 'dir');

            if ~hasRest && ~hasISNCSCI && ~hasCoord
                % No data case
                app.NoDataLabel = uilabel(app.UIFigure);
                app.NoDataLabel.FontSize = 14;
                app.NoDataLabel.Position = [100 150 200 30];
                app.NoDataLabel.Text = 'No data for this subject';
            else
                % Create buttons for existing data types
                buttonWidth = 200;
                buttonHeight = 40;
                baseY = 180;
                spacing = 50;

                if hasRest
                    app.RestButton = uibutton(app.UIFigure, 'push');
                    app.RestButton.Position = [100 baseY buttonWidth buttonHeight];
                    app.RestButton.Text = 'Rest';
                    app.RestButton.FontSize = 14;
                    app.RestButton.ButtonPushedFcn = @(btn,event) restButtonPushed(app);
                    baseY = baseY - spacing;
                end

                if hasISNCSCI
                    app.ISNCSCIButton = uibutton(app.UIFigure, 'push');
                    app.ISNCSCIButton.Position = [100 baseY buttonWidth buttonHeight];
                    app.ISNCSCIButton.Text = 'ISNCSCI';
                    app.ISNCSCIButton.FontSize = 14;
                    app.ISNCSCIButton.ButtonPushedFcn = @(btn,event) isncsciButtonPushed(app);
                    baseY = baseY - spacing;
                end

                if hasCoord
                    app.CoordButton = uibutton(app.UIFigure, 'push');
                    app.CoordButton.Position = [100 baseY buttonWidth buttonHeight];
                    app.CoordButton.Text = 'Coordination';
                    app.CoordButton.FontSize = 14;
                    app.CoordButton.ButtonPushedFcn = @(btn,event) coordButtonPushed(app);
                end
            end
        end

        function restButtonPushed(app)
            app.clearWindow();
            AssessmentSelectionWindow(app.UIFigure, app.SubjectID, 'Rest');
        end

        function isncsciButtonPushed(app)
            app.clearWindow();
            AssessmentSelectionWindow(app.UIFigure, app.SubjectID, 'ISNCSCI');
        end

        function coordButtonPushed(app)
            app.clearWindow();
            AssessmentSelectionWindow(app.UIFigure, app.SubjectID, 'Coordination');
        end
    end
    
    methods (Access = public)
        function app = SubjectDataWindow(fig, subjectID)
            app.SubjectID = subjectID;
            if nargin > 0
                app.UIFigure = fig;
            end
            createComponents(app);
        end
    end
end 