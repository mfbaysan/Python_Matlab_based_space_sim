import numpy as np
import math
from stl import mesh as stl_mesh
import os
import matlab.engine
import scipy.io
import torch
import trimesh




# scaling

# my_mesh = mesh.Mesh.from_file('wheel.stl')
# my_mesh.vectors *= 5                                # Scale mesh to 5 times bigger
# my_mesh.rotate([0.5, 0.0, 0.0], math.radians(90))   # Rotate mesh 90° on x axis
# my_mesh.save('scaled_wheel.stl')


def calculate_bounding_box(mesh_data):

    min_values = np.min(mesh_data.vectors.reshape((-1, 3)), axis=0)
    max_values = np.max(mesh_data.vectors.reshape((-1, 3)), axis=0)

    object_bounding_box = {
        'min_x': min_values[0],
        'max_x': max_values[0],
        'min_y': min_values[1],
        'max_y': max_values[1],
        'min_z': min_values[2],
        'max_z': max_values[2]
    }

    return object_bounding_box


def calculate_dimensions(bounding_box):
    min_x, max_x = bounding_box['min_x'], bounding_box['max_x']
    min_y, max_y = bounding_box['min_y'], bounding_box['max_y']
    min_z, max_z = bounding_box['min_z'], bounding_box['max_z']

    dx = max_x - min_x
    dy = max_y - min_y
    dz = max_z - min_z

    object_dimensions = {
        'x': dx,
        'y': dy,
        'z': dz
    }

    return object_dimensions


def calculate_diagonal(bounding_box):
    min_x, max_x = bounding_box['min_x'], bounding_box['max_x']
    min_y, max_y = bounding_box['min_y'], bounding_box['max_y']
    min_z, max_z = bounding_box['min_z'], bounding_box['max_z']

    dx = max_x - min_x
    dy = max_y - min_y
    dz = max_z - min_z

    diagonal = math.sqrt(dx ** 2 + dy ** 2 + dz ** 2)
    return diagonal


def trimesh_to_mesh(tri_mesh):
    vertices = tri_mesh.vertices
    faces = tri_mesh.faces
    mesh = stl_mesh.Mesh(np.zeros(len(faces), dtype=stl_mesh.Mesh.dtype))
    for i, f in enumerate(faces):
        for j in range(3):
            mesh.vectors[i][j] = vertices[f[j]]
    return mesh


def scale_mesh(stl_file_path, scaling_factor):
    # Load the original mesh
    original_mesh = trimesh.load(stl_file_path)

    scaled_mesh = original_mesh.apply_scale(scaling_factor)

    return trimesh_to_mesh(scaled_mesh)


def run_simulation(obj_rcs, obj_directory, mat_eng, scale_factor):

    size = calculate_diagonal(calculate_bounding_box(scale_mesh(obj_directory, scale_factor)))
    obj_dims = calculate_dimensions(calculate_bounding_box(scale_mesh(obj_directory, scale_factor)))
    print(obj_rcs)
    vals = mat_eng.runSimulation(obj_rcs, obj_dims)
    vals['size'] = size

    #radar_return, starting_position, end_position, random_speed
    return vals #radar_return, starting_position, end_position, random_speed, size


def find_stl_and_rcs(class_path, rcs_path):

    class_name = os.path.splitext(os.path.basename(class_path))[0]

    mat_eng = matlab.engine.start_matlab()

    # Iterate over each folder under path1
    for object_id in os.listdir(class_path):
        folder_stl = os.path.join(class_path, object_id)

        stl_name = object_id + ".stl"
        stl_path = os.path.join(folder_stl, stl_name)

        # Check if the item under path1 is a folder
        if os.path.isdir(folder_stl):
            # Search for a file with the same name under path2
            mat_name = object_id + ".mat"
            mat_path = os.path.join(rcs_path, mat_name)
            if os.path.isfile(mat_path):
                mat = scipy.io.loadmat(mat_path)
                for i in range(1000):
                    scale_factor = 1
                    radar_return, starting_position, end_position, random_speed, size = run_simulation(mat_path, stl_path, mat_eng, scale_factor)
                    trial_id = f"{class_name}-{object_id}-{i}"  # consisting on object_id + class + trialnum
                    new_data_row = {'trial_id': trial_id, 'radar_return': radar_return,
                                    'starting_position': starting_position, 'end_position': end_position,
                                    'random_speed': random_speed, 'size': size, 'object_id': object_id, 'class': class_name}
                    savedir = 'D:\ShapeNet\data_bench'
                    savename = f'{savedir}\\{trial_id}.pt' #change in linux

                    torch.save(new_data_row, savename)
                    print(f'{savename} is saved')

    mat_eng.quit()


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Model trainer")
    parser.add_argument("--directory", type=str)
    parser.add_argument("--save_loc", type=str)
    parser.add_argument("--start_index", type=int)
    parser.add_argument("--end_index", type=int)

    args = parser.parse_args()
    rcs_files = '/dss/dsshome1/03/ge26xih2/sim/codes/rcs_files'

    print("Run sim for: ", args.directory, args.save_loc)
    find_stl_and_rcs(args.directory, rcs_files, args.save_loc, args.start_index, args.end_index)





directory = 'D:\ShapeNet\shapenet-watertight\Bench_100'
rcs_files = 'D:\ShapeNet\\rcs_files'




