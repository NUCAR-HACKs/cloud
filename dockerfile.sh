#!/bin/bash

#MPI Install

if ! type "mpicc" > /dev/null; then
  echo "**** first env"
  sudo env
  echo "**** second env"
  sudo -E env
  sudo apt-get install build-essential -y
  sudo apt-get install wget -y
  wget https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.3.tar.gz
  sudo tar -xvzf openmpi-3.1.3.tar.gz
  sudo mv openmpi-3.1.3 /usr/lib/
  cd /usr/lib/openmpi-3.1.3
  sudo -E ./configure --prefix=/usr/lib/openmpi-3.1.3
  sudo -E make all install
  export PATH=/usr/lib/openmpi-3.1.3/bin:$PATH
  echo "**** after install"
  type "mpicc" > /dev/null
fi

echo "**** mpi test"
which mpicc
# Install dependencies from Debian package manager
# Removed mpi related packages
sudo apt-get update -y &&
sudo apt-get upgrade -y &&
sudo apt-get install -y cmake python-setuptools python3-pip wget git openssh-server openssh-client gfortran g++ libhdf5-serial-dev libhdf5-openmpi-dev imagemagick
sudo apt-get autoremove

# Environmental Vars
#export FC=/usr/bin/mpif90
#export CC=/usr/bin/mpicc
#export CXX=/usr/bin/mpicxx
#export PATH=/opt/openmc/bin:/opt/NJOY2016/build:$PATH
#export LD_LIBRARY_PATH=/opt/openmc/lib:$LD_LIBRARY_PATH
#export OPENMC_CROSS_SECTIONS=/root/nndc_hdf5/cross_sections.xml
#export OPENMC_MULTIPOLE_LIBRARY=/root/WMP_Library
#export OPENMC_ENDF_DATA=/root/endf-b-vii.1
cd ~/
source env.sh
echo "***** env"
env

# Update system-provided pip
echo "**** pip test"
pip --version
pip3 --version
sudo pip3 install --upgrade pip

sudo pip install six NumPy SciPy pandas h5py Matplotlib uncertainties lxml

sudo rm -rf /opt/NJOY2016 /opt/openmc

# Clone and install NJOY2016
sudo mkdir /opt/NJOY2016
sudo git clone https://github.com/njoy/NJOY2016 /opt/NJOY2016

cd /opt/NJOY2016

sudo mkdir build 
cd build 
sudo -E cmake -Dstatic=on -DCMAKE_CXX_COMPILER=/usr/bin/mpicxx -DCMAKE_CC_COMPILER=/usr/bin/mpicc -DCMAKE_FC_COMPILER=/usr/bin/mpif90 ..
sudo -E make 2>/dev/null 
sudo -E make install

# Clone and install OpenMC
sudo mkdir /opt/openmc
sudo git clone https://github.com/mit-crpg/openmc.git /opt/openmc
cd /opt/openmc
sudo git checkout master
sudo mkdir -p build
cd build
sudo -E cmake -Dopenmp=on -Doptimize=on -DHDF5_PREFER_PARALLEL=on -DCMAKE_CXX_COMPILER=/usr/bin/mpicxx -DCMAKE_CC_COMPILER=/usr/bin/mpicc -DCMAKE_FC_COMPILER=/usr/bin/mpif90 .. 
sudo -E make 
sudo -E make install
cd ..

# Download cross sections (NNDC and WMP) and ENDF data needed by test suite
sudo wget -O nndc_hdf5.tar.xz $(cat /opt/openmc/.travis.yml | grep anl.box | awk '{print $2}')
sudo tar xJvf nndc_hdf5.tar.xz
export OPENMC_CROSS_SECTIONS=/opt/openmc/nndc_hdf5/cross_sections.xml
sudo git clone --branch=master git://github.com/smharper/windowed_multipole_library.git wmp_lib
sudo tar xzvf wmp_lib/multipole_lib.tar.gz
export OPENMC_MULTIPOLE_LIBRARY=/opt/openmc/multipole_lib

cd /opt/openmc/examples/xml/pincell
                                                                                                                                                                                                

#$ -cwd
#$ -j y
#$ -S /bin/bash
#
# mpiexec -np 1 --bind-to socket -x OPENMC_MULTIPOLE_LIBRARY -x OPENMC_CROSS_SECTIONS --allow-run-as-root openmc --threads 128

ls
pwd
# /usr/lib64/openmpi-3.1.3/bin/mpiexec -np $NSLOTS /shared/home/ccuser/a.out
/usr/bin/mpiexec -np $NSLOTS -x OPENMC_MULTIPOLE_LIBRARY -x OPENMC_CROSS_SECTIONS openmc
