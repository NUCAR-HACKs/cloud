mpiexec -wdir /opt/openmc/examples/xml/pincell -display-map -map-by node -np $NSLOTS -x OPENMC_MULTIPOLE_LIBRARY=/opt/openmc/multipole_lib -x OPENMC_CROSS_SECTIONS=/opt/openmc/nndc_hdf5/cross_sections.xml -x OPENMC_ENDF_DATA=/opt/openmc/nndc_hdf5/cross_sections.xml -x LD_LIBRARY_PATH=/opt/openmc/lib:$LD_LIBRARY_PATH -x PATH=/opt/openmc/bin:/opt/NJOY2016/build:$PATH openmc --threads 1