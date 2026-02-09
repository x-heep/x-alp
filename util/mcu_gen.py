#!/usr/bin/env python3

# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Simplified version of occamygen.py https://github.com/pulp-platform/snitch/blob/master/util/occamygen.py

import argparse
import hjson
import pathlib
import sys
import re
import logging
import pickle
from jsonref import JsonRef
from mako.template import Template
from SystemGen import load_cfg_file, BusType
from SystemGen.load_config import load_peripherals_config
from SystemGen.cpu import CPU
from SystemGen.pads.PadRing import PadRing
from xalp import XAlp
import os


# ANSI color codes for pretty printing
class Colors:
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    RESET = "\033[0m"
    BOLD = "\033[1m"


# Compile a regex to trim trailing whitespaces on lines.
re_trailws = re.compile(r"[ \t\r]+$", re.MULTILINE)


def string2int(hex_json_string):
    return (hex_json_string.split("x")[1]).split(",")[0]


def write_template(tpl_path, outfile, **kwargs):
    if tpl_path:
        tpl_path = pathlib.Path(tpl_path).absolute()
        if tpl_path.exists():
            tpl = Template(filename=str(tpl_path))
            if outfile:
                filename = outfile
            else:
                filename = tpl_path.with_suffix("")

            with open(filename, "w") as file:
                code = tpl.render_unicode(**kwargs, strict_undefined=True)
                code = re_trailws.sub("", code)
                file.write(code)
        else:
            raise FileNotFoundError("Template file not found: {0}".format(tpl_path))
    else:
        raise FileNotFoundError("Template file not provided")


"""
    Ideally, generate the xheep object with the configuration passed in args. After generating the xheep object, serialize it to a file and save it.

    Currently, generates xheep object with other parameters (and serialize everything)
"""


def generate_xalp(args):

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)

    if args.config != None and args.config != "":
        xalp = load_cfg_file(
            pathlib.PurePath(str(args.config)), system_factory=XAlp
        )
    else:
        xalp = load_cfg_file(
            pathlib.PurePath(str(args.config)), system_factory=XAlp
        )

    # Load pads HJSON configuration file
    with open(args.pads_cfg, "r") as file:
        try:
            srcfull = file.read()
            pad_cfg = hjson.loads(srcfull, use_decimal=True)
            pad_cfg = JsonRef.replace_refs(pad_cfg)
        except ValueError:
            raise SystemExit(sys.exc_info()[1])

    # Here the xalp system is built,
    # The missing gaps are filled, like the missing end address of the data section.
    xalp.build()
    pad_ring = PadRing(pad_cfg)
    xalp.set_padring(pad_ring)
    if not xalp.validate():
        raise RuntimeError("There are errors when configuring X-ALP system. Please check the configuration and try again.")

    kwargs = {
        "xalp": xalp,
    }

    return kwargs


def main():
    parser = argparse.ArgumentParser(prog="mcugen")

    parser.add_argument(
        "--cached_path", "-cp", help="Path to the cached xalp file", required=True
    )

    parser.add_argument(
        "--cached",
        "-ca",
        help="If set, the script will not generate the xalp object, but will use the cached version instead",
        required=False,
        action="store_true",
    )

    args, _ = parser.parse_known_args()

    if args.cached:
        # Validate cached file exists
        if not os.path.exists(args.cached_path):
            parser.error(
                f"Cached file {args.cached_path} does not exist. Cannot use --cached flag."
            )

        # X-Alp object has been generated
        print(
            f"{Colors.BLUE}[MCU-GEN]{Colors.RESET} Loading cached configuration from: {Colors.BOLD}{args.cached_path}{Colors.RESET}"
        )
        with open(args.cached_path, "rb") as f:
            kwargs = pickle.load(f)
        print(f"{Colors.GREEN}[MCU-GEN]{Colors.RESET} Cache loaded successfully")

        parser.add_argument(
            "--outfile",
            "-o",
            type=pathlib.Path,
            required=False,
            help="Target filename. If not provided, the template filename will be used as the output filename.",
        )

        parser.add_argument(
            "--outtpl",
            "-ot",
            type=str,
            required=True,
            help="Target template filename or comma-separated list of template filenames",
        )

        args = parser.parse_args()
        outtpl = args.outtpl
        outfile = args.outfile

        # Handle single template or multiple templates
        outtpl_list = [t for t in re.split(r"[,\s]+", outtpl.strip()) if t]

        if len(outtpl_list) == 1:
            # Single template case
            print(
                f"{Colors.BLUE}[MCU-GEN]{Colors.RESET} Processing template: {Colors.BOLD}{outtpl_list[0]}{Colors.RESET}"
            )
            write_template(pathlib.Path(outtpl_list[0]), outfile, **kwargs)
            print(
                f"{Colors.GREEN}[MCU-GEN]{Colors.RESET} Template processed successfully"
            )
        else:
            # Multiple templates case
            if outfile is not None:
                parser.error(
                    "Cannot specify --outfile when using multiple templates. Filenames will be generated from template names."
                )
            print(
                f"{Colors.BLUE}[MCU-GEN]{Colors.RESET} Processing {Colors.BOLD}{len(outtpl_list)}{Colors.RESET} templates..."
            )
            for idx, tpl in enumerate(outtpl_list, 1):
                tpl_path = pathlib.Path(tpl.strip())
                # Generate output filename from template name by removing .tpl extension
                tpl_str = str(tpl_path)
                if tpl_str.endswith(".tpl"):
                    generated_outfile = pathlib.Path(tpl_str[:-4])
                else:
                    generated_outfile = tpl_path
                print(
                    f"{Colors.YELLOW}[MCU-GEN]{Colors.RESET} [{idx}/{len(outtpl_list)}] {tpl_path.name} {Colors.YELLOW}→{Colors.RESET} {generated_outfile.name}"
                )
                write_template(tpl_path, generated_outfile, **kwargs)
            print(
                f"{Colors.GREEN}[MCU-GEN]{Colors.RESET} All templates processed successfully"
            )

    else:
        # X-ALP object must be generated
        cached_path = args.cached_path

        parser.add_argument(
            "--config",
            metavar="file",
            type=str,
            required=False,
            nargs="?",
            default="",
            help="X-ALP general Python configuration",
        )

        parser.add_argument(
            "--pads_cfg",
            "-pc",
            metavar="file",
            type=str,
            required=True,
            help="Pads HJSON configuration",
        )

        parser.add_argument(
            "-v", "--verbose", help="increase output verbosity", action="store_true"
        )

        args = parser.parse_args()
        print(
            f"{Colors.BLUE}[MCU-GEN]{Colors.RESET} Generating X-ALP configuration..."
        )
        kwargs = generate_xalp(args)
        print(
            f"{Colors.GREEN}[MCU-GEN]{Colors.RESET} X-ALP configuration generated successfully"
        )

        # Create directory structure if it doesn't exist
        print(
            f"{Colors.BLUE}[MCU-GEN]{Colors.RESET} Saving configuration cache to: {Colors.BOLD}{cached_path}{Colors.RESET}"
        )
        os.makedirs(os.path.dirname(cached_path), exist_ok=True)
        with open(cached_path, "wb") as f:
            pickle.dump(kwargs, f)
        print(
            f"{Colors.GREEN}[MCU-GEN]{Colors.RESET} Configuration cache saved successfully"
        )


if __name__ == "__main__":
    main()
