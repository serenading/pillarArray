%% Script plots trajectories for visualisation from variable spacing devices
% Author: @serenading. Dec 2020

%% Set parameters
metadataPath = '/Users/sding/OneDrive - Imperial College London/pillarArray/AuxiliaryFiles/metadata.csv';
device2use = 300; % variable spacing devices have diameters of 384, 480, 420
frameRate = 25;
pixelsize = 10; % each pixel is 10 microns

%% Find the relevant files and go through them one by one
% Get relevant filenames
metadata = readtable(metadataPath,'Delimiter',',','preserveVariableNames',true);
fileInd = find(metadata.devicePitch == device2use);
for fileCtr = 1:numel(fileInd)
    % Get skeletons filename
    filename = [metadata.dirName{fileCtr}, '/run' num2str(metadata.runNumber(fileCtr)),'_' metadata.strain_name{fileCtr},'/', metadata.basename{fileCtr}];
    filename = strrep(strrep(filename,'/Volumes/behavgenom$/Serena/pillarArray/','/Volumes/diskAshurDT/pillarArray/Results/'),'.hdf5','_skeletons.hdf5');
    % Load data
    trajData = h5read(filename,'/trajectories_data');
    foodContour = h5read(filename,'/food_cnt_coord');
    % Set colormap for traj colours according to time
    timeCmap = double(trajData.framember)/double(max(trajData.frame_number));
    % Plot
    figure; hold on
    pointsize = 10;
    scatter(trajData.coord_y,trajData.coord_x,pointsize,timeCmap,'filled');
    colorbar
    plot(foodContour(2,:),foodContour(1,:),'r-')
    title(metadata.strain_name{fileCtr})
    axis equal
    % Orient
end