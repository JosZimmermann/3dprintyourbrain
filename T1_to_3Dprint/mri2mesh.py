import nibabel.freesurfer.io as fsio
import pymeshlab
import sys
import numpy as np

# Check for the correct number of arguments
if len(sys.argv) != 3:
    print("Usage: python3 mri2mesh.py <input_pial> <output_mesh>")
    sys.exit(1)

# Retrieve file paths and desired length from command-line arguments
input_pial_path = sys.argv[1]         # Path to the input pial (e.g., lh.pial)
output_mesh_path = sys.argv[2]        # Path to save the output mesh (e.g., cortical.stl)

# Step 1: Read the FreeSurfer .pial file (returns vertices and faces)
vertices, faces = fsio.read_geometry(input_pial_path)

# Step 2: Convert faces to triangles if needed (should be already)
faces = faces.astype(np.int32)

# Step 3: Create a MeshSet and add the mesh
ms = pymeshlab.MeshSet()

# Add mesh to MeshSet
ms.add_mesh(pymeshlab.Mesh(vertex_matrix=vertices, face_matrix=faces), "lh_pial")


# Step 4: Save as STL
ms.save_current_mesh(output_mesh_path)


