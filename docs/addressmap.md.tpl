# Address Map

${"##"} Bus Slaves

| Name | Base Address | Size | End Address |
|------|-------------|------|-------------|
% for a_slave in xalp.bus.slaves:
<%
    base = int(a_slave.get_start_address(), 16)
    size = int(a_slave.get_length(), 16)
    end = base + size
%>\
| ${a_slave.name} | `0x${f"{base:016x}"}` | `0x${f"{size:016x}"}` | `0x${f"{end:016x}"}` |
% endfor

<%
    periph_domain = xalp.get_peripheral_domain("peripherals")
    periph_base = int([s for s in xalp.bus.slaves if s.name.upper() == "PERIPHERALS"][0].get_start_address(), 16)
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
