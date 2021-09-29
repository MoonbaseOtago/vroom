//  UART core define
//
// Author: Jacob Gorban   (jacob.gorban@flextronicssemi.com)
// Company: Flextronics Semiconductor
//
// Filename: UART_defines.v
//
// Releases:
//              1.1     First release
//

`define ADDR_WIDTH	3

// Register addresses
`define REG_RB	0	// receiver buffer
`define REG_TR  0	// transmitter
`define REG_IE	1	// Interrupt enable
`define REG_II  2	// Interrupt identification
`define REG_FC  2	// FIFO control
`define REG_LC	3	// Line Control
`define REG_MC	4	// Modem control
`define REG_LS  5	// Line status
`define REG_MS  6	// Modem status
`define REG_DL1	0	// Divisor latch bytes (1-4)
`define REG_DL2	1
`define REG_DL3	4
`define REG_DL4	5

// Interrupt Enable register bits
`define IE_RDA	0	// Received Data available interrupt
`define IE_THRE	1	// Transmitter Holding Register empty interrupt
`define IE_RLS	2	// Receiver Line Status Interrupt
`define	IE_MS	3	// Modem Status Interrupt

// Interrupt Identification register bits
`define II_IP	0	// Interrupt pending when 0
`define II_II	3:1	// Interrupt identification

// Interrupt identification values for bits 3:1
`define II_RLS	3b`011	// Receiver Line Status
`define II_RDA	3b`010	// Receiver Data available
`define II_TI	3b`110	// Timeout Indication
`define II_THRE	3b`001	// Transmitter Holding Register empty
`define II_MS	3b`000	// Modem Status

// FIFO Control Register bits
`define FC_CR	0	// Clear receiver
`define FC_CT	1	// Clear transmitter
`define FC_TL	3:2	// Trigger level

// FIFO trigger level values
`define FC_1	2b`00
`define FC_4	2b`01
`define FC_8	2b`10
`define FC_14	2b`11

// Line Control register bits
`define LC_BITS	1:0	// bits in character
`define LC_SB	2	// stop bits
`define LC_PE	3	// parity enable
`define LC_EP	4	// even parity
`define LC_SP	5	// stick parity
`define LC_BC	6	// Break control
`define	LC_DL	7	// Divisor Latch access bit

// Modem Control register bits
`define MC_DTR	0
`define MC_RTS	1
`define MC_OUT1	2
`define	MC_OUT2	3
`define	MC_LB	4	// Loopback mode

// Line Status Register bits
`define LS_DR	0	// Data ready
`define LS_OE	1	// Overrun Error
`define LS_PE	2	// Parity Error
`define	LS_FE	3	// Framing Error
`define LS_BI	4	// Break interrupt
`define LS_TFE	5	// Transmit FIFO is empty
`define LS_TE	6	// Transmitter Empty indicator
`define LS_EI	7	// Error indicator

// Modem Status Register bits
`define MS_DCTS	0	// Delta signals
`define MS_DDSR	1
`define MS_TERI	2
`define	MS_DDCD	3
`define MS_CCTS	4	// Complement signals
`define MS_CDSR	5
`define MS_CRI	6
`define	MS_CDCD	7


// FIFO parameter defines

`define FIFO_WIDTH	8
`define FIFO_DEPTH	16
`define FIFO_POINTER_W	4
`define FIFO_COUNTER_W	5
// receiver fifo has width 10 because it has parity and framing error bits
`define FIFO_REC_WIDTH  10
