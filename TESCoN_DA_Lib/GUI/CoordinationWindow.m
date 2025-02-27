classdef CoordinationWindow < BaseWindow
    properties (Access = private)
        SubjectID string
        AssessType string
        TaskType string
        TitleLabel matlab.ui.control.Label
        ExtractButton matlab.ui.control.Button
        VisualiseButton matlab.ui.control.Button
        SaveButton matlab.ui.control.Button
        StatusLabel matlab.ui.control.Label
        PlotArea matlab.ui.control.UIAxes
        DataExtractor
        ExtractGoEndButton matlab.ui.control.Button
        RecordingNamesField matlab.ui.control.EditField
        ConfirmRecordButton matlab.ui.control.Button
        RecordingNames string
        LeftDominantButton matlab.ui.control.Button
        RightDominantButton matlab.ui.control.Button
    end
    
    methods (Access = private)
        function backButtonPushed(app)
            app.clearWindow();
            AssessmentSelectionWindow(app.UIFigure, app.SubjectID, app.TaskType);
        end
        
        function extractButtonPushed(app)
            % Create DataExtractor instance
            taskType = "Coordination";
            sampleRate = 2000;
            app.DataExtractor = DataExtractor(app.SubjectID, app.AssessType, taskType, sampleRate);
            app.DataExtractor = app.DataExtractor.loadExtractChannelPipline();
            
            % Define recording names
            app.DataExtractor = app.DataExtractor.extractChannelsMultiRecording();
            
            % Update status
            app.StatusLabel.Text = 'Extraction finished!';
            app.StatusLabel.Visible = 'on';
            
            % Enable visualise and save buttons
            app.VisualiseButton.Enable = true;
            app.SaveButton.Enable = true;
            
            % Enable Extract GO-END button after extraction
            app.ExtractGoEndButton.Enable = true;
        end
        
        function visualiseButtonPushed(app)
            if ~isempty(app.DataExtractor)
                testType = "Coordination";
                app.DataExtractor.graphAllChannelsMultiRecording();
            end
        end
        
        function saveButtonPushed(app)
            % Create directory path
            basePath = './Data_Processed/';
            subjectPath = fullfile(basePath, app.SubjectID);
            testPath = fullfile(subjectPath, 'Coordination');
            savePath = fullfile(testPath, app.AssessType);
            
            % Create directories if they don't exist
            if ~exist(basePath, 'dir')
                mkdir(basePath);
            end
            if ~exist(subjectPath, 'dir')
                mkdir(subjectPath);
            end
            if ~exist(testPath, 'dir')
                mkdir(testPath);
            end
            if ~exist(savePath, 'dir')
                mkdir(savePath);
            end
            
            % Create filename
            filename = ['processed_' char(app.SubjectID) '_Coordination_' char(app.AssessType) '.mat'];
            fullPath = fullfile(savePath, filename);
            
            % Create a copy of DataExtractor
            saveData = app.DataExtractor;
            saveData.rawData = [];
            saveData.dsFactor = [];
            
            % Save the data
            save(fullPath, 'saveData');
            
            % Update status
            app.StatusLabel.Text = 'Data saved successfully!';
            app.StatusLabel.Visible = 'on';
        end
        
        function extractGoEndButtonPushed(app)
            testType = "Coordination";
            
            % Process each recording
            for recordIdx = 1:length(app.RecordingNames)
                % Find "GO" and "END" indices
                [goFrameIdx, endFrameIdx] = app.DataExtractor.extractGoEndData(testType, recordIdx);
                
                if ~isempty(goFrameIdx) && ~isempty(endFrameIdx)
                    % Extract data between GO and END for each channel
                    channelNames = app.DataExtractor.metaData.(testType).channelNames;
                    for i = 1:length(channelNames)
                        channelName = channelNames(i);
                        fullData = app.DataExtractor.chnlData.(testType).(channelName).(app.RecordingNames(recordIdx));
                        
                        % Extract data between GO and END
                        app.DataExtractor.chnlData.(testType).(channelName).(app.RecordingNames(recordIdx)) = ...
                            fullData(goFrameIdx:endFrameIdx);
                            disp("Start: " + goFrameIdx + " End: " + endFrameIdx);
                    end
                end
            end
            
            % Update status
            app.StatusLabel.Text = 'GO-END extraction complete!';
            app.StatusLabel.Visible = 'on';
        end
        
        function confirmRecordButtonPushed(app)
            % Get text from input field
            inputText = app.RecordingNamesField.Value;
            
            % Split by comma and remove spaces
            recordNames = strtrim(split(inputText, ','));
            
            % Store the processed names
            app.RecordingNames = recordNames;
            
            % Update status
            app.StatusLabel.Text = 'Recording names confirmed!';
            app.StatusLabel.Visible = 'on';
        end
        
        function leftDominantButtonPushed(app)
            app.RecordingNamesField.Value = 'Left_SS, Left_Fast, Right_SS, Right_Fast, Left_SS2, Left_Fast2';
            app.StatusLabel.Text = 'Left dominant pattern selected';
            app.StatusLabel.Visible = 'on';
        end
        
        function rightDominantButtonPushed(app)
            app.RecordingNamesField.Value = 'Right_SS, Right_Fast, Left_SS, Left_Fast, Right_SS2, Right_Fast2';
            app.StatusLabel.Text = 'Right dominant pattern selected';
            app.StatusLabel.Visible = 'on';
        end
        
        function createComponents(app)
            initializeBaseWindow(app);
            app.UIFigure.Name = ['Coordination Data - ' char(app.AssessType)];
            
            % Show back button
            showBackButton(app, @(~,~) backButtonPushed(app));
            
            % Create title label
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [20 550 360 30];
            app.TitleLabel.Text = ['Coordination Data Processing - ' char(app.AssessType)];
            
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
            
            % Create Save button
            app.SaveButton = uibutton(app.UIFigure, 'push');
            app.SaveButton.Position = [260 500 100 30];
            app.SaveButton.Text = 'Save';
            app.SaveButton.FontSize = 12;
            app.SaveButton.Enable = false;
            app.SaveButton.ButtonPushedFcn = @(~,~) saveButtonPushed(app);
            
            % Create Extract GO-END button
            app.ExtractGoEndButton = uibutton(app.UIFigure, 'push');
            app.ExtractGoEndButton.Position = [380 500 120 30];
            app.ExtractGoEndButton.Text = 'Extract GO-END';
            app.ExtractGoEndButton.FontSize = 12;
            app.ExtractGoEndButton.Enable = false;
            app.ExtractGoEndButton.ButtonPushedFcn = @(~,~) extractGoEndButtonPushed(app);
            
            % Create status label
            app.StatusLabel = uilabel(app.UIFigure);
            app.StatusLabel.FontSize = 12;
            app.StatusLabel.Position = [520 500 200 30];
            app.StatusLabel.Visible = 'off';
            
            % Create plot area
            app.PlotArea = uiaxes(app.UIFigure);
            app.PlotArea.Position = [20 100 960 380];
            app.PlotArea.Visible = 'off';
            
            % Create recording names input field
            app.RecordingNamesField = uieditfield(app.UIFigure, 'text');
            app.RecordingNamesField.Position = [20 450 500 30];
            app.RecordingNamesField.FontSize = 12;
            app.RecordingNamesField.Value = 'Right_SS, Right_Fast, Left_SS, Left_Fast, Right_SS2, Right_Fast2';
            
            % Create Confirm Record Label button
            app.ConfirmRecordButton = uibutton(app.UIFigure, 'push');
            app.ConfirmRecordButton.Position = [540 450 120 30];
            app.ConfirmRecordButton.Text = 'Confirm Labels';
            app.ConfirmRecordButton.FontSize = 12;
            app.ConfirmRecordButton.ButtonPushedFcn = @(~,~) confirmRecordButtonPushed(app);
            
            % Create Left Dominant button
            app.LeftDominantButton = uibutton(app.UIFigure, 'push');
            app.LeftDominantButton.Position = [680 450 100 30];
            app.LeftDominantButton.Text = 'Left dominant';
            app.LeftDominantButton.FontSize = 12;
            app.LeftDominantButton.ButtonPushedFcn = @(~,~) leftDominantButtonPushed(app);
            
            % Create Right Dominant button
            app.RightDominantButton = uibutton(app.UIFigure, 'push');
            app.RightDominantButton.Position = [800 450 100 30];
            app.RightDominantButton.Text = 'Right dominant';
            app.RightDominantButton.FontSize = 12;
            app.RightDominantButton.ButtonPushedFcn = @(~,~) rightDominantButtonPushed(app);
        end
    end
    
    methods (Access = public)
        function app = CoordinationWindow(fig, subjectID, assessType, taskType)
            app.SubjectID = subjectID;
            app.AssessType = assessType;
            app.TaskType = taskType;
            if nargin > 0
                app.UIFigure = fig;
            end
            createComponents(app);
        end
    end
end 