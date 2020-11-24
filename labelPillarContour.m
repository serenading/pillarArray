clear
close all

addpath('../AggScreening/auxiliary/')

%% Set directories
% read directory
videodir = '/Volumes/diskAshurDT/pillarArray/MaskedVideos/20201119';
% save directory    
savedir = '/Volumes/diskAshurDT/pillarArray/AuxiliaryFiles/pillarContourImages/20201119';

%% Get a list of masked video names
filenames = rdir([videodir,'/**/*.hdf5']);

%% Export images for annotation
% Note: The exported image has x and y coordinates inverted compared to how Tierpsy reads the image but we will swap the coordinates around in the next section of code
% go through each masked video
for fileCtr = 1:numel(filenames)
    % read MaskedVideo filename
    videofilename = filenames(fileCtr).name;
    % read full image from the MaskedVideo
    fullData = h5read(videofilename,'/full_data');
    firstFullImage = fullData(:,:,1);
    % save first image
    splitname = strsplit(videofilename,'/');
    imagefilename = [savedir,'/',splitname{end}];
    imagefilename = strrep(imagefilename,'.hdf5','.jpg');
    imwrite(firstFullImage,imagefilename);
end

%% Hand label food contour using VGG annotator (http://www.robots.ox.ac.uk/~vgg/software/via/via.html) and save annotations

%% Interpolate xy coordinates to generate the correct coordinate format
% annotation file name
annocsv = '/Users/sding/OneDrive - Imperial College London/pillarArray/AuxiliaryFiles/via_project_20Nov2020_21h39m_csv.csv';
% read xy coordinates
annotations = readtable(annocsv,'PreserveVariableNames',true);
% go through each file to extract coordinates
for imageCtr = 1:size(annotations,1)
    annotation = annotations.region_shape_attributes{imageCtr};
    % format coordinates (I'm sure regex is the much, much better way to do this..)
    coordsRaw = strsplit(annotation,'[');
    xcoordsRaw = strsplit(coordsRaw{2},']'); 
    ycoordsRaw = strsplit(coordsRaw{3},']');
    xcoords = xcoordsRaw{1};
    ycoords = ycoordsRaw{1};
    xcoords = strsplit(xcoords,',');
    ycoords = strsplit(ycoords,',');
    xcoords = cellfun(@str2double,xcoords)';
    ycoords = cellfun(@str2double,ycoords)';
    % switch x and y coordinates around to match image format in the hdf5 file
    foodCntCoords = [ycoords, xcoords];  
    % override or add the 5th point with the 1st point to close the rectangular shape
    foodCntCoords(5,:) = foodCntCoords(1,:); 
    % check that the coordinates are the correct dimension
    assert((size(foodCntCoords,1)==5 & size(foodCntCoords,2)==2),'The coordinates must be 5x2 to specify a rectangular food contour.') 
    % transpose shape because Tierpsy apparently does this so we need to undo it
    foodCntCoords = foodCntCoords';
    
    %% write food contour coordinates to skeletons.hdf5
    % get partial filename
    annofilename = strrep(char(annotations.filename(imageCtr)),'.jpg','.hdf5');
    % find full skeletons filename
    for fileCtr = 1:numel(filenames)
        videofilename = filenames(fileCtr).name;
        if contains(videofilename,annofilename)
            fileIdx = fileCtr;
            break
        end
    end
    skeletonfilename = strrep(strrep(videofilename,'MaskedVideos','Results'),'.hdf5','_skeletons.hdf5');

    % write food contour coordinates into the skeletons file
    h5create(skeletonfilename,'/food_cnt_coord',size(foodCntCoords),'Datatype','double');
    h5write(skeletonfilename,'/food_cnt_coord',double(foodCntCoords));
    disp(['Food contour coordinates added to ' videofilename ])
    
    %% delete bad feature files so they can be re-calculated from the feat_init step of Tierpsy analysis
    featuresfilename = strrep(skeletonfilename,'_skeletons','_featuresN');
    if exist(featuresfilename)
        delete(featuresfilename)
    end
end