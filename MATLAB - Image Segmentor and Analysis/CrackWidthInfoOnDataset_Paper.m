%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                           Crack Package						       *%
%//%*                                                                      *%
%//%*             Name: Preetham Aghalaya Manjunatha    		           *%
%//%*             USC ID Number: 7356627445		                           *%
%//%*             USC Email: aghalaya@usc.edu                              *%
%//%*             Submission Date: --/--/2012                              *%
%//%************************************************************************%
%//%*             Viterbi School of Engineering,                           *%
%//%*             Sonny Astani Dept. of Civil Engineering,                 *%
%//%*             University of Southern california,                       *%
%//%*             Los Angeles, California.                                 *%
%//%************************************************************************%
clear; close all; clc;
Start = tic;
warning('off','all');

% Improvements to be done
% centerline and crack width line (steep slope) linking use sub-pixel (done)
% crack intersection accurate width
% minimize crack ends centerline skewness

%% Inputs
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Crack width calculation parameters
%--------------------------------------------------------------------------
inpstruct.thinPruneMethod = 'alex';  % conventional | alex | voronoi | FMM
inpstruct.thinPruneThresh = 0.1; %0.15
inpstruct.figShow ='no';

% Unit scale of pixel in world units
inpstruct.pixelScale = 1;% * 0.3736; %0.481; 

% File to write output
inpstruct.fileName2write ='ZZZ_crackStatistics.txt';

% Moving window size
inpstruct.movWindowSize = 7;
inpstruct.move_mean_median = 2;  % 1 ==  mean | 2 == median

% Skeleton orientation block size
inpstruct.skelOrientBlockSize = 3;
markerAlpha = 0.4;

%--------------------------------------------------------------------------
% Synthetic cracks folder
%--------------------------------------------------------------------------
% 'D:\OneDrive\Team Work\Team RoboCRACK\Program\2020-01-05\data\Testing\Dataset I\Pixel Labels\GT\crack';
% 'D:\OneDrive\Team Work\Team RoboCRACK\Program\2020-01-05\data\Testing\Dataset V\Pixel Labels\GT\crack';
% 'D:\OneDrive\Team Work\Team RoboCRACK\Program\2020-01-05\data\Testing\Dataset VII (Liu)\Pixel Labels\GT\crack';
inpstruct.CrackFolder = 'H:\Project DLCRACK\My Datasets\Graph Synthetic Crack (GSynCrack - GSC)\Pixel Labels';

%--------------------------------------------------------------------------
% Algorithm outputs folder for the synthetic cracks 
%--------------------------------------------------------------------------
inpstruct.writeAlgoOutputFig2folder ='';

%% Synthetic cracks images  folder
imgSet = imageDatastore(inpstruct.CrackFolder,"IncludeSubfolders",true);

%% Extract crack physical quantities

%Before the loop, we need to construct the object. 
WaitMessage = waitbarParfor(numel(imgSet.Files),'Waitbar', true);

parfor itr = 1:numel(imgSet.Files)

    %Send a message to the object. 
    WaitMessage.Send;

    % Populate the image to extract the physical quantities
    BW4 = imread(imgSet.Files{itr});
    stats = regionprops(BW4,'Area');
    area_array = cat(1,stats.Area);

    % Cracks physical quantities
    if (sum(sum(BW4)) > 0)
        CrackWidthLength_output = Calculate_CrackWidthLength_Paper(inpstruct,BW4,...
            [], [], []);

        % Record the crack physical quantities
        measured_CrackLength_record(itr,1) = CrackWidthLength_output.measured_length;
        measured_minCrackWidth_record(itr,1) = CrackWidthLength_output.minCrackWidth;
        measured_maxCrackWidth_record(itr,1) = CrackWidthLength_output.maxCrackWidth;
        measured_averageCrackWidth_record(itr,1) = CrackWidthLength_output.averageCrackWidth;
        measured_Crackarea_record(itr,1) = CrackWidthLength_output.totalArea;
        measured_stdCrackWidth_record(itr,1) = CrackWidthLength_output.stdCrackWidth;
        measured_RMSCrackWidth_record(itr,1) = CrackWidthLength_output.RMSCrackWidth;
        total_measure_record(itr,1) = CrackWidthLength_output.total_measure;
    else
        % Record the crack physical quantities
        measured_CrackLength_record(itr,1) = NaN;
        measured_minCrackWidth_record(itr,1) = NaN;
        measured_maxCrackWidth_record(itr,1) = NaN;
        measured_averageCrackWidth_record(itr,1) = NaN;
        measured_Crackarea_record(itr,1) = NaN;
        measured_stdCrackWidth_record(itr,1) = NaN;
        measured_RMSCrackWidth_record(itr,1) = NaN;
        total_measure_record(itr,1) = NaN;
    end
end

%Destroy the object.
WaitMessage.Destroy

%% Create table
table_header  = {'Measured avg/med width','Measured length','Measured area', ...
                'Measured min width','Measured max width','Measured std width',...
                'Measured RMS width','Total measure points'};

record_matrix = [measured_averageCrackWidth_record, measured_CrackLength_record,...
                 measured_Crackarea_record, measured_minCrackWidth_record,...
                 measured_maxCrackWidth_record, measured_stdCrackWidth_record,...
                 measured_RMSCrackWidth_record,total_measure_record];

record_Table = array2table(record_matrix,'VariableNames',table_header);

% Remove NaN rows
record_matrix_no_nan = record_matrix;
record_matrix_no_nan(any(isnan(record_matrix_no_nan), 2), :) = [];
record_Table_no_NaN = array2table(record_matrix_no_nan,'VariableNames',table_header);

%% End
%--------------------------------------------------------------------------
Runtime = toc(Start);
