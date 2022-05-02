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

#include <owl/owl.h>
#include <optix_device.h>

OPTIX_RAYGEN_PROGRAM(dimsTestRaygenProgram)(){
    uint3 lbounds = optixGetLaunchDimensions();
    uint3 lidx = optixGetLaunchIndex();
    if(lidx.x == 0 && lidx.y == 0 && lidx.z == 0){
        printf("Raygen with size (%d,%d,%d) successful\n", lbounds.x, lbounds.y, lbounds.z);
    }
}
