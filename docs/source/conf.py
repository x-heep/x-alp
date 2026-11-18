# Copyright 2026 X-HEEP contributors
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Description: Sphinx configuration for the X-ALP documentation

import os
import sys

sys.path.insert(0, os.path.abspath("../../util"))
sys.path.insert(0, os.path.abspath("../../util/xheep_gen"))

project = "X-ALP"
copyright = "2026, X-HEEP contributors"
author = "X-HEEP contributors"

release = "0.0.1"
version = "0.0.1"

extensions = [
    "sphinx.ext.duration",
    "sphinx.ext.doctest",
    "sphinx.ext.autodoc",
    "sphinx.ext.autosummary",
    "sphinx.ext.intersphinx",
    "sphinxcontrib.apidoc",
    "myst_parser",
]

source_suffix = [".rst", ".md"]

intersphinx_mapping = {
    "python": ("https://docs.python.org/3/", None),
    "sphinx": ("https://www.sphinx-doc.org/en/master/", None),
}
intersphinx_disabled_domains = ["std"]

templates_path = ["_templates"]

html_theme = "sphinx_rtd_theme"

epub_show_urls = "footnote"

apidoc_module_dir = os.path.abspath("../../util/xheep_gen")
apidoc_output_dir = "Configuration/xheep_gen"
apidoc_separate_modules = True
apidoc_toc_file = "index"
# Subpackages of xheep_gen without __init__.py (address_map, bus, ...)
apidoc_extra_args = ["--implicit-namespaces"]

# Auto-generate header anchors for MyST
myst_heading_anchors = 4
myst_enable_extensions = ["deflist"]
