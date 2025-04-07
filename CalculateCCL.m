% This script calculates the Co-Contraction Index (CCI) for a set of given subjects for the Coordination task.
% Choice can be make using differnt normalisation methods.
% 
% Mingrui Sun
% 6 April 2025
% 

clear;

dataRootPath = './Data_Processed';
subjectIDs = {'TA01003', 'TA01004', 'TA01005', 'TA01007', 'TA01008', 'TA02004', 'TA02005', 'TA02006', 'TA02008', 'TA03004', 'TA04004', };
% subjectIDs = {'TA01003'};
dominantSides = {'R', 'L', 'R', 'L', 'R', 'R', 'R', 'R', 'R', 'R', 'L'};
agonistMuscleName = 'Biceps';
antagonistMuscleName = 'Triceps';
taskTypeName = 'SS';  % SS: Self-Selected, Fast: As fast as possible

preferredScaleFactorName = 'CycleMean';  % 'Rest', 'MVC', 'CycleMean', 'CycleMax'
defaultScaleFactorName = 'CycleMean';  % 'CycleMean', 'CycleMax'

isPlot = true;

figure('Renderer', 'painters', 'Position', [300 300 1000 800])
tiledlayout(length(subjectIDs), 2, 'Padding', 'none', 'TileSpacing', 'tight');
for subjectIdx = 1:length(subjectIDs)
    subjectID = subjectIDs{subjectIdx};
    dominantSide = dominantSides{subjectIdx};
    agonistMuscle = [dominantSide, '_', agonistMuscleName];
    antagonistMuscle = [dominantSide, '_', antagonistMuscleName];

    taskType = getTaskType(dominantSide, taskTypeName); 

    nexttile;
    assessType = 'BSL';  % BSL: Baseline, PIV: Post-Intervention
    calculateCoContractionIndexPipeline(subjectID, assessType, dataRootPath, dominantSide, agonistMuscle, antagonistMuscle, taskType, preferredScaleFactorName, defaultScaleFactorName, isPlot);

    nexttile;
    assessType = 'PIV';  % BSL: Baseline, PIV: Post-Intervention
    calculateCoContractionIndexPipeline(subjectID, assessType, dataRootPath, dominantSide, agonistMuscle, antagonistMuscle, taskType, preferredScaleFactorName, defaultScaleFactorName, isPlot);
end



%% Fcuntions
function [coContractionIndex] = calculateCoContractionIndexPipeline(subjectID, assessType, dataRootPath, dominantSide, agonistMuscle, antagonistMuscle, taskType, preferredScaleFactorName, defaultScaleFactorName, isPlot)
    coordData = loadDataFromFile(subjectID, assessType, dataRootPath);

    if isempty(coordData)
        disp(['No Coordination data found for subject ID: ', subjectID, ' Dominant Side: ', dominantSide]);
        return;
    end

    cciCalculator = CoContractionIndexCalculator(coordData.CoordProcessed, agonistMuscle, antagonistMuscle, taskType);
    cciCalculator = cciCalculator.scaleEmg(preferredScaleFactorName, defaultScaleFactorName);
    coContractionIndex = cciCalculator.calculateCoContractionIndex();
    if isPlot
        cciCalculator.visualiseAgonistAndAntagonistEmg();
        xlabel('Frame');
        ylabel('Normalised EMG');
        title([subjectID, ' DomSide: ', dominantSide, ', ', assessType, ' CCI: ', num2str(coContractionIndex)]);
    end
end

function [coordData] = loadDataFromFile(subjectID, assessType, dataRootPath)
    % Load Coordination data
    coordPath = fullfile(dataRootPath, subjectID, assessType);
    coordFile = dir(fullfile(coordPath, '*.mat'));
    
    % Check if any files exist
    if isempty(coordFile)
        disp(['No .mat files found in: ', coordPath]);
        coordData = [];
        return;
    end
    
    % Check for multiple files
    if length(coordFile) > 1
        error(['Multiple .mat files found for subject: ', subjectID, ' in: ', coordPath]);
    end
    
    % Load the single file found
    coordData = load(fullfile(coordPath, coordFile.name));
end

function [taskType] = getTaskType(dominantSide, taskTypeName)
    if strcmp(dominantSide, 'L')
        taskType = ['Left_', taskTypeName];
    elseif strcmp(dominantSide, 'R')
        taskType = ['Right_', taskTypeName];
    else
        error('Invalid dominant side');
    end
end