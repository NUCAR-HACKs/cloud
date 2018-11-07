FROM ubuntu:latest

ENV FC=/usr/bin/mpif90 CC=/usr/bin/mpicc CXX=/usr/bin/mpicxx \
    PATH=/opt/openmc/bin:/opt/NJOY2016/build:$PATH \
    LD_LIBRARY_PATH=/opt/openmc/lib:$LD_LIBRARY_PATH \
    OPENMC_CROSS_SECTIONS=/root/nndc_hdf5/cross_sections.xml \
    OPENMC_MULTIPOLE_LIBRARY=/root/WMP_Library \
    OPENMC_ENDF_DATA=/root/endf-b-vii.1

# Install dependencies from Debian package manager
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y python3-pip && \
    apt-get install -y wget git openssh-server openssh-client && \
    apt-get install -y gfortran g++ cmake && \
    apt-get install -y openmpi-bin libopenmpi-dev && \
    apt-get install -y libhdf5-serial-dev libhdf5-openmpi-dev && \
    apt-get install -y imagemagick && \
    apt-get autoremove


# Update system-provided pip
RUN pip3 install --upgrade pip

RUN pip install six NumPy SciPy pandas h5py Matplotlib uncertainties lxml

# Clone and install NJOY2016
RUN git clone https://github.com/njoy/NJOY2016 /opt/NJOY2016

WORKDIR /opt/NJOY2016
    
RUN mkdir build && cd build && \
    cmake -Dstatic=on .. && make 2>/dev/null && make install

# Clone and install OpenMC
RUN git clone https://github.com/mit-crpg/openmc.git /opt/openmc

WORKDIR /opt/openmc

RUN git checkout master && mkdir -p build

WORKDIR build
    
RUN cmake -Dopenmp=on -Doptimize=on -DHDF5_PREFER_PARALLEL=on .. && \
    make && make install

WORKDIR .. 

# Download cross sections (NNDC and WMP) and ENDF data needed by test suite
RUN wget -O nndc_hdf5.tar.xz $(cat /opt/openmc/.travis.yml | grep anl.box | awk '{print $2}') && \
    tar xJvf nndc_hdf5.tar.xz

ENV OPENMC_CROSS_SECTIONS=/opt/openmc/nndc_hdf5/cross_sections.xml

RUN git clone --branch=master git://github.com/smharper/windowed_multipole_library.git wmp_lib && \
    tar xzvf wmp_lib/multipole_lib.tar.gz
ENV OPENMC_MULTIPOLE_LIBRARY=/opt/openmc/multipole_lib

# RUN ./opt/openmc/tools/ci/download-xs.sh

WORKDIR /opt/openmc/examples/xml/pincell

RUN mkdir /root/.ssh
COPY ./threading.sh /opt/openmc/examples/xml/pincell
COPY ./hostfile.txt /opt/openmc/examples/xml/pincell
COPY ./.ssh/* /root/.ssh/
RUN echo "    IdentityFile /root/.ssh/id_rsa" >> /etc/ssh/ssh_config
RUN echo "    Port 8081" >> /etc/ssh/ssh_config
RUN echo "    Port 8081" >> /etc/ssh/sshd_config
RUN echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
#RUN echo "    PermitRootLogin yes" >> /etc/ssh/ssh_config
#RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/ssh_config
RUN eval `ssh-agent` && ssh-add /root/.ssh/id_rsa
RUN ssh-keygen -f "/root/.ssh/known_hosts" -R "[192.168.100.1]:8081"
RUN ssh-keygen -f "/root/.ssh/known_hosts" -R "[192.168.100.2]:8081"
RUN ssh-keygen -f "/root/.ssh/known_hosts" -R "[192.168.100.3]:8081"
RUN ssh-keygen -f "/root/.ssh/known_hosts" -R "[192.168.100.4]:8081"

#ENV OMPI_MCA_oob_tcp_static_ipv4ports=40020
CMD mpiexec -np 1 --bind-to socket -x OPENMC_MULTIPOLE_LIBRARY -x OPENMC_CROSS_SECTIONS --allow-run-as-root --mca oop_tcp_static_ports 40020 -machinefile hostfile.txt openmc --threads 128
#RUN ./threading.sh
#CMD /bin/bash
#CMD openmc --threads 128
