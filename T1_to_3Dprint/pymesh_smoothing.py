import pymeshlab
import sys

# Ensure the script receives the required arguments
if len(sys.argv) != 3:
    print("Usage: python3 smooth_mesh.py <input_mesh> <output_mesh>")
    sys.exit(1)

# Retrieve the file paths from command-line arguments
input_mesh = sys.argv[1]   # Input mesh file path
output_mesh = sys.argv[2]  # Output mesh file path


# Create a MeshSet object
ms = pymeshlab.MeshSet()

# Load the input mesh
ms.load_new_mesh(input_mesh)

# Calculate the bounding box diagonal for scaling
bbox_diag = ms.current_mesh().bounding_box().diagonal()

# Calculate the threshold as 1/10000 of the bounding box diagonal
# and ensure it is within the min (0) and max (2.40433) bounds
delta = pymeshlab.PercentageValue(min(max(bbox_diag / 10000, 0), 2.40433))

# Apply "Merge Close Vertices" filter with the calculated and bounded threshold
ms.apply_filter('meshing_merge_close_vertices', threshold=threshold)
# default is as above

# Apply "ScaleDependent Laplacian Smooth" filter
delta = pymeshlab.PercentageValue(0.1)
ms.apply_filter('apply_coord_laplacian_smoothing_scale_dependent', stepsmoothnum=100, delta=delta)

# Save the processed mesh
ms.save_current_mesh(output_mesh)
