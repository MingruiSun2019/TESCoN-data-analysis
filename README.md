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
- Export as Matlab: choose upsample to the same rate, and NOT using simple format
- Name the file as 
    - TAxxxxx_EMG_BSL_Rest.mat
    - TAxxxxx_EMG_PIV_Rest.mat
    - TAxxxxx_EMG_BSL_ISNCSCI.mat
    - TAxxxxx_EMG_PIV_ISNCSCI.mat
    - TAxxxxx_EMG_PIV_Coord.mat
    - TAxxxxx_EMG_BSL_Coord.mat

#### 2. Set up file structure
- Data_Source
|- TAxxxxx
    |- Rest
        |- BSL
            |- TAxxxxx_EMG_BSL_Rest.mat
        |- PIV
            |- TAxxxxx_EMG_PIV_Rest.mat
    |- ISNCSCI
        |- BSL
            |- TAxxxxx_EMG_BSL_ISNCSCI.mat
        |- PIV
            |- TAxxxxx_EMG_PIV_ISNCSCI.mat
    |- Coordination
        |- BSL
            |- TAxxxxx_EMG_BSL_Coord.mat
        |- PIV
            |- TAxxxxx_EMG_PIV_Coord.mat

#### 3. Extract data
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
5. Confirm the channel names are corrected labeld, select "Invalid" for the abnormal channels (data will not be saved & not be used for MVC/Rest normalisation)
6. Click "Confirm Mapping" when done
7. Click "Save"

##### 3.2 Extract ISNCSCI data

