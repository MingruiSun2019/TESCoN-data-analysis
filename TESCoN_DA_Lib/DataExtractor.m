% The data file is too big for normal computer,
% I'm downsampling it for visualisation and after noting down all parameters
% I will save the original data to a new file.

classdef DataExtractor
    % assessType: Baseline (BSL) or post-intervention (PIV)
    % testType: Rest, ISNCSCI, Coordination (Coord)
    properties
        subID
        sampleRate
        rawData
        params
        chnlData
        metaData
        dsFactor
        graphDsFactor
        triggerThres
    end

    methods
        function obj = DataExtractor(subID, assessType, testType, sampleRate)
            obj.subID = subID;
            obj.sampleRate = sampleRate;  % Hz
            obj.metaData.assessType = assessType; % BSL or PIV
            obj.metaData.taskType = testType; % Rest, ISNCSCI, Coordination (Coord)
            obj.dsFactor = 1;
            obj.graphDsFactor = 100;
            obj.triggerThres = 5;
            
            % Add y-axis limits parameters
            obj.params.ylim.emg = [-1, 1];
            obj.params.ylim.trigger = [-1, 12];
        end

        function obj = loadExtractChannelPipline(obj, side)
            if obj.metaData.taskType == "Coordination"
                fileTaskType = "Coord";  % I want to display the text as Coordination but the naming convention is Coord from the project.
            else
                fileTaskType = obj.metaData.taskType;
            end

            if nargin < 2
                % No side parameter provided, do something
                filename = sprintf("./Data_Source/%s/%s/%s/%s_EMG_%s_%s.mat", obj.subID, obj.metaData.taskType, obj.metaData.assessType, obj.subID, obj.metaData.assessType, fileTaskType);
                obj = obj.loadTest(filename);
                obj = obj.extractChannelNames();
            else
                % Side parameter provided, do something else
                % You can implement your logic here based on the side parameter
                filename = sprintf("./Data_Source/%s/%s/%s/%s_EMG_%s_%s_%s.mat", obj.subID, obj.metaData.taskType, obj.metaData.assessType, obj.subID, obj.metaData.assessType, fileTaskType, upper(side));
                obj = obj.loadTest(filename);
                obj = obj.extractChannelNames();
            end
        end

        function obj = loadTest(obj, filename)
            myVars = {"com","comtext","data","datastart","dataend", "titles"};
            load(filename,myVars{:})
            obj.rawData.(obj.metaData.taskType).com = com;
            obj.rawData.(obj.metaData.taskType).comtext = comtext;
            obj.rawData.(obj.metaData.taskType).data = data;
            obj.rawData.(obj.metaData.taskType).datastart = datastart;
            obj.rawData.(obj.metaData.taskType).dataend = dataend;
            obj.rawData.(obj.metaData.taskType).titles = titles;
            obj.params.(obj.metaData.taskType).numChannel = size(titles, 1);     
        end

        function obj = extractChannelNames(obj)
            channelNames = strings(1, obj.params.(obj.metaData.taskType).numChannel);
            for channelIdx = 1:obj.params.(obj.metaData.taskType).numChannel
                rawChannelName = obj.rawData.(obj.metaData.taskType).titles(channelIdx, :);
                channelNames(channelIdx) = processChannelName(rawChannelName);                
            end
            obj.metaData.(obj.metaData.taskType).channelNames = channelNames;
        end

        function obj = extractChannelsSingleRecording(obj)
            % Ensure data is available for extraction
            assert(size(obj.rawData.(obj.metaData.taskType).datastart, 2) == 1, "Error: multiple recordings found.");
        
            % Extract and store downsampled data
            for channelIdx = 1:obj.params.(obj.metaData.taskType).numChannel
                channelName = obj.metaData.(obj.metaData.taskType).channelNames(channelIdx);
        
                % Get full-resolution index range
                startIdx = obj.rawData.(obj.metaData.taskType).datastart(channelIdx);
                endIdx = obj.rawData.(obj.metaData.taskType).dataend(channelIdx);
        
                % Extract original high-frequency data
                if startIdx > 0 && endIdx > 0
                    fullResData = obj.rawData.(obj.metaData.taskType).data(startIdx:endIdx);
                    % Downsample: Keep every dsFactor-th sample
                    obj.chnlData.(obj.metaData.taskType).(channelName) = fullResData(1:obj.dsFactor:end);
                else
                    obj.chnlData.(obj.metaData.taskType).(channelName) = [];
                end
            end
        end


        function obj = extractChannelsMultiRecording(obj)
            % Get number of recordings
            numRecording = size(obj.rawData.(obj.metaData.taskType).datastart, 2);
            % assert(numRecording == length(recordingNames), "Error: Number of recordings does not match the number of recording names");

            % Recording1, Recording2, ...
            recordingNames = strings(1, numRecording);
            for i = 1:numRecording
                recordingNames(i) = sprintf('Recording%d', i);
            end
            obj.metaData.(obj.metaData.taskType).recordingNames = recordingNames;
        
            % Ensure channel names are extracted
            obj = obj.extractChannelNames();
            
            % Loop through each channel
            for channelIdx = 1:obj.params.(obj.metaData.taskType).numChannel
                channelName = obj.metaData.(obj.metaData.taskType).channelNames(channelIdx);
                
                % Initialize struct for recordings
                obj.chnlData.(obj.metaData.taskType).(channelName) = struct();
        
                % Process each recording
                for recordIdx = 1:numRecording
                    startIdx = obj.rawData.(obj.metaData.taskType).datastart(channelIdx, recordIdx);
                    endIdx = obj.rawData.(obj.metaData.taskType).dataend(channelIdx, recordIdx);
        
                    % Extract full-resolution data
                    if startIdx > 0 && endIdx > 0
                        chData = obj.rawData.(obj.metaData.taskType).data(startIdx:endIdx);
                    else
                        chData = [];
                    end
        
                    % Downsample before storing
                    chDataDS = chData(1:obj.dsFactor:end);
        
                    % Store downsampled data with recording name
                    obj.chnlData.(obj.metaData.taskType).(channelName).(recordingNames(recordIdx)) = chDataDS;
                end
            end
        end


        function graphAllChannelsSingleRecording(obj)
            % Create figure
            figure("Position", [200, 200, 1400, 800])
        
            % Number of channels for this testType
            numChannels = obj.params.(obj.metaData.taskType).numChannel;
            commentTimestamps = calculateCommentTimestamps(obj, obj.metaData.taskType);
            intervals = obj.getTriggerActiveIntervals(obj.metaData.taskType);
            tiledlayout(numChannels,1, 'Padding', 'none', 'TileSpacing', 'tight'); 
        
            for channelIdx = 1:numChannels
                nexttile(channelIdx);
        
                % Extract channel name
                channelName = obj.metaData.(obj.metaData.taskType).channelNames(channelIdx);
        
                % Get channel data and time
                chData = obj.chnlData.(obj.metaData.taskType).(channelName);
                chData = chData(1:obj.graphDsFactor:end);
                t = (1:length(chData)) / (obj.sampleRate / obj.graphDsFactor);
        
                % Plot downsampled data
                cla(gca, 'reset');  % Clears current axes and resets properties
                plot(t, chData, 'b');
                drawnow limitrate;

                % Set y-axis limits based on channel type
                obj.setChannelYLim(channelName);

                % Plot trigger-based color bands
                obj.plotTriggerBands(intervals);
        
                % Overlay comment lines and text
                obj.plotCommentLines(commentTimestamps.Recording1);
                if channelIdx == numChannels
                    obj.plotCommentText(obj.metaData.taskType, commentTimestamps.Recording1);
                end
        
                % For the very last subplot, add an x-label
                if channelIdx == numChannels
                    xlabel("Time (second)");
                end
                ylabel("mV");
            end

        end

        function graphAllChannelsMultiRecording(obj)
            % Create figure
            figure("Position", [200, 200, 1400, 800])

            % Number of channels for this testType
            numChannels = obj.params.(obj.metaData.taskType).numChannel;
            recordingNames = obj.metaData.(obj.metaData.taskType).recordingNames;
            commentTimestamps = calculateCommentTimestamps(obj, obj.metaData.taskType);
            tiledlayout(numChannels,1, 'Padding', 'none', 'TileSpacing', 'tight'); 

            % Calculate total time length for x-axis scaling
            totalLength = 0;
            timeOffsets = zeros(1, length(recordingNames));
            for recordIdx = 1:length(recordingNames)
                % Get length of first channel as reference
                channelName = obj.metaData.(obj.metaData.taskType).channelNames(1);
                recordData = obj.chnlData.(obj.metaData.taskType).(channelName).(recordingNames(recordIdx));
                recordData = recordData(1:obj.graphDsFactor:end);
                timeOffsets(recordIdx) = totalLength;
                totalLength = totalLength + length(recordData) / (obj.sampleRate / obj.graphDsFactor);
            end

            for channelIdx = 1:numChannels
                nexttile(channelIdx);
                channelName = obj.metaData.(obj.metaData.taskType).channelNames(channelIdx);

                % Plot each recording segment
                for recordIdx = 1:length(recordingNames)
                    % Get channel data and time for this recording
                    chData = obj.chnlData.(obj.metaData.taskType).(channelName).(recordingNames(recordIdx));
                    chData = chData(1:obj.graphDsFactor:end);
                    tLocal = (1:length(chData)) / (obj.sampleRate / obj.graphDsFactor);
                    t = tLocal + timeOffsets(recordIdx);

                    % Plot data
                    if recordIdx == 1
                        cla(gca, 'reset');
                    end
                    plot(t, chData, 'b');
                    hold on;
                    drawnow limitrate;

                    % Add vertical line to separate recordings (except after last recording)
                    if recordIdx < length(recordingNames)
                        xline(timeOffsets(recordIdx + 1), 'g-', 'LineWidth', 1.5);
                    end

                    obj.plotGoEndBands(t, obj.metaData.taskType, recordIdx)
                    
                    % Plot comments for this recording
                    if isfield(commentTimestamps, sprintf('Recording%d', recordIdx))
                        recordingComments = commentTimestamps.(sprintf('Recording%d', recordIdx));
                        commentTimestampsThisRecording = recordingComments + timeOffsets(recordIdx);
                        obj.plotCommentLines(commentTimestampsThisRecording);
                        disp(sprintf('Recording %d', recordIdx));

                        
                        if channelIdx == numChannels
                            obj.plotCommentText(obj.metaData.taskType, commentTimestampsThisRecording, recordIdx);
                            disp(sprintf('Recording in the last channel %d', recordIdx));
                        end
                    end
                end

                % Set y-axis limits based on channel type
                obj.setChannelYLim(channelName);

                % Labels
                if channelIdx == numChannels
                    xlabel("Time (second)");
                end
                ylabel("mV");
                hold off;
            end
        end

        function setChannelYLim(obj, channelName)
            if strcmpi(channelName, 'Trigger')
                ylim(obj.params.ylim.trigger);
            else
                ylim(obj.params.ylim.emg);
            end
        end

        function obj = mergeRecordings(obj, testType)
            % Get all channel names
            channelNames = obj.metaData.(testType).channelNames;
            
            % Process each channel
            for channelIdx = 1:obj.params.(testType).numChannel
                channelName = channelNames(channelIdx);
                
                % Skip if the channel doesn't have multiple recordings
                if ~isstruct(obj.chnlData.(testType).(channelName))
                    continue;
                end
                
                % Get all recording names for this channel
                recordingNames = fieldnames(obj.chnlData.(testType).(channelName));
                
                % Initialize merged data array
                mergedData = [];
                
                % Concatenate all recordings
                for i = 1:length(recordingNames)
                    recData = obj.chnlData.(testType).(channelName).(recordingNames{i});
                    mergedData = [mergedData; recData(:)];
                end
                
                % Replace the struct with merged data
                obj.chnlData.(testType).(channelName) = mergedData;
            end
        end

        function [goFrameIdx, endFrameIdx] = extractGoEndData(obj, testType, recordIdx)
            recIndices = obj.rawData.(testType).com(:,2) == recordIdx;
                
            % Get comment indices for this recording
            comTextIndices = obj.rawData.(testType).com(recIndices, 5);
            commentTexts = obj.rawData.(testType).comtext(comTextIndices, :);
            
            % Find "GO" and "END" indices
            goIdx = find(contains(string(commentTexts), 'GO'), 1);
            endIdx = find(contains(string(commentTexts), 'END'), 1);

            frameIndices = obj.rawData.(testType).com(recIndices, 3);
            goFrameIdx = frameIndices(goIdx);
            endFrameIdx = frameIndices(endIdx);
            
            goFrameIdx = round(goFrameIdx / obj.dsFactor);
            endFrameIdx = round(endFrameIdx / obj.dsFactor);
        end
    end

    methods (Access = private)
        function intervals = getTriggerActiveIntervals(obj, testType)
            % Ensure "Trigger" channel exists
            if ~isfield(obj.chnlData.(testType), 'Trigger')
                warning("Trigger channel not found.");
                intervals = [];
                return;
            end
        
            % Extract trigger data
            triggerData = obj.chnlData.(testType).Trigger;
        
            % Find indices where trigger > 5
            triggerAboveThreshold = triggerData > 5;
        
            % Find change points (start and end of each high period)
            diffSignal = diff([0, triggerAboveThreshold, 0]); % Add padding to detect edges
            startIdx = find(diffSignal == 1);  % Rising edges
            endIdx   = find(diffSignal == -1) - 1; % Falling edges
        
            % Convert indices to time (seconds)
            intervals = [startIdx; endIdx] / (obj.sampleRate / obj.dsFactor);
        end

        function plotTriggerBands(obj, intervals)
            % Check if intervals exist
            if isempty(intervals)
                return;
            end
        
            % Define color (light gray with transparency)
            bandColor = [0.8, 0.8, 0.8]; 
            alphaValue = 0.3;  % Transparency level
            yLimits = ylim();
        
            hold on;
            for i = 1:size(intervals, 2)
                x = [intervals(1, i), intervals(2, i), intervals(2, i), intervals(1, i)];
                y = [yLimits(1), yLimits(1), yLimits(2), yLimits(2)];
                fill(x, y, bandColor, 'EdgeColor', 'none', 'FaceAlpha', alphaValue);
            end
            hold off;
        end



        function timestamps = calculateCommentTimestamps(obj, testType)
            % Check if 'com' and 'comtext' exist and are non-empty
            if ~isfield(obj.rawData.(testType), 'com') || isempty(obj.rawData.(testType).com)
                timestamps = struct();
                return;
            end
            
            % Initialize empty struct to store timestamps for each recording
            timestamps = struct();
            
            % Get all unique recording numbers from column 2 of com matrix
            recordingNums = unique(obj.rawData.(testType).com(:,2));
            
            % For each recording number
            for recNum = recordingNums'
                % Get indices for this recording
                recIndices = obj.rawData.(testType).com(:,2) == recNum;
                
                % Extract frame indices for this recording (column 3)
                frameIndices = obj.rawData.(testType).com(recIndices,3);
                
                % Convert to timestamps
                recTimestamps = frameIndices / obj.sampleRate;
                
                % Remove invalid timestamps
                recTimestamps = recTimestamps(recTimestamps > 0);
                
                % Store in struct with recording number as field name
                fieldName = sprintf('Recording%d', recNum);
                timestamps.(fieldName) = recTimestamps;
            end
        end

        function plotCommentLines(obj, timestamps)
            % Ensure timestamps exist
            if isempty(timestamps)
                return;
            end
        
            % Draw vertical red dashed lines
            yLimits = ylim();
            for i = 1:length(timestamps)
                hold on
                plot([timestamps, timestamps], [yLimits(1), yLimits(2)], '-r', 'LineWidth', 1.0);
            end
        end

        

        function plotCommentText(obj, testType, timestamps, recordIdx)
            % Check if 'comtext' field exists and is non-empty
            if ~isfield(obj.rawData.(testType), 'comtext') || isempty(obj.rawData.(testType).comtext)
                return;
            end
        
            % Get Y-axis limits for text positioning
            yLimits = ylim();
            yTop = yLimits(2);
        
            % Extract comment text
            commentTexts = obj.rawData.(testType).comtext;
            
            % Handle single recording case
            if nargin < 4
                % Get comments for this recording
                recordingComments = timestamps;
                % Ensure we only use as many comments as we have timestamps
                numComments = min(length(recordingComments), size(commentTexts, 1));
                
                for i = 1:numComments
                    
                    text(recordingComments(i), 0.9 * yTop, strtrim(commentTexts(i, :)), ...
                        'Rotation', 90, ...
                        'VerticalAlignment', 'top', ...
                        'HorizontalAlignment', 'left', ...
                        'FontSize', 8, ...
                        'Interpreter', 'none');
                end
            else
                % Multiple recordings case

                recordingComments = timestamps;
                numComments = length(recordingComments);

                % extract the rows where the 2nd column of com is equal to recordIdx
                comIndicesThisRecording = obj.rawData.(testType).com(:,2) == recordIdx;
                comTextIndicesThisRecording = obj.rawData.(testType).com(comIndicesThisRecording, 5);

                for i = 1:numComments
                    text(recordingComments(i), 0.9 * yTop, strtrim(commentTexts(comTextIndicesThisRecording(i), :)), ...
                        'Rotation', 90, ...
                        'VerticalAlignment', 'top', ...
                        'HorizontalAlignment', 'left', ...
                        'FontSize', 8, ...
                        'Interpreter', 'none');
                end
            end
        end

        function plotGoEndBands(obj, timestamps, testType, recordIdx)
            
            % Find "GO" and "END" indices
            [goFrameIdx, endFrameIdx] = obj.extractGoEndData(testType, recordIdx);
            
            if ~isempty(goFrameIdx) && ~isempty(endFrameIdx)
                % Get timestamps for GO and END
                goTime = timestamps(goFrameIdx);
                endTime = timestamps(endFrameIdx);
                
                % Plot grey band
                yLimits = obj.params.ylim.emg;
                hold on;
                x = [goTime, endTime, endTime, goTime];
                y = [yLimits(1), yLimits(1), yLimits(2), yLimits(2)];
                fill(x, y, [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
                hold off;
            end
        end

        

    end

end

% Reference
% 1. ABC of EMG: https://www.velamed.com/wp-content/uploads/ABC-of-EMG.pdf











