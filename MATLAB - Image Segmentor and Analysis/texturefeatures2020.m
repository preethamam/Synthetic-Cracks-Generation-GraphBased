function [IM_texture_info, totalimages] = texturefeatures2020 (input)

%//%************************************************************************%
%//%*                     Project RoboCRACK      					       *%
%//%*                                                                      *%
%//%*       Modified and optimized in November 2020 by                     *%
%//%*       Original Author Name: Preetham Manjunatha                      *%
%//%*                    Ph.D in Civil Engineering                         *%
%//%*                    M.S in Computer Science                           *%
%//%*                    M.S in Electrical Engineering                     *%
%//%*                    M.S in Civil Engineering                          *%
%//%*       Modified by: Aniketh Manjunath                                 *%
%//%*                    M.S in Computer Science                           *%
%//%************************************************************************%
%//%*             Viterbi School of Engineering,                           *%
%//%*             Sonny Astani Dept. of Civil Engineering,                 *%
%//%*             University of Southern california,                       *%
%//%*             Los Angeles, California.                                 *%
%//%************************************************************************%

% Iniliaze the image details struct
IM_texture_info = [];
IM_texture_info_array = [];  

% Image info. structure counter
totalimages = zeros(length(input.originaldata_folders),1);
imgCount_index = [0,input.imgCount];
idx_range = cumsum(imgCount_index);
    
for i = 1 : length(input.originaldata_folders)
    
    % Total images
    totalimages(i) = input.imgCount(i);
    
    WaitMessage = waitbarParfor(totalimages(i), 'Waitbar', true);
    
    idx = idx_range(i)+1 : idx_range(i+1);           
        
    % For all training images
        parfor j = idx
            
            pathstr =[]; name = []; ext = [];
            ImageID =[]; Feature_Vector =[]; 
            
            %Send a message to the object. 
            WaitMessage.Send;
            
            %----------------------------------------------------------
            % Image parameters
            %----------------------------------------------------------
            %
            switch input.datasetType
                case 'training'
                    % File parts
                    [pathstr,name,ext] = ...
                    fileparts(input.imgPartitionStruct.trainingSets(1,k(i)).ImageLocation{j});

                    % Read image
                    filePath = input.imgPartitionStruct.trainingSets(1,k(i)).ImageLocation{j};
                    
                case 'testing'
                    if (i <= input.noncrack_crack_foldercount(1))
                        % Read image
                        ImageID = fullfile(input.crack(j).folder, input.crack(j).name);

                        % File parts
                        [filePath,name,ext] = fileparts(ImageID);

                    else
                        % Read image
                        ImageID = fullfile(input.non_crack(j).folder, input.non_crack(j).name);

                        % File parts
                        [filePath,name,ext] = fileparts(ImageID);

                    end
                    
                                    
            end
            [imheight, imwidth, imbytesppix, Ioriginal, Igray] ...
                    = imconversion2gray (ImageID, input.gpuarray, input.resizeImage, ...
                        input.maxImageResizePixels, input.resizeImageSize, input.resizeImageSizeScale, input.contrast_type)

            
            %  SFTA algorithm (Segmentation-based Fractal Texture
            %  Analysis) callback
            % Laws filter callback
            switch input.texturefilter_type
                case 'sfta'
                    Feature_Vector  = sfta( Igray, 4 );
                case 'laws'
                    Feature_Vector  = laws_filter(Igray, input.normtype,...
                                                  input.windowsize);
                case 'glcm'
                    Feature_Vector = glcm_textureFilter(Igray, input.windowsize);
            end


            % Populate image information structure
            IM_texture_info(j).name     = name;
            IM_texture_info(j).fileExt  = ext;
            IM_texture_info(j).filePath = filePath;

            % Image channel type
            if (imbytesppix > 1)
                IM_texture_info(j).imageType = 'RGB';
            else
                IM_texture_info(j).imageType = 'Grayscale';
            end

            % Feature image resolution
            IM_texture_info(j).imageResoution = [imwidth, imheight];

            % Feature vector
            IM_texture_info(j).featureVec     = Feature_Vector;            
            
        end
        
    % Remove empty rows
%     IM_texture_info_array = [IM_texture_info_array, IM_texture_info];
%     IM_texture_info = [];
    
    %Destroy the object.
    WaitMessage.Destroy
    
end

end
   

