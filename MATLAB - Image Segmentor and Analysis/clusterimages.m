function [class_index, centroids] = clusterimages (data, k, imagefolders, ...
                                                   folderpath, totalimages, ...
                                                   imtextures, datasetType,...
                                                   clusterImcpyPaste)

% K-means clustering                                                 
[class_index, centroids] = kmeans(data, k, 'Distance', 'sqEuclidean',...
                                  'Replicates', 5);
% Counter flag
cntflag = 1;

% Check if the clustering folder exists, else create new folder
if (clusterImcpyPaste)
    switch datasetType
        case 'training'
            for j = 1:length(imagefolders)
                for i = 1:k
                    if (exist(fullfile(folderpath, [imagefolders{j}, ' Training', ...
                              ' Cluster'], num2str(i)),'dir'))            
                        delete(fullfile(folderpath, [imagefolders{j}, ' Training', ...
                              ' Cluster'], num2str(i),  '*.*'));
                    else
                        mkdir(fullfile(folderpath, [imagefolders{j}, ' Training', ...
                              ' Cluster'], num2str(i)))
                    end
                end
            end

        case 'testing'
            for j = 1:length(imagefolders)
                for i = 1:k
                    if (exist(fullfile(folderpath, [imagefolders{j}, ' Testing', ...
                              ' Cluster'], num2str(i)),'dir'))            
                        delete(fullfile(folderpath, [imagefolders{j}, ' Testing', ...
                              ' Cluster'], num2str(i),  '*.*'));
                    else
                        mkdir(fullfile(folderpath, [imagefolders{j}, ' Testing', ...
                              ' Cluster'], num2str(i)))
                    end
                end
            end

    end
end

% Loop to cluster the images (copy/paste) at respective classes folders
if (clusterImcpyPaste)
    switch datasetType
        case 'training'
            % Image textures filepath
            filepath = {imtextures.filePath};         

            for j = 1:length(imagefolders)                            

                % Copyfile in a loop
                for i = 1:totalimages(j)

                    % File parts
                    [~,name,ext] = fileparts(filepath{cntflag});

                    % Copy files
                    copyfile(filepath{cntflag}, ...
                             fullfile(folderpath, [imagefolders{j}, ' Training', ' Cluster'],...
                             num2str(class_index(cntflag)), [name ext]),'f');

                    % Increment the counter
                    cntflag = cntflag + 1;
                end
            end

        case 'testing'

            % Image textures filepath
            filepath = {imtextures.filePath};         

            for j = 1:length(imagefolders)                            

                % Copyfile in a loop
                for i = 1:totalimages(j)

                    % File parts
                    [~,name,ext] = fileparts(filepath{cntflag});

                    % Copy files
                    copyfile(filepath{cntflag}, ...
                             fullfile(folderpath, [imagefolders{j}, ...
                             ' Testing', ' Cluster'],...
                             num2str(class_index(cntflag)), [name ext]),'f');

                    % Increment the counter
                    cntflag = cntflag + 1;
                end
            end
    end
end
end

   
% end