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
    end

    methods
        function obj = CoContractionIndexCalculator(processedData, agonistMuscle, antagonistMuscle, taskType)
            obj.agonistEmg = processedData.chnl.Coord.(agonistMuscle).(taskType);
            obj.antagonistEmg = processedData.chnl.Coord.(antagonistMuscle).(taskType);
            obj.agonistScaleFactorsSet = processedData.ampScaleFactors.(agonistMuscle).(taskType);
            obj.antagonistScaleFactorsSet = processedData.ampScaleFactors.(antagonistMuscle).(taskType);
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

        function visualiseAgonistAndAntagonistEmg(obj)
            plot(obj.agonistEmg, 'r', 'DisplayName', 'Agonist EMG');
            hold on;
            plot(obj.antagonistEmg, 'b', 'DisplayName', 'Antagonist EMG');
            legend;
        end
    end
end

