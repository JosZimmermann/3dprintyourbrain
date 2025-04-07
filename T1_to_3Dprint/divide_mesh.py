import pymeshlab
import sys

# Check for the correct number of arguments
if len(sys.argv) != 4:
    print("Usage: python3 scale_mesh.py <input_mesh> <output_mesh_L> <output_mesh_R>")
    sys.exit(1)

# Retrieve file paths and desired length from command-line arguments
input_mesh_path = sys.argv[1]         # Path to the input mesh (e.g., final_3Dbrain.stl)
output_mesh_path_L = sys.argv[2]        # Path to save the left halfed output mesh (e.g., subcortical_L.stl)
output_mesh_path_R = sys.argv[3]        # Path to save the right halfed output mesh (e.g., subcortical_R.stl)

# Create a MeshSet object
ms = pymeshlab.MeshSet()

# Load the input mesh
ms.load_new_mesh(input_mesh_path)

# Get the Y-axis bounds of the mesh's bounding box
bbox = ms.current_mesh().bounding_box()
current_length = bbox.dim_x()
min_x = bbox.min_coord()[0]
mid_x = min_x + current_length / 2




# ---- SAVE LEFT HALF OF VERTEX ----

# Select vertices on left side
ms.apply_filter('compute_selection_by_condition_per_vertex', condition=f"x < {mid_x}")

# Delete unselected (keep left)
ms.apply_filter('delete_unselected_vertices')

# Save left half
ms.save_current_mesh(output_mesh_path_L, binary=True)




# ---- SAVE RIGHT HALF OF VERTEX ----

# Select vertices on right side
ms.apply_filter('compute_selection_by_condition_per_vertex', condition=f"x > {mid_x}")

# Delete unselected (keep right)
ms.apply_filter('delete_unselected_vertices')

# Save right half
ms.save_current_mesh(output_mesh_path_R, binary=True)



