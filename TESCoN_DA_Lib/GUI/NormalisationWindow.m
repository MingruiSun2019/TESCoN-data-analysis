classdef NormalisationWindow < BaseWindow
    properties (Access = private)
        TitleLabel matlab.ui.control.Label
        SubjectGrid cell    % Store subject labels and buttons in a grid
        GridPanel matlab.ui.container.Panel
        StatusLabel matlab.ui.control.Label
    end
    
    methods (Access = private)
        function backButtonPushed(app)
            app.clearWindow();
            MainWindow(app.UIFigure);
        end
        
        function createComponents(app)
            % Initialize base window
            initializeBaseWindow(app);
            app.UIFigure.Position = [100 100 1000 800];
            app.UIFigure.Name = 'EMG Data Normalisation';
            
            % Show back button
            showBackButton(app, @(~,~) backButtonPushed(app));
            
            % Create title
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 20;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [20 760 400 30];
            app.TitleLabel.Text = 'EMG Data Normalisation';
            
            % Create grid panel
            app.GridPanel = uipanel(app.UIFigure);
            app.GridPanel.Position = [20 100 950 660];  % Adjusted position to accommodate back button
            app.GridPanel.BackgroundColor = [1 1 1];
            
            % Initialize and populate the grid
            initializeGrid(app);
            
            % Create status label
            app.StatusLabel = uilabel(app.UIFigure);
            app.StatusLabel.FontSize = 12;
            app.StatusLabel.Position = [20 70 500 20];  % Position below the grid panel
            app.StatusLabel.Visible = 'off';
        end
        
        function initializeGrid(app)
            % Get all subject folders
            baseDir = './Data_Extracted/';
            if ~exist(baseDir, 'dir')
                mkdir(baseDir);
                return;
            end
            
            % Get and sort subject folders
            subjects = dir(baseDir);
            subjects = subjects([subjects.isdir]);  % Keep only directories
            subjects = subjects(~ismember({subjects.name}, {'.', '..'}));  % Remove . and ..
            subjectNames = sort({subjects.name});  % Sort alphabetically
            
            % Grid parameters
            cellWidth = 90;
            cellHeight = 60;
            spacing = 5;
            gridSize = 10;
            
            % Initialize grid
            app.SubjectGrid = cell(gridSize, gridSize);
            
            % Create grid
            for row = 1:gridSize
                for col = 1:gridSize
                    idx = (row-1)*gridSize + col;
                    xPos = (col-1)*(cellWidth + spacing) + 10;
                    yPos = (gridSize-row)*(cellHeight + spacing) + 10;
                    
                    if idx <= length(subjectNames)
                        subjectID = subjectNames{idx};
                        
                        % Create subject label
                        label = uilabel(app.GridPanel);
                        label.Position = [xPos yPos+40 cellWidth 20];
                        label.Text = subjectID;
                        label.HorizontalAlignment = 'center';
                        
                        % Create BSL button
                        bslBtn = uibutton(app.GridPanel, 'push');
                        bslBtn.Position = [xPos yPos+20 cellWidth 20];
                        bslBtn.Text = 'BSL';
                        bslBtn.Tag = [subjectID '_BSL'];
                        bslBtn.ButtonPushedFcn = @(btn,event) app.buttonPushed(btn);
                        
                        % Create PIV button
                        pivBtn = uibutton(app.GridPanel, 'push');
                        pivBtn.Position = [xPos yPos cellWidth 20];
                        pivBtn.Text = 'PIV';
                        pivBtn.Tag = [subjectID '_PIV'];
                        pivBtn.ButtonPushedFcn = @(btn,event) app.buttonPushed(btn);
                        
                        % Store in grid
                        app.SubjectGrid{row,col} = struct('label', label, ...
                            'bslButton', bslBtn, 'pivButton', pivBtn);
                        
                        % Check and enable/disable buttons
                        updateButtonStatus(app, subjectID, bslBtn, pivBtn);
                    end
                end
            end
        end
        
        function updateButtonStatus(app, subjectID, bslBtn, pivBtn)
            % Check if required files exist for BSL
            bslValid = checkAssessmentFiles(app, subjectID, 'BSL');
            pivValid = checkAssessmentFiles(app, subjectID, 'PIV');
            
            % Enable/disable buttons
            bslBtn.Enable = bslValid;
            pivBtn.Enable = pivValid;
        end
        
        function valid = checkAssessmentFiles(app, subjectID, assessType)
            baseDir = './Data_Extracted/';
            
            % Check ISNCSCI file
            isncsciPath = fullfile(baseDir, subjectID, 'ISNCSCI', assessType);
            isncsciFiles = dir(fullfile(isncsciPath, '*.mat'));
            
            % Check Coordination file
            coordPath = fullfile(baseDir, subjectID, 'Coordination', assessType);
            coordFiles = dir(fullfile(coordPath, '*.mat'));
            
            % Valid if exactly one file exists in each directory
            valid = (length(isncsciFiles) == 1) && (length(coordFiles) == 1);
        end
        
        function buttonPushed(app, button)
            % Get subject ID and assessment type from button tag
            tagParts = split(button.Tag, '_');
            subjectID = tagParts{1};
            assessType = tagParts{2};
        
            % 1. Load the data files
            % Load ISNCSCI data
            isncsciPath = fullfile('./Data_Extracted', subjectID, 'ISNCSCI', assessType);
            isncsciFile = dir(fullfile(isncsciPath, ['*_ISNCSCI_' assessType '_extracted.mat']));
            isncsciData = load(fullfile(isncsciPath, isncsciFile.name));
            ISNCSCI_data = isncsciData.ISNCSCIData;

            % Load Coordination data
            coordPath = fullfile('./Data_Extracted', subjectID, 'Coordination', assessType);
            coordFile = dir(fullfile(coordPath, ['*_Coordination_' assessType '_extracted.mat']));
            coordData = load(fullfile(coordPath, coordFile.name));
            Coord_data = coordData.CoordinationData;

            % Initialize DataProcessor
            processor = DataProcessor(subjectID, ISNCSCI_data, Coord_data);

            % 2. Process the data
            processor = processor.baselineCorrection();
            processor = processor.getLinearEnvelope();
            processor = processor.getScaleFactorsAllChannels();

            % 3. Create output struct
            CoordProcessed = struct();
            CoordProcessed.chnl.Coord = processor.chnl.Coord;
            CoordProcessed.ampScaleFactors = processor.ampScaleFactors;

            % 4. Save processed data
            % Create directory path
            basePath = './Data_Processed/';
            subjectPath = fullfile(basePath, subjectID);
            assessPath = fullfile(subjectPath, assessType);

            % Create directories if they don't exist
            if ~exist(basePath, 'dir')
                mkdir(basePath);
            end
            if ~exist(subjectPath, 'dir')
                mkdir(subjectPath);
            end
            if ~exist(assessPath, 'dir')
                mkdir(assessPath);
            end

            % Create filename and save
            filename = [subjectID '_Coordination_' assessType '_processed.mat'];
            fullPath = fullfile(assessPath, filename);
            save(fullPath, 'CoordProcessed');

            % Update status
            app.StatusLabel.Text = ['Processing complete for ' subjectID ' - ' assessType];
            app.StatusLabel.Visible = 'on';

        end
    end
    
    methods (Access = public)
        function app = NormalisationWindow(fig)
            if nargin > 0
                app.UIFigure = fig;
            end
            createComponents(app)
            app.UIFigure.Visible = 'on';
        end
    end
end 