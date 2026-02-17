# Address Map

${"##"} Bus Slaves

| Name | Base Address | Size | End Address |
|------|-------------|------|-------------|
% for a_slave in xalp.bus().get_slaves():
| ${a_slave.name} | `0x${f"{a_slave.start_address:016x}"}` | `0x${f"{a_slave.length:016x}"}` | `0x${f"{a_slave.end_address:016x}"}` |
% endfor

<%
    periph_domain = xalp.get_peripheral_domain("Peripherals")
    periph_slaves = xalp.bus().get_slaves()
    periph_base = [s for s in periph_slaves if s.name.upper() == "PERIPHERALS"][0].start_address
%>\
${"##"} Peripherals

| Name | Base Address | Size | End Address |
|------|-------------|------|-------------|
% for a_peripheral in periph_domain.get_peripherals():
<%
    offset = a_peripheral.get_address()
    size = a_peripheral.get_length()
    abs_base = periph_base + offset
    abs_end = abs_base + size
%>\
| ${a_peripheral._name} | `0x${f"{abs_base:016x}"}` | `0x${f"{size:016x}"}` | `0x${f"{abs_end:016x}"}` |
% endfor
