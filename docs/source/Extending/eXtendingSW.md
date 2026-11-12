# eXtending software

If X-ALP is vendored into your project, you can keep your software in your top-level repository and build it with X-ALP's compilation flow.

## Repository structure

The following is an example repository folder structure focusing on the software flow.

    BASE
    ├── sw
    │   ├── applications
    │   │   └── your_app
    │   │       ├── main.c
    │   │       ├── your_app.c
    │   │       └── your_app.h
    │   ├── build -> ../hw/vendor/x-heep_x-alp/sw/build
    │   ├── device -> ../hw/vendor/x-heep_x-alp/sw/device
    │   ├── linker -> ../hw/vendor/x-heep_x-alp/sw/linker
    │   └── external
    │       └── drivers
    │           └── your_accelerator
    │               ├── your_accelerator.c
    │               └── your_accelerator.h
    ├── hw
    │   └── vendor
    │       ├── x-heep_x-alp.vendor.hjson
    │       └── x-heep_x-alp
    │           ├── sw
    │           ├── Makefile
    │           └── ...
    └── ...

Where `BASE` is your repository's base directory, `x-heep_x-alp` is the vendored X-ALP repository and `your_app` is the name of the application you want to build.

## The sw folder

Your `sw` folder must follow X-ALP's structure, with an `applications`, `build`, `device` and `linker` folder. The `build`, `device` and `linker` folders should be links to the vendored X-ALP folders. In this example, from the `BASE` directory:

```bash
ln -s ../hw/vendor/x-heep_x-alp/sw/build sw/build
ln -s ../hw/vendor/x-heep_x-alp/sw/device sw/device
ln -s ../hw/vendor/x-heep_x-alp/sw/linker sw/linker
```

Then compile your application from the X-ALP folder, passing the path of your `sw` folder **relative to X-ALP's `sw` folder** with the `SOURCE` variable:

```bash
make -C hw/vendor/x-heep_x-alp app PROJECT=your_app SOURCE=../../../../sw
```

## The applications folder

Inside `sw/applications/` you can have several applications, built separately. Each application is a folder named after the application, containing one and only one `main.c` file. The folder can contain other source and header files, with any name but `main.c`.

## The external folder

In the (optional) `external` folder you can add whatever is needed for software to work with your accelerator, such as drivers, sources, headers or links to them. All the sources in `external` are compiled with every application, and all its folders with headers are added to the include path.

The `external` folder and its subfolders must not contain a `device` or an `applications` folder, since they would collide with the corresponding folders in `sw`. They should not contain a `main.c` file either. Files whose path contains `exclude` are not compiled.
