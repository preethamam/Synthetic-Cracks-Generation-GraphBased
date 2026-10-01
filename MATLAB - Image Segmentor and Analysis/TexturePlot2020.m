%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                         Project RoboCRACK						       *%
%//%*                                                                      *%
%//%*             Name: Preetham Manjunatha               		           *%
%//%*             USC ID Number: 7356627445		                           *%
%//%*             USC Email: aghalaya@usc.edu                              *%
%//%*             Submission Date: --/--/----                              *%
%//%************************************************************************%
%//%*             Viterbi School of Engineering,                           *%
%//%*             Sonny Astani Dept. of Civil Engineering,                 *%
%//%*             University of Southern california,                       *%
%//%*             Los Angeles, California.                                 *%
%//%************************************************************************%

%% Start parameters
%--------------------------------------------------------------------------
clear; close all; clc;
Start = tic;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

%% Inputs
%--------------------------------------------------------------------------

% Callback
% MainInputs_TestingDataset_I;
% MainInputs_TestingDataset_II;
% MainInputs_TestingDataset_III;
TexturePlot_Inputs


% Create image sets
if (texturefeature_inpstruct.flag_texturefeatures && ~ exist(texturefeature_inpstruct.Imgs_filename,'file'))
            
    % crack images and Non-crack images
    crack_non_crack_Imgs = [];
    if~(isempty(texturefeature_inpstruct.originaldata_folders))
        parfor i = 1:length(texturefeature_inpstruct.originaldata_folders)
            crack_non_crack_Imgs_i = dir(fullfile(texturefeature_inpstruct.folderpath_texture{i},...
                                                  texturefeature_inpstruct.originaldata_folders{i}));
            crack_non_crack_Imgs_i = crack_non_crack_Imgs_i(~ismember({crack_non_crack_Imgs_i.name},{'.','..','desktop.ini'}));
            imgCount(i) = length(crack_non_crack_Imgs_i)
            crack_non_crack_Imgs = [crack_non_crack_Imgs; crack_non_crack_Imgs_i];
        end
    end
    save(texturefeature_inpstruct.Imgs_filename, 'crack_non_crack_Imgs' ,'imgCount');
else    
    load(texturefeature_inpstruct.Imgs_filename);
end


% Images
texturefeature_inpstruct.crack = crack_non_crack_Imgs...
    (1:sum(imgCount(1:texturefeature_inpstruct.noncrack_crack_foldercount(1))));

texturefeature_inpstruct.non_crack = [];
if ~(texturefeature_inpstruct.noncrack_crack_foldercount(2) == 0)
    texturefeature_inpstruct.non_crack = crack_non_crack_Imgs...
    (1:sum(imgCount(1+texturefeature_inpstruct.noncrack_crack_foldercount(1), end)));
end

%% Processing steps
%--------------------------------------------------------------------------
% Image texture features callback function
texturefeature_inpstruct.imgCount = imgCount;

if (texturefeature_inpstruct.flag_texturefeatures && ~ exist(texturefeature_inpstruct.matFilename,'file'))
    % Extract texture features
    [imtextures, totalimages] = texturefeatures2020 (texturefeature_inpstruct);

    % Cluster the data
    imtexture_feature_matrix  = cat(1, imtextures.featureVec);
    class_labels_stack = [];
    
    imgCount_index = [0,imgCount];
    idx_range = cumsum(imgCount_index);
    
    for i = 1:length(texturefeature_inpstruct.originaldata_folders)        
        
        idx = idx_range(i)+1 : idx_range(i+1);        
        imtexture_fmatrix_perdataset = imtexture_feature_matrix(idx,:);

        % Cluster the images
        [class_labels, centroids] = clusterimages (imtexture_fmatrix_perdataset, texturefeature_inpstruct.k,  ...
                                   texturefeature_inpstruct.originaldata_folders, ...
                                   texturefeature_inpstruct.folderpath_texture,...
                                   totalimages, imtextures, ...
                                   texturefeature_inpstruct.datasetType,...
                                   texturefeature_inpstruct.flag_clusterImcpyPaste);


        % Check norm to decide low or high texture (low -> high l2 norm)
        if norm(centroids(1,:), 2) < norm(centroids(2,:), 2)
           %  To ensure Class 1 always corresponds to low texture
             class_labels = 3 - class_labels;
        end
        
        class_labels_stack = [class_labels_stack; class_labels];
    end
    
    class_labels = class_labels_stack;
      
    % Plot the 3D bar graph
    save (texturefeature_inpstruct.matFilename, 'imtextures', 'totalimages',...
          'class_labels');      
else
    load(texturefeature_inpstruct.matFilename);
end

%% Plot texture, class, image resolution (testing dataset attributes)
% Inputs
class_string = {'GSC Train', 'GSC Val', 'GSC Test'};
texturefeature_inpstruct.pixels_normfactor = 1e3;
width = 0.3;    
texturefeature_inpstruct.alpha = 1;
texturefeature_inpstruct.lowTextureonTop = 1;

% Plot the texture 3D bar plot
plot3Dbargraph2020 (texturefeature_inpstruct, class_string, width);

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);
