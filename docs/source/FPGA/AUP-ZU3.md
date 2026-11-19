# FPGA AUP-ZU3: Getting Started

This guide provides step-by-step instructions to run X-ALP on the AUP-ZU3 (8GB) FPGA board. It assumes that you have already installed the tools described in [Run on FPGA](./RunOnFPGA.md).

The X-ALP clock (15 MHz) is derived from the 100 MHz board clock.

```{warning}
On the AUP-ZU3, the LLC master port is not connected to any memory: the 8GB DRAM of the board is attached to the PS, which X-ALP does not use. Only programs linked with `LINKER=spm` can run.
```

---

## Hardware Connection Steps

1. **Power Up the Board**
   - Connect the power supply and turn on the board with the power switch.

2. **Connect USB**
   - Use a USB cable to connect your development machine to the USB-JTAG port of the board. Vivado uses it to program the bitstream.

3. **Connect the Programmer**
   - Connect the ESL programmer to the PMOD connectors A and B. It provides the JTAG of X-ALP and the UART. The pinout is in `hw/target/fpga/xheep_fpga_support/constraints/aup-zu3/pin_assign.xdc`.
   - Connect the programmer to your development machine with a second USB cable.

---

## Programming the Board

The steps are the same as for the [ZCU104](./ZCU_104.md), only the **FPGA_BOARD** changes.

4. **Build and Program the Bitstream**
   ```bash
   make mcu-gen
   make vivado-fpga FPGA_BOARD=aup-zu3
   make vivado-fpga-pgm FPGA_BOARD=aup-zu3
   ```

5. **Compile the App**
   Refer to the [Compile the Apps Documentation](./../How_to/CompileApps.md). There is no software target for the AUP-ZU3: use `TARGET=zcu104`, since X-ALP runs at 15 MHz on both boards.
   ```bash
   make app PROJECT=hello_world TARGET=zcu104
   ```

6. **Run the App**
   In three different shells:
   ```bash
   make fpga-picocom
   ```
   ```bash
   make fpga-openocd
   ```
   ```bash
   make fpga-gdb
   ```
   then, in GDB:
   ```
   (gdb) load
   (gdb) continue
   ```

---

## LEDs and Buttons

| Signal         | Board         | Description                                          |
|----------------|---------------|------------------------------------------------------|
| `rst_i`        | push button 3 | reset (active high)                                  |
| `rst_led_o`    | RGB LED 0     | on when X-ALP is out of reset                        |
| `clk_led_o`    | RGB LED 1     | toggles about every 4.5 s                            |
| `exit_valid_o` | RGB LED 2     | on when the program has returned from `main()`       |
| `exit_value_o` | RGB LED 3     | bit 0 of the exit value: off for `EXIT_SUCCESS`      |

---

## Notes
- The AUP-ZU3 board is the 8GB memory model.
- The board files are in `hw/target/fpga/xheep_fpga_support/board_files/aup-zu3-8gb`.
- Always make sure the bitstream and Vivado configuration match your hardware revision.
