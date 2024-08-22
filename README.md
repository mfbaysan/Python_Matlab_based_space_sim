# synthetic-data



## OBJ Data Repair from ShapeNet
Objects from ShapeNet dataset are not watertight manifolds. But this is a requirement for RCS calculation in MatLab. to convert ShapeNet objects to watertight manifold objects do the following:

1. Clone and build the Manifold repository from https://github.com/hjwdzh/Manifold as described in their repo.

2. Get back to this repo and install Python requirements using the requirements.txt file

3. Open repair_obj.py and change the simplify_exec_path to the path of 'simplify' executable that is created after building Manifold.

4. Change other paths in the script as described in the comments.

5. Run repair_obj.py and see the magic happen.
