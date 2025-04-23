% At this stage, the data has been extracted and cleaned by DataExtractor, and saved in Data_Extracted folder with the following structure:
% Data_Extracted
%   - subID (e.g. TA02010)
%       - ISNCSCI
%           - BSL
%               - extracted_[subID]_ISNCSCI_BSL.mat
%           - PIV
%               - extracted_[subID]_ISNCSCI_PIV.mat
%       - Coordination
%           - BSL
%               - extracted_[subID]_Coordination_BSL.mat
%           - PIV
%               - extracted_[subID]_Coord_PIV.mat
%           ...

% In each ISNCSCI mat file, the data is stored in the following structure:
% |-- ISNCSCIData
%       |-- L_Intraspinatus
%       |-- L_Deltoid
%       |-- ...
%       |-- R_Intraspinatus
%       |-- R_Deltoid
%       |-- ...
%       |-- Trigger
% Each field contains a 1 x n array, where n is the number of samples in the recording.
% If there is no available data for a field, the field will be an empty array in the mat file.

% In each Coordination mat file, the data is stored in the following structure:
% |-- CoordinationData
%       |-- L_Intraspinatus
%           |-- Right_SS
%           |-- Right_Fast
%           |-- Left_SS
%           |-- Left_Fast
%       |-- L_Deltoid
%           |-- ...
%       |-- ...
%       |-- R_Intraspinatus
%           |-- ...
%       |-- R_Deltoid
%           |-- ...
%       |-- Trigger
%           |-- ...
% Each field contains a 1 x n array, where n is the number of samples in the recording.
% If there is no available data for a field, the field will be an empty array in the mat file.


