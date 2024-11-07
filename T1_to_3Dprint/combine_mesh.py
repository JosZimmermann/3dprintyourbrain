import pymeshlab
import sys

# Check if the correct number of arguments is provided
if len(sys.argv) != 4:
    print("Usage: python3 smooth_mesh.py <input_mesh1> <input_mesh2> <output_mesh>")
    sys.exit(1)

# Retrieve the file paths from command-line arguments
initial_mesh_path = sys.argv[1]        # First input mesh (e.g., cortical.stl)
additional_mesh_path = sys.argv[2]     # Second input mesh (e.g., subcortical.stl)
output_mesh_path = sys.argv[3]         # Output mesh path

# Create a MeshSet object
ms = pymeshlab.MeshSet()

# Load the initial mesh (first input mesh)
ms.load_new_mesh(initial_mesh_path)

# Load the additional mesh (second input mesh) and merge it into the MeshSet
ms.load_new_mesh(additional_mesh_path)

# Flatten all the layers (merge them into one mesh)
ms.flatten_visible_layers()

# Apply filters to clean up the merged mesh
ms.apply_filter('remove_duplicate_vertices')       # Remove duplicate vertices
ms.apply_filter('remove_unreferenced_vertices')    # Remove unreferenced vertices
ms.apply_filter('remove_isolated_pieces', mincomponent=0)  # Keep only the largest component

# Save the cleaned, merged mesh as a binary STL
ms.save_current_mesh(output_mesh_path, binary=True)