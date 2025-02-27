classdef DataProcessor

    properties
        ampScaleFactor
        sampleRate
        params
        clean
        chnl
        metaData
    end

    methods
        function obj = DataProcessor(data)
            obj.subID = subID;
            obj.sampleRate = 2000;  % Hz
            obj.clean.rmsWindowLen = 0.1; %ms
        end

        function obj = getInitDelayLen(obj)
            % can be manually done, and with inspection
            obj.params.initDelayLen = 2 * obj.sampleRate;
        end

        function obj = baselineCorrection(obj)
            for channelIdx = 1:obj.params.numChannel
                channelName = obj.metaData.channelNames(channelIdx);
                cropped = obj.chnl.(channelName)(obj.params.initDelayLen:end); % cut the initialisation segment
                corrected = cropped - mean(cropped);
                obj.chnl.(channelName) = corrected;
            end
        end

        function obj = getLinearEnvelope(obj)
            for channelIdx = 1:obj.params.numChannel
                channelName = obj.metaData.channelNames(channelIdx);
                emgSignal = obj.chnl.(channelName); % cut the initialisation segment
                rectified = rectification(emgSignal);
                rmsSmoothed = rmsSmoothing(rectified, obj.clean.rmsWindowLen, obj.sampleRate);
                obj.chnl.(channelName) = rmsSmoothed;
            end
        end

        function obj = baselineCorr(obj)
            obj = obj.getInitDelayLen();
            obj = obj.baselineCorrection();
        end

        function getMaxFromTraj(obj)
            
        end

        function getMaxFromISNCSCI(obj)
            % 
        end

        function getScaleFactor(obj, option)
            % MVC: with patient, one cannot expect a valid MVC trial at all (p34, [1])
            % cycle_mean, cycle_max: some researchers recommend them for
            %                           ensemble average EMG,but will loose
            %                           innvervation ratio under
            %                           inter-trial comparision
            % rest: 
            if option == "MVC"
                % Caution: with patient, one cannot expect a valid MVC trial at all (p34, [1])

            elseif option == "rest"

            elseif option == "cycle_mean"
                % separate cycles, then calculate mean of each cycle (p35, [1])

            elseif option == "cycle_max"


            else
                error("Please specify normalisation method: MVC, rest, cycle_mean, cycle_max");
            end
        end

    

        function getTimeNormedAve(obj)
            % Time normalised averaging
        end


    end
end
