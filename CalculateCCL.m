% This script calculates the Co-Contraction Index (CCI) for a set of given subjects for the Coordination task.
% Choice can be make using differnt normalisation methods.
% 
% Mingrui Sun
% 6 April 2025
% 

clear;

dataRootPath = './Data_Processed';
subjectIDs = {'TA01003', 'TA01004', 'TA01005', 'TA01007', 'TA01008', 'TA02004', 'TA02005', 'TA02006', 'TA02008', 'TA03004', 'TA04004', };
% subjectIDs = {'TA01003', 'TA01004', 'TA01005', 'TA01007', 'TA01008', 'TA02004', 'TA02005', 'TA02006', 'TA03004', 'TA04004', };

% subjectIDs = {'TA01003'};
dominantSides = {'R', 'L', 'R', 'L', 'R', 'R', 'R', 'R', 'R', 'R', 'L'};

% dominantSides = {'R', 'L', 'R', 'L', 'R', 'R', 'R', 'R', 'R', 'L'};
agonistMuscleName = 'Biceps';
antagonistMuscleName = 'Triceps';
sideSelection = 'Dominant';  % Dominant, Non-Dominant
taskTypeName = 'Fast';  % SS: Self-Selected, Fast: As fast as possible
sampleRate = 2000;

preferredScaleFactorName = 'MVC';  % 'Rest', 'MVC', 'CycleMean', 'CycleMax'
defaultScaleFactorName = 'CycleMean';  % 'CycleMean', 'CycleMax'

isPlot = true;

CCI_BSL = zeros(1, length(subjectIDs));
CCI_PIV = zeros(1, length(subjectIDs));
MVC_BSL_AGONIST = zeros(1, length(subjectIDs));
MVC_BSL_ANTAGONIST = zeros(1, length(subjectIDs));
MVC_PIV_AGONIST = zeros(1, length(subjectIDs));
MVC_PIV_ANTAGONIST = zeros(1, length(subjectIDs));

figure('Renderer', 'painters', 'Position', [300 300 1000 1000])
tiledlayout(length(subjectIDs), 2, 'Padding', 'none', 'TileSpacing', 'tight');
for subjectIdx = 1:length(subjectIDs)
    subjectID = subjectIDs{subjectIdx};
    dominantSide = dominantSides{subjectIdx};
    agonistMuscle = [dominantSide, '_', agonistMuscleName];
    antagonistMuscle = [dominantSide, '_', antagonistMuscleName];

    taskType = getTaskType(dominantSide, taskTypeName, sideSelection); 

    nexttile;
    assessType = 'BSL';  % BSL: Baseline, PIV: Post-Intervention
    [cci, mvcAgonist, mvcAntagonist] = calculateCoContractionIndexPipeline(subjectID, assessType, dataRootPath, dominantSide, agonistMuscle, antagonistMuscle, taskType, preferredScaleFactorName, defaultScaleFactorName, isPlot, sampleRate);
    CCI_BSL(subjectIdx) = cci;
    MVC_BSL_AGONIST(subjectIdx) = mvcAgonist;
    MVC_BSL_ANTAGONIST(subjectIdx) = mvcAntagonist;

    nexttile;
    assessType = 'PIV';  % BSL: Baseline, PIV: Post-Intervention
    [cci, mvcAgonist, mvcAntagonist] = calculateCoContractionIndexPipeline(subjectID, assessType, dataRootPath, dominantSide, agonistMuscle, antagonistMuscle, taskType, preferredScaleFactorName, defaultScaleFactorName, isPlot, sampleRate);
    CCI_PIV(subjectIdx) = cci;
    MVC_PIV_AGONIST(subjectIdx) = mvcAgonist;
    MVC_PIV_ANTAGONIST(subjectIdx) = mvcAntagonist;
end
legend;

disp("CCI BSL: " + CCI_BSL)
disp("CCI PIV: " + CCI_PIV)

% Paired t-test
[h, p, ci, stats] = ttest(CCI_BSL, CCI_PIV);

% Mean and IQR of baseline (before)
mean_baseline = mean(CCI_BSL, 'omitnan');
iqr_baseline = iqr(CCI_BSL);

% Mean and IQR of post-intervention (after)
mean_post = mean(CCI_PIV, 'omitnan');
iqr_post = iqr(CCI_PIV);

