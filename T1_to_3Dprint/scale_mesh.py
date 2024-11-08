import pymeshlab
import sys

# Check for the correct number of arguments
if len(sys.argv) != 4:
    print("Usage: python3 scale_mesh.py <input_mesh> <output_mesh> <desired_length>")
    sys.exit(1)

# Retrieve file paths and desired length from command-line arguments
input_mesh_path = sys.argv[1]         # Path to the input mesh (e.g., final_3Dbrain.stl)
output_mesh_path = sys.argv[2]        # Path to save the scaled output mesh (e.g., final_3Dbrain_<length>mm.stl)
desired_length = float(sys.argv[3])   # Desired length in mm

# Create a MeshSet object
ms = pymeshlab.MeshSet()

# Load the input mesh
ms.load_new_mesh(input_mesh_path)

# Get the Y-axis bounds of the mesh's bounding box
bounding_box = ms.current_mesh().bounding_box()
current_length = bounding_box.dim_y()
print("current length: " + str(current_length))


# Compute the scale factor to achieve the desired length
scale_factor = desired_length / current_length
print("scale factor: " + str(scale_factor))

# Apply scaling to the mesh
ms.apply_filter('compute_matrix_from_scaling_or_normalization', axisx=scale_factor, uniformflag=True) #scaley=scale_factor, scalez=scale_factor -> not needed if uniformflag

# Save the scaled mesh as a binary STL file
ms.save_current_mesh(output_mesh_path, binary=True)
