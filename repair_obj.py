import trimesh
import point_cloud_utils as pcu
import subprocess
import os
from pathlib import Path

Path("data/tmp/watertight").mkdir(parents=True, exist_ok=True)
Path('data/tmp/simplified' ).mkdir(parents=True, exist_ok=True)

simplify_exec_path = '/usr/local/src/Manifold/build/simplify'   # Where the 'simplify' executable is located

rootdir = '/usr/local/src/actlabs-data/MockDataset_100'         # Location of non-manifold OBJ files
watertight_obj_dir_path = 'data/tmp/watertight'                 # Keep this as it is
simplified_obj_dir_path = 'data/tmp/simplified'                 # Keep this as it is
stl_dir_path = '/usr/local/src/actlabs-data/watertight-stl'     # Where you want to save your manifold stl files

object_id = [f for f in os.listdir(rootdir) if not f.startswith('.')]
count = 0

for subdir, dirs, files in os.walk(rootdir):
    for file in files:
        if file.endswith('.obj'):
            id = object_id[count]
            obj_path = os.path.join(subdir, file)
            watertight_obj_path = os.path.join(watertight_obj_dir_path, file)
            simplified_obj_path = os.path.join(simplified_obj_dir_path, file)
            stl_path = os.path.join(stl_dir_path, id + '.stl')
            
            v, f = pcu.load_mesh_vf(obj_path)
            resolution = 20_000
            vw, fw = pcu.make_mesh_watertight(v, f, resolution)
            repaired_mesh = trimesh.Trimesh(vertices=vw, faces=fw)
            repaired_mesh.export(watertight_obj_path)

            result = subprocess.run([simplify_exec_path, "-i", watertight_obj_path, "-o", simplified_obj_path, "-m", "-r", "0.02"], check=True)
            if result.returncode != 0:
                count += 1
                continue
            
            mesh = trimesh.load(simplified_obj_path)
            if mesh.is_watertight:
                mesh.export(stl_path)

            os.remove(watertight_obj_path)
            os.remove(simplified_obj_path)
            count += 1
