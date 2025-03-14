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
        ManualInputs cell
        ManualExtractButton matlab.ui.control.Button
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
            basePath = './Data_Extracted/';
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
            filename = [char(app.SubjectID) '_Coordination_' char(app.AssessType) '_extracted.mat'];
            fullPath = fullfile(savePath, filename);
            
            % Save only the chnlData.Coordination struct
            CoordinationData = app.DataExtractor.chnlData.Coordination;  % Get the specific struct to save
            
            % Save the data
            save(fullPath, 'CoordinationData');
            
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
            renameChannelRecordingNames(app);

            % Update status
            app.StatusLabel.Text = 'Recording names confirmed!';
            app.StatusLabel.Visible = 'on';
        end

        function renameChannelRecordingNames(app)
            channelNames =  app.DataExtractor.metaData.Coordination.channelNames;
            for i = 1:length(channelNames)
                numRecording = length(app.RecordingNames);
                oldRecordingNames = "Recording" + string(1:numRecording);
                newRecordingNames = app.RecordingNames;
                
                % Get current channel name
                currentChannel = channelNames{i};
                
                % Update field names in the channel data
                for j = 1:numRecording
                    oldFieldName = oldRecordingNames(j);
                    newFieldName = newRecordingNames(j);
                    disp(oldFieldName);
                    disp(newFieldName);
                    
                    % Check if the old field exists before renaming
                    if isfield(app.DataExtractor.chnlData.Coordination.(currentChannel), oldFieldName)
                        % Store the data temporarily
                        tempData = app.DataExtractor.chnlData.Coordination.(currentChannel).(oldFieldName);
                        % Remove old field
                        app.DataExtractor.chnlData.Coordination.(currentChannel) = rmfield(app.DataExtractor.chnlData.Coordination.(currentChannel), oldFieldName);
                        % Add new field with the same data
                        app.DataExtractor.chnlData.Coordination.(currentChannel).(newFieldName) = tempData;
                    end
                end
            end
        end
        
        function leftDominantButtonPushed(app)
            app.RecordingNamesField.Value = 'Left_SS, Left_Fast, Right_SS, Right_Fast';
            app.StatusLabel.Text = 'Left dominant pattern selected';
            app.StatusLabel.Visible = 'on';
        end
        
        function rightDominantButtonPushed(app)
            app.RecordingNamesField.Value = 'Right_SS, Right_Fast, Left_SS, Left_Fast';
            app.StatusLabel.Text = 'Right dominant pattern selected';
            app.StatusLabel.Visible = 'on';
        end
        
        function manualExtractButtonPushed(app)
            testType = "Coordination";
            sampleRate = 2000; % Assuming 2000Hz sample rate
            extractedData = struct();
            
            % Process each row of manual inputs
            for row = 1:6
                % Get values from the current row
                startTime = app.ManualInputs{row, 1}.Value;
                endTime = app.ManualInputs{row, 2}.Value;
                recordingLabel = app.ManualInputs{row, 3}.Value;
                
                % Only process if all fields in the row are filled
                if ~isempty(startTime) && ~isempty(endTime) && ~isempty(recordingLabel)
                    % Convert time to frame indices
                    goFrameIdx = round(str2double(startTime) * sampleRate);
                    endFrameIdx = round(str2double(endTime) * sampleRate);
                    
                    if ~isnan(goFrameIdx) && ~isnan(endFrameIdx) && goFrameIdx < endFrameIdx
                        % Extract data between start and end for each channel
                        channelNames = app.DataExtractor.metaData.(testType).channelNames;
                        for i = 1:length(channelNames)
                            channelName = channelNames{i};

                            % Combine all recordings into one
                            combinedData = [];
                            % find all field names in app.DataExtractor.chnlData.(testType).(channelName)
                            recordingNames = fieldnames(app.DataExtractor.chnlData.(testType).(channelName));
                            for j = 1:length(recordingNames)
                                combinedData = [combinedData, app.DataExtractor.chnlData.(testType).(channelName).(cell2mat(recordingNames(j)))];
                            end

                            % Ensure indices are within bounds
                            goFrameIdx = max(1, goFrameIdx);
                            endFrameIdx = min(length(combinedData), endFrameIdx);

                            extractedData.(channelName).(recordingLabel) = combinedData(goFrameIdx:endFrameIdx);
                        end
                    else
                        warning('Invalid time values in row %d: Start=%s, End=%s', row, startTime, endTime);
                    end
                end
            end
            app.DataExtractor.chnlData.(testType) = extractedData;
            
            % Update status
            app.StatusLabel.Text = 'Manual GO-END extraction complete!';
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
            app.RecordingNamesField.Value = 'Right_SS, Right_Fast, Left_SS, Left_Fast';
            
            % Create column labels
            startLabel = uilabel(app.UIFigure);
            startLabel.Position = [20 420 60 20];
            startLabel.Text = 'Start time';
            
            endLabel = uilabel(app.UIFigure);
            endLabel.Position = [90 420 60 20];
            endLabel.Text = 'End time';
            
            labelText = uilabel(app.UIFigure);
            labelText.Position = [160 420 60 20];
            labelText.Text = 'Label';
            
            % Create 6x3 grid of text input boxes
            inputWidth = 60;
            inputHeight = 25;
            startX = 20;
            startY = 390;
            spacing = 70;
            
            % Initialize cell arrays to store the input fields
            app.ManualInputs = cell(6, 3);
            
            for row = 1:6
                for col = 1:3
                    app.ManualInputs{row, col} = uieditfield(app.UIFigure, 'text');
                    app.ManualInputs{row, col}.Position = [startX + (col-1)*spacing, ...
                        startY - (row-1)*30, inputWidth, inputHeight];
                end
            end
            
            % Create Manual Extract GO-END button
            app.ManualExtractButton = uibutton(app.UIFigure, 'push');
            app.ManualExtractButton.Position = [240 390 140 30];
            app.ManualExtractButton.Text = 'Manual Extract GO-END';
            app.ManualExtractButton.FontSize = 12;
            app.ManualExtractButton.ButtonPushedFcn = @(~,~) manualExtractButtonPushed(app);
            
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
            
            % Create instruction text box
            instructionBox = uitextarea(app.UIFigure);
            instructionBox.Value = {'Instructions:', ...
                '', ...
                'Normally, each recording (separated by green line)', ...
                'contains one movement, use:', ...
                'Extract -> Extract GO-END -> Save', ...
                '', ...
                'For not well-structured recording, do it manually:', ...
                'enter the times and labels -> Manual Extract GO-END -> Save'};
            instructionBox.Position = [400 250 300 150];
            instructionBox.FontSize = 11;
            instructionBox.BackgroundColor = [0.95 0.95 0.95];
            %instructionBox.Enable = 'off';  % Make it read-only
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