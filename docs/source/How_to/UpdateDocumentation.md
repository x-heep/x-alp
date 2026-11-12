# Update the documentation

All documentation is found in the `docs/source` directory and is built with [Sphinx](https://www.sphinx-doc.org/) and [MyST](https://myst-parser.readthedocs.io/). Thank you for helping keep X-ALP accurately and extensively documented!

1. If you need to create a new entry, add the new document in Markdown (`.md` extension) to the corresponding folder. Otherwise, just edit the corresponding file.

```{note}
Make sure the document has one single `# header`, otherwise it will be considered as different documents.
```

2. Add the new document, or the new folder, to the `toctree` of the corresponding index file.
3. Check the changes locally (see [Build the documentation locally](#build-the-documentation-locally) below).
4. Commit and push.
5. Open a pull request. If Read the Docs is enabled for the repository, the CI builds a preview of the documentation, linked in the checks of the pull request.

6. Once the pull request is merged, the documentation is updated automatically.

The API reference of the `xheep_gen` generator is built automatically from the docstrings in `util/xheep_gen`. The address map page includes `docs/addressmap.md`, which `make mcu-gen` generates from `docs/addressmap.md.tpl`.

## Build the documentation locally

1. Make sure the conda environment (or the virtual environment) is activated: it includes the packages listed in `docs/python-requirements.txt`.
2. From the `docs` folder, run:

```bash
make clean html
```

3. Open `docs/build/html/index.html` with a web browser.
