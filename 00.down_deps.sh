!/bin/bash

# Clean up from last install
sudo rm -rf /opt/NJOY2016 /opt/openmc
cd /shared/home/ccuser

export PATH=/shared/home/ccuser/bin:/shared/home/ccuser/.local/bin:/sched/sge/sge-2011.11/bin/linux-x64:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/opt/cycle/jetpack/bin:$PATH

# Removed mpi related packages
sudo apt-get update -y &&
sudo apt-get upgrade -y &&
sudo apt-get install -y cmake sudo openmpi-bin libopenmpi-dev python-setuptools python3-pip wget git openssh-server openssh-client gfortran g++ libhdf5-serial-dev libhdf5-openmpi-dev imagemagick
sudo apt-get autoremove

# Update system-provided pip
sudo pip3 install --upgrade pip
sudo pip install six NumPy SciPy pandas h5py Matplotlib uncertainties lxml

export FC=/usr/bin/mpif90
export CC=/usr/bin/mpicc
export CXX=/usr/bin/mpicxx

# Clone and install NJOY2016
sudo mkdir /opt/NJOY2016
sudo git clone https://github.com/njoy/NJOY2016 /opt/NJOY2016
cd /opt/NJOY2016
sudo mkdir build
cd build
sudo -E cmake -Dstatic=on ..
sudo -E make 2>/dev/null
sudo -E make install

# Clone and install OpenMC
sudo mkdir /opt/openmc
sudo git clone https://github.com/mit-crpg/openmc.git /opt/openmc
cd /opt/openmc
sudo git checkout tags/0.10.0
sudo mkdir -p build
cd build
sudo -E cmake -Dopenmp=on -Doptimize=on -DHDF5_PREFER_PARALLEL=on ..
sudo -E make
sudo -E make install
cd ..

# Download cross sections (NNDC and WMP) and ENDF data needed by test suite
sudo wget -O nndc_hdf5.tar.xz https://anl.box.com/shared/static/a6sw2cep34wlz6b9i9jwiotaqoayxcxt.xz
sudo tar -xJf nndc_hdf5.tar.xz
sudo git clone --branch=master git://github.com/smharper/windowed_multipole_library.git wmp_lib
sudo tar -xzf wmp_lib/multipole_lib.tar.gz
cd /opt/openmc/examples/xml/pincell
sudo chmod -R 777 /opt/openmc/
sudo chmod -R 777 /tmp


