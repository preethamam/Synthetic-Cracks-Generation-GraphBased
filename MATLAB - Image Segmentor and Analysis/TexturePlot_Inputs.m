
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Texture feature vector params
%--------------------------------------------------------------------------
% K-centroids
%--------------------------------------------------------------------------
texturefeature_inpstruct.k = 2;

%--------------------------------------------------------------------------
% Shuffle flag
%--------------------------------------------------------------------------
texturefeature_inpstruct.flag_texturefeatures    = 1;   %[0-off | 1-on]

%--------------------------------------------------------------------------
% Texture filter
%--------------------------------------------------------------------------
% laws - Laws multi-channel filter (level, edge, spot, wave and ripple)
% sfta - Segmentation-based Fractal Texture Analysis
% glcm - grey level co-occurring matix
texturefeature_inpstruct.texturefilter_type      = 'glcm';

%--------------------------------------------------------------------------
% GPU array
%--------------------------------------------------------------------------
% yes - creates GPU array (note: works for certain Matlab functions)
% no  - non GPU array
texturefeature_inpstruct.gpuarray                = 'no';

%--------------------------------------------------------------------------
% Norm type
%--------------------------------------------------------------------------
% L1        - L1 norm
% L2        - l2 norm
% infinity  - infinity norm
% frobenius - frobenius norm
texturefeature_inpstruct.normtype                = 'L2';

%--------------------------------------------------------------------------
% Window size (energy)
%--------------------------------------------------------------------------
% n    - odd integer value (such as 3, 5, 7, 11, 13, 15, 17, ...)
texturefeature_inpstruct.windowsize              = 5;

%--------------------------------------------------------------------------
% Provide names of original data folders (include name of the folder even its folder
% is empty)
%--------------------------------------------------------------------------
texturefeature_inpstruct.noncrack_crack_foldercount = [3,0];

texturefeature_inpstruct.originaldata_folders    = {'train', ...
                                                    'val', ...
                                                    'test'};


%--------------------------------------------------------------------------
% Data folder path
%--------------------------------------------------------------------------
texturefeature_inpstruct.folderpath_texture = {'H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)\Cracks',...
                                               'H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)\Cracks',...
                                               'H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)\Cracks'};

%--------------------------------------------------------------------------
% Data set type
% training | testing
%--------------------------------------------------------------------------
texturefeature_inpstruct.datasetType              = 'testing';

%--------------------------------------------------------------------------
% Cluster images copy/paste shuffle flag
%--------------------------------------------------------------------------
texturefeature_inpstruct.flag_clusterImcpyPaste   = 0;   %[0-off | 1-on]

% Texture data saving mat file
texturefeature_inpstruct.matFilename = 'ZZZ_texture_CDLN_Dataset.mat';

[filepath,name,ext] = fileparts(texturefeature_inpstruct.matFilename);

texturefeature_inpstruct.Imgs_filename = [name '_images.mat'];


% Texture plots saving folder location
texturefeature_inpstruct.plot_folder_location = '../../Results/Texture Plots';

%--------------------------------------------------------------------------
% Turn on/off adaptive histogram
%--------------------------------------------------------------------------
% adaphist - adaptive histogram
% image_adjust - imadjust
% hist_equi - histogram equalization
% none
% Texture contrast type
texturefeature_inpstruct.contrast_type        = 'none';


%--------------------------------------------------------------------------
% Image resize for too large images
%--------------------------------------------------------------------------
texturefeature_inpstruct.resizeImage = 'no'; % 'yes' | 'no'
texturefeature_inpstruct.maxImageResizePixels = 700;
texturefeature_inpstruct.resizeImageSize = [];
texturefeature_inpstruct.resizeImageSizeScale = 0.25;