% Display results
fprintf('Paired t-test:\n');
fprintf('t(%d) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);
fprintf('95%% CI: [%.3f, %.3f]\n\n', ci(1), ci(2));

fprintf('Baseline Mean: %.3f\n', mean_baseline);
fprintf('Baseline IQR: %.3f\n', iqr_baseline);

fprintf('Post-intervention Mean: %.3f\n', mean_post);
fprintf('Post-intervention IQR: %.3f\n', iqr_post);

disp("MVC_BSL_AGONIST: " + MVC_BSL_AGONIST)
disp("MVC_PIV_AGONIST: " + MVC_PIV_AGONIST)
disp("MVC_BSL_ANTAGONIST: " + MVC_BSL_ANTAGONIST)
disp("MVC_PIV_ANTAGONIST: " + MVC_PIV_ANTAGONIST)

% After the main loop ends
% plotMvcComparison(MVC_BSL_AGONIST, MVC_PIV_AGONIST, MVC_BSL_ANTAGONIST, MVC_PIV_ANTAGONIST, subjectIDs);

%% Fcuntions
function [coContractionIndex, mvcAgonist, mvcAntagonist] = calculateCoContractionIndexPipeline(subjectID, assessType, dataRootPath, dominantSide, agonistMuscle, antagonistMuscle, taskType, preferredScaleFactorName, defaultScaleFactorName, isPlot, sampleRate)
    coordData = loadDataFromFile(subjectID, assessType, dataRootPath);

    if isempty(coordData)
        disp(['No Coordination data found for subject ID: ', subjectID, ' Dominant Side: ', dominantSide]);
        return;
    end


    cciCalculator = CoContractionIndexCalculator(coordData.CoordProcessed, agonistMuscle, antagonistMuscle, taskType, sampleRate);
    cciCalculator = cciCalculator.scaleEmg(preferredScaleFactorName, defaultScaleFactorName);
    cciCalculator = cciCalculator.removeSpikes();
    cciCalculator = cciCalculator.cut15seconds();
    coContractionIndex = cciCalculator.calculateCoContractionIndex();
    [mvcAgonist, mvcAntagonist] = cciCalculator.exportMVC();
        % coContractionIndex = nan;
        % 

    if isPlot
        cciCalculator.visualiseAgonistAndAntagonistEmg();
        xlabel('Time (s)');
        ylabel('$EMG_{normalised}$','interpreter','latex');
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

function [taskType] = getTaskType(dominantSide, taskTypeName, sideSelection)
    if strcmp(dominantSide, 'L')
        if sideSelection == "Dominant"
            taskType = ['Left_', taskTypeName];
        elseif sideSelection == "Non-Dominant"
            taskType = ['Right_', taskTypeName];
        else
            error('Invalid side selection');
        end
    elseif strcmp(dominantSide, 'R')
        if sideSelection == "Dominant"
            taskType = ['Right_', taskTypeName];
        elseif sideSelection == "Non-Dominant"
            taskType = ['Left_', taskTypeName];
        else
            error('Invalid side selection');
        end
    else
        error('Invalid dominant side');
    end
end

function plotMvcComparison(MVC_BSL_AGONIST, MVC_PIV_AGONIST, MVC_BSL_ANTAGONIST, MVC_PIV_ANTAGONIST, subjectIDs)
    % Create a figure with 1x2 subplot layout
    figure('Position', [100 100 1200 500]);
    
    % Number of subjects
    numSubjects = length(subjectIDs);
    
    % Create x-axis positions for the bars
    x = 1:numSubjects;
    width = 0.35; % Width of bars
    
    % Left subplot for Agonist muscle
    subplot(1, 2, 1);
    b1 = bar(x - width/2, MVC_BSL_AGONIST, width, 'FaceColor', [0.2 0.6 0.8]);
    hold on;
    b2 = bar(x + width/2, MVC_PIV_AGONIST, width, 'FaceColor', [0.8 0.4 0.2]);
    
    % Customize the agonist plot
    title('Agonist Muscle MVC');
    xlabel('Subject ID');
    ylabel('MVC Value');
    set(gca, 'XTick', 1:numSubjects);
    set(gca, 'XTickLabel', subjectIDs);
    xtickangle(45);
    legend('Baseline', 'Post-Intervention');
    grid on;
    
    % Right subplot for Antagonist muscle
    subplot(1, 2, 2);
    b3 = bar(x - width/2, MVC_BSL_ANTAGONIST, width, 'FaceColor', [0.2 0.6 0.8]);
    hold on;
    b4 = bar(x + width/2, MVC_PIV_ANTAGONIST, width, 'FaceColor', [0.8 0.4 0.2]);
    
    % Customize the antagonist plot
    title('Antagonist Muscle MVC');
    xlabel('Subject ID');
    ylabel('MVC Value');
    set(gca, 'XTick', 1:numSubjects);
    set(gca, 'XTickLabel', subjectIDs);
    xtickangle(45);
    legend('Baseline', 'Post-Intervention');
    grid on;
    
    % Add a main title
    sgtitle('MVC Comparison: Baseline vs Post-Intervention');
end