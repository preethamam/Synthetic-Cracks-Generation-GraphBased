function feature_vector  = laws_filter(imageG, normtype, windowsize)

% Laws multi-channels
filters{1} = [ 1 4 6 4 1 ];       % level
filters{2} = [-1 -2 0 2 1];       % edge
filters{3} = [-1 0 2 0 -1];       % spot
filters{4} = [1 -4 6 -4 1];       % ripple
filters{5} = [-1 2 0 -2 1];       % wave

% Energy kernel
energy_h = ones(windowsize, windowsize);

% Feature vector initialization
feature_vector = zeros(1, size(filters,2) * size(filters,2));
counter        = 1;
        
% Main loop to extract the features
    for i = 1:size(filters,2)
        for j = 1:size(filters,2)

            % Form 5x5 tensors
            tensor     = filters{i}' * filters{j};

            % Create tensor filtered image
            filtered2D = imfilter(imageG, tensor, 'conv', 'replicate');

            % Find the energy of the tensor filtered image
            energy2D   = imfilter(filtered2D.^2, energy_h, 'conv', 'replicate');

            % Find a unique scalar for energy matrix (such as norm or others)
            switch normtype
                case 'L1'
                    feature_vector (counter) = norm (energy2D , 1);          % L1 norm
                case 'L2'
                    feature_vector (counter) = norm (energy2D , 2);          % L2 norm   
                case 'infinity'                
                    feature_vector (counter) = norm (energy2D , 'Inf');      % infinity norm
                case 'frobenius'
                    feature_vector (counter) = norm (energy2D , 'fro');      % Frobenius norm
            end

            % Counter to index vector
            counter = counter + 1;           
        end
    end
    
end