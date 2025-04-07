classdef DataExtractionWindow < BaseWindow
    properties (Access = public)
        SubjectButtons  matlab.ui.control.Button
        DataLabel       matlab.ui.control.Label
    end
    
    methods (Access = private)
        function backButtonPushed(app)
            app.clearWindow();
            WelcomeWindow;
        end
        
        function subjectButtonPushed(app, subjectID)
            app.clearWindow();
            SubjectDataWindow(app.UIFigure, subjectID);
        end
        
        function createComponents(app)
            initializeBaseWindow(app);
            app.UIFigure.Name = 'Data Extraction';
            
            % Show back button
            showBackButton(app, @(~,~) backButtonPushed(app));
            
            % Create title label
            app.DataLabel = uilabel(app.UIFigure);
            app.DataLabel.FontSize = 20;
            app.DataLabel.FontWeight = 'bold';
            app.DataLabel.Position = [20 750 200 30];
            app.DataLabel.Text = 'Select Subject:';

            % Get subject folders and create buttons
            createSubjectButtons(app);
        end

        function createSubjectButtons(app)
            % Get list of subject folders
            dataPath = './Data_Source/';
            subjects = dir(dataPath);
            subjects = subjects([subjects.isdir]); % Get only directories
            subjects = subjects(~ismember({subjects.name}, {'.', '..'})); % Remove . and ..

            % Calculate button layout
            buttonWidth = 120;
            buttonHeight = 60;
            horizontalSpacing = 20;
            verticalSpacing = 20;
            buttonsPerRow = floor((app.UIFigure.Position(3) - 40) / (buttonWidth + horizontalSpacing));
            
            % Create buttons for each subject
            for i = 1:length(subjects)
                % Calculate button position
                row = floor((i-1) / buttonsPerRow);
                col = mod(i-1, buttonsPerRow);
                xPos = 20 + col * (buttonWidth + horizontalSpacing);
                yPos = app.UIFigure.Position(4) - 120 - row * (buttonHeight + verticalSpacing);

                % Check which data types exist
                dataTypes = '';
                if exist(fullfile(dataPath, subjects(i).name, 'Rest'), 'dir')
                    dataTypes = [dataTypes 'R '];
                end
                if exist(fullfile(dataPath, subjects(i).name, 'ISNCSCI'), 'dir')
                    dataTypes = [dataTypes 'I '];
                end
                if exist(fullfile(dataPath, subjects(i).name, 'Coordination'), 'dir')
                    dataTypes = [dataTypes 'C'];
                end

                % Create button with subject ID and data types
                btn = uibutton(app.UIFigure, 'push');
                btn.Position = [xPos yPos buttonWidth buttonHeight];
                btn.Text = sprintf('%s\n%s', subjects(i).name, dataTypes);
                btn.WordWrap = 'on';
                btn.FontSize = 12;
                btn.ButtonPushedFcn = @(btn,event) subjectButtonPushed(app, subjects(i).name);
            end
        end
    end
    
    methods (Access = public)
        function app = DataExtractionWindow(fig)
            if nargin > 0
                app.UIFigure = fig;
            end
            createComponents(app);
        end
    end
end 