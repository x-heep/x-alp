# Copyright 2025 EPFL contributors
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Author: Michele Caon, David Mallasen
# Description: Script to generate the power_manager registers

PERIPHERAL_NAME=power_manager

REG_DIR=$(dirname -- $0)
ROOT=$(dirname -- $0)
export PYTHONPATH=$PYTHONPATH:$ROOT/util
REGTOOL=$ROOT/hw/vendor/pulp_platform_register_interface/vendor/lowrisc_opentitan/util/regtool.py
PERIPH_STRUCTS_GEN=$ROOT/util/structs_periph_gen.py
HJSON_FILE=$REG_DIR/data/$PERIPHERAL_NAME.hjson
TEMPLATE_FILE=$ROOT/util/periph_structs.tpl
RTL_DIR=$REG_DIR/rtl
SW_DIR=$ROOT/sw/device/lib/drivers/$PERIPHERAL_NAME

mkdir -p $RTL_DIR $SW_DIR

printf -- "Rendering Mako template to HJSON... \n"
python3 $ROOT/util/render_template.py $REG_DIR/data/$PERIPHERAL_NAME.hjson.tpl $HJSON_FILE
[ $? -eq 0 ] || exit $?

printf -- "Generating $PERIPHERAL_NAME registers RTL... \n"
$REGTOOL -r -t $RTL_DIR $HJSON_FILE
[ $? -eq 0 ] && printf " OK\n" || exit $?

printf -- "Generating $PERIPHERAL_NAME software header... \n"
$REGTOOL --cdefines -o ${SW_DIR}/${PERIPHERAL_NAME}_regs.h $HJSON_FILE
[ $? -eq 0 ] && printf " OK\n" || exit $?

printf -- "Generating $PERIPHERAL_NAME software header structs... \n"
python3 $PERIPH_STRUCTS_GEN --template_filename $TEMPLATE_FILE \
                           --hjson_filename $HJSON_FILE \
                           --output_filename ${SW_DIR}/${PERIPHERAL_NAME}_structs.h
[ $? -eq 0 ] && printf " OK\n" || exit $?

printf -- "Generating $PERIPHERAL_NAME documentation... \n"
$REGTOOL -d $HJSON_FILE > ${SW_DIR}/${PERIPHERAL_NAME}_regs.md
[ $? -eq 0 ] && printf " OK\n" || exit $?