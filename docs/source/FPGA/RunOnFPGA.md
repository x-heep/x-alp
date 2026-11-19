# Run on FPGA

X-ALP can be implemented on Xilinx FPGAs with Vivado.

## Set-up

X-ALP is implemented in the programmable logic (PL) of the FPGA. The Processing System (PS) is not used. The FPGA top level is `hw/target/fpga/xilinx_core_v_mcu_wrapper.sv`. It instantiates `x_alp`, generates the SoC clock with a Clock Wizard and, on boards with PL DRAM, connects the LLC master port (`ext_llc`) to a DDR4 memory controller. JTAG and UART are exposed on the PMOD connectors.

The following FPGA boards are supported:

| Vendor      | Board                                                                                                                    | `FPGA_BOARD` | X-ALP clock | External DRAM |
|-------------|--------------------------------------------------------------------------------------------------------------------------|--------------|-------------|---------------|
| AMD         | [Zynq™ UltraScale+™ MPSoC ZCU104](https://www.amd.com/en/products/adaptive-socs-and-fpgas/evaluation-boards/zcu104.html) | `zcu104`     | 15 MHz      | PL DDR4 (MIG) |
| RealDigital | [AUP-ZU3 (8GB)](https://www.amd.com/en/corporate/university-program/aup-boards/realdigital-aup-zu3.html)                 | `aup-zu3`    | 15 MHz      | no            |

The board-specific files (Vivado board files, constraints and IP generation scripts) are vendored from [x-heep-fpga-support](https://github.com/x-heep/x-heep-fpga-support) into `hw/target/fpga/xheep_fpga_support`. The FuseSoC targets of each board are defined in `xalp.core`. The LLC data and tag arrays are mapped to block RAM through `tc_sram_xilinx`.

1. Install Vivado, then set up its environment by running:

   ```bash
   source <vivado-installation-path>/settings64.sh
   ```

   > We recommend adding this command to your `.bashrc`.

2. You do not need to install the board files in Vivado: `xalp.core` points Vivado to the board files in `hw/target/fpga/xheep_fpga_support/board_files`.

3. Install the Xilinx cable drivers to program the FPGA from Vivado.
   * Follow the [instructions for Linux](https://docs.amd.com/api/khub/documents/6EIhov6ruoilhq8zq7bXBA/content?Ft-Calling-App=ft%2Fturnkey-portal&Ft-Calling-App-Version=4.3.26#G4.262534)
   * Restart your PC

## Building and programming the FPGA

To build the bitstream for your board, make sure you have run `make mcu-gen`, then run:

```bash
make vivado-fpga FPGA_BOARD=<BOARD_NAME>
```

where `<BOARD_NAME>` is one of the boards in the table above. The Vivado log is written to `buildvivado.log`, and the project and the bitstream to `build/x-heep_x-alp_x-alp_0.0.1/<BOARD_NAME>-vivado`.

```{warning}
`make vivado-fpga` does not regenerate the platform. Run `make mcu-gen` again after you change the configuration in `configs/`.
```

To only create the Vivado project, without running synthesis and implementation (e.g. to open it in the Vivado GUI), run:

```bash
make vivado-fpga-nobuild FPGA_BOARD=<BOARD_NAME>
```

To program the bitstream, connect the board to your PC through its USB-JTAG port and run:

```bash
make vivado-fpga-pgm FPGA_BOARD=<BOARD_NAME>
```

Otherwise, open Vivado,

```
open --> Hardware Manager --> Open Target --> Autoconnect --> Program Device
```

and choose `x-heep_x-alp_x-alp_0.0.1.bit` in `build/x-heep_x-alp_x-alp_0.0.1/<BOARD_NAME>-vivado`.

## Running firmware on the FPGA

On the FPGA, X-ALP runs programs loaded over JTAG: the boot ROM waits for the debugger, and GDB loads the program and sets the program counter to its entry point (see [Debug](../How_to/Debug.md)).

The JTAG and UART interfaces of X-ALP are mapped to the PMOD connectors to be compliant with the [ESL iceprog compatible programmer](https://github.com/esl-epfl/x-heep-programmer-pmod), as in X-HEEP. The programmer has an `FT4232H` chip (Vendor ID `0x0403`, Product ID `0x6011`): one channel is used for JTAG and one for the UART. The pinout of each board is in `hw/target/fpga/xheep_fpga_support/constraints/<BOARD_NAME>/pin_assign.xdc`.

The four status signals of the wrapper are mapped to LEDs:

| Signal         | Description                                                    |
|----------------|----------------------------------------------------------------|
| `rst_led_o`    | on when X-ALP is out of reset                                  |
| `clk_led_o`    | toggles every 2^26 clock cycles (about 4.5 s at 15 MHz)        |
| `exit_valid_o` | on when the program has returned from `main()`                 |
| `exit_value_o` | bit 0 of the exit value: off for `EXIT_SUCCESS`                |

The reset input `rst_i` is active high and is mapped to a push button.

### Prerequisites

1. The RISC-V GDB of your toolchain, e.g. `$RISCV_XALP/bin/riscv32-corev-elf-gdb`.
2. [OpenOCD](https://openocd.org/) with the FTDI driver enabled. Build it as described in [Debug](../How_to/Debug.md), adding `--enable-ftdi`:

   ```bash
   ./configure --enable-ftdi --enable-remote-bitbang --prefix=/home/$USER/tools/openocd
   make
   make install
   ```

3. [picocom](https://linux.die.net/man/8/picocom) to read the UART.
4. On Linux, allow your user to access the programmer. Create the file `/etc/udev/rules.d/60-ft4232.rules` (you need sudo permits) with:

   ```
   ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6011", MODE="664", GROUP="plugdev"
   ```

   then run `sudo usermod -a -G plugdev $USER` and `sudo udevadm control --reload`, and log in again.

### Compile the application

Compile your application for the FPGA target. `TARGET=zcu104` selects `sw/device/target/zcu104/x-alp.h`, which sets the 15 MHz reference clock used to compute the UART baud rate:

```bash
make app PROJECT=hello_world TARGET=zcu104
```

The default `LINKER=spm` places the program in the LLC scratchpad. On boards with external DRAM you can use `LINKER=dram` (see [Compile applications](../How_to/CompileApps.md#memory-layouts)).

### Run the application

You need three shells, all opened in the root of the repository.

1. Open the UART console:

   ```bash
   make fpga-picocom
   ```

   The default device is `/dev/serial/by-id/usb-FTDI_Quad_RS232-HS-if02-port0` and the default baud rate is `256000`. Set `FPGA_UART=<device>` or `UART_BAUD=<baud>` to change them. Exit with `ctrl+A`, `ctrl+Q`.

2. Start OpenOCD:

   ```bash
   make fpga-openocd
   ```

   It uses `tb/core-v-mcu-xheep-programmer.cfg`, which selects the programmer by its USB description (`Quad RS232-HS`), since the board JTAG may also be an FT4232. OpenOCD halts the CPU, prints `Ready for Remote Connections.` and listens for GDB on port `3333`. It shuts down when GDB detaches. Set `OPENOCD_CFG=<file>` to use another configuration.

3. Load and run the program with GDB. For a program linked with `LINKER=spm`, run:

   ```bash
   make fpga-gdb
   ```

   This target runs `util/fpga_init.gdb`, which connects to OpenOCD, resets and halts the CPU, and locks every LLC way as scratchpad, as the boot ROM does. Without this step, writes to the scratchpad (`0x1000_0000`) return `SLVERR`. Then run:

   ```
   (gdb) load
   (gdb) continue
   ```

   For a program linked with `LINKER=dram`, run instead:

   ```bash
   make fpga-gdb-dram
   ```

   and `load`, `continue` in GDB. The DRAM is accessed through the cache, so the LLC does not need to be configured.

The output of `printf` appears in the picocom shell. When the program returns from `main()`, the `exit_valid_o` LED turns on.

For example, `dram_vector` streams a 4 MiB vector, 16 times larger than the LLC, through the external DRAM of the ZCU104:

```bash
make app PROJECT=dram_vector TARGET=zcu104 LINKER=dram
make fpga-gdb-dram
```

### Make targets

| Target                | Description                                                        |
|-----------------------|--------------------------------------------------------------------|
| `vivado-fpga`         | Build the bitstream for `FPGA_BOARD`                               |
| `vivado-fpga-nobuild` | Create the Vivado project for `FPGA_BOARD`, without building it    |
| `vivado-fpga-pgm`     | Program the bitstream of `FPGA_BOARD`                              |
| `fpga-picocom`        | Open the UART console                                              |
| `fpga-openocd`        | Start OpenOCD on the programmer JTAG, GDB server on port `3333`    |
| `fpga-gdb`            | Load `sw/build/main.spm.elf` in the LLC scratchpad                 |
| `fpga-gdb-dram`       | Load `sw/build/main.dram.elf` in the external DRAM                 |

FuseSoC flags and parameters can be passed to `vivado-fpga` with `FUSESOC_FLAGS` and `FUSESOC_PARAM`.
