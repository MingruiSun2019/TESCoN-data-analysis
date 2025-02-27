classdef ISNCSCIWindow < BaseWindow
    properties (Access = private)
        SubjectID string
        AssessType string
        TaskType string
        Side string
        TitleLabel matlab.ui.control.Label
        ExtractButton matlab.ui.control.Button
        VisualiseButton matlab.ui.control.Button
        MergeButton matlab.ui.control.Button
        SaveButton matlab.ui.control.Button
        StatusLabel matlab.ui.control.Label
        PlotArea matlab.ui.control.UIAxes
        DataExtractor
        NumRecordings
        ExtractTriggeredButton matlab.ui.control.Button
    end
    
    methods (Access = private)
        function backButtonPushed(app)
            app.clearWindow();
            AssessmentSelectionWindow(app.UIFigure, app.SubjectID, app.TaskType);
        end
        
        function mergeButtonPushed(app)
            testType = "ISNCSCI";
            app.DataExtractor = app.DataExtractor.mergeRecordings(testType);
            app.NumRecordings = 1;  % After merging, treat as single recording
            
            % Update status
            app.StatusLabel.Text = 'Recordings merged!';
            app.StatusLabel.Visible = 'on';
            
            % Disable merge button after merging
            app.MergeButton.Enable = false;
        end
        
        function saveButtonPushed(app)
            % Create directory path
            basePath = './Data_Processed/';
            subjectPath = fullfile(basePath, app.SubjectID);
            testPath = fullfile(subjectPath, 'ISNCSCI');
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
            filename = ['processed_' char(app.SubjectID) '_ISNCSCI_' char(app.AssessType) '_' char(app.Side) '.mat'];
            fullPath = fullfile(savePath, filename);
            
            % Save only the chnlData.ISNCSCI struct
            saveData = app.DataExtractor.chnlData.ISNCSCI;  % Get the specific struct to save
            
            % Save the data
            save(fullPath, 'saveData');
            
            % Update status
            app.StatusLabel.Text = 'Data saved successfully!';
            app.StatusLabel.Visible = 'on';
        end
        
        function extractButtonPushed(app, side)
            % Create DataExtractor instance
            taskType = "ISNCSCI";
            sampleRate = 2000;
            app.DataExtractor = DataExtractor(app.SubjectID, app.AssessType, taskType, sampleRate);

            if nargin < 2
                app.Side = "";
                app.DataExtractor = app.DataExtractor.loadExtractChannelPipline();
            else
                app.Side = side;
                app.DataExtractor = app.DataExtractor.loadExtractChannelPipline(side);
            end
            
            % Check number of recordings
            numRecordings = size(app.DataExtractor.rawData.(taskType).datastart, 2);
            
            if numRecordings == 1
                app.DataExtractor = app.DataExtractor.extractChannelsSingleRecording();
                app.MergeButton.Enable = false;
            else
                % Create recording names (Rec1, Rec2, etc.)
                recordingNames = strings(1, numRecordings);
                for i = 1:numRecordings
                    recordingNames(i) = "Rec" + i;
                end
                app.DataExtractor = app.DataExtractor.extractChannelsMultiRecording(recordingNames);
                app.MergeButton.Enable = true;
            end
            
            % Update status
            app.StatusLabel.Text = 'Extraction finished!';
            app.StatusLabel.Visible = 'on';
            
            % Store number of recordings for visualization
            app.NumRecordings = numRecordings;
            
            % Enable visualise button
            app.VisualiseButton.Enable = true;
            
            % Enable save button after extraction
            app.SaveButton.Enable = true;
            
            % Enable Extract Triggered button after extraction
            app.ExtractTriggeredButton.Enable = true;
        end
        
        function visualiseButtonPushed(app)
            if ~isempty(app.DataExtractor)
                testType = "ISNCSCI";
                if app.NumRecordings == 1
                    app.DataExtractor.graphAllChannelsSingleRecording();
                else
                    % Create recording names (Rec1, Rec2, etc.)
                    recordingNames = strings(1, app.NumRecordings);
                    for i = 1:app.NumRecordings
                        recordingNames(i) = "Rec" + i;
                    end
                    app.DataExtractor.graphAllChannelsMultiRecording(recordingNames);
                end
            end
        end
        
        function extractTriggeredButtonPushed(app)
            testType = "ISNCSCI";
            
            % Get trigger channel data
            triggerChannel = app.DataExtractor.chnlData.(testType).Trigger;
            
            % Find indices where trigger exceeds threshold
            triggerMask = triggerChannel > app.DataExtractor.triggerThres;
            
            % Extract triggered data for each channel
            channelNames = app.DataExtractor.metaData.(testType).channelNames;
            for i = 1:length(channelNames)
                channelName = channelNames(i);
                fullData = app.DataExtractor.chnlData.(testType).(channelName);
                
                % Apply trigger mask
                app.DataExtractor.chnlData.(testType).(channelName) = fullData(triggerMask);
            end
            
            % Update status
            app.StatusLabel.Text = 'Triggered data extracted!';
            app.StatusLabel.Visible = 'on';
        end
        
        function createComponents(app)
            initializeBaseWindow(app);
            app.UIFigure.Name = ['ISNCSCI Data - ' char(app.AssessType)];
            
            % Show back button
            showBackButton(app, @(~,~) backButtonPushed(app));
            
            % Create title label
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [20 550 360 30];
            app.TitleLabel.Text = ['ISNCSCI Data Processing - ' char(app.AssessType)];
            
            % Create Extract button
            app.ExtractButton = uibutton(app.UIFigure, 'push');
            app.ExtractButton.Position = [20 500 100 30];
            app.ExtractButton.Text = 'Extract';
            app.ExtractButton.FontSize = 12;
            app.ExtractButton.ButtonPushedFcn = @(~,~) extractButtonPushed(app);

            % Create Extract left button
            app.ExtractLeftButton = uibutton(app.UIFigure, 'push');
            app.ExtractLeftButton.Position = [20 400 100 30];
            app.ExtractLeftButton.Text = 'Extract Left';
            app.ExtractLeftButton.FontSize = 12;
            app.ExtractLeftButton.ButtonPushedFcn = @(~,~) extractButtonPushed(app, 'Left');

            % Create Extract right button
            app.ExtractRightButton = uibutton(app.UIFigure, 'push');
            app.ExtractRightButton.Position = [20 300 100 30];
            app.ExtractRightButton.Text = 'Extract Right';
            app.ExtractRightButton.FontSize = 12;
            app.ExtractRightButton.ButtonPushedFcn = @(~,~) extractButtonPushed(app, 'Right');
            
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
            
            % Create Extract Triggered button
            app.ExtractTriggeredButton = uibutton(app.UIFigure, 'push');
            app.ExtractTriggeredButton.Position = [400 500 100 30];
            app.ExtractTriggeredButton.Text = 'Extract Triggered';
            app.ExtractTriggeredButton.FontSize = 12;
            app.ExtractTriggeredButton.Enable = false;
            app.ExtractTriggeredButton.ButtonPushedFcn = @(~,~) extractTriggeredButtonPushed(app);
            
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
    
    methods (Access = public)
        function app = ISNCSCIWindow(fig, subjectID, assessType, taskType)
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