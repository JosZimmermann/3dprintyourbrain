import nibabel as nib
import nibabel.freesurfer.io as fsio
import numpy as np
import pymeshlab
import os
import sys

# Check for the correct number of arguments
if len(sys.argv) != 4:
    print("Usage: python3 mri2mesh_new.py <input_pial> <input_T1> <output_mesh>")
    sys.exit(1)

# Retrieve file paths and desired length from command-line arguments
input_pial_path = sys.argv[1]         # Path to the input pial (e.g., lh.pial)
input_T1_path = sys.argv[2]         # Path to the input T1 (e.g., T1.mgz)
output_mesh_path = sys.argv[3]        # Path to save the output mesh (e.g., cortical.stl)



def load_and_transform_surface(surface_path, t1_path, output_path):

    # Load the surface (returns vertices in surface space)
    vertices, faces = fsio.read_geometry(surface_path)

    # Load T1.mgz to get the voxel-to-scanner-space affine matrix
    t1_img = nib.load(t1_path)
    affine = t1_img.header.get_vox2ras_tkr()  # matches FreeSurfer's surface space
    #affine = t1_img.affine
    # Convert surface coordinates to homogeneous (N x 4)
    n_vertices = vertices.shape[0]
    vertices_h = np.hstack((vertices, np.ones((n_vertices, 1))))

    # Apply affine: surface RAS → scanner RAS
    transformed_vertices = (affine @ vertices_h.T).T[:, :3]

    # Save mesh via PyMeshLab
    ms = pymeshlab.MeshSet()
    ms.add_mesh(pymeshlab.Mesh(vertex_matrix=transformed_vertices, face_matrix=faces), os.path.basename(surface_path))
    ms.save_current_mesh(output_path)
    print(f"Saved: {output_path}")



