% This code is for TESCoN data analysis
% This is for Layer 1
% Layer 1: Extract all the data. 
%          Make sure the data dimensions, data labels, etc. are correct 
%          (so that we make sure e.g. fast pace doesn't mistakenly labelled as self-selected pace), 
%          and label missing data or missing channel. 
%          And synchronisation.
% Layer 2: Normalisation. 
%          Use max(ISNCSCI, entire Coord recording) as the normalisation factor, 
%          but also provide other normaliation methods just in case. 
% Layer 3: Calculate various metrics (e.g., CCI)
%          based on clean, well-structured data from layer 2.
%
% Mingrui Sun, Jan 2025

% ==================================
% Data structure is as follows
% obj
% - subID
% - sampleRate
% - metaData
% - params
% - rawData
%   - Rest
%       - com (this contains the comments' position)
%           - n x 5 (n is the number of comments, column 2 is which recording, column 3 is the position of the comment in the spectific recording, i.e., at which frame, column 5 is the index of comtext that corresponds to the text of the comment text at the spectific timestamp)
%       - comtext
%           - n x m (n is the number of comments, m is the length of the longest comment)
%       - data
%           - 1 x n (contains data from all channels and all recordings)
%       - datastart
%           - p x q (p is the number of channels, q is the number of recordings, each value represents the start index of channel p recording q in 'data')
%       - dataend
%           - p x q (p is the number of channels, q is the number of recordings, each value represents the end index of channel p recording q in 'data')
%       - titles
%           - p x n (p is the number of channels, n is the length of the longest channel name. Each row corresponds to the channel name 1 to p.)
%   - ISNCSCI
%       - same as above
%   - Coord
%       - same as above
% - chnlData
%   - Rest
%       - Channel 1
%           - 1 x n array
%       - Channel 2
%       ...
%       - Channel p 
%   - ISNCSCI
%     - Same as Rest
%   - Coord 
%       - Channel 1
%           - Recording 1
%               - 1 x n array
%           - Recording 2
%           ...
%           - Recording q
%       - Channel 2
%       ...
%       - Channel p

% typically, p = 17 (16 EMG + 1 trigger), q = 6.


clc
clear

addpath(genpath('TESCoN_DA_Lib/'));

startGUI();

% disp("test start")
% subID = "TA02010";
% assessType = "BSL";
% testType = "ISNCSCI";
% sampleRate = 2000;  % Hz
% dataExtractor = DataExtractor(subID, assessType, testType, sampleRate);
% 
% dataExtractor = dataExtractor.loadExtractChannelPipline();
% dataExtractor = dataExtractor.extractChannelsSingleRecording(testType);
% 
% recordingNames = ["Right_SS", "Right_Fast", "Left_SS", "Left_Fast", "Right_SS2", "Right_Fast2"];
% dataExtractor = dataExtractor.extractChannelsMultiRecording("Coord", recordingNames);

% % dataExtractor = dataExtractor.baselineCorr(); % baseline correction
% % dataExtractor = dataExtractor.getLinearEnvelope();  % rectify + smooth

% dataExtractor.graphAllChannelsSingleRecording(testType);


% testType = "Coord";
% recordingNames = ["Right_SS", "Right_Fast", "Left_SS", "Left_Fast", "Right_SS2", "Right_Fast2"];
% dataExtractor.graphAllChannelsMultiRecording(testType, recordingNames);




