# eXtending X-ALP

X-ALP is meant to be extended with your own custom IPs. X-ALP itself is a hardware-software platform able to work standalone. If you want to extend it, you need to merge your hardware and software with X-ALP's, without modifying X-ALP itself.

For this purpose, the `x_alp` top level exposes:

- an **AXI slave** window (`ext_slv_req_o`/`ext_slv_rsp_i`), mapped to the `ext_slaves` region (`0xF000_0000`, 16 MiB by default), to connect accelerators and memories that the CPU accesses;
- an **AXI master** port (`ext_mst_req_i`/`ext_mst_rsp_o`), to connect IPs that access the X-ALP memory map, e.g. DMAs or accelerators with their own memory port;
- a **register-interface** port (`ext_reg_req_o`/`ext_reg_rsp_i`), mapped to the `ext_peripheral` slot of the peripheral domain, to connect the control registers of an external peripheral;
- the **LLC master** port (`ext_llc_req_o`/`ext_llc_rsp_i`), to connect the DRAM.

To learn how to extend X-ALP, read the guides in this section.

```{toctree}
:maxdepth: 3
:numbered: 1

eXtendingHW
eXtendingSW
```
