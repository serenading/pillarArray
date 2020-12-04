%% This script uses three files to generate a features summary table.

% 1. Manually curated metadata file; 2. Filenames file generated by Tierpsy; 3. Features summary file generated by Tierpsy.
% author: serenading. Nov 2020

clear 
close all

%% Import features data and combine with metadata

% set which feature extraction timestamp to use
extractStamp = '20201202_184448'; % '20201202_171608' for standard feats; '20201202_182346' for filtered feats; '20201202_184448' for first half of 30 min

% load features matrix, correspondong filenames, and metadata
tierpsyFeatureTable = readtable(['/Users/sding/OneDrive - Imperial College London/pillarArray/Results/features_summary_tierpsy_plate_' extractStamp '.csv'],'Delimiter',',');%,'preserveVariableNames',true);
tierpsyFileTable = readtable(['/Users/sding/OneDrive - Imperial College London/pillarArray/Results/filenames_summary_tierpsy_plate_' extractStamp '.csv'],'Delimiter',',','CommentStyle','#');%,'preserveVariableNames',true);
metadataTable = readtable('/Users/sding/OneDrive - Imperial College London/pillarArray/AuxiliaryFiles/metadata.csv','Delimiter',',','preserveVariableNames',true);

% rename metadata column heads to match Tierpsy output
metadataTable.Properties.VariableNames{'basename'} = 'filename';

%% Join tables

% join the Tierpsy tables to match filenames with file_id. Required in case
% features were not extracted for any files.
combinedTierpsyTable = outerjoin(tierpsyFileTable,tierpsyFeatureTable,'MergeKeys',true);

% get just the filenames from the full path in the combined Tierpsy table
[~, fileNamesTierpsy] = cellfun(@fileparts, combinedTierpsyTable.filename, 'UniformOutput', false);
combinedTierpsyTable.filename = strrep(fileNamesTierpsy,'_featuresN','.hdf5');

% finally, join tables to get strain names for each set of features
featureTable = outerjoin(metadataTable,combinedTierpsyTable,'MergeKeys',true);

% get row logical index for valid files
rowLogInd = strcmp(featureTable.is_good,'True') & featureTable.is_bad == 0;

% trim featureTable down to those with valid files
featureTable = featureTable(rowLogInd,:);

% export full features table
writetable(featureTable,['/Users/sding/OneDrive - Imperial College London/pillarArray/Results/fullFeaturesTable_' extractStamp '.csv']);