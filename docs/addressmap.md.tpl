# Address Map

${"##"} AXI Masters

| Index | Name |
|-------|------|
% for m in xalp.bus().get_axi_masters():
| ${m["idx"]} | ${m["macro"]} |
% endfor

${"##"} AXI Slaves

| Index | Name | Base Address | Size | End Address |
|-------|------|-------------|------|-------------|
% for s in xalp.bus().get_axi_slaves():
| ${s["idx"]} | ${s["macro"]} | `0x${f'{s["base"]:016x}'}` | `0x${f'{s["size"]:016x}'}` | `0x${f'{s["end"]:016x}'}` |
% endfor

${"##"} Register Slaves

| Index | Name | Base Address | Size | End Address |
|-------|------|-------------|------|-------------|
% for r in xalp.bus().get_reg_slaves():
| ${r["idx"]} | ${r["macro"]} | `0x${f'{r["base"]:016x}'}` | `0x${f'{r["size"]:016x}'}` | `0x${f'{r["end"]:016x}'}` |
% endfor
