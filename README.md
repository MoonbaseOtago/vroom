# VRoom! RISC-V CPU

![Moonbase Logo](https://moonbaseotago.github.io/talk/assets/moonbase_small.png)

## A new high-end RISC-V implementation
Paul Campbell - October 2021

paul@taniwha.com @moonbaseotago

(C) Copyright Moonbase Otago 2021

## Executive summary
* Very high end RISC-V implementation – goal cloud server class
* Out of order, super scalar, speculative
* RV64-IMAFDCHB(V)
* Up to 8 IPC (instructions per clock) peak, goal ~4 average on ALU heavy work
* 2-way simultaneous multithreading capable
* Multi-core
* Early dhrystone numbers: ~4 DMips/MHz - still a work in progress. Goal 5+
* Currently boots Linux on an AWS-FPGA instance
* GPL3 – dual licensing possible

[Detailed architectural presentation](https://moonbaseotago.github.io/talk/index.html)

