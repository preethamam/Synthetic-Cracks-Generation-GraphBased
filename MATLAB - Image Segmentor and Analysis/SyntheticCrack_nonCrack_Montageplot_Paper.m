%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                         Project RoboCRACK						       *%
%//%*                                                                      *%
%//%*             Name: Preetham Manjunatha               		           *%
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
imageNum = 20;

non_crack_fileFolder = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper II - Graph Synthetic Crack\Training images\non-crack';
crack_fileFolder = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper II - Graph Synthetic Crack\Training images\crack';

imgSet_non_crack = imageSet(non_crack_fileFolder, 'recursive');
imgSet_crack = imageSet(crack_fileFolder, 'recursive');

imgSet_non_crack = randsample(imgSet_non_crack.ImageLocation, imageNum);
imgSet_crack = randsample(imgSet_crack.ImageLocation, imageNum);

parfor i=1:imageNum
   montagefiles_non_cracks(:,:,:,i) = imresize(imcomplement(imread(imgSet_non_crack{i})),[100 100]);
   montagefiles_cracks(:,:,:,i)     = imresize(imcomplement(imread(imgSet_crack{i})),[100 100]);
end

figure; m1 = montage(montagefiles_non_cracks, 'BackgroundColor', 'white', 'BorderSize', [3 3], ...
                    'Size', [5,4]);
exportgraphics(gcf,'../Results/Figures/non_cracks_blobs.pdf')

figure; m2 = montage(montagefiles_cracks, 'BackgroundColor', 'white', 'BorderSize', [3 3], ...
                    'Size', [5,4]);
exportgraphics(gcf,'../Results/Figures/syn_cracks1.pdf')

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);
