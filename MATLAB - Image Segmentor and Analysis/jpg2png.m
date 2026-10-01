clc; close all; clear;

% Inputs
gtFolder = "H:\Project DLCRACK\External Datasets\Çağlar Fırat Özgenel - Concrete Crack Segmentation Dataset\Pixel Labels JPG";
writeFolder = "H:\Project DLCRACK\External Datasets\Çağlar Fırat Özgenel - Concrete Crack Segmentation Dataset\Pixel Labels";


% Read directory
imgs = dir(gtFolder);
imgs = imgs(3:end);

% Get image filenames
imgs = {imgs.name};

for i = 1:length(imgs)   
    I = imread(fullfile(gtFolder, imgs{i}));

    [height,width,channels] = size(I);

    if channels == 3
        Igray = rgb2gray(I);
    else
        Igray= im2gray(I);
    end
    I2 = imbinarize(Igray);

    [filepath,name,ext] = fileparts(imgs{i});        
    imwrite(I2, fullfile(writeFolder, [name '.png']))    
end  
