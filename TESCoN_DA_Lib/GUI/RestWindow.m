classdef RestWindow < ISNCSCIWindow
    properties (Access = private)

    end

    methods (Access = public)
        function app = RestWindow(fig, subjectID, assessType, taskType)
            % Call parent class constructor with the same parameters
            app = app@ISNCSCIWindow(fig, subjectID, assessType, taskType);
            
            % Clear the parent's components and create our own
            % app.clearWindow();
            disp("II'm in before create Componenets")
            % createComponents(app);
        end
    end
    
    methods (Access = private)
        function createComponents(app)
            disp("II'm in createComponents")
            % disp("II'm in restwindow 22 " + app.TaskType + " " + app.AssessType)
            disp("II'm in before initializeBaseWindow")
            initializeBaseWindow(app);
            disp("II'm in after initializeBaseWindow")
            
            % Debug check
            disp("TaskType: " + class(app.TaskType) + ", value: " + app.TaskType);
            disp("AssessType: " + class(app.AssessType) + ", value: " + app.AssessType);
            
            % Safer string concatenation using string type
            app.UIFigure.Name = string(app.TaskType) + " Data - " + string(app.AssessType);
            
            % Alternative if you need to use char:
            % app.UIFigure.Name = [char(string(app.TaskType)) ' Data - ' char(string(app.AssessType))];
            
            % Show back button
            showBackButton(app, @(~,~) backButtonPushed(app));
            
            % Create title label
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [20 550 360 30];
            app.TitleLabel.Text = [char(app.TaskType) ' Data Processing - ' char(app.AssessType)];
            
            % Create Extract button
            app.ExtractButton = uibutton(app.UIFigure, 'push');
            app.ExtractButton.Position = [20 500 100 30];
            app.ExtractButton.Text = 'Extract';
            app.ExtractButton.FontSize = 12;
            app.ExtractButton.ButtonPushedFcn = @(~,~) extractButtonPushed(app);

            % Create Visualise button
            app.VisualiseButton = uibutton(app.UIFigure, 'push');
            app.VisualiseButton.Position = [140 500 100 30];
            app.VisualiseButton.Text = 'Visualise';
            app.VisualiseButton.FontSize = 12;
            app.VisualiseButton.Enable = false;
            app.VisualiseButton.ButtonPushedFcn = @(~,~) visualiseButtonPushed(app);
            
            % Create Merge Recordings button
            app.MergeButton = uibutton(app.UIFigure, 'push');
            app.MergeButton.Position = [260 500 120 30];
            app.MergeButton.Text = 'Merge Recordings';
            app.MergeButton.FontSize = 12;
            app.MergeButton.Enable = false;  % Initially disabled
            app.MergeButton.ButtonPushedFcn = @(~,~) mergeButtonPushed(app);
            
            % Create Save button
            app.SaveButton = uibutton(app.UIFigure, 'push');
            app.SaveButton.Position = [640 500 100 30];
            app.SaveButton.Text = 'Save';
            app.SaveButton.FontSize = 12;
            app.SaveButton.Enable = false;  % Initially disabled
            app.SaveButton.ButtonPushedFcn = @(~,~) saveButtonPushed(app);
            
            % Move status label to accommodate new button
            app.StatusLabel = uilabel(app.UIFigure);
            app.StatusLabel.FontSize = 12;
            app.StatusLabel.Position = [520 500 200 30];
            app.StatusLabel.Visible = 'off';
            
            % Create plot area
            app.PlotArea = uiaxes(app.UIFigure);
            app.PlotArea.Position = [20 100 960 380];
            app.PlotArea.Visible = 'off';
        end
    end
end
