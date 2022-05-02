# OptiXDimsTest

Launch dimensions test for NVIDIA OptiX, as a reproducer for a bug. Uses OWL
but this is not related to / the cause of the bug.

### What is the bug?

Valid ranges for raygen launch dimensions have some bizarre, undocumented
behavior.

[https://raytracing-docs.nvidia.com/optix7/guide/index.html#limits#limits](This
page in the OptiX docs) states that the maximum launch size is x * y * z <= 2**30.
In reality, some sizes below this limit also fail, producing an error like
```
[ 2][       ERROR]: Error launching work to RTX
Optix call (optixLaunch(device->pipeline, lpDD.stream, (CUdeviceptr)lpDD.deviceMemory.get(), lpDD.deviceMemory.sizeInBytes, &lpDD.sbt, dims.x,dims.y,dims.z )) failed with code 7050 (line 206)
```
This is presumably due to the fact that the maximum grid dimension is different
in X and Y (at least on this GPU):
```
Device 0: "NVIDIA GeForce RTX 3080"
  CUDA Driver Version / Runtime Version          11.5 / 11.5
  ...
  Max dimension size of a thread block (x,y,z): (1024, 1024, 64)
  Max dimension size of a grid size    (x,y,z): (2147483647, 65535, 65535)
```

Even more bizarre is the fact that *increasing* the X size can cause a launch
which was "too big" before to start working. See rows 20-23 below.

This is a test program which launches raygen programs for a size specified on
the command line, and a Python script to run this program for all reasonable
combinations of power-of-2 sizes.

### Sample output

Driver Version: 495.46, CUDA Version: 11.5, OptiX headers 7.2,
NVIDIA GeForce RTX 3080

```
Results are shown in powers of 2, e.g. 0 1 2 3 means 1, 2, 4, 8
^: OK, X: failed, .: not tested

z = 0 (1)
   |x                     1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3
y  |  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0
---+---------------------------------------------------------------
 0 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^
 1 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X
 2 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X .
 3 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . .
 4 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . .
 5 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . .
 6 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . .
 7 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . .
 8 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . .
 9 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . . .
10 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . . . .
11 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . . . . .
12 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . . . . . .
13 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . . . . . . .
14 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . . . . . . . .
15 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . . . . . . . . .
16 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . . . . . . . . . .
17 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . . . . . . . . . . .
18 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . . . . . . . . . . . .
19 |  ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ X . . . . . . . . . . . . . . . . . .
20 |  ^ ^ ^ X ^ ^ ^ ^ ^ ^ ^ X . . . . . . . . . . . . . . . . . . .
21 |  ^ ^ X X X ^ ^ ^ ^ ^ X . . . . . . . . . . . . . . . . . . . .
22 |  ^ X X X X X ^ ^ ^ X . . . . . . . . . . . . . . . . . . . . .
23 |  X X X X X X X ^ X . . . . . . . . . . . . . . . . . . . . . .
24 |  X X X X X X X X . . . . . . . . . . . . . . . . . . . . . . .
25 |  X X X X X X X . . . . . . . . . . . . . . . . . . . . . . . .
26 |  X X X X X X . . . . . . . . . . . . . . . . . . . . . . . . .
27 |  X X X X X . . . . . . . . . . . . . . . . . . . . . . . . . .
28 |  X X X X . . . . . . . . . . . . . . . . . . . . . . . . . . .
29 |  X X X . . . . . . . . . . . . . . . . . . . . . . . . . . . .
30 |  X X . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
```

### What are the needed fixes?

1. Update the OptiX documentation to reflect this behavior. At minimum a
statement like "there may be additional restrictions on launch size when the Y
size is large", so the user knows that this is a potential source of issues.
Ideally, document the actual behavior, especially if it is hardware-dependent.
2. Remove the bizarre behavior; support all launches meeting the currently
documented limit of x * y * z <= 2**30 (or a similar suitable limit involving
powers of 2). That is, change the algorithm for assigning the dimensions to
grid size / block size so that the currently unsupported sizes above become
supported.
3. Ideally, create a specific error code for "unsupported / invalid launch
dimensions" to be returned by `optixLaunch` and related functions, so the
developer can narrow down the issue.

### How to reproduce the results above?

Tested on recent Debian but should be compatible with Windows as well, using
an appropriate Windows CMake workflow.

- Make sure you have the `owl` submodule.
- `mkdir build; cd build`
- `cmake -DOptiX_ROOT_DIR=/path/to/your/optix/install ..`
- `make -j`
- `cd ..`
- `python3 autotest.py`
