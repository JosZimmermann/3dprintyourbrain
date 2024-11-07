# smooth_mesh.py

import pymeshlab

# Define input and output paths
input_mesh = '/path/to/your/final_3Dbrain_raw.stl'
output_mesh = '/path/to/your/final_3Dbrain.stl'

# Create a MeshSet object
ms = pymeshlab.MeshSet()

# Load the input mesh
ms.load_new_mesh(input_mesh)

# Calculate the bounding box diagonal for scaling
bbox_diag = ms.current_mesh().bounding_box().diag()

# Calculate the threshold as 1/10000 of the bounding box diagonal
# and ensure it is within the min (0) and max (2.40433) bounds
threshold = min(max(bbox_diag / 10000, 0), 2.40433)

# Apply "Merge Close Vertices" filter with the calculated and bounded threshold
ms.apply_filter('merge_close_vertices', threshold=threshold)

# Apply "ScaleDependent Laplacian Smooth" filter
ms.apply_filter('scaledependent_laplacian_smooth', stepsmoothnum=100, delta=0.1)

# Save the processed mesh
ms.save_current_mesh(output_mesh)
