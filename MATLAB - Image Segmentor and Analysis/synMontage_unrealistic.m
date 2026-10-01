%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                     Datasets result montage                          *%
%//%*                                                                      *%
%//%*             Name: Preetham Aghalaya Manjunatha    		           *%
%//%*             USC Email: aghalaya@usc.edu                              *%
%//%*             Submission Date: --/--/2019                              *%
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
warning('off', 'Images:initSize:adjustingMag');

%% Inputs
imSize = [512 512];
StrictResize = 1;
imColumns = 6;
imageClass = 6;
imageTileSize = [imageClass, imColumns];
k = 6;

folderPath = "F:\Datasets\SyntheticCRACK\Weird Cases\Unrealistic samples";
crackClass = {'transverse', 'longitudinal', 'shear', 'rrt', 'branched', 'surface'};


fileNames = dir(folderPath);
fileNames = natsort({fileNames(3:end).name})';


% Select k files per class, preserving crackClass order
selected = {};
for i = 1:numel(crackClass)
    classFiles = fileNames(contains(fileNames, crackClass{i}, 'IgnoreCase', true));
    if numel(classFiles) < k
        warning('Class "%s" has only %d files (need %d).', crackClass{i}, numel(classFiles), k);
    end
    selected = [selected; classFiles(1:min(k, numel(classFiles)))];
end

fileNames = fullfile(folderPath, selected);

%% Processing steps
%--------------------------------------------------------------------------
if (StrictResize == 1)
    montagefiles = cell(1, length(fileNames));
    myColnum = 1;
    for i = 1:length(fileNames)
       myImage = imread(fileNames(i));
       [h,w,bytesppix] = size(myImage);
       
        if (islogical(myImage) || bytesppix == 1)
            Icomp = imcomplement(imbinarize(im2double(myImage)));
            Imresized = imresize(Icomp, imSize);
            Iborder   = addborder(Imresized, 5, 0, 'outer');
            montagefiles{i} = Iborder;
        else
           if i == myColnum
                montagefiles{i} = imresize(myImage, imSize);
                myColnum = myColnum + imColumns;
           else
                Icomp = imcomplement(imbinarize(rgb2gray(myImage)));
                Imresized = imresize(Icomp, imSize); 
                Iborder = addborder(Imresized, 5, 0, 'outer');
                montagefiles{i} = Iborder;
           end
        end
    end
    figure; 
    m1 = montage(montagefiles, 'BackgroundColor', 'white', 'BorderSize', [5 5], ...
                    'Size', imageTileSize);
else
    figure; 
    m1 = montage(fileNames, 'BackgroundColor', 'white', 'BorderSize', [3 3], ...
                    'Size', imageTileSize, 'ThumbnailSize',[100 100]);
end

exportgraphics(gcf,['..\results\Paper Figs\' 'fig_unrealistic_samples.png'], 'BackgroundColor','white');


%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);