classdef DataProcessor

    properties
        subID
        ampScaleFactors
        sampleRate
        params
        clean
        chnl
        metaData
    end

    methods
        function obj = DataProcessor(subID, Rest_data, ISNCSCI_data, Coord_data)
            obj.subID = subID;
            obj.sampleRate = 2000;  % Hz
            obj.clean.rmsWindowLen = 0.1; %ms
            obj.chnl.Rest = Rest_data;
            obj.chnl.ISNCSCI = ISNCSCI_data;
            obj.chnl.Coord = Coord_data;
            obj = obj.getAvailableChannelNames(Rest_data, "Rest");
            obj = obj.getAvailableChannelNames(ISNCSCI_data, "ISNCSCI");
            obj = obj.getAvailableChannelNames(Coord_data, "Coord");
        end

        function obj = getAvailableChannelNames(obj, data, taskType)
            channelNames = fieldnames(data);
            obj.metaData.(taskType).channelNames = [];
            for i = 1:length(channelNames)
                channelName = channelNames{i};
                if isempty(obj.chnl.(taskType).(channelName)) == false
                    obj.metaData.(taskType).channelNames = [obj.metaData.(taskType).channelNames, string(channelName)];
                end
            end
            obj.params.numChannel.(taskType) = length(obj.metaData.(taskType).channelNames);
        end

        function obj = getInitDelayLen(obj)
            % can be manually done, and with inspection
            obj.params.initDelayLen = 2 * obj.sampleRate;  % remove the first 2 seconds of data
        end

        function obj = baselineCorrection(obj)
            % ISNCSCI
            for channelIdx = 1:obj.params.numChannel.ISNCSCI
                channelName = obj.metaData.ISNCSCI.channelNames(channelIdx);
                % cropped = obj.chnl.Coord.(channelName)(obj.params.initDelayLen:end); % cut the initialisation segment
                cropped = obj.chnl.ISNCSCI.(channelName); % cut the initialisation segment
                corrected = cropped - mean(cropped);
                obj.chnl.ISNCSCI.(channelName) = corrected;
            end
            
            % Coordination
            for channelIdx = 1:obj.params.numChannel.Coord
                channelName = obj.metaData.Coord.channelNames(channelIdx);
                recordingNames = fieldnames(obj.chnl.Coord.(cell2mat(channelName)));
                for recordingNameIdx = 1:length(recordingNames)
                    % cropped = obj.chnl.Coord.(channelName)(obj.params.initDelayLen:end); % cut the initialisation segment
                    recordingName = string(recordingNames{recordingNameIdx});
                    cropped = obj.chnl.Coord.(channelName).(recordingName);
                    corrected = cropped - mean(cropped);
                    obj.chnl.Coord.(channelName).(recordingName) = corrected;
                end
            end
        end

        function obj = getLinearEnvelope(obj)
            % Rest
            for channelIdx = 1:obj.params.numChannel.Rest
                channelName = obj.metaData.Rest.channelNames(channelIdx);
                restSignal = obj.chnl.Rest.(channelName);
                restRectified = rectification(restSignal);
                restRmsSmoothed = rmsSmoothing(restRectified, obj.clean.rmsWindowLen, obj.sampleRate);
                obj.chnl.Rest.(channelName) = restRmsSmoothed;
            end

            % ISNCSCI
            for channelIdx = 1:obj.params.numChannel.ISNCSCI
                channelName = obj.metaData.ISNCSCI.channelNames(channelIdx);
                ISNCSCISignal = obj.chnl.ISNCSCI.(channelName); % cut the initialisation segment
                ISNCSCIRectified = rectification(ISNCSCISignal);
                ISNCSCIRmsSmoothed = rmsSmoothing(ISNCSCIRectified, obj.clean.rmsWindowLen, obj.sampleRate);
                obj.chnl.ISNCSCI.(channelName) = ISNCSCIRmsSmoothed;
            end
            
            % Coordination
            for channelIdx = 1:obj.params.numChannel.Coord
                channelName = obj.metaData.Coord.channelNames(channelIdx);
                recordingNames = fieldnames(obj.chnl.Coord.(channelName));
                for recordingNameIdx = 1:length(recordingNames)
                    recordingName = string(recordingNames{recordingNameIdx});

                    % Coordination
                    CoordSignal = obj.chnl.Coord.(channelName).(recordingName); % cut the initialisation segment
                    CoordRectified = rectification(CoordSignal);
                    CoordRmsSmoothed = rmsSmoothing(CoordRectified, obj.clean.rmsWindowLen, obj.sampleRate);
                    obj.chnl.Coord.(channelName).(recordingName) = CoordRmsSmoothed;
                end
            end
        end

        function obj = getScaleFactorsAllChannels(obj)
            for channelIdx = 1:obj.params.numChannel.Coord
                channelName = obj.metaData.Coord.channelNames(channelIdx);
                recordingNames = fieldnames(obj.chnl.Coord.(channelName));
                for recordingNameIdx = 1:length(recordingNames)
                    recordingName = string(recordingNames{recordingNameIdx});
                    obj.ampScaleFactors.(channelName).(recordingName) = obj.getScaleFactors(channelName, recordingName);
                end
            end
        end


        function scaleFactors = getScaleFactors(obj, channelName, recordingName)
            % MVC: with patient, one cannot expect a valid MVC trial at all (p34, [1])
            % cycle_mean, cycle_max: some researchers recommend them for
            %                           ensemble average EMG,but will loose
            %                           innvervation ratio under
            %                           inter-trial comparision
            % 

            if isfield(obj.chnl.Coord, channelName) && isfield(obj.chnl.Coord.(channelName), recordingName)
                coordSignal = obj.chnl.Coord.(channelName).(recordingName);
            else
                coordSignal = [];
            end
            
            if isfield(obj.chnl.ISNCSCI, channelName)
                isncsciSignal = obj.chnl.ISNCSCI.(channelName);
            else
                isncsciSignal = [];
            end

            if isfield(obj.chnl.Rest, channelName)
                restSignal = obj.chnl.Rest.(channelName);
            else
                restSignal = [];
            end
            scaleFactors = struct();

            if ~isempty(coordSignal) 
                % MVC
                % |-- use a gliding window of 500ms to calculate the mean of the signal
                if ~isempty(isncsciSignal)
                    % windowLen = 500; % 250 ms
                    % stepSize = 100; % 50 ms
                    % numWindows = floor((length(isncsciSignal) - windowLen) / stepSize) + 1;
                    % filteredSignal = zeros(1, length(numWindows));
                    % for i = 1:numWindows
                    %     window = isncsciSignal(i:i+windowLen-1);
                    %     filteredSignal(i) = mean(window);
                    % end
                    % scaleFactors.MVC = max(filteredSignal);
                    filteredSignal = rmsSmoothing(isncsciSignal, obj.clean.rmsWindowLen, obj.sampleRate);
                    scaleFactors.MVC = max(filteredSignal);
                end
                
                % Rest
                if ~isempty(restSignal)
                    scaleFactors.Rest = mean(restSignal);
                end

                % Cycle mean
                scaleFactors.CycleMean = mean(coordSignal);

                % Cycle max
                scaleFactors.CycleMax = max(coordSignal);
            end
        end

    end
end
