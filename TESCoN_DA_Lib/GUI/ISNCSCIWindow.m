classdef ISNCSCIWindow < BaseWindow
    properties (Access = protected)
        SubjectID string
        AssessType string
        TaskType string
        Side string
        TitleLabel matlab.ui.control.Label
        ExtractButton matlab.ui.control.Button
        ExtractLeftButton matlab.ui.control.Button
        ExtractRightButton matlab.ui.control.Button
        MergeLeftRightButton matlab.ui.control.Button
        VisualiseButton matlab.ui.control.Button
        MergeButton matlab.ui.control.Button
        SaveButton matlab.ui.control.Button
        StatusLabel matlab.ui.control.Label
        DataExtractor
        NumRecordings
        ExtractTriggeredButton matlab.ui.control.Button
        % New properties for channel mapping feature
        ChannelMappingPanel matlab.ui.container.Panel
        ChannelNameLabels matlab.ui.control.Label
        ChannelMappingDropdowns matlab.ui.control.DropDown
        ConfirmMappingButton matlab.ui.control.Button
        ChannelMappingOptions
        DefaultChannelMapping
        SelectedMappings
        AllInvalidButton matlab.ui.control.Button
    end
    
    methods (Access = private)
        function backButtonPushed(app)
            app.clearWindow();
            AssessmentSelectionWindow(app.UIFigure, app.SubjectID, app.TaskType);
        end
        
        function mergeButtonPushed(app)
            app.DataExtractor = app.DataExtractor.mergeRecordings(app.TaskType);
            app.NumRecordings = 1;  % After merging, treat as single recording
            
            % Update status
            app.StatusLabel.Text = 'Recordings merged!';
            app.StatusLabel.Visible = 'on';
            
            % Disable merge button after merging
            app.MergeButton.Enable = false;
        end
        
        function saveButtonPushed(app)
            % Create directory path
            basePath = './Data_Extracted/';
            subjectPath = fullfile(basePath, app.SubjectID);
            testPath = fullfile(subjectPath, char(app.TaskType));
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
            if app.Side == ""
                filename = [char(app.SubjectID) '_' char(app.TaskType) '_' char(app.AssessType) '_extracted.mat'];
            else
                filename = [char(app.SubjectID) '_' char(app.TaskType) '_' char(app.AssessType) '_' char(app.Side) '_extracted.mat'];
            end
            fullPath = fullfile(savePath, filename);
            
            % Save only the chnlData.ISNCSCI struct
            data = app.DataExtractor.chnlData.(char(app.TaskType));  % Get the specific struct to save
            
            % Save the data
            save(fullPath, 'data');
            
            % Update status
            app.StatusLabel.Text = 'Data saved successfully!';
            app.StatusLabel.Visible = 'on';
        end
        
        function extractButtonPushed(app, side)
            % Create DataExtractor instance
            sampleRate = 2000;
            app.DataExtractor = DataExtractor(app.SubjectID, app.AssessType, app.TaskType, sampleRate);

            if nargin < 2
                app.Side = "";
                app.DataExtractor = app.DataExtractor.loadExtractChannelPipline();
            else
                app.Side = side;
                app.DataExtractor = app.DataExtractor.loadExtractChannelPipline(side);
            end
            
            % Check number of recordings
            numRecordings = size(app.DataExtractor.rawData.(app.TaskType).datastart, 2);
            
            if numRecordings == 1
                app.DataExtractor = app.DataExtractor.extractChannelsSingleRecording();
                app.MergeButton.Enable = false;
            else
                % Create recording names (Rec1, Rec2, etc.)
                recordingNames = strings(1, numRecordings);
                for i = 1:numRecordings
                    recordingNames(i) = "Rec" + i;
                end
                app.DataExtractor = app.DataExtractor.extractChannelsMultiRecording();
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
            if app.TaskType == "ISNCSCI"
                app.ExtractTriggeredButton.Enable = true;
            end
            
            % Update channel mapping panel with extracted channel names
            setupChannelMappingPanel(app);
        end

        function mergeLeftRightButtonPushed(app)
            % Merage the left and right recordings in the processed data
            basePath = './Data_Extracted/';
            subjectPath = fullfile(basePath, app.SubjectID);
            testPath = fullfile(subjectPath, char(app.TaskType));
            savePath = fullfile(testPath, app.AssessType);

            filenameLeft = [char(app.SubjectID) '_' char(app.TaskType) '_' char(app.AssessType) '_Left_extracted.mat'];
            filenameRight = [char(app.SubjectID) '_' char(app.TaskType) '_' char(app.AssessType) '_Right_extracted.mat'];
            filenameMerged = [char(app.SubjectID) '_' char(app.TaskType) '_' char(app.AssessType) '_extracted.mat'];
            fullPathLeft = fullfile(savePath, filenameLeft);
            fullPathRight = fullfile(savePath, filenameRight);
            fullPathMerged = fullfile(savePath, filenameMerged);

            % Load the left and right data
            dataLeft = load(fullPathLeft);
            dataRight = load(fullPathRight);

            % dataLeft and dataRight are structs with the same fields, each field is a muscle/trigger with 1xn double arrays
            % We want to merge the dataLeft and dataRight structs into a single struct
            % Get the field names from dataLeft
            dataLeft = dataLeft.data;
            dataRight = dataRight.data;
            fieldNames = fieldnames(dataLeft);
            
            % Loop through each field in the dataLeft, and concatenate the dataRight field to the end of the dataLeft field
            for i = 1:length(fieldNames)
                % Get the current field name
                fieldName = fieldNames{i};
                dataLeft.(fieldName) = [dataLeft.(fieldName), dataRight.(fieldName)];
            end
            data = dataLeft;

            % Save the merged data to a new file
            save(fullPathMerged, 'data');

            % Delete the filenameLeft and filenameRight files
            delete(fullPathLeft);
            delete(fullPathRight);

            % Update status
            app.StatusLabel.Text = 'Left and right recordings merged!';
            app.StatusLabel.Visible = 'on';
            
        end
        
        
        function visualiseButtonPushed(app)
            if ~isempty(app.DataExtractor)
                if app.NumRecordings == 1
                    app.DataExtractor.graphAllChannelsSingleRecording();
                else
                    % Create recording names (Rec1, Rec2, etc.)
                    recordingNames = strings(1, app.NumRecordings);
                    for i = 1:app.NumRecordings
                        recordingNames(i) = "Rec" + i;
                    end
                    app.DataExtractor.graphAllChannelsMultiRecording();
                end
            end
        end
        
        function extractTriggeredButtonPushed(app)
            
            % Get trigger channel data
            triggerChannel = app.DataExtractor.chnlData.(app.TaskType).Trigger;
            
            % Find indices where trigger exceeds threshold
            triggerMask = triggerChannel > app.DataExtractor.triggerThres;
            
            % Extract triggered data for each channel
            channelNames = app.DataExtractor.metaData.(app.TaskType).channelNames;
            for i = 1:length(channelNames)
                channelName = channelNames(i);
                fullData = app.DataExtractor.chnlData.(app.TaskType).(channelName);
                
                % Apply trigger mask
                if isempty(fullData)
                    app.DataExtractor.chnlData.(app.TaskType).(channelName) = [];
                else
                    app.DataExtractor.chnlData.(app.TaskType).(channelName) = fullData(triggerMask);
                end
            end
            
            % Update status
            app.StatusLabel.Text = 'Triggered data extracted!';
            app.StatusLabel.Visible = 'on';
        end
        
        % New method for setting up the channel mapping panel
        function setupChannelMappingPanel(app)
            % Clear previous components if they exist
            if ~isempty(app.ChannelNameLabels)
                delete(app.ChannelNameLabels);
                delete(app.ChannelMappingDropdowns);
            end
            
            % Get the channel names from DataExtractor
            if isempty(app.DataExtractor) || ~isfield(app.DataExtractor.metaData, app.TaskType)
                return;
            end
            
            channelNames = app.DataExtractor.metaData.(app.TaskType).channelNames;
            numChannels = length(channelNames);
            
            % Create mapping options (A1, A2, ... A20)
            app.ChannelMappingOptions = ["Invalid", "L_Intraspinatus", "L_Deltoid", "L_Biceps", ...
                                         "L_Extensor", "L_Triceps", "L_Flexor_Digitorum", "L_Abductor_Digiti_Minimi", ...
                                         "Rectus_Abdominis", "L_Opponens", ...
                                         "R_Intraspinatus", "R_Deltoid", "R_Biceps", ...
                                         "R_Extensor", "R_Triceps", "R_Flexor_Digitorum", "R_Abductor_Digiti_Minimi", ...
                                         "Back_Extensor", "R_Opponens", ...
                                         "Trigger"];
            app.DefaultChannelMapping = ["L_Intraspinatus", "L_Deltoid", "L_Biceps", ...
                                            "L_Extensor", "L_Triceps", "L_Flexor_Digitorum", "L_Abductor_Digiti_Minimi", ...
                                            "Rectus_Abdominis", ...
                                            "R_Intraspinatus", "R_Deltoid", "R_Biceps", ...
                                            "R_Extensor", "R_Triceps", "R_Flexor_Digitorum", "R_Abductor_Digiti_Minimi", ...
                                            "Back_Extensor", ...
                                            "Trigger"];
            
            % Initialize selected mappings
            app.SelectedMappings = app.DefaultChannelMapping;
            
            % Create panel if it doesn't exist
            if isempty(app.ChannelMappingPanel)
                app.ChannelMappingPanel = uipanel(app.UIFigure);
                app.ChannelMappingPanel.Title = 'Channel Mapping';
                app.ChannelMappingPanel.FontWeight = 'bold';
                app.ChannelMappingPanel.Position = [580, 100, 400, 580];  % Increased height
                
                % Create confirm button - keep at bottom of panel
                app.ConfirmMappingButton = uibutton(app.ChannelMappingPanel, 'push');
                app.ConfirmMappingButton.Position = [10, 10, 180, 25];
                app.ConfirmMappingButton.Text = 'Confirm Mapping';
                app.ConfirmMappingButton.FontSize = 12;
                app.ConfirmMappingButton.Enable = false;  % Initially disabled
                app.ConfirmMappingButton.ButtonPushedFcn = @(~,~) confirmMappingButtonPushed(app);

                % Add All Invalid button
                app.AllInvalidButton = uibutton(app.ChannelMappingPanel, 'push');
                app.AllInvalidButton.Position = [200, 10, 180, 25];  % Position to the right of Confirm Mapping
                app.AllInvalidButton.Text = 'All Invalid';
                app.AllInvalidButton.FontSize = 12;
                app.AllInvalidButton.ButtonPushedFcn = @(~,~) allInvalidButtonPushed(app);
            end
            
            % Create labels and dropdowns
            app.ChannelNameLabels = matlab.ui.control.Label.empty(numChannels, 0);
            app.ChannelMappingDropdowns = matlab.ui.control.DropDown.empty(numChannels, 0);
            
            for i = 1:numChannels
                % Calculate y position - adjusted spacing for more room
                yPos = 580 - 30 - (i * 25);  % Increased vertical spacing between items
                
                % Create label
                app.ChannelNameLabels(i) = uilabel(app.ChannelMappingPanel);
                app.ChannelNameLabels(i).Position = [10, yPos, 180, 20];
                app.ChannelNameLabels(i).Text = channelNames(i);
                
                % Create dropdown
                app.ChannelMappingDropdowns(i) = uidropdown(app.ChannelMappingPanel);
                app.ChannelMappingDropdowns(i).Position = [200, yPos, 180, 20];
                app.ChannelMappingDropdowns(i).Items = ['Select...', app.ChannelMappingOptions];
                app.ChannelMappingDropdowns(i).Value = app.DefaultChannelMapping(i);
                app.ChannelMappingDropdowns(i).ValueChangedFcn = @(src, ~) channelMappingDropdownChanged(app, src, i);
            end
        end
        
        % Method to handle dropdown selection change
        function channelMappingDropdownChanged(app, src, channelIndex)
            % Get the selected value
            newMapping = src.Value;
            
            % If "Select..." is chosen, clear any previous mapping
            if strcmp(newMapping, 'Select...') || strcmp(newMapping, 'Invalid')
                % If there was a previous mapping, add it back to all other dropdowns
                oldMapping = app.SelectedMappings(channelIndex);
                if ~isempty(oldMapping) && ~strcmp(oldMapping, 'Invalid')
                    for i = 1:length(app.ChannelMappingDropdowns)
                        if i ~= channelIndex
                            currentItems = app.ChannelMappingDropdowns(i).Items;
                            if ~ismember(oldMapping, currentItems)
                                app.ChannelMappingDropdowns(i).Items = [currentItems, oldMapping];
                                % Sort the items
                                allItems = app.ChannelMappingDropdowns(i).Items;
                                if ~strcmp(allItems(1), 'Select...') 
                                    allItems = sort(allItems);
                                    app.ChannelMappingDropdowns(i).Items = allItems;
                                else
                                    remainingItems = sort(allItems(2:end));
                                    app.ChannelMappingDropdowns(i).Items = ['Select...', remainingItems];
                                end
                            end
                        end
                    end
                end
                app.SelectedMappings(channelIndex) = newMapping;
                updateConfirmButtonState(app);
                return;
            end
            
            % Store old mapping if exists
            oldMapping = app.SelectedMappings(channelIndex);
            
            % Update selected mappings
            app.SelectedMappings(channelIndex) = newMapping;
            
            % Only remove non-"Invalid" mappings from other dropdowns
            if ~strcmp(newMapping, 'Invalid')
                % Remove the selected mapping from all other dropdowns
                for i = 1:length(app.ChannelMappingDropdowns)
                    if i ~= channelIndex
                        currentItems = app.ChannelMappingDropdowns(i).Items;
                        if ismember(newMapping, currentItems)
                            currentItems(strcmp(currentItems, newMapping)) = [];
                            app.ChannelMappingDropdowns(i).Items = currentItems;
                        end
                        
                        % If there was a previous non-"Invalid" mapping, add it back
                        if ~isempty(oldMapping) && ~strcmp(oldMapping, 'Invalid') && ~ismember(oldMapping, currentItems)
                            app.ChannelMappingDropdowns(i).Items = [currentItems, oldMapping];
                            % Sort the items
                            allItems = app.ChannelMappingDropdowns(i).Items;
                            if ~strcmp(allItems(1), 'Select...')
                                allItems = sort(allItems);
                                app.ChannelMappingDropdowns(i).Items = allItems;
                            else
                                remainingItems = sort(allItems(2:end));
                                app.ChannelMappingDropdowns(i).Items = ['Select...', remainingItems];
                            end
                        end
                    end
                end
            end
            
            % Update confirm button state
            updateConfirmButtonState(app);
        end
        
        % Method to update confirm button state based on mappings
        function updateConfirmButtonState(app)
            % Check if any dropdown is set to "Select..."
            hasSelectOption = false;
            for i = 1:length(app.ChannelMappingDropdowns)
                if strcmp(app.ChannelMappingDropdowns(i).Value, 'Select...') || strcmp(app.ChannelMappingDropdowns(i).Value, '')
                    hasSelectOption = true;
                    break;
                end
            end
            
            % Enable/disable confirm button based on check
            app.ConfirmMappingButton.Enable = ~hasSelectOption;
        end
        
        % Method to handle confirm mapping button
        function confirmMappingButtonPushed(app)
            % Get original channel names
            originalChannelNames = app.DataExtractor.metaData.(app.TaskType).channelNames;
            
            % Create a mapping structure to store the original data
            tempData = struct();
            validChannelNames = {};
            
            % First, copy all data to temporary structure
            for i = 1:length(originalChannelNames)
                channelName = originalChannelNames(i);
                disp("judgement: " + app.SelectedMappings(i));
                
                % Skip if no mapping selected for this channel or if it's marked as Invalid
                if isempty(app.SelectedMappings(i)) || strcmp(app.SelectedMappings(i), 'Invalid')
                    disp("channelName: " + channelName + " is invalid");
                    continue;
                end
                
                % Copy data with new name
                newChannelName = app.SelectedMappings(i);
                validChannelNames{end+1} = newChannelName;
                disp("newChannelName: " + newChannelName);
                
                % Handle single or multi recording data
                if app.NumRecordings == 1
                    tempData.(newChannelName) = app.DataExtractor.chnlData.(app.TaskType).(channelName);
                else
                    % For multi-recording, we need to handle the struct differently
                    tempData.(newChannelName) = struct();
                    recordingNames = fieldnames(app.DataExtractor.chnlData.(app.TaskType).(channelName));
                    for j = 1:length(recordingNames)
                        recName = recordingNames{j};
                        tempData.(newChannelName).(recName) = app.DataExtractor.chnlData.(app.TaskType).(channelName).(recName);
                    end
                end
            end
            
            % Now replace the original data with remapped data
            app.DataExtractor.chnlData.(app.TaskType) = tempData;
            
            % Update channel names in metadata - only include valid channels
            app.DataExtractor.metaData.(app.TaskType).channelNames = validChannelNames;
            
            % Update status
            app.StatusLabel.Text = 'Channel mapping updated!';
            app.StatusLabel.Visible = 'on';
        end
        
        function allInvalidButtonPushed(app)
            % Set all dropdowns to "Invalid"
            for i = 1:length(app.ChannelMappingDropdowns)
                % Store old mapping
                oldMapping = app.SelectedMappings(i);
                
                % Set dropdown to "Invalid"
                app.ChannelMappingDropdowns(i).Value = 'Invalid';
                
                % Update selected mappings
                app.SelectedMappings(i) = 'Invalid';
                
                % If there was a previous non-"Invalid" mapping, add it back to other dropdowns
                if ~isempty(oldMapping) && ~strcmp(oldMapping, 'Invalid')
                    for j = 1:length(app.ChannelMappingDropdowns)
                        if j ~= i
                            currentItems = app.ChannelMappingDropdowns(j).Items;
                            if ~ismember(oldMapping, currentItems)
                                app.ChannelMappingDropdowns(j).Items = [currentItems, oldMapping];
                                % Sort the items
                                allItems = app.ChannelMappingDropdowns(j).Items;
                                if ~strcmp(allItems(1), 'Select...')
                                    allItems = sort(allItems);
                                    app.ChannelMappingDropdowns(j).Items = allItems;
                                else
                                    remainingItems = sort(allItems(2:end));
                                    app.ChannelMappingDropdowns(j).Items = ['Select...', remainingItems];
                                end
                            end
                        end
                    end
                end
            end
            
            % Enable confirm button since all dropdowns are now set
            app.ConfirmMappingButton.Enable = true;
        end
        
        function createComponents(app)
            initializeBaseWindow(app);
            app.UIFigure.Name = [char(app.TaskType) ' Data - ' char(app.AssessType)];
            
            % Show back button
            showBackButton(app, @(~,~) backButtonPushed(app));
            
            % Create title label - moved up
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [20 750 360 30];
            app.TitleLabel.Text = [char(app.TaskType) ' Data Processing - ' char(app.AssessType)];
            
            % Create Extract button - moved up
            app.ExtractButton = uibutton(app.UIFigure, 'push');
            app.ExtractButton.Position = [20 700 100 30];
            app.ExtractButton.Text = 'Extract';
            app.ExtractButton.FontSize = 12;
            app.ExtractButton.ButtonPushedFcn = @(~,~) extractButtonPushed(app);

            % Create Extract left button - adjusted spacing
            app.ExtractLeftButton = uibutton(app.UIFigure, 'push');
            app.ExtractLeftButton.Position = [20 600 100 30];
            app.ExtractLeftButton.Text = 'Extract Left';
            app.ExtractLeftButton.FontSize = 12;
            app.ExtractLeftButton.ButtonPushedFcn = @(~,~) extractButtonPushed(app, 'Left');

            % Create Extract right button - adjusted spacing
            app.ExtractRightButton = uibutton(app.UIFigure, 'push');
            app.ExtractRightButton.Position = [20 500 100 30];
            app.ExtractRightButton.Text = 'Extract Right';
            app.ExtractRightButton.FontSize = 12;
            app.ExtractRightButton.ButtonPushedFcn = @(~,~) extractButtonPushed(app, 'Right');

            % Merge left and right button - adjusted position
            app.MergeLeftRightButton = uibutton(app.UIFigure, 'push');
            app.MergeLeftRightButton.Position = [140 550 120 30];
            app.MergeLeftRightButton.Text = 'Merge Left and Right';
            app.MergeLeftRightButton.FontSize = 12;
            app.MergeLeftRightButton.ButtonPushedFcn = @(~,~) mergeLeftRightButtonPushed(app);
            
            % Create Visualise button - moved up
            app.VisualiseButton = uibutton(app.UIFigure, 'push');
            app.VisualiseButton.Position = [140 700 100 30];
            app.VisualiseButton.Text = 'Visualise';
            app.VisualiseButton.FontSize = 12;
            app.VisualiseButton.Enable = false;
            app.VisualiseButton.ButtonPushedFcn = @(~,~) visualiseButtonPushed(app);
            
            % Create Merge Recordings button - moved up
            app.MergeButton = uibutton(app.UIFigure, 'push');
            app.MergeButton.Position = [260 700 120 30];
            app.MergeButton.Text = 'Merge Recordings';
            app.MergeButton.FontSize = 12;
            app.MergeButton.Enable = false;  % Initially disabled
            app.MergeButton.ButtonPushedFcn = @(~,~) mergeButtonPushed(app);
            
            % Create Extract Triggered button - moved up
            app.ExtractTriggeredButton = uibutton(app.UIFigure, 'push');
            app.ExtractTriggeredButton.Position = [400 700 100 30];
            app.ExtractTriggeredButton.Text = 'Extract Triggered';
            app.ExtractTriggeredButton.FontSize = 12;
            app.ExtractTriggeredButton.Enable = false;
            app.ExtractTriggeredButton.ButtonPushedFcn = @(~,~) extractTriggeredButtonPushed(app);
            
            % Create Save button - moved up
            app.SaveButton = uibutton(app.UIFigure, 'push');
            app.SaveButton.Position = [880 700 100 30];
            app.SaveButton.Text = 'Save';
            app.SaveButton.FontSize = 12;
            app.SaveButton.Enable = false;  % Initially disabled
            app.SaveButton.ButtonPushedFcn = @(~,~) saveButtonPushed(app);
            
            % Move status label - moved up
            app.StatusLabel = uilabel(app.UIFigure);
            app.StatusLabel.FontSize = 12;
            app.StatusLabel.Position = [520 700 200 30];
            app.StatusLabel.Visible = 'off';
            
            % Initialize empty arrays for the channel mapping components
            app.ChannelNameLabels = matlab.ui.control.Label.empty(0, 0);
            app.ChannelMappingDropdowns = matlab.ui.control.DropDown.empty(0, 0);

            % Create instruction text box
            instructionBox = uitextarea(app.UIFigure);
            instructionBox.Value = {'Instructions:', ...
                'For either REST or ISNCSCI assessment:', ...
                '1. Extract (if left and right are in the same file), or Extract Left and Right (if left and right are in different files)', ...
                '2. Visualise: check for any abnormalities: e.g., some data does not have any data, or have signal range > 5mV', ...
                '3. Merge recording if there are multiple recordings (separated using green vertical line). If there is only one recording, the button will be disabled.', ...
                '4. *Only for ISNCSCI* Click the Extract Triggered button. This will extract data only when the trigger is on.', ...
                '5. Confirm the channel names are corrected labeld, select "Invalid" for the abnormal channels (data will not be saved & not be used for MVC/Rest normalisation)', ...
                '6. Click "Confirm Mapping" when done', ...
                '7. Click "Save"', ...
                '8. Back - process other files'};
            instructionBox.Position = [20 200 320 250];
            instructionBox.FontSize = 11;
            instructionBox.BackgroundColor = [0.95 0.95 0.95];
        end
    end
    
    methods (Access = public)
        function app = ISNCSCIWindow(fig, subjectID, assessType, taskType)
            disp("II'm in ISNCSCIWindow, subject ID is: " + subjectID)
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