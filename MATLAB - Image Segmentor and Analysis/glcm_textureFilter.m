function feature_vector  = glcm_textureFilter(imageG, offset)

%//%************************************************************************%
%//%*                     Project RoboCRACK      					       *%
%//%*                                                                      *%
%//%*       Developed in November 2020 by                                  *%
%//%*       Original Author Name: Aniketh Manjunath                        *%
%//%*                    M.S in Computer Science                           *%
%//%************************************************************************%
%//%*             Viterbi School of Engineering,                           *%
%//%*             Sonny Astani Dept. of Civil Engineering,                 *%
%//%*             University of Southern california,                       *%
%//%*             Los Angeles, California.                                 *%
%//%************************************************************************%

% glcm_texture Funtion that returns GLCM texture properties as a feature
% vector for a given grayscale image.
% Returns:
%   feature vector is a (4 x 1) vector of GLCM properties - contrast,
%   correlation, energy and homogeneity.
% Parameters:
%   imageG is a (m x n) matrix representing a grayscale image of m rows and
%   n cols.
%   offset is a parameter used to define the window size for GLCM matrix
%   computation.


% Feature vector initialization
% 4 GLCM Properties - Contrast, Correlation, Energy, Homogeneity
feature_vector = zeros(1, 4);

if size(imageG, 2) > 512 && size(imageG, 1) > 512
    % Center crop image to 512 x 512
    x_cent = size(imageG, 2) / 2;
    y_cent = size(imageG, 1) / 2;
    size_of_cropped_img = 512;

    xmin = x_cent - size_of_cropped_img / 2;
    ymin = y_cent - size_of_cropped_img / 2;

    imageG_cropped = imcrop(imageG,[xmin ymin size_of_cropped_img size_of_cropped_img]);
    
    % Compute GLCM matrix for given grayscale image
    glcm = graycomatrix(imageG_cropped, 'Offset',[0 offset], 'Symmetric',true, 'NumLevels', 256);
else
    % Compute GLCM matrix for given grayscale image
    glcm = graycomatrix(imageG, 'Offset',[0 offset], 'Symmetric',true, 'NumLevels', 256);
end

% Extract GLCM propertires
stats = graycoprops(glcm, {'all'});

% Return the feature vector containing GLCM properties
feature_vector(1, 1) = stats.Contrast;
feature_vector(1, 2) = stats.Correlation;
feature_vector(1, 2) = stats.Energy;
feature_vector(1, 3) = stats.Homogeneity;

% Replace NaN with -1
feature_vector(isnan(feature_vector)) = -1;