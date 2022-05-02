// ======================================================================== //
// Copyright 2022 Louis Pisha                                               //
//                                                                          //
// Licensed under the Apache License, Version 2.0 (the "License");          //
// you may not use this file except in compliance with the License.         //
// You may obtain a copy of the License at                                  //
//                                                                          //
//     http://www.apache.org/licenses/LICENSE-2.0                           //
//                                                                          //
// Unless required by applicable law or agreed to in writing, software      //
// distributed under the License is distributed on an "AS IS" BASIS,        //
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. //
// See the License for the specific language governing permissions and      //
// limitations under the License.                                           //
// ======================================================================== //

#include <iostream>
#include "owl/owl.h"

struct DimsTestRaygenData {
    uint32_t dummy;
};

int32_t gpu_number = 0;

extern "C" char deviceCode_ptx[];

int main(int argc, char **argv){
    if(argc != 4){
        std::cout << "Usage: ./OptiXDimsTest X Y Z\nwhere X, Y, Z are positive integers representing the OptiX launch dimensions\n";
        return -1;
    }
    int x, y, z;
    char *endx, *endy, *endz;
    x = strtol(argv[1], &endx, 0);
    y = strtol(argv[2], &endy, 0);
    z = strtol(argv[3], &endz, 0);
    if(x <= 0 || y <= 0 || z <= 0 || *endx != 0 || *endy != 0 || *endz != 0){
        std::cout << "Invalid arguments\n";
        return -1;
    }
    
    OWLContext owlContext = owlContextCreate(&gpu_number, 1);
    OWLModule owlModule = owlModuleCreate(owlContext, deviceCode_ptx);
    OWLVarDecl dimsTestRaygenDataTypeDecl[] = {
        {"dummy", OWL_UINT, OWL_OFFSETOF(DimsTestRaygenData, dummy)},
        {}
    };
    OWLRayGen dimsTestRaygen = owlRayGenCreate(owlContext, owlModule, "dimsTestRaygenProgram",
        sizeof(DimsTestRaygenData), dimsTestRaygenDataTypeDecl, -1);
    owlBuildPrograms(owlContext);
    owlBuildPipeline(owlContext);
    owlRayGenSet1ui(dimsTestRaygen, "dummy", 12345);
    owlBuildSBT(owlContext);
    owlRayGenLaunch3D(dimsTestRaygen, x, y, z);
    cudaError_t err = cudaDeviceSynchronize();
    if(err != cudaSuccess){
        std::cout << "Sync failed with error " << (int)err << "\n";
        return 1;
    }
    return 0;
}
