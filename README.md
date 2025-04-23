This file describes the file structure and code structure.

Layer 1: Extract all the data. 
         Make sure the data dimensions, data labels, etc. are correct 
         (so that we make sure e.g. fast pace doesn't mistakenly labelled as self-selected pace), 
         and label missing data or missing channel. 
         And synchronisation.
Layer 2: Normalisation. 
         Use max(ISNCSCI, entire Coord recording) as the normalisation factor, 
         but also provide other normaliation methods just in case. 
Layer 3: Calculate various metrics (e.g., CCI)
         based on clean, well-structured data from layer 2.

### Workflow
#### 1. Export data from LabChart
- Check and (re-code) the commonets of the coordination recordings so that: the start and stop of the activities are commoned as LEFT SELF SS, LEFT FAST SS, RIGHT SELF SS, RIGHT FAST SS.
- Export as Matlab: choose upsample to the same rate, and NOT using simple format.
- Ensure the sampling frequency is at 2000Hz.
- Name the file as 
    - TAxxxxx_EMG_BSL_Rest.mat
    - TAxxxxx_EMG_PIV_Rest.mat
    - TAxxxxx_EMG_BSL_ISNCSCI.mat
    - TAxxxxx_EMG_PIV_ISNCSCI.mat
    - TAxxxxx_EMG_PIV_Coord.mat
    - TAxxxxx_EMG_BSL_Coord.mat

#### 2. Set up file structure
##### Data_Source
Data_Source/
└── TAxxxxx/
    ├── Rest/
    │   ├── BSL/
    │   │   └── TAxxxxx_EMG_BSL_Rest.mat
    │   └── PIV/
    │       └── TAxxxxx_EMG_PIV_Rest.mat
    ├── ISNCSCI/
    │   ├── BSL/
    │   │   └── TAxxxxx_EMG_BSL_ISNCSCI.mat
    │   └── PIV/
    │       └── TAxxxxx_EMG_PIV_ISNCSCI.mat
    └── Coordination/
        ├── BSL/
        │   └── TAxxxxx_EMG_BSL_Coord.mat
        └── PIV/
            └── TAxxxxx_EMG_PIV_Coord.mat


##### Data_Extracted
|- TAxxxxx
    |- Rest
        |- BSL
            |- TAxxxxx_TAxxxxx_Rest_BSL_extracted.mat
        |- PIV
            |- TAxxxxx_TAxxxxx_Rest_PIV_extracted.mat
    |- ISNCSCI
        |- BSL
            |- TAxxxxx_TAxxxxx_ISNCSCI_BSL_extracted.mat
        |- PIV
            |- TAxxxxx_TAxxxxx_ISNCSCI_PIV_extracted.mat
    |- Coordination
        |- BSL
            |- TAxxxxx_TAxxxxx_Coordination_BSL_extracted.mat
        |- PIV
            |- TAxxxxx_TAxxxxx_Coordination_PIV_extracted.mat
##### Data_Processed
|- TAxxxxx
    |- BSL
        |- TAxxxxx_Coordination_BSL_processed.mat
    |- PIV
        |- TAxxxxx_Coordination_PIV_processed.mat

#### 3. Data Extraction
- Run Data_Analysis.m
-> Data Extraction
-> Select subject
    - Each button displays the subject ID, and whether there are data files for Res (R), ISNCSCI (I) and Coordination (C).
-> Select Tasktype: Rest, ISNCSCI, Coord
-> Select Assessmemnt type: BSL, PIV

##### 3.1 Extract Rest data
1. Extract (if left and right are in the same file), or Extract Left and Right (if left and right are in different files)
2. Visualise: check for any abnormalities.
    - If some data doesn't have any data, or have signal range > 5mV
3. Merge recording if there are multiple recordings (separated using green vertical line). If there is only one recording, the button will be disabled.
4. *This step is only needed in 3.2* Click the Extract Triggered button. This will extract data only when the trigger is on.
5. Select the channel names are corrected labeld, select "Invalid" for the abnormal channels (data will not be saved & not be used for MVC/Rest normalisation)
6. Click "Confirm Mapping" when done
7. Click "Save"

##### 3.2 Extract ISNCSCI data
The workflow is similar to 3.1.
The only difference is step 4. Click the Extract Triggered button. This will extract data only when the trigger is on.

##### 3.3 Extract Coordination data
1. Extract
2. Visualise: confirm that the person is left/right dominant (the dominant side is performed first). The that GO and END is marked properly.
    "Properly" means: The "GO" event is marked with a string that contains either one of the {'SELF GO', 'FAST GO', 'SELF START', 'FAST START'} and the "END" event is marked with a string that contains either one of the {'SELF END', 'FAST END', 'SELF STOP', 'FAST STOP'} If one or more of the events is not labled so, need to extract manually.
3. Type in the coordination activity labels. For left dominant subjects, they are "Left_SS, Left_Fast, Right_SS, Right_Fast", for right dominant subjects, they are "Right_SS, Right_Fast, Left_SS, Left_Fast". 
    - Tip: if there are invalid trials, assign it with a label that is not one of the above 4, e.g., "Left_SS_Invalid", and it will be ignored in the consequent processing.
4. Select the channel names similar to 3.1 and 3.2. 
5. Click "Confirm Mapping" when done.
6. Click "Extract GO-END" (if need manual extraction, go to step 7 instead)
7. Manual Extraction
    - Input Start time (in seconds), End time (in seconds), Label (e.g., Left_SS). You can read start/end time by interacting with the plot.
    - Click "Manual Extract GO-END" 

#### 4. Data normalisation
In this window, each subject will have two buttons "BSL" and "PIV". If data are presented (Step 3 are correctly performed), the buttons will be enabled. Simply click on the two buttons and wait for the "Processing complete for <subject ID> - <Assessment type>". 

#### 5. Calculate metrics
This feature is currently implemented independently from the GUI. 
At this stage, data has been cleaned in a consistent format for all subjects. It is very easy to write code for calculate various metrics from here.
- The code for calculating CCI is in CalculateCCL.m
Future development can consider remove this feature from the GUI.

### Processed data structure
After step 4 (data normalisation), the data is cleaned, ready to use, and is stored in the following structure.
Data_processed
|- TAxxxxx
    |- BSL
        |- TAxxxxx_Coordination_BSL_processed.mat
    |- PIV
        |- TAxxxxx_Coordination_PIV_processed.mat

In each .mat file, the data is organised as:
CoordProcessed
|- chnl
    |- Coord
        |- Muscle1
            |- Right_SS: 1 x n array, unnormalised EMG signal, at 2000Hz.
            |- Right_fast: 1 x n array, unnormalised EMG signal, at 2000Hz.
            |- Left_SS: 1 x n array, unnormalised EMG signal, at 2000Hz.
            |- Left_Fast: 1 x n array, unnormalised EMG signal, at 2000Hz.
        |- Muscle2
        ...
        |- Musclex
|- ampScaleFactors
    |- Muscle1
        |- Right_SS
            |- MVC: scale factor calculated from MVC. Use it as: normalised = unnormalisedEmg / scaleFactor
            |- Rest: scale factor calculated from Rest 
            |- CycleMean: scale factor calculated from the mean of emg of this trial
            |- CycleMax: scale factor calculated from the max of emg of this trial
        |- Right_fast: 1 x n array, unnormalised EMG signal, at 2000Hz.
        |- Left_SS: 1 x n array, unnormalised EMG signal, at 2000Hz.
        |- Left_Fast: 1 x n array, unnormalised EMG signal, at 2000Hz.
    |- Muscle2
    ...
    |- Musclex