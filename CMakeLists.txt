# ======================================================================== #
# Copyright 2022 Louis Pisha                                               #
#                                                                          #
# Licensed under the Apache License, Version 2.0 (the "License");          #
# you may not use this file except in compliance with the License.         #
# You may obtain a copy of the License at                                  #
#                                                                          #
#     http://www.apache.org/licenses/LICENSE-2.0                           #
#                                                                          #
# Unless required by applicable law or agreed to in writing, software      #
# distributed under the License is distributed on an "AS IS" BASIS,        #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. #
# See the License for the specific language governing permissions and      #
# limitations under the License.                                           #
# ======================================================================== #

cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

set(BUILD_TYPE_INTERNAL RelWithDebInfo) # Debug, RelWithDebInfo, Release

set(CMAKE_BUILD_TYPE ${BUILD_TYPE_INTERNAL})
set(CMAKE_CONFIGURATION_TYPES ${CMAKE_BUILD_TYPE} CACHE STRING "" FORCE) # Only allow Visual Studio to generate the correct build type (not default to Debug)

project(Space3D-GPU LANGUAGES C CXX CUDA)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CUDA_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT OptiX_ROOT_DIR)
    message(FATAL_ERROR "Please set OptiX_ROOT_DIR to the path to your OptiX install")
endif()

add_subdirectory(owl EXCLUDE_FROM_ALL)

embed_ptx(
    OUTPUT_TARGET OptiXDimsTest-ptx
    PTX_LINK_LIBRARIES owl::owl
    SOURCES deviceCode.cu
)

add_executable(OptiXDimsTest OptiXDimsTest.cu)
target_link_libraries(OptiXDimsTest PRIVATE owl::owl OptiXDimsTest-ptx)
