classdef AssessmentSelectionWindow < BaseWindow
    properties (Access = private)
        SubjectID string
        TaskType string
        TitleLabel matlab.ui.control.Label
        BaselineButton matlab.ui.control.Button
        PostInterventionButton matlab.ui.control.Button
        BaselineNote matlab.ui.control.Label
        PostInterventionNote matlab.ui.control.Label
    end
    
    methods (Access = private)
        function backButtonPushed(app)
            app.clearWindow();
            SubjectDataWindow(app.UIFigure, app.SubjectID);
        end
        
        function baselineButtonPushed(app)
            app.clearWindow();
            if app.TaskType == "Rest"
                RestWindow(app.UIFigure, app.SubjectID, 'BSL', app.TaskType);
            elseif app.TaskType == "ISNCSCI"
                ISNCSCIWindow(app.UIFigure, app.SubjectID, 'BSL', app.TaskType);
            elseif app.TaskType == "Coordination"
                CoordinationWindow(app.UIFigure, app.SubjectID, 'BSL', app.TaskType);
            end
        end
        
        function postInterventionButtonPushed(app)
            app.clearWindow();
            if app.TaskType == "Rest"
                RestWindow(app.UIFigure, app.SubjectID, 'PIV', app.TaskType);
            elseif app.TaskType == "ISNCSCI"
                ISNCSCIWindow(app.UIFigure, app.SubjectID, 'PIV', app.TaskType);
            elseif app.TaskType == "Coordination"
                CoordinationWindow(app.UIFigure, app.SubjectID, 'PIV', app.TaskType);
            end
        end
        
        function createComponents(app)
            initializeBaseWindow(app);
            app.UIFigure.Name = ['Assessment Selection - ' char(app.TaskType)];
            
            % Show back button
            showBackButton(app, @(~,~) backButtonPushed(app));
            
            % Create title label
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [20 750 360 30];
            app.TitleLabel.Text = ['Select Assessment Type - ' char(app.TaskType)];
            
            % Check data availability
            dataPath = './Data_Source/';
            taskPath = fullfile(dataPath, app.SubjectID, app.TaskType);
            
            % Check BSL data
            bslPath = fullfile(taskPath, 'BSL');
            bslFiles = dir(fullfile(bslPath, '*.*'));
            bslFiles = bslFiles(~[bslFiles.isdir]); % Remove directories
            lengthBSL = length(bslFiles);
            hasBSL = exist(bslPath, 'dir') && lengthBSL >= 1;
            if lengthBSL >  1
                noteTextBSL = sprintf("Found %d BSL files", lengthBSL);
            else
                noteTextBSL = "";
            end
            
            % Check PIV data
            pivPath = fullfile(taskPath, 'PIV');
            pivFiles = dir(fullfile(pivPath, '*.*'));
            pivFiles = pivFiles(~[pivFiles.isdir]); % Remove directories
            lengthPIV = length(pivFiles);
            hasPIV = exist(pivPath, 'dir') && lengthPIV >= 1;
            if lengthPIV >  1
                noteTextPIV = sprintf("Found %d PIV files", lengthPIV);
            else
                noteTextPIV = "";
            end
            
            % Create buttons
            buttonWidth = 200;
            buttonHeight = 40;
            
            % Baseline button
            app.BaselineButton = uibutton(app.UIFigure, 'push');
            app.BaselineButton.Position = [400 450 buttonWidth buttonHeight];
            app.BaselineButton.Text = 'Baseline';
            app.BaselineButton.FontSize = 14;
            app.BaselineButton.Enable = hasBSL;
            app.BaselineButton.ButtonPushedFcn = @(~,~) baselineButtonPushed(app);

            % Baseline note
            app.BaselineNote = uilabel(app.UIFigure);
            app.BaselineNote.Position = [400 420 200 30];
            app.BaselineNote.Text = noteTextBSL;
            app.BaselineNote.FontSize = 12;
            
            % Post Intervention button
            app.PostInterventionButton = uibutton(app.UIFigure, 'push');
            app.PostInterventionButton.Position = [400 380 buttonWidth buttonHeight];
            app.PostInterventionButton.Text = 'Post Intervention';
            app.PostInterventionButton.FontSize = 14;
            app.PostInterventionButton.Enable = hasPIV;
            app.PostInterventionButton.ButtonPushedFcn = @(~,~) postInterventionButtonPushed(app);

            % Post Intervention note
            app.PostInterventionNote = uilabel(app.UIFigure);
            app.PostInterventionNote.Position = [400 350 200 30];
            app.PostInterventionNote.Text = noteTextPIV;
            app.PostInterventionNote.FontSize = 12;
        end
    end
    
    methods (Access = public)
        function app = AssessmentSelectionWindow(fig, subjectID, taskType)
            app.SubjectID = subjectID;
            app.TaskType = taskType;
            if nargin > 0
                app.UIFigure = fig;
            end
            createComponents(app);
        end
    end
end 