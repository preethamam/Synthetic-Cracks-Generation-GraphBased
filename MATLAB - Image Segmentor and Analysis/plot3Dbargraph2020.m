function plot3Dbargraph2020 (input, str, width)

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

    % Plot the 3D bar graph
    load (input.matFilename, 'imtextures', 'totalimages',...
          'class_labels');

    % Concatenate the image resolution
    imresolution    = cat(1,imtextures.imageResoution);

    % Texture class bin count / mega pixel
    imbincountstack = textureclass_bincount (totalimages, imresolution, ...
        class_labels, input.pixels_normfactor, input.lowTextureonTop);

    % Plot 3D graph
    hFig = figure;
    for k = 1:length(imbincountstack)
        crackclass = imbincountstack{k};
        if (size(crackclass,1) == 1)
            crackclassnew(1,:) = crackclass(1,:);
            crackclassnew(2,:) = [crackclass(1,1)+1, zeros(1,length(crackclass(1, 2:end)))];
        else
            crackclassnew = crackclass;
        end
        
        z = crackclassnew(:,2:end);
        h = bar3(crackclassnew(:, 1), crackclassnew(:, 2:end),width,'stacked');   
        hold on;
       for j=1:length(h)
          set(h(j),'xdata',get(h(j),'xdata')+k-1);
          set(h(j),'FaceAlpha',input.alpha)
%           set(h(j),'LineWidth',1.5)
       end
              
       % If crackclass has only one row then pad with zero and hide zero
       % bar graph
       if (size(crackclass,1) == 1)
           for i = 1:numel(h)
              index = logical(kron(z(:, i) == 0, ones(6, 1)));
              zData = get(h(i), 'ZData');
              zData(index, :) = nan;
              set(h(i), 'ZData', zData);
           end
       end
       
       crackclassnew = [];
    end

    set(gca, 'PlotBoxAspectRatioMode','auto')
%     pbaspect([0.5 0.2 0.3])
    set(gca, 'XTickLabel',str, 'XTick', 1:numel(str), 'FontSize', 20, 'LineWidth', 3) %, ...
%     set(gca, 'YTickLabel','auto', 'YTick', 'auto',...
%              'FontSize', 20, 'LineWidth', 3)
%     set(gca, 'XTickLabel',str, 'XTick', 1:numel(str), ...           
%              'FontSize', 20, 'LineWidth', 3)
    ylabel ('Image Resolution (kilo pixels)', 'FontSize', 20)
    zlabel ('Number of Images', 'FontSize', 20)
    if (input.lowTextureonTop == 1)
        legend ('High Texture','Low Texture','Location','NorthEast');
    else
        legend ('Low Texture','High Texture','Location','NorthEast');
    end
    
    
    axis tight; 
    hold off
    hYLabel = get(gca,'YLabel');
    set(hYLabel,'rotation',-18,'VerticalAlignment','middle')
    set(groot,'DefaultFigureColormap', prism)

    % resize the figure window
    set(hFig, 'units','normalized','outerposition',[0 0 1 1])

    % Export figure to some format
    [~,name,~] = fileparts(input.matFilename);
    
    % Export figure
%     export_fig(fullfile(input.plot_folder_location, [name, '.pdf']),...
%         '-pdf', '-transparent', gcf);
    
end