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

import sys

if sys.version_info.major < 3:
    print('This is a python3 script')
    sys.exit(-1)

import subprocess

progname = './build/OptiXDimsTest'

def printusage():
    print('Usage: python3 autotest.py [2D or 3D]')
    sys.exit(-1)

threed = False
if len(sys.argv) == 2:
    m = sys.argv[1]
    if m in {'threed', '3d', '3D'}:
        threed = True
        print('3D mode')
    elif m in {'twod', '2d', '2D'}:
        print('2D mode')
    else:
        printusage()
elif len(sys.argv) == 1:
    print('2D mode')
else:
    printusage()

zrange = list(range(31 if threed else 1))

zres = []
for zz in zrange:
    yres = []
    for yy in range(31):
        xres = []
        rangefailed = False
        for xx in range(31):
            if rangefailed or xx + yy + zz > 31:
                xres.append('.')
                continue
            x = 1 << xx
            y = 1 << yy
            z = 1 << zz
            print('{} x {} x {}'.format(x, y, z))
            ret = subprocess.run([progname, str(x), str(y), str(z)])
            if ret.returncode < 0:
                print('failed with code {}'.format(ret.returncode))
                sys.exit(-1)
            elif ret.returncode == 0:
                print('...succeeded')
                xres.append('^')
            else:
                print('...failed')
                xres.append('X')
                #rangefailed = True
        yres.append(xres)
    zres.append(yres)

print('\n\nResults are shown in powers of 2, e.g. 0 1 2 3 means 1, 2, 4, 8')
print('^: OK, X: failed, .: not tested')

for (zz, yres) in zip(zrange, zres):
    horizline = '---+---------------------------------------------------------------'
    print('\nz = {} ({})'.format(zz, 1<<zz))
    print('   |x', end='')
    for i in range(31):
        print((' {:2d}'.format(i))[0:2], end='')
    print('\ny  | ', end='')
    for i in range(31):
        print(' {}'.format(i%10), end='')
    print('\n' + horizline)
    for (yy, xres) in zip(range(31), yres):
        print('{:2d} | '.format(yy), end='')
        for r in xres:
            print(' {}'.format(r), end='')
        print('')
