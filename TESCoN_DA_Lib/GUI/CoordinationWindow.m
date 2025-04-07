classdef CoordinationWindow < BaseWindow
    properties (Access = protected)
        SubjectID string
        AssessType string
        TaskType string
        TitleLabel matlab.ui.control.Label
        ExtractButton matlab.ui.control.Button
        VisualiseButton matlab.ui.control.Button
        SaveButton matlab.ui.control.Button
        StatusLabel matlab.ui.control.Label
        DataExtractor
        ExtractGoEndButton matlab.ui.control.Button
        RecordingNamesField matlab.ui.control.EditField
        ConfirmRecordButton matlab.ui.control.Button
        RecordingNames string
        LeftDominantButton matlab.ui.control.Button
        RightDominantButton matlab.ui.control.Button
        ManualInputs cell
        ManualExtractButton matlab.ui.control.Button
        % New properties for channel mapping feature
        ChannelMappingPanel matlab.ui.container.Panel
        ChannelNameLabels matlab.ui.control.Label
        ChannelMappingDropdowns matlab.ui.control.DropDown
        ConfirmMappingButton matlab.ui.control.Button
        ChannelMappingOptions
        SelectedMappings
        AllInvalidButton matlab.ui.control.Button
        DefaultChannelMapping
        % New properties for comment-based GO-END selection
        CommentInputs cell
        CommentExtractButton matlab.ui.control.Button
        CommentTimestamps struct
        
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

            app.DataExtractor = app.DataExtractor.extractCommentAndTimestamps();
            
            % Update status
            app.StatusLabel.Text = 'Extraction finished!';
            app.StatusLabel.Visible = 'on';
            
            % Enable visualise and save buttons
            app.VisualiseButton.Enable = true;
            app.SaveButton.Enable = true;
            
            % Enable Extract GO-END button after extraction
            app.ExtractGoEndButton.Enable = true;

            % Setup channel mapping panel
            setupChannelMappingPanel(app);
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
            data = app.DataExtractor.chnlData.Coordination;  % Get the specific struct to save
            
            % Save the data
            save(fullPath, 'data');
            
            % Update status
            app.StatusLabel.Text = 'Data saved successfully!';
            app.StatusLabel.Visible = 'on';
        end
        
        function extractGoEndButtonPushed(app)
            testType = "Coordination";
            recordingNames = app.DataExtractor.metaData.Coordination.recordingNames;
            extractedRecordingNames = string(strsplit(app.RecordingNamesField.Value, ','));

            % Process each recording
            
            extractedRecordingIdx = 0;
            for recordIdx = 1:length(recordingNames)
                % Find "GO" and "END" indices
                [goFrameIdx, endFrameIdx] = app.DataExtractor.extractGoEndData(testType, recordIdx);

                if isempty(goFrameIdx)
                    continue;
                end
                
                numGoEnd = length(goFrameIdx);
                disp("Number of Go-End: " + num2str(numGoEnd))
                for j = 1:numGoEnd
                    % Extract data between GO and END for each channel
                    channelNames = app.DataExtractor.metaData.(testType).channelNames;
                    extractedRecordingIdx = extractedRecordingIdx + 1;
                    disp("Recording: " + extractedRecordingNames(extractedRecordingIdx) + " GO: " + goFrameIdx{j} + " END: " + endFrameIdx{j});
                
                    for i = 1:length(channelNames)
                        channelName = channelNames{i};
                        disp("Channel: " + channelName + " Recording: " + recordingNames(recordIdx));
                        fullData = app.DataExtractor.chnlData.(testType).(channelName).(recordingNames(recordIdx));
                        
                        % Extract data between GO and END
                        fieldName = extractedRecordingNames(extractedRecordingIdx);
                        validFieldName = processChannelName(fieldName);
                        tempData.(channelName).(validFieldName) = fullData(goFrameIdx{j}:endFrameIdx{j});
                    end
                end
            end

            app.DataExtractor.chnlData.(testType) = tempData;
            
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
            % renameChannelRecordingNames(app);

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
        
        % New method for setting up the channel mapping panel
        function setupChannelMappingPanel(app)
            % Clear previous components if they exist
            if ~isempty(app.ChannelNameLabels)
                delete(app.ChannelNameLabels);
                delete(app.ChannelMappingDropdowns);
            end
            
            % Get the channel names from DataExtractor
            if isempty(app.DataExtractor) || ~isfield(app.DataExtractor.metaData, 'Coordination')
                return;
            end
            
            channelNames = app.DataExtractor.metaData.Coordination.channelNames;
            numChannels = length(channelNames);
            
            % Update mapping options to include Invalid
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
                app.ChannelMappingPanel.Position = [580, 40, 400, 580];  % Adjusted height
                
                % Create confirm button
                app.ConfirmMappingButton = uibutton(app.ChannelMappingPanel, 'push');
                app.ConfirmMappingButton.Position = [10, 10, 180, 25];
                app.ConfirmMappingButton.Text = 'Confirm Mapping';
                app.ConfirmMappingButton.FontSize = 12;
                app.ConfirmMappingButton.Enable = false;
                app.ConfirmMappingButton.ButtonPushedFcn = @(~,~) confirmMappingButtonPushed(app);

                % Add All Invalid button
                app.AllInvalidButton = uibutton(app.ChannelMappingPanel, 'push');
                app.AllInvalidButton.Position = [200, 10, 180, 25];
                app.AllInvalidButton.Text = 'All Invalid';
                app.AllInvalidButton.FontSize = 12;
                app.AllInvalidButton.ButtonPushedFcn = @(~,~) allInvalidButtonPushed(app);
            end
            
            % Create labels and dropdowns
            app.ChannelNameLabels = matlab.ui.control.Label.empty(numChannels, 0);
            app.ChannelMappingDropdowns = matlab.ui.control.DropDown.empty(numChannels, 0);
            
            for i = 1:numChannels
                % Calculate y position
                yPos = 580 - 30 - (i * 25);
                
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
            
            % Update confirm button state
            updateConfirmButtonState(app);
        end
        
        % Method to update confirm button state based on mappings
        function updateConfirmButtonState(app)
            % Check if any dropdown is set to "Select..."
            hasSelectOption = false;
            for i = 1:length(app.ChannelMappingDropdowns)
                if strcmp(app.ChannelMappingDropdowns(i).Value, 'Select...')
                    hasSelectOption = true;
                    break;
                end
            end

            disp("Updated: " + hasSelectOption)
            
            % Enable/disable confirm button based on check
            app.ConfirmMappingButton.Enable = ~hasSelectOption;
        end
        
        % Method to handle confirm mapping button
        function confirmMappingButtonPushed(app)
            % Get original channel names
            originalChannelNames = app.DataExtractor.metaData.Coordination.channelNames;
            
            % Create a mapping structure to store the original data
            tempData = struct();
            validChannelNames = {};
            
            % First, copy all data to temporary structure
            for i = 1:length(originalChannelNames)
                channelName = originalChannelNames{i};
                
                % Skip if no mapping selected for this channel or if it's marked as Invalid
                if isempty(app.SelectedMappings(i)) || strcmp(app.SelectedMappings(i), 'Invalid')
                    continue;
                end
                
                % Copy data with new name
                newChannelName = app.SelectedMappings(i);
                validChannelNames{end+1} = newChannelName;
                
                % Handle recording data
                recordingNames = fieldnames(app.DataExtractor.chnlData.Coordination.(channelName));
                tempData.(newChannelName) = struct();
                for j = 1:length(recordingNames)
                    recName = recordingNames{j};
                    tempData.(newChannelName).(recName) = app.DataExtractor.chnlData.Coordination.(channelName).(recName);
                end
            end
            
            % Now replace the original data with remapped data
            app.DataExtractor.chnlData.Coordination = tempData;
            
            % Update channel names in metadata - only include valid channels
            app.DataExtractor.metaData.Coordination.channelNames = validChannelNames;
            
            % Update status
            app.StatusLabel.Text = 'Channel mapping updated!';
            app.StatusLabel.Visible = 'on';
        end
        
        % Add allInvalidButtonPushed function
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
        
        function setupCommentDropdowns(app)
            % Get available comments and timestamps from DataExtractor
            if ~isempty(app.DataExtractor) && ...
               isfield(app.DataExtractor.metaData, 'Coordination') && ...
               isfield(app.DataExtractor.metaData.Coordination, 'comments')
                
                % Get comments and timestamps
                comments = app.DataExtractor.metaData.Coordination.comments;
                timestamps = app.DataExtractor.metaData.Coordination.commentTimestamps;
                
                % Store for later use
                app.CommentTimestamps = timestamps;
                
                % Update the dropdown lists with available comments
                for row = 1:6
                    % Update start event dropdown
                    app.CommentInputs{row, 1}.Items = ["Select..."; comments];
                    app.CommentInputs{row, 1}.Value = "Select...";
                    
                    % Update stop event dropdown
                    app.CommentInputs{row, 2}.Items = ["Select..."; comments];
                    app.CommentInputs{row, 2}.Value = "Select...";
                    
                    % Clear any existing timestamp labels
                    app.CommentInputs{row, 3}.Text = '';
                    app.CommentInputs{row, 4}.Text = '';
                end
                
                % Enable the comment extract button
                app.CommentExtractButton.Enable = true;
                
                % Update status
                app.StatusLabel.Text = 'Comment dropdowns updated with available events';
                app.StatusLabel.Visible = 'on';
            else
                app.StatusLabel.Text = 'No comments available - extract data first';
                app.StatusLabel.Visible = 'on';
            end
        end
        
        function commentDropdownChanged(app, src, ~)
            % Find which dropdown was changed
            for row = 1:6
                for col = 1:2
                    if src == app.CommentInputs{row, col}
                        % Get the selected comment
                        selectedComment = src.Value;
                        
                        % Skip if "Select..." is chosen
                        if strcmp(selectedComment, 'Select...')
                            return;
                        end
                        
                        % Find matching timestamp
                        if isfield(app.CommentTimestamps, 'comments')
                            idx = find(strcmp(app.CommentTimestamps.comments, selectedComment), 1);
                            if ~isempty(idx)
                                timestamp = app.CommentTimestamps.timestamps(idx);
                                
                                % Display timestamp below dropdown
                                timestampLabel = app.CommentInputs{row, col+2};
                                timestampLabel.Text = sprintf('%.2f s', timestamp);
                            end
                        end
                        return;
                    end
                end
            end
        end
        
        function commentExtractButtonPushed(app)
            testType = "Coordination";
            sampleRate = 2000; % Assuming 2000Hz sample rate
            extractedData = struct();
            
            % Process each row of comment inputs
            for row = 1:6
                % Get selected comments
                startComment = app.CommentInputs{row, 1}.Value;
                endComment = app.CommentInputs{row, 2}.Value;
                recordingLabel = app.CommentInputs{row, 5}.Value;
                
                % Only process if all fields in the row are filled
                if ~strcmp(startComment, 'Select...') && ~strcmp(endComment, 'Select...') && ~isempty(recordingLabel)
                    % Find timestamps for selected comments
                    startIdx = find(strcmp(app.CommentTimestamps.comments, startComment), 1);
                    endIdx = find(strcmp(app.CommentTimestamps.comments, endComment), 1);
                    
                    if ~isempty(startIdx) && ~isempty(endIdx)
                        startTimestamp = app.CommentTimestamps.timestamps(startIdx);
                        endTimestamp = app.CommentTimestamps.timestamps(endIdx);
                        
                        % Convert time to frame indices
                        goFrameIdx = round(startTimestamp * sampleRate);
                        endFrameIdx = round(endTimestamp * sampleRate);
                        
                        if goFrameIdx < endFrameIdx
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
                            warning('Invalid time sequence in row %d: Start=%f, End=%f', row, startTimestamp, endTimestamp);
                        end
                    end
                end
            end
            
            % Update the data in DataExtractor
            app.DataExtractor.chnlData.(testType) = extractedData;
            
            % Update status
            app.StatusLabel.Text = 'Comment-based GO-END extraction complete!';
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
            app.TitleLabel.Position = [20 750 360 30];
            app.TitleLabel.Text = ['Coordination Data Processing - ' char(app.AssessType)];
            
            % Create Extract button
            app.ExtractButton = uibutton(app.UIFigure, 'push');
            app.ExtractButton.Position = [20 700 100 30];
            app.ExtractButton.Text = 'Extract';
            app.ExtractButton.FontSize = 12;
            app.ExtractButton.ButtonPushedFcn = @(~,~) extractAndSetupComments(app);
            
            % Create Visualise button
            app.VisualiseButton = uibutton(app.UIFigure, 'push');
            app.VisualiseButton.Position = [140 700 100 30];
            app.VisualiseButton.Text = 'Visualise';
            app.VisualiseButton.FontSize = 12;
            app.VisualiseButton.Enable = false;
            app.VisualiseButton.ButtonPushedFcn = @(~,~) visualiseButtonPushed(app);
            
            % Create Save button
            app.SaveButton = uibutton(app.UIFigure, 'push');
            app.SaveButton.Position = [400 700 100 30];
            app.SaveButton.Text = 'Save';
            app.SaveButton.FontSize = 12;
            app.SaveButton.Enable = false;
            app.SaveButton.ButtonPushedFcn = @(~,~) saveButtonPushed(app);
            
            % Create Extract GO-END button
            app.ExtractGoEndButton = uibutton(app.UIFigure, 'push');
            app.ExtractGoEndButton.Position = [260 700 120 30];
            app.ExtractGoEndButton.Text = 'Extract GO-END';
            app.ExtractGoEndButton.FontSize = 12;
            app.ExtractGoEndButton.Enable = false;
            app.ExtractGoEndButton.ButtonPushedFcn = @(~,~) extractGoEndButtonPushed(app);
            
            % Create status label
            app.StatusLabel = uilabel(app.UIFigure);
            app.StatusLabel.FontSize = 12;
            app.StatusLabel.Position = [520 700 300 30];
            app.StatusLabel.Visible = 'off';
            
            % Create recording names input field
            app.RecordingNamesField = uieditfield(app.UIFigure, 'text');
            app.RecordingNamesField.Position = [20 650 500 30];
            app.RecordingNamesField.FontSize = 12;
            app.RecordingNamesField.Value = 'Right_SS, Right_Fast, Left_SS, Left_Fast';
            
            % Create Confirm Record Label button
            app.ConfirmRecordButton = uibutton(app.UIFigure, 'push');
            app.ConfirmRecordButton.Position = [540 650 120 30];
            app.ConfirmRecordButton.Text = 'Confirm Labels';
            app.ConfirmRecordButton.FontSize = 12;
            app.ConfirmRecordButton.ButtonPushedFcn = @(~,~) confirmRecordButtonPushed(app);
            
            % Create Left Dominant button
            app.LeftDominantButton = uibutton(app.UIFigure, 'push');
            app.LeftDominantButton.Position = [680 650 100 30];
            app.LeftDominantButton.Text = 'Left dominant';
            app.LeftDominantButton.FontSize = 12;
            app.LeftDominantButton.ButtonPushedFcn = @(~,~) leftDominantButtonPushed(app);
            
            % Create Right Dominant button
            app.RightDominantButton = uibutton(app.UIFigure, 'push');
            app.RightDominantButton.Position = [800 650 100 30];
            app.RightDominantButton.Text = 'Right dominant';
            app.RightDominantButton.FontSize = 12;
            app.RightDominantButton.ButtonPushedFcn = @(~,~) rightDominantButtonPushed(app);
            
            % Create column labels for manual input
            startLabel = uilabel(app.UIFigure);
            startLabel.Position = [20 620 60 20];
            startLabel.Text = 'Start time';
            
            endLabel = uilabel(app.UIFigure);
            endLabel.Position = [90 620 60 20];
            endLabel.Text = 'End time';
            
            labelText = uilabel(app.UIFigure);
            labelText.Position = [160 620 60 20];
            labelText.Text = 'Label';
            
            % Create 6x3 grid of text input boxes
            inputWidth = 60;
            inputHeight = 25;
            startX = 20;
            startY = 590;
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
            app.ManualExtractButton.Position = [240 590 140 30];
            app.ManualExtractButton.Text = 'Manual Extract GO-END';
            app.ManualExtractButton.FontSize = 12;
            app.ManualExtractButton.ButtonPushedFcn = @(~,~) manualExtractButtonPushed(app);
            
            % Initialize empty arrays for the channel mapping components
            app.ChannelNameLabels = matlab.ui.control.Label.empty(0, 0);
            app.ChannelMappingDropdowns = matlab.ui.control.DropDown.empty(0, 0);
            
            % Create instruction text box
            instructionBox = uitextarea(app.UIFigure);
            instructionBox.Value = {'Instructions:', ...
                '1. Extract', ...
                '2. Visualise: check left or right dominant, check GO-END are marked properly', ...
                '3. Select Left or Right Dominant', ...
                '4. Do the channel mapping', ...
                '5. Confirm Mapping', ...
                '6. Extract GO-END', ...
                '7. Save', ...
                'For manual extraction:', ...
                '1. Extract', ...
                '2. Enter start time, end time, and label for each segment', ...
                '3. Click Manual Extract GO-END -> Save'};
            instructionBox.Position = [250 400 300 150];
            instructionBox.FontSize = 11;
            instructionBox.BackgroundColor = [0.95 0.95 0.95];
            
            % After creating the manual inputs section, add the comment-based selection
            
            % Create column labels for comment-based input
            startEventLabel = uilabel(app.UIFigure);
            startEventLabel.Position = [20 390 80 20];
            startEventLabel.Text = 'Start event';
            
            stopEventLabel = uilabel(app.UIFigure);
            stopEventLabel.Position = [180 390 80 20];
            stopEventLabel.Text = 'Stop event';
            
            labelTextComment = uilabel(app.UIFigure);
            labelTextComment.Position = [340 390 60 20];
            labelTextComment.Text = 'Label';
            
            % Create 6x3 grid for comment-based extraction
            dropdownWidth = 150;
            inputWidth = 80;
            inputHeight = 25;
            startX = 20;
            startY = 360;
            
            % Initialize cell arrays to store the input fields and labels
            app.CommentInputs = cell(6, 5); % 2 dropdowns, 1 text field, 2 timestamp labels
            
            for row = 1:6
                % Start event dropdown
                app.CommentInputs{row, 1} = uidropdown(app.UIFigure);
                app.CommentInputs{row, 1}.Position = [startX, startY - (row-1)*40, dropdownWidth, inputHeight];
                app.CommentInputs{row, 1}.Items = {'Select...'};
                app.CommentInputs{row, 1}.Value = 'Select...';
                app.CommentInputs{row, 1}.ValueChangedFcn = @(src, event) commentDropdownChanged(app, src, event);
                
                % Start timestamp label
                app.CommentInputs{row, 3} = uilabel(app.UIFigure);
                app.CommentInputs{row, 3}.Position = [startX, startY - (row-1)*40 - 20, dropdownWidth, 20];
                app.CommentInputs{row, 3}.Text = '';
                
                % Stop event dropdown
                app.CommentInputs{row, 2} = uidropdown(app.UIFigure);
                app.CommentInputs{row, 2}.Position = [startX + dropdownWidth + 10, startY - (row-1)*40, dropdownWidth, inputHeight];
                app.CommentInputs{row, 2}.Items = {'Select...'};
                app.CommentInputs{row, 2}.Value = 'Select...';
                app.CommentInputs{row, 2}.ValueChangedFcn = @(src, event) commentDropdownChanged(app, src, event);
                
                % Stop timestamp label
                app.CommentInputs{row, 4} = uilabel(app.UIFigure);
                app.CommentInputs{row, 4}.Position = [startX + dropdownWidth + 10, startY - (row-1)*40 - 20, dropdownWidth, 20];
                app.CommentInputs{row, 4}.Text = '';
                
                % Label text field
                app.CommentInputs{row, 5} = uieditfield(app.UIFigure, 'text');
                app.CommentInputs{row, 5}.Position = [startX + 2*dropdownWidth + 20, startY - (row-1)*40, inputWidth, inputHeight];
            end
            
            % Create Manually Extract GO-END 2 button
            app.CommentExtractButton = uibutton(app.UIFigure, 'push');
            app.CommentExtractButton.Position = [startX + 2*dropdownWidth + inputWidth + 30, startY, 150, 30];
            app.CommentExtractButton.Text = 'Manually Extract GO-END 2';
            app.CommentExtractButton.FontSize = 12;
            app.CommentExtractButton.Enable = false;
            app.CommentExtractButton.ButtonPushedFcn = @(~,~) commentExtractButtonPushed(app);
            
            % Update extract button to also set up comment dropdowns
            app.ExtractButton.ButtonPushedFcn = @(~,~) extractAndSetupComments(app);
        end
        
        function extractAndSetupComments(app)
            % First run the original extract function
            extractButtonPushed(app);
            
            % Then set up the comment dropdowns
            setupCommentDropdowns(app);
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