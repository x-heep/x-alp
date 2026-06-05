# Copyright 2026 EPFL 
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Python values (default)
ifndef CONDA_DEFAULT_ENV
$(info USING VENV)
PYTHON = $(PWD)/$(VENV)/python
else
$(info USING MINICONDA $(CONDA_DEFAULT_ENV))
PYTHON := $(shell which python)
endif

# Runs black formating for python files
format-python:
	$(PYTHON) -m black .
