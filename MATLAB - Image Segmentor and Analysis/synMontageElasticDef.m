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
imColumns = 7;
imageClass = 2;
imageTileSize = [imageClass, imColumns];

fileNames = readlines("D:\OneDrive\Education Materials\Team Work\Team SyntheticCRACK\Codebase\2022-01-22 - A graph-based (non-force)\Results\Text Files\synthetic_graphstructure_samples.txt");

%% Processing steps
%--------------------------------------------------------------------------
if (StrictResize == 1)
    montagefiles = cell(1, length(fileNames));
    myColnum = 1;
    for i = 1:length(fileNames)
       myImage = imread(fileNames(i));
       [h,w,bytesppix] = size(myImage);
       
        if (islogical(myImage) || bytesppix == 1)
            % Icomp = imbinarize(im2double(myImage));
            Imresized = imresize(myImage, imSize);
            Iborder = Imresized;
            % Iborder   = addborder(Imresized, 5, 0, 'outer');
            montagefiles{i} = Iborder;
        else
           if i == myColnum
                montagefiles{i} = imresize(myImage, imSize);
                myColnum = myColnum + imColumns;
           else
                % Icomp = imbinarize(rgb2gray(myImage));
                Imresized = imresize(myImage, imSize); 
                Iborder = Imresized;
                % Iborder = addborder(Imresized, 5, 0, 'outer');
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

exportgraphics(gcf,['..\Results\Paper Figs\' 'synthetic_graphstructure_samples.png']);


%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);





