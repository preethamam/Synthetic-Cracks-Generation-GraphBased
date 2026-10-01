function imbincountstack = textureclass_bincount (totalimages,imresolution, ...
                                                  class_index,pixels_normfactor, lowTextureonTop)


    % Convert the resolution to mega pixels
    imMP            = round(imresolution(:,1) .* imresolution(:,2) / pixels_normfactor);

    % Get the zeros indices
    zeroindx        = imMP == 0;

    % Replace all zeros by 1
    imMP(zeroindx)  = 1;

    % Populate the array to holds mega pixels and class labels
    indxstartflag = 1;
    indxendflag = 0;
    for i = 1:numel(totalimages)

        % Initialize start/end counter flags
        indxstart = indxstartflag;
        indxend   = indxendflag + totalimages(i);

        % Grab the indices
        imMPindx{i}     = imMP(indxstart:indxend); 
        imclass_indx{i} = class_index(indxstart:indxend);

        % Find the unique image resolution (mega pixels)
        uniqueMP{i}     = sort(unique(imMPindx{i}));

        % Update counte flags
        indxstartflag = indxend + 1;
        indxendflag   = indxend;
    end

    for j = 1:length(imMPindx)
        uMPmat   = uniqueMP{j};
        imMpmat  = imMPindx{j};
        imclmat  = imclass_indx{j};

        % Stack all the indices for different classes
        for i = 1:numel(uMPmat)
            dummy{i}  = find(imMpmat == uMPmat(i));
            mpindx = dummy{i};
            clsidx{i} = imclmat(mpindx);
            getbincnt = clsidx{i};
            bncount{i} = hist(getbincnt, max(class_index));
            bb = bncount{i};
            bincnt(i,:) = [uMPmat(i) bb];
        end
        
        if (lowTextureonTop == 1)
            bincnt(:,[2 3]) = bincnt(:,flip([2,3]));
        end
            imbincountstack{j}   = bincnt;

        % Clear duplicates
        clear bincnt 
    end
end