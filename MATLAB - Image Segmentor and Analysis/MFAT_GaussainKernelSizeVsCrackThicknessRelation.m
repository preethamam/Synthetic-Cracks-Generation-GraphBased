%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                       Project RoboCRACK	             			   *%
%//%*                                                                      *%
%//%*             Author(s): Preetham Aghalaya Manjunatha                  *%
%//%*             USC Email: aghalaya@usc.edu                              *%
%//%*             Submission Date: 04/21/2017                              *%
%//%************************************************************************%
%//%*             Viterbi School of Engineering,                           *%
%//%*             Sonny Astani Dept. of Civil Engineering,                 *%
%//%*             University of Southern california,                       *%
%//%*             Los Angeles, California.                                 *%
%//%************************************************************************%

clc; close all; clear;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Start = tic;

% parpool(16);


%% Inputs
gaussWidthLooper = 1;   % 0 | 1
%

% Anisotropic diffusion
input.num_iter = 50;
input.delta_t = 1/7;
input.kappa = 30;
input.option = 3;

%--------------------------------------------------------------------------
% Crack Debrancher inputs
%--------------------------------------------------------------------------
input.crackDebrancher_required = 'no'; % 'yes' | 'no'
input.thinPruneMethod = 'alex';  % 'conventional' | 'alex'
input.thinPruneThresh = 0.1; % [0 1]
input.branchlengthThreshold = 35;

% Label matrix generator type
input.labelMatixType = 'testing';

%--------------------------------------------------------------------------
% Crack/non-crack decider parameters
%--------------------------------------------------------------------------
input.non_crack_class         = 1;
input.crack_class             = 2;
input.CC_overlap_percent      = 0.5; %[0 1]
input.BBoxthreshold           = 0.5;

input.branchpoints = 3;
input.figShow_visLabels  = 'no';     % 'yes' | 'no'

% Post-processing using circularity index
input.postprocess = 0;
input.circularity_threshold = [0.02 0.2];  %image 356 [0.005 0.4]
input.post_process_Type = 'circularity';  % 'circularity' | 'circ_branchpoint_holes'


%--------------------------------------------------------------------------
showPlot = 0;

%--------------------------------------------------------------------------
totalSynCracks = 500;
createSynCracks = 0;

% Synthetic cracks width and length input
%--------------------------------------------------------------------------
% Output image size range
minRadius = 1;
maxRadius = 20;

%--------------------------------------------------------------------------
% Image filtering parameters
%--------------------------------------------------------------------------
sigma = 5;
GaussFiltSize = [5 5];

%--------------------------------------------------------------------------
% Elastic deformation
%--------------------------------------------------------------------------
% Show figure points
showfig_points = 0;
geotrans_type = {'affine', 'projective', 'polynomial', 'piecewise_linear', 'local_weighted_mean'};
totNumberCracksElasticDef = 1;

%
%--------------------------------------------------------------------------
% Folder and image sets
%--------------------------------------------------------------------------
% Non-crack image to be overlayed
if ismac

elseif isunix
    imageFolder = '/media/preethamam/BigData/Project MegaCRACK-RoboCRACK/Real World Data/Hybrid Paper/Synthetic Crack Profile Analysis/non-crack';
elseif ispc
    imageFolder = 'U:\Project MegaCRACK-RoboCRACK\Real World Data\Hybrid Paper\Synthetic Crack Profile Analysis\non-crack';
else
    disp('Platform not supported')
end


% Synthetic cracks images save folder
if ismac

elseif isunix
    synCrackFolder = '/media/preethamam/BigData/Project MegaCRACK-RoboCRACK/Real World Data/Hybrid Paper/Gaussian Kernel Width Estimation - Synthetic Cracks';
elseif ispc
    synCrackFolder = 'U:\Project MegaCRACK-RoboCRACK\Real World Data\Hybrid Paper\Gaussian Kernel Width Estimation - Synthetic Cracks';
else
    disp('Platform not supported')
end

%{
%% Read Image sets
imgSet    = imageSet(imageFolder, 'recursive');
imgSubSet = datasample(imgSet.ImageLocation, totalSynCracks,'Replace',false);
imgSetSynCrack = imageSet(synCrackFolder, 'recursive');

%}

%% Classifiers
% Combined 100000 unique feature vectors
ANN_classifier_hybrid = 'ZZZ_MdlANN_elastic_hybrid_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
KNN_classifier_hybrid = 'ZZZ_MdlKNN_elastic_hybrid_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
SVM_classifier_hybrid = 'ZZZ_MdlSVM_elastic_hybrid_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';

ANN_classifier_morpho = 'ZZZ_MdlANN_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
KNN_classifier_morpho = 'ZZZ_MdlKNN_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
SVM_classifier_morpho = 'ZZZ_MdlSVM_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';


%--------------------------------------------------------------------------
% Load ANN, KNN and SVM kernels
load (ANN_classifier_hybrid,'net');
load (KNN_classifier_hybrid,'MdlKNN');
load (SVM_classifier_hybrid,'ScoreCSVMModel');

%% Make synthetic examples
if (createSynCracks)
%     createSyntheticCracks(synCrackFolder, imgSubSet, minRadius, maxRadius);
end
  
