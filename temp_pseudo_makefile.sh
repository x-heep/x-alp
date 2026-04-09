#!/bin/bash

# this is a pseudo-makefile, temporary makefile substitute, not to be pushed (not final solution).
# current makefile doesn't support these instructions as targets

#!/bin/bash

# pseudo-makefile script

# usage: ./temp_pseudo_makefile.sh spi-vendor spi-gen

for arg in "$@"
do
  case $arg in

    # vendor xheep_spi
    spi-vendor)
      echo "Vendoring xheep_spi..."
      python ./util/vendor.py ./hw/vendor/xheep_spi.vendor.hjson -vU
      ;;

    # xheep_spi/rtl/spi_subsystem.sv generation
    spi-gen)
      echo "Generating spi_subsystem.sv..."
      currdir=$(pwd)
      cd hw/vendor/spi || exit
      make gen-spi
      cd "$currdir" || exit
      ;;

    *)
      echo "Unknown target: $arg"
      ;;
  esac
done