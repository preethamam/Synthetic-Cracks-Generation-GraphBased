%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                     Datasets image sizes                             *%
%//%*                                                                      *%
%//%*             Name: Preetham Aghalaya Manjunatha    		           *%
%//%*             USC ID Number: 7356627445		                           *%
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
ImageRootFolder = 'B:\Project MegaCRACK-RoboCRACK\Synthetic Data\Training-RoboCrack';
folderName = 'synthetic_cracks_non_uniform_diffimsize_longshortpath_rot5_90'; %'synthetic_cracks_non_uniform_diffimsize_longshortpath_rot5_90';

%% Image size
filenames = dir(fullfile(ImageRootFolder,folderName));
filenames = filenames(~ismember({filenames.name},{'.','..'}));
        
%% Get image info
maxnum = -1e16;
minnum = 1e16;
imageResoutionMin = [];
imageResoutionMax = [];

h = waitbar(0,'1','Name','Finding the min and max values... ',...
    'CreateCancelBtn',...
    'setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)

for i = 1:length(filenames)

    % Wait bar parameters
    % Check for Cancel button press
    if getappdata(h,'canceling')
        break
    end

    % Report current estimate in the waitbar's message field
    % Update the estimate
    waitbar(i/length(filenames), h, sprintf(['Total Images: %i | '...
            'Current Image: %i'], length(filenames), i))
   
   Ioriginal = imread(fullfile(filenames(i).folder,filenames(i).name));
   
   [imheight,imwidth,imbytesppix] = size(Ioriginal);
   
    % Feature image resolution
    TotalPixels = imwidth * imheight;
    
    if (maxnum < TotalPixels )
        imageResoutionMax = [imwidth, imheight];
        maxnum = TotalPixels;
    end
    
    
    if (minnum > TotalPixels )
        imageResoutionMin = [imwidth, imheight];
        minnum = TotalPixels;
    end
   
end

%Destroy the object.
delete(h)       % DELETE the waitbar; don't try to CLOSE it. 

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);