%% Perform analysis on the synthetic cracks
load ZZZ_MFAT_GaussainKernelSizeVsCrackThickness_SyntheticCracks_PhysicalProps.mat

% Sort structure
T = struct2table(Output); % convert the struct array to a table
sortedT = sortrows(T, 'width_actual_record'); % sort the table by 'DOB'
sortedS = table2struct(sortedT); % change it back to struct array if necessary

% Initialize metric record structure
gaussDiameterFactor = sort([1:0.1:4 2.355]);
metricsRecord = cell(1,length(sortedS));
L = length(sortedS);

% %Before the loop, we need to construct the object. 
WaitMessage = waitbarParfor(L, 'Waitbar', true);

parfor i = 1:L
    %Separnd a message to the object. 
    WaitMessage.Send;

    metricsRecord{i} = gaussWidthLooper_Paper(i, input, synCrackFolder, sortedS, gaussDiameterFactor, ....
                                              MdlKNN, ScoreCSVMModel, net, showPlot);                                        
end
    
%Destroy the object.
WaitMessage.Destroy 



%%
if (gaussWidthLooper == 1)    
    metricsRecord_2mat = cell2mat(metricsRecord(:)');    
    metricsRecord_array = reshape(struct2array(metricsRecord_2mat), 11,[])';    
    metricsRecord_3D = pagetranspose(reshape(metricsRecord_array',[], length(gaussDiameterFactor), L));   
    metricsRecord_3D(any(isnan(metricsRecord_3D), 2), :) = [];
    
    % Save the variables to the MAT file
    save ZZZ_MFAT_GaussainKernelSizeVsCrackThicknessRelation_Variables_ClassiferBased_GaussWidth_Varied.mat
    
else
    metricsRecord_no_nan = cell2mat(metricsRecord');
    metricsRecord_no_nan(any(isnan(metricsRecord_no_nan), 2), :) = [];
    
    % Save the variables to the MAT file
    save ZZZ_MFAT_GaussainKernelSizeVsCrackThicknessRelation_Variables_ClassiferBased_2.mat
end
%}

%% Plot the data
gaussWidthLooper = 0;
if (gaussWidthLooper == 1)
    load ZZZ_MFAT_GaussainKernelSizeVsCrackThicknessRelation_Variables_ClassiferBased_GaussWidth_Varied.mat
    
    gaussWidFact        = metricsRecord_3D(:,2,1);
    crackWidthVector    = reshape(metricsRecord_3D(1,1,:), [],1);         
    
    [X,Y] = meshgrid(gaussWidFact, 1:length(crackWidthVector));
    Z = reshape(metricsRecord_3D(:,11,:), [], 500)';
    
    figure;
    surf(X,Y,Z)
    colormap jet
    xlabel('Gauss Width Factor');
    ylabel('Image Number');
    zlabel('F1 score');
    
    
    figure;
    plot(gaussWidFact', mean(Z,1))
    xlabel('Gauss Width Factor');
    ylabel('F1 score');
    grid on;
    
else
    % Plot the data
    load ZZZ_MFAT_GaussainKernelSizeVsCrackThicknessRelation_Variables_ClassiferBased.mat

    x = cat(1, metricsRecord.crackWidth);
    y = cat(1, metricsRecord.GaussianRadius);

    % y = (2.355 * ((cat(1, metricsRecord.crackWidth)/ 2.355)));

    mdl = fitlm(x,y);

    markerAlpha = 1;
    markerSize = 65;
    fontSize = 26;
    fig_window_size = [100, 100, 1500, 1080];
    figSavePath = ['..\..\results\Hybrid Paper Figs\' 'fig_kernel_crack_width_relation.pdf'];

    figure;
    scatter(x,y, ...
            markerSize,'r','d', 'filled', 'MarkerFaceAlpha', markerAlpha,'MarkerEdgeAlpha', markerAlpha)
    h1 = lsline;
    p2 = polyfit(get(h1,'xdata'), get(h1,'ydata'),1);
    h1(1).Color = 'r';
    h1(1).LineWidth = 2;
    h1(1).LineStyle = '-';
    xlim([0 40])
    ylim([0 50])

    xlabel('Actual Crack Width (pixels)');
    ylabel('Gaussian Filter Diameter (pixels)');
    h = legend('$\mathsf{Data}$',['$\mathsf{Linear \, Fit}$ (' sprintf('$y = %4.4fx + %4.4f, R^2 = %4.4f)$', ...
           p2(1), p2(2), mdl.Rsquared.Ordinary)], 'interpreter','latex',...
           'Location','northwest');
%     set(h,'FontSize',22);
    grid on;
    set(gca,'FontSize', fontSize)
    set(gcf, 'Position',  fig_window_size)

    % export_fig(figSavePath, '-pdf', '-transparent', gcf);
end

%% Sigma range
x = [1, 21.0053]'; % DS 1 = 4.4478 | DS 5 = 24.4188 | DS 7 = 14.2715 | syn = 19.8520
y = 1.1758 .* x + 0.5153;
% y = 1 .* x + 0;
sigmaMinMax = (y / 2.355)

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
statusFclose = fclose('all');
if(statusFclose == 0)
    disp('All files are closed.')
end
Runtime = toc(Start);
disp(Runtime);