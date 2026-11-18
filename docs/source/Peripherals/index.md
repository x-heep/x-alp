# Peripherals

Here you can find the documentation for the peripherals of X-ALP. All of them are register-interface slaves in the peripheral domain (`0x2000_0000` by default); their final addresses are listed in the [Address Map](../Configuration/AddressMap.md), and in software they are available through the `<NAME>_BASE_ADDRESS` macros of `core_v_mcu.h`. To add or move peripherals, see [Peripheral Configuration](../Configuration/PeripheralConfiguration.md).

When you run `make mcu-gen`, the register documentation of each peripheral is generated in `sw/device/lib/drivers/<name>/<name>_regs.md` (see [Generate peripheral registers](../How_to/GenerateRegisters.md)).

## SoC controller (`soc_ctrl`)

The SoC controller (`hw/ip/soc_ctrl`) holds the registers used to boot and to end a program:

| Register | Description |
|----------|-------------|
| `EXIT_VALID` | Set to `1` when the program ends. Drives the `exit_valid` output of the chip |
| `EXIT_VALUE` | Value returned by the program. Drives the `exit_value_o` output |
| `BOOT_SELECT` | Boot mode selection |
| `BOOT_EXIT_LOOP` | Set to release the boot ROM wait loop |
| `BOOT_ADDRESS` | Address the boot ROM jumps to |
| `SYSTEM_FREQUENCY_HZ` | Frequency of the system, in Hz |

The driver is in `sw/device/lib/drivers/soc_ctrl`.

## Boot ROM (`bootrom`)

The boot ROM (`hw/ip/bootrom`) is the first code executed by the CPU. It is built from `hw/ip/bootrom/bootrom.S` by `make boot-rom` (called by `make mcu-gen`). It:

1. clears the integer registers;
2. waits until `BOOT_EXIT_LOOP` of the SoC controller is set;
3. reads `BOOT_ADDRESS`. If it points to the LLC scratchpad, it waits for the LLC built-in self-test and locks every cache way as scratchpad;
4. jumps to the boot address.

When the program returns, the C runtime writes the return value to `EXIT_VALUE` and sets `EXIT_VALID`.

## UART (`uart`)

The [OpenTitan UART](https://opentitan.org/book/hw/ip/uart/index.html) (`hw/subsystems/uart_subsystem.sv`). The software runtime uses it for `printf`. The UART interrupts are not connected. The driver is in `sw/device/lib/drivers/uart`.

In simulation, the UART is connected to the UART DPI of the testbench, and its output is written to `uart0.log` (see [Simulate](../How_to/Simulate.md)). The baud rate and the reference clock assumed by software are set in `sw/device/target/sim/x-alp.h`.

## Fast interrupt controller (`fast_intr_ctrl`)

The fast interrupt controller (`hw/ip/fast_intr_ctrl`) collects up to 16 fast interrupt lines, with the `FAST_INTR_PENDING`, `FAST_INTR_CLEAR` and `FAST_INTR_ENABLE` registers. In the current RTL, its interrupt inputs are tied to zero. The driver is in `sw/device/lib/drivers/fast_intr_ctrl`.

## Last-level cache configuration (`axi_llc`)

The configuration registers of the [AXI LLC](https://github.com/pulp-platform/axi_llc), the memory subsystem of X-ALP (see [Memory Configuration](../Configuration/MemoryConfiguration.md)). The C header with the register offsets, `sw/device/lib/drivers/axi_llc/axi_llc_regs.h`, and the full register documentation, `sw/device/lib/drivers/axi_llc/axi_llc_regs.md`, are generated from the vendored IP. The main registers are:

| Register | Description |
|----------|-------------|
| `CFG_SPM_LOW` / `CFG_SPM_HIGH` | One bit per way: `1` uses the way as scratchpad, `0` as cache |
| `CFG_FLUSH_LOW` / `CFG_FLUSH_HIGH` | One bit per way to flush |
| `COMMIT_CFG` | Write `1` to apply the configuration written in `CFG_SPM` and `CFG_FLUSH` |
| `FLUSHED_LOW` / `FLUSHED_HIGH` | One bit per way, set when the way is flushed |
| `SET_ASSO_LOW`, `NUM_LINES_LOW`, `NUM_BLOCKS_LOW` | Instantiated cache geometry |
| `BIST_STATUS` | Status of the built-in self-test of the tag storage |

To switch ways between cache and scratchpad, write the new mask to `CFG_SPM`, write `1` to `COMMIT_CFG`, and wait until `FLUSHED` matches the mask, as the boot ROM does. While the LLC applies a new configuration, it does not serve requests.

## External peripheral (`ext_peripheral`)

A slot of the peripheral domain forwarded to the `ext_reg_req_o`/`ext_reg_rsp_i` port of the `x_alp` top level, to connect the registers of a peripheral outside X-ALP. See [eXtending hardware](../Extending/eXtendingHW.md).

## Pad control (`pad_control`)

The pad control registers, generated from the [pad configuration](../Configuration/PadConfiguration.md). It is available in {py:attr}`~xheep_gen.xalp.XAlp.AVAILABLE_PERIPHERALS` but not instantiated in the default configuration.
