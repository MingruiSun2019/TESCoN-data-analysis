% This script calculates the co-contraction index (CCI) of a given agonist and antagonist muscle.
% Ensure the files are placed in the directory
% - Data_Processed
% -- TAxxxxx
% --- BSL
% ---- TA01003_Coordination_BSL_processed.mat
% --- PIV
% ---- TA01003_Coordination_PIV_processed.mat
% -- TAxxxxx
% --- ...



classdef CoContractionIndexCalculator
    properties
        agonistEmg
        antagonistEmg
        agonistScaleFactorsSet
        antagonistScaleFactorsSet
        agonistMuscleName
        antagonistMuscleName
        sampleRate
    end

    methods
        function obj = CoContractionIndexCalculator(processedData, agonistMuscle, antagonistMuscle, taskType, sampleRate)
            obj.agonistEmg = processedData.chnl.Coord.(agonistMuscle).(taskType);
            obj.antagonistEmg = processedData.chnl.Coord.(antagonistMuscle).(taskType);
            obj.agonistScaleFactorsSet = processedData.ampScaleFactors.(agonistMuscle).(taskType);
            obj.antagonistScaleFactorsSet = processedData.ampScaleFactors.(antagonistMuscle).(taskType);
            obj.agonistMuscleName = agonistMuscle;
            obj.antagonistMuscleName = antagonistMuscle;
            obj.sampleRate = sampleRate;
        end

        function obj = cut15seconds(obj)
            obj.agonistEmg = obj.agonistEmg(1, 1:15*obj.sampleRate);
            obj.antagonistEmg = obj.antagonistEmg(1, 1:15*obj.sampleRate);
        end

        function obj = scaleEmg(obj, preferredScaleFactorName, defaultScaleFactorName)
            if isfield(obj.agonistScaleFactorsSet, preferredScaleFactorName)
                obj.agonistEmg = obj.agonistEmg / obj.agonistScaleFactorsSet.(preferredScaleFactorName);
            else
                disp('Preferred scale factor not found, using default scale factor');
                obj.agonistEmg = obj.agonistEmg / obj.agonistScaleFactorsSet.(defaultScaleFactorName);
            end

            if isfield(obj.antagonistScaleFactorsSet, preferredScaleFactorName)
                obj.antagonistEmg = obj.antagonistEmg / obj.antagonistScaleFactorsSet.(preferredScaleFactorName);
            else
                disp('Preferred scale factor not found, using default scale factor');
                obj.antagonistEmg = obj.antagonistEmg / obj.antagonistScaleFactorsSet.(defaultScaleFactorName);
            end
        end

        function coContractionIndex = calculateCoContractionIndex(obj)
            assert(length(obj.agonistEmg) == length(obj.antagonistEmg), 'The length of agonist and antagonist EMG must be the same');
            overlapTrajectory = min(obj.agonistEmg, obj.antagonistEmg);
            overlapArea = sum(overlapTrajectory);
            agonistArea = sum(obj.agonistEmg);
            antagonistArea = sum(obj.antagonistEmg);
            coContractionIndex = overlapArea / (agonistArea + antagonistArea);
        end

        function [mvcAgonist, mvcAntagonist] = exportMVC(obj)
            if isfield(obj.agonistScaleFactorsSet, 'MVC')
                mvcAgonist = obj.agonistScaleFactorsSet.MVC;
            else
                mvcAgonist = nan;
            end
            if isfield(obj.antagonistScaleFactorsSet, 'MVC')
                mvcAntagonist = obj.antagonistScaleFactorsSet.MVC;
            else
                mvcAntagonist = nan;
            end
        end

        function visualiseAgonistAndAntagonistEmg(obj)
            time = (0:length(obj.agonistEmg)-1) / obj.sampleRate;
            plot(time, obj.agonistEmg, 'r', 'DisplayName', 'Agonist EMG');
            hold on;
            plot(time, obj.antagonistEmg, 'b', 'DisplayName', 'Antagonist EMG');
            grid on;
        end

        function obj = removeSpikes(obj)
            % Remove spikes from agonist EMG
            % agonistStd = std(obj.agonistEmg);
            % agonistMean = mean(obj.agonistEmg);
            % spikeIndices = abs(obj.agonistEmg - agonistMean) > 10 * agonistStd;
            
            % Fill spikes with nearest neighbor interpolation
            % obj.agonistEmg = filloutliers(obj.agonistEmg,"previous","movmean",500);
            obj.agonistEmg = filloutliers(obj.agonistEmg,"previous","percentiles",[0, 98]);
            
            % % Remove spikes from antagonist EMG
            % antagonistStd = std(obj.antagonistEmg);
            % antagonistMean = mean(obj.antagonistEmg);
            % spikeIndices = abs(obj.antagonistEmg - antagonistMean) > 10 * antagonistStd;
            
            % Fill spikes with nearest neighbor interpolation
            % obj.antagonistEmg = filloutliers(obj.antagonistEmg,"previous","movmean",500);
            obj.antagonistEmg = filloutliers(obj.antagonistEmg,"previous","percentiles",[0, 98]);
        end
    end
end

