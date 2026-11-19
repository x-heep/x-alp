# Prepare X-ALP on FPGA for a `load` into the LLC scratchpad (LINKER=spm).
# Mirrors the boot ROM: wait for the LLC BIST, lock every way as SPM, wait
# for the commit to land. Without this, writes to 0x10000000 return SLVERR.
#
# Usage: riscv64-unknown-elf-gdb -x util/fpga_init.gdb <app>.elf
#        then: load, continue

target extended-remote :3333
monitor reset halt

# AXI_LLC_BASE_ADDRESS = 0x20050000
while (*(unsigned int *)0x20050048 & 1) == 0
end
set $ways = *(unsigned int *)0x20050028
set *(unsigned int *)0x20050000 = (1 << $ways) - 1
set *(unsigned int *)0x20050004 = 0
set *(unsigned int *)0x20050010 = 1
while *(unsigned int *)0x20050018 != *(unsigned int *)0x20050000
end
printf "LLC SPM locked: CFG_SPM_LOW=0x%08x\n", *(unsigned int *)0x20050000
