# Copyright EPFL contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Juan Sapriza <juan.sapriza@epfl.ch>
#
# Info: This script parses the generated main.map and core_v_mcu_pkg.sv files to
# display the usage of the different memory banks of the generated MCU for code (text) and data.
# The script considers the possibility of having interleaved (IL) memory banks at the end of the
# continuous memory banks. In the IL banks, data is distributed homogeneously across banks (although
# this does not necessarily need to be the case).
# The code extracts the number and size of the memory banks from the MCU package.
# Then extracts the regions (code and data) from the main.map file -- i.e. where code and data can
# be stored.
# Later extracts the utilization of those regions by looking for the addresses in which text and data
# has been written in the main.map file.
# For the IL data (ildt) only the length is extracted, for simplicity. We assume an homogeneous distribution.

import subprocess
import re
import os


def is_readelf_available():
    try:
        subprocess.run(
            ["readelf", "--version"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        return True
    except FileNotFoundError:
        return False


def get_banks_and_sizes(mcu_header_path):
    """
    Parse the MCU configuration header to extract the count of memory banks and their sizes.
    The current platform exposes these in sw/device/lib/runtime/core_v_mcu.h via macros like:
        #define MEMORY_BANKS 1
        #define RAM0_START_ADDRESS 0x...
        #define RAM0_END_ADDRESS   0x...

    Returns:
        num_banks    - Total count of memory banks
        num_il_banks - Number of interleaved banks (not used in this platform)
        sizes_B      - Size in bytes of each bank
    """
    num_banks = 0
    num_il_banks = 0
    start_addrs = {}
    end_addrs = {}

    try:
        with open(mcu_header_path, "r") as file:
            for line in file:
                banks = re.match(r"#define\s+MEMORY_BANKS\s+(\d+)", line)
                if banks:
                    num_banks = int(banks.group(1))
                    continue

                start_match = re.match(
                    r"#define\s+RAM(\d+)_START_ADDRESS\s+0x([0-9A-Fa-f_]+)", line
                )
                if start_match:
                    idx = int(start_match.group(1))
                    start_addrs[idx] = int(start_match.group(2).replace("_", ""), 16)
                    continue

                end_match = re.match(
                    r"#define\s+RAM(\d+)_END_ADDRESS\s+0x([0-9A-Fa-f_]+)", line
                )
                if end_match:
                    idx = int(end_match.group(1))
                    end_addrs[idx] = int(end_match.group(2).replace("_", ""), 16)
                    continue
    except FileNotFoundError:
        print("File not found. Please check the path and try again.")
        return num_banks, num_il_banks, []

    sizes_B = []
    if start_addrs and not num_banks:
        num_banks = max(start_addrs.keys()) + 1

    for idx in sorted(start_addrs.keys()):
        if idx in end_addrs:
            sizes_B.append(end_addrs[idx] - start_addrs[idx])

    # Fallback to the bus size in the SystemVerilog package if nothing was found in the header.
    if not sizes_B:
        try:
            with open("hw/include/core_v_mcu_pkg.sv", "r") as file:
                for line in file:
                    bus_size = re.search(
                        r"MEM_BUS_SIZE\s*=\s*64'h([0-9A-Fa-f_]+)", line
                    )
                    if bus_size:
                        sizes_B.append(int(bus_size.group(1).replace("_", ""), 16))
                        break
            if sizes_B and not num_banks:
                num_banks = 1
        except FileNotFoundError:
            pass

    return num_banks, num_il_banks, sizes_B


def _parse_ld_number(text):
    """
    Parse a linker-script numeric literal: hex (0x...), decimal, optionally with a
    K/M/G size suffix (e.g. "16K", "1024M"). Returns an int or None.
    """
    text = text.strip().rstrip("\r\n;")
    mult = 1
    if text and text[-1] in "kKmMgG":
        mult = {"k": 1024, "m": 1024**2, "g": 1024**3}[text[-1].lower()]
        text = text[:-1]
    try:
        return int(text, 0) * mult
    except ValueError:
        return None


def _iter_ld_lines(ld_path, search_dirs=None, _seen=None):
    """
    Yield the lines of a linker script, transparently following `INCLUDE <file>`
    directives. Included files are searched in the directory of the including
    file first, then in search_dirs. Guards against include cycles.
    """
    if _seen is None:
        _seen = set()
    ld_path = os.path.abspath(ld_path)
    if ld_path in _seen:
        return
    _seen.add(ld_path)

    dirs = [os.path.dirname(ld_path)] + list(search_dirs or [])
    try:
        f = open(ld_path, "r")
    except FileNotFoundError:
        print(f"File not found: {ld_path}")
        return
    with f:
        for line in f:
            inc = re.match(r'\s*INCLUDE\s+"?([^"\s]+)"?', line)
            if inc:
                name = inc.group(1)
                for d in dirs:
                    cand = os.path.join(d, name)
                    if os.path.exists(cand):
                        yield from _iter_ld_lines(cand, search_dirs, _seen)
                        break
                continue
            yield line


def get_memory_sections(ld_path, search_dirs=None):
    """
    Parse the linker script MEMORY block and return all declared regions.
    Works with entries such as:
        RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00010000
    """
    sections = {}
    mem_regex = re.compile(
        r"(\w+)\s*\([^)]*\)\s*:\s*ORIGIN\s*=\s*([^,]+),\s*LENGTH\s*=\s*([^\s/]+)"
    )

    collect = False
    for line in _iter_ld_lines(ld_path, search_dirs):
        if line.strip().startswith("MEMORY"):
            collect = True
            continue
        if collect:
            if line.strip().startswith("}"):
                collect = False
                continue
            match = mem_regex.search(line)
            if match:
                name = match.group(1)
                origin = _parse_ld_number(match.group(2))
                length = _parse_ld_number(match.group(3).split()[0])
                if origin is not None and length is not None:
                    sections[name] = {"origin": origin, "length": length}
    return sections


def get_readelf_output(elf_file):
    """
    Executes the readelf command on the provided ELF file with -lW option to list program headers without wrapping.
    """
    try:
        result = subprocess.run(
            ["readelf", "-lW", elf_file], capture_output=True, text=True
        )
        return result.stdout
    except Exception as e:
        print(f"Error running readelf: {e}")
        return None


def parse_program_headers(readelf_output):
    """
    Parse the program headers emitted by `readelf -lW`.
    """
    program_headers = []
    headers_started = False

    for line in readelf_output.split("\n"):
        if "Program Headers:" in line:
            headers_started = True
            continue
        if not headers_started:
            continue
        if line.strip().startswith("Type"):
            continue
        if "Section to Segment mapping:" in line:
            break
        if not line.strip():
            continue

        parts = line.split()
        if len(parts) < 8:
            continue

        program_headers.append(
            {
                "Type": parts[0],
                "Offset": int(parts[1], 16),
                "VirtAddr": int(parts[2], 16),
                "PhysAddr": int(parts[3], 16),
                "FileSiz": int(parts[4], 16),
                "MemSiz": int(parts[5], 16),
                "Flg": parts[6],
                "Align": int(parts[7], 16),
                "Idx": len(program_headers),
            }
        )

    return program_headers


def get_regions(program_headers, section_to_segment):
    """
    Parse program headers and section-to-segment mapping to create a list of dictionaries
    describing each segment's start address, size, and type.
    """
    # Define a mapping from section names to region types
    code_sections = {".vectors", ".init", ".text", ".eh_frame"}
    data_sections = {
        ".power_manager",
        ".rodata",
        ".data",
        ".sdata",
        ".sbss",
        ".bss",
        ".heap",
        ".stack",
    }
    interleaved_data_sections = {".data_interleaved"}

    # List to store region dictionaries
    regions = []

    # Iterate through each program header
    for ph in program_headers:
        # Determine the type of region based on the sections it contains
        sections = section_to_segment.get(ph["Idx"], [])
        region_type = "d"  # default to data
        name = "data"
        if any(sec in sections for sec in code_sections):
            region_type = "C"
            name = "code"
        elif any(sec in sections for sec in interleaved_data_sections):
            region_type = "i"  # Special data handling like interleaved can be marked differently if needed
            name = "IL data"
        # Create dictionary for the region
        region_dict = {
            "name": name,
            "symbol": region_type,
            "start_add": ph["VirtAddr"],
            "size_B": ph["MemSiz"],
            "end_add": ph["VirtAddr"] + ph["MemSiz"],
        }

        # Append to the list
        regions.append(region_dict)

    return regions


def parse_section_to_segment(readelf_output):
    """
    Parse the "Section to Segment mapping" from the output of readelf.
    """
    mapping = {}
    capture = False
    for line in readelf_output.split("\n"):
        if "Section to Segment mapping:" in line:
            capture = True
            continue
        if not capture:
            continue
        if line.strip().startswith("Segment") or not line.strip():
            continue

        match = re.match(r"\s*(\d+)\s+(.*)", line)
        if match:
            segment_index = int(match.group(1))
            sections = match.group(2).split()
            mapping[segment_index] = sections
    return mapping


def parse_section_headers(elf_file):
    """
    Parse section headers from the ELF using `readelf -SW`.
    Returns a list of dictionaries with name, start address, size, and end address.
    """
    try:
        result = subprocess.run(
            ["readelf", "-SW", elf_file], capture_output=True, text=True
        )
        output = result.stdout
    except Exception as e:
        print(f"Error running readelf for sections: {e}")
        return []

    sections = []
    capture = False
    for line in output.split("\n"):
        if line.strip().startswith("[Nr]"):
            capture = True
            continue
        if not capture:
            continue
        if line.strip().startswith("Key to Flags:"):
            break

        match = re.match(
            r"\s*\[\s*\d+\]\s+(\S+)\s+\S+\s+([0-9A-Fa-f]+)\s+\S+\s+([0-9A-Fa-f]+)", line
        )
        if match:
            name = match.group(1)
            addr = int(match.group(2), 16)
            size = int(match.group(3), 16)
            sections.append(
                {
                    "name": name,
                    "start_add": addr,
                    "size_B": size,
                    "end_add": addr + size,
                }
            )

    return sections


def get_regions_from_sections(section_headers):
    """
    Build regions directly from section headers by classifying known code and data sections.
    """
    code_sections = {".vectors", ".init", ".text", ".eh_frame"}
    data_sections = {
        ".power_manager",
        ".rodata",
        ".srodata",
        ".data",
        ".sdata",
        ".sbss",
        ".bss",
        ".heap",
        ".stack",
        ".preinit_array",
        ".init_array",
        ".fini_array",
    }
    interleaved_data_sections = {".data_interleaved"}

    regions = []

    for sec in section_headers:
        region_type = None
        region_name = None

        if sec["name"] in code_sections:
            region_type = "C"
            region_name = "code"
        elif sec["name"] in interleaved_data_sections:
            region_type = "i"
            region_name = "IL data"
        elif sec["name"] in data_sections:
            region_type = "d"
            region_name = "data"
        else:
            continue

        regions.append(
            {
                "name": region_name,
                "symbol": region_type,
                "start_add": sec["start_add"],
                "size_B": sec["size_B"],
                "end_add": sec["end_add"],
            }
        )

    return regions


if not is_readelf_available():
    print("readelf not available. Will not print the memory utilization report.")
    quit()

# READ THE READELF OUTPUT AND PARSE TO OBTAIN THE DIFFERENT REGIONS
output = get_readelf_output("sw/build/main.elf")
if not output:
    print("readelf output unavailable; cannot compute memory usage.")
    quit()
program_headers = parse_program_headers(output)
section_to_segment = parse_section_to_segment(output)
regions = get_regions(program_headers, section_to_segment)
section_headers = parse_section_headers("sw/build/main.elf")
section_regions = get_regions_from_sections(section_headers)
if section_regions:
    regions = section_regions
elif not regions:
    print("No regions could be identified in the ELF file.")
    quit()

# OBTAIN THE NUMBER AND SIZE OF THE BANKS
num_banks, num_il_banks, bank_sizes_B = get_banks_and_sizes(
    "sw/device/lib/runtime/core_v_mcu.h"
)
total_size_B = sum(bank_sizes_B)
if total_size_B:
    cont_sizes = [
        int(s / 1024) for s in bank_sizes_B[: max(num_banks - num_il_banks, 0)]
    ]
    il_sizes = (
        [int(s / 1024) for s in bank_sizes_B[-num_il_banks:]] if num_il_banks else []
    )
    print(
        f"Total space: {total_size_B/1024:0.1f} kB = Continuous:",
        cont_sizes,
        "kB + Interleaved:",
        il_sizes if il_sizes else [0],
        "kB",
    )
else:
    print("Could not determine SRAM bank sizes; proceeding with linker regions only.")

# CONVERT THE BANKS INTO A LIST OF DICTIONARIES
banks = []
for i in range(num_banks):
    if i >= len(bank_sizes_B):
        break
    bank = {
        "type": "Cont" if i < (num_banks - num_il_banks) else "IntL",
        "size": bank_sizes_B[i],
    }
    banks.append(bank)

# GET THE MEMORY REGIONS FOR CODE AND DATA.
# The linker script lives in sw/build/main.ld and pulls in the MEMORY block via
# `INCLUDE common.ldh`, so the parser is told where to find included files.
sections = get_memory_sections("sw/build/main.ld", ["sw/linker"])
if not sections:
    print(
        "Memory distribution analysis not available: no MEMORY regions found in linker script."
    )
    quit()

# The program may be linked into any region (e.g. spm or dram). Pick the region
# that contains the program's start address so the report follows LINKER=spm/dram.
# Regions can overlap numerically (e.g. extrom 0x0+48K vs spm 0x2000+64K), so prefer
# an exact base-address match, then the smallest region that still contains the program.
prog_start = min((r["start_add"] for r in regions), default=0)
containing = [
    s for s in sections.values() if s["origin"] <= prog_start < s["origin"] + s["length"]
]
exact = [s for s in containing if s["origin"] == prog_start]
if exact:
    target = exact[0]
elif containing:
    target = min(containing, key=lambda s: s["length"])
else:
    # Fall back to the largest region if nothing contains the program start.
    target = max(sections.values(), key=lambda s: s["length"])

# Code and data share the single target region; no interleaved banks on this platform.
sections = {
    "code": target,
    "data": target,
    "ildt": {"origin": target["origin"] + target["length"], "length": 0},
}

# If the SRAM bank sizes could not be read from the MCU header, fall back to the
# selected linker region so the utilization bar can still be rendered.
if not bank_sizes_B:
    bank_sizes_B = [target["length"]]
    num_banks = 1
    num_il_banks = 0
    banks = [{"type": "Cont", "size": target["length"]}]

# Compute the total space used for code and data
total_space_used_code = sum(
    region["size_B"] for region in regions if region["name"] == "code"
)
total_space_used_data = sum(
    region["size_B"] for region in regions if region["name"] == "data"
)
total_space_used_ildt = sum(
    region["size_B"] for region in regions if region["name"] == "IL data"
)

# Compute the total space required to store code and data
code_regions = [region for region in regions if region["name"] == "code"]
data_regions = [region for region in regions if region["name"] == "data"]
ildt_regions = [region for region in regions if region["name"] == "IL data"]

min_code_start = (
    min(region["start_add"] for region in code_regions) if code_regions else 0
)
max_code_end = max(region["end_add"] for region in code_regions) if code_regions else 0
total_space_required_code = max_code_end - min_code_start

min_data_start = (
    min(region["start_add"] for region in data_regions) if data_regions else 0
)
max_data_end = max(region["end_add"] for region in data_regions) if data_regions else 0
total_space_required_data = max_data_end - min_data_start

min_ildt_start = (
    min(region["start_add"] for region in ildt_regions) if ildt_regions else 0
)
max_ildt_end = max(region["end_add"] for region in ildt_regions) if ildt_regions else 0
total_space_required_ildt = max_ildt_end - min_ildt_start

# # PRINT THE SUMMARY OF UTILIZATION
print("Region \t Start \tEnd\tSz(kB)\tUsd(kB)\tReq(kB)\tUtilz(%) ")


def safe_util(required, length):
    return 0 if length == 0 else 100 * required / length


print(
    f"Code:  \t{sections['code']['origin']/1024:5.1f}\t{(sections['code']['origin']+sections['code']['length'])/1024:5.1f}\t{sections['code']['length']/1024:5.1f}\t{total_space_used_code/1024:0.1f}\t{total_space_required_code/1024:5.1f}\t{safe_util(total_space_required_code, sections['code']['length']):0.1f}"
)
print(
    f"Data:  \t{sections['data']['origin']/1024:5.1f}\t{(sections['data']['origin']+sections['data']['length'])/1024:5.1f}\t{sections['data']['length']/1024:5.1f}\t{total_space_used_data/1024:0.1f}\t{total_space_required_data/1024:5.1f}\t{safe_util(total_space_required_data, sections['data']['length']):0.1f}"
)
if num_il_banks:
    print(
        f"ILdata:\t{sections['ildt']['origin']/1024:5.1f}\t{(sections['ildt']['origin']+sections['ildt']['length'])/1024:5.1f}\t{sections['ildt']['length']/1024:5.1f}\t{total_space_used_ildt/1024:0.1f}\t{total_space_required_ildt/1024:5.1f}\t{safe_util(total_space_required_ildt, sections['ildt']['length']):0.1f}"
    )


# DISPLAY THE UTILIZATION BY SHOWING THE BANKS
# Cont for continuous, IntL for interleaved
# The area used by code is identified with a C
# The area used by data is identified with a d
# The utilization is shown at the end
# The granularity stands for how many Bytes each character represents
char = "."
address = 0
# Each character represents 1 kB, but cap the bar width so large regions (e.g. a
# 1 GiB DRAM) do not produce a multi-million-character line. Round up to a kB multiple.
MAX_BAR_CHARS = 128
largest_bank_B = max(bank_sizes_B) if bank_sizes_B else 1024
granularity_B = 1024  # To show each division having a value of 1kB
if largest_bank_B / granularity_B > MAX_BAR_CHARS:
    granularity_B = -(-largest_bank_B // MAX_BAR_CHARS // 1024) * 1024
start_IL_B = (
    sum(bank_sizes_B[: max(len(bank_sizes_B) - num_il_banks, 0)])
    if num_il_banks
    else sum(bank_sizes_B)
)

print("")
# Start the bar at the target region origin so absolute ELF addresses line up.
address = sections["code"]["origin"]
for bank_idx, bank in enumerate(banks):
    bank["use"] = ["-"] * int((bank["size"] / granularity_B))
    utilization = 0
    bank_start_addr = address
    bank_end_addr = address + bank["size"]

    if bank["type"] == "Cont":
        for piece in range(len(bank["use"])):
            piece_start = bank_start_addr + piece * granularity_B
            piece_end = piece_start + granularity_B

            bank["use"][piece] = "-"
            for region in regions:
                # Check if this piece overlaps with the region
                if piece_start < region["end_add"] and piece_end > region["start_add"]:
                    bank["use"][piece] = region["symbol"]
                    utilization += granularity_B
                    break

    if bank["type"] == "IntL":
        for piece in range(len(bank["use"])):
            piece_start = bank_start_addr + piece * granularity_B
            piece_end = piece_start + granularity_B

            bank["use"][piece] = "-"
            for region in regions:
                used_by_others = region["size_B"] * (num_il_banks - 1) / num_il_banks
                if (
                    piece_start >= region["start_add"]
                    and piece_start < region["end_add"] - used_by_others
                ):
                    bank["use"][piece] = region["symbol"]
                    utilization += granularity_B
                    break

    bank["use"] = "".join(["".join(sublist) for sublist in bank["use"]])
    print(
        bank["type"], bank_idx, bank["use"], f"\t{100*(utilization/bank['size']):0.1f}%"
    )

    # Update address for next bank
    address = bank_end_addr
