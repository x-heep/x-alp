#!/bin/bash

# this is a pseudo-makefile, temporary makefile substitute, not to be pushed (not final solution).
# current makefile doesn't support these instructions as targets

# usage: ./temp_pseudo_makefile.sh vendor periph-gen

for arg in "$@"
do
  case $arg in

    # vendor xheep/spi
    vendor)
      echo "Vendoring xheep_spi..."
      python ./util/vendor.py ./hw/vendor/xheep_spi.vendor.hjson -vU
      ;;

    # vendor/xheep/spi/rtl/spi_subsystem.sv generation
    periph-gen)
      echo "Generating spi_subsystem.sv..."
      make -C  hw/vendor/xheep/spi periph-gen \
      SPI_SUBSYS_PERIPH_GEN=axi
      ;;

    *)
      echo "Unknown target: $arg"
      ;;
  esac
done