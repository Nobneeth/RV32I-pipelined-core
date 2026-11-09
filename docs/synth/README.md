# Synthesis reports

Vivado 2025.1 synthesis, part xc7a15tcpg236-3, 10 ns clock (`constraints/clock.xdc`). Both tops include the instruction and data memories, with `programs/fulltest.mem` loaded into the ROM.

| File | Contents |
|---|---|
| [`util_top.rpt`](util_top.rpt) | Utilization, single-cycle `top` |
| [`timing_top.rpt`](timing_top.rpt) | Timing summary, single-cycle `top` |
| [`util_top_pipe.rpt`](util_top_pipe.rpt) | Utilization, pipelined `top_pipe` |
| [`timing_top_pipe.rpt`](timing_top_pipe.rpt) | Timing summary, pipelined `top_pipe` |
| [`critpath_top_pipe.rpt`](critpath_top_pipe.rpt) | Worst rising-to-rising (full-cycle) path of `top_pipe` |

## Summary

| | `top` | `top_pipe` |
|---|---|---|
| LUTs (logic + LUTRAM) | 836 (756 + 80) | 953 (873 + 80) |
| Flip-flops | 32 | 517 |
| WNS at 10 ns | −4.342 ns | +2.971 ns (half-cycle path), +3.490 ns (full-cycle path) |
| Limiting path | PC → regfile write, 9.15 ns in a 5 ns half cycle | Execute stage, 6.29 ns in 10 ns |
| Minimum period | 2 × (5 + 4.342) = 18.7 ns | 10 − 3.490 = 6.51 ns |
| Fmax | ≈ 53 MHz | ≈ 154 MHz |

The register file writes on the falling clock edge, so any path ending at it has half a period. For the single-cycle core that is the whole datapath, which makes the default `report_timing_summary` show a violation at 10 ns. The minimum period above accounts for this. The pipeline's half-cycle paths (Writeback → regfile write, regfile read → D→E) are short, at about 4 ns of equivalent period, so the full-cycle Execute path sets its Fmax.

To reproduce the full-cycle path report, with `top_pipe` synthesized and opened:

```tcl
report_timing -rise_from [get_clocks clk] -rise_to [get_clocks clk] -max_paths 1
```
