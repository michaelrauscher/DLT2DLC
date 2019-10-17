# DLT2DLC

Converts an xypts CSV file from DLTdv (http://biomech.web.unc.edu/dltdv/) and its associated video into a labeled training dataset for use with DeepLabCut (https://github.com/AlexEMG/DeepLabCut).

The conversion of the resultant dataset can then be finalized by running the following code in the python interpreter:
`deeplabcut.convertcsv2h5(<config path>)`
