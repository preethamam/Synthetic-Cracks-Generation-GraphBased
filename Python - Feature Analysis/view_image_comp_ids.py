import numpy as np
from skimage import io
from skimage import io, measure

full_mask_path = "path/to/full_mask.png"
comp_id = 123  # Example component ID to visualize



mask = io.imread(full_mask_path, as_gray=True) > 0.5
component = (measure.label(mask) == comp_id)
io.imsave("preview.png", component.astype(np.uint8)*255)