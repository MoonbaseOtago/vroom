#include <stdlib.h>
#include "Vchip__Syms.h"
#include "Vchip.h"
#include "verilated.h"
#include <verilated_vcd_c.h>

class TESTBENCH {
public:
	
	unsigned long	m_tickcount;
	unsigned long	m_ticklimit;
	unsigned long   m_trace_start;
	Vchip	*m_core;
	VerilatedVcdC	*m_trace;

	TESTBENCH(void) {
		m_core = new Vchip;
		m_tickcount = 0l;
		m_ticklimit = 0l;
		m_trace = 0;
		m_trace_start = 0;
	}

	virtual ~TESTBENCH(void) {
		delete m_core;
		m_core = NULL;
	}
	virtual	void	opentrace(const char *vcdname) {
		if (!m_trace) {
			m_trace = new VerilatedVcdC;
			m_core->trace(m_trace, 99);
			m_trace->open(vcdname);
		}
	}
	virtual void	close(void) {
		if (m_trace) {
			m_trace->close();
			m_trace = NULL;
		}
	}

	virtual void	reset(void) {
		m_core->ireset = 1;
		// Make sure any inheritance gets applied
		this->tick();
		m_core->ireset = 0;
	}

	virtual void	tick(void) {
		int t;
		// Increment our own internal time reference
		m_tickcount+=5;
		m_core->clk_in = 0;
		m_core->eval();
		if (m_trace) {
			// This portion, though, is a touch different.
			// After dumping our values as they exist on the
			// negative clock edge ...
			m_trace->dump(m_tickcount);
			//
			// We'll also need to make sure we flush any I/O to
			// the trace file, so that we can use the assert()
			// function between now and the next tick if we want to.
			m_trace->flush();
		} else 
		if (m_trace_start && m_trace_start <= m_tickcount) {
			Verilated::traceEverOn(true);
			opentrace("trace.vcd");
			m_trace->dump(m_tickcount);
			m_trace->flush();
		}
		m_tickcount+=5;
		m_core->clk_in = 1;
		m_core->eval();
		if(m_trace) m_trace->dump(m_tickcount);

		if (m_ticklimit && m_tickcount >= m_ticklimit) {
			vl_finish("req", 0, "hier");
		}
		if ((m_tickcount%10000)==0){fflush(stdout);}
	}
	virtual void start(bool pipe_trace, bool deep_trace, bool pipe_trace_enable, const char **file, uint64_t *addr, int load_count, unsigned long limit, unsigned long start, bool boot)
	{
		FILE *f;
		int i;

		m_trace_start = start;
		m_ticklimit = limit*10;
		if (boot) {
			
			m_core->gpio_pads = 1;
			m_core->block_addr_0 = 0;
                        m_core->block_count_0 = 0;
                        m_core->block_addr_1 = 0;
                        m_core->block_count_1 = 0;
			for (int k = 0; k < load_count; k++) {
				f = fopen(file[k], "r");
				if (!f) {
					fprintf(stderr, "can't open %s\n", file[k]);
					exit(2);
				}
				for (i = addr[k]/8; ; i++) {
					if (fread(&m_core->rootp->chip__DOT__io_switch__DOT__sd__DOT__disk[i], 8, 1, f) <= 0)
						break;
				}
				fclose(f);
				switch (k) {
                                case 0: m_core->block_addr_0 = addr[k];
                                        m_core->block_count_0 = ((i>>5)+1);
                                        break;
                                case 1: m_core->block_addr_1 = addr[k];
                                        m_core->block_count_1 = ((i>>5)+1);;
                                        break;
                                }

			}
		} else {
			m_core->gpio_pads = 0;
			for (int k = 0; k < load_count; k++) {
				f = fopen(file[k], "r");
				if (!f) {
					fprintf(stderr, "can't open %s\n", file[k]);
					exit(2);
				}
				//printf("Loading %s @ 0x%lx\n", file[k], addr[k]);
				for (i = addr[k]/64; ; i++) {
					if (fread(&m_core->rootp->chip__DOT__mem__DOT__mem[i][0], 64, 1, f) <= 0)
						break;
				}
				fclose(f);
			}
		}
		m_core->clk_in = 0;
		//m_core->clkX4 = 0; m_core->clkX4_phase = 1;
		m_core->cpu_id = 0;
		m_core->simd_enable = (pipe_trace?1:0);
		m_core->pipe_enable = (deep_trace?1:0);
		m_core->simd_trace_enable = (pipe_trace_enable?1:0);
		m_core->ireset = 1;
		m_core->eval();
		m_tickcount=10;
		m_core->clk_in = 1;
		//m_core->clkX4 = 1;
		m_core->eval();
		//m_core->clkX4 = 0; m_core->clkX4_phase = 1;
		m_core->clk_in = 0;
		m_core->eval();
		//m_tickcount+=5;
		m_core->clk_in = 1;
		//m_core->clkX4 = 1;
		m_core->eval();
		//m_core->clkX4 = 0;
		m_core->clk_in = 0;
		m_core->eval();
		m_core->ireset = 0;
	}

	virtual bool	done(void) { return (Verilated::gotFinish()); }
};

TESTBENCH *tb;
double sc_time_stamp()
{
	return tb->m_tickcount;//*10.0;
}

int
main(int argc, char **argv)
{
	bool pipe_trace=0, pipe_trace_enable=1, trace=0, deep_trace=0;
	int load_ind = 0;
	const char *load[32] = {0};
	uint64_t addr[32]={0};
	unsigned long limit=0;
	unsigned long log_start=0;
	bool boot=0;
	// Initialize Verilators variables
	uint64_t next_addr = 0;

	for (int i = 1; i < argc; i++) {
		if (!strncmp(argv[i], "-l", 2)) 
			limit = atol(&argv[i][2]);
		if (!strncmp(argv[i], "-s", 2)) {
			if (argv[i][2]) {
				log_start = atol(&argv[i][2]);
			} else
			if (i < (argc-1)) {
				i++;
				log_start = strtol(argv[i], 0, 0);
			}
		}
		if (!strcmp(argv[i], "-t"))
			trace = 1;
		if (!strcmp(argv[i], "-b") || !strcmp(argv[i], "+b")) 
			boot = 1;
		if (!strcmp(argv[i], "-p"))
			pipe_trace = 1;
		if (!strcmp(argv[i], "-d"))
			deep_trace = 1;
		if (!strcmp(argv[i], "-T"))
			pipe_trace_enable = 1-pipe_trace_enable;
		if (!strcmp(argv[i], "-a") && i < (argc-1)) {
			i++;
			next_addr = strtol(argv[i], 0, 0);
			continue;
		} 
		if (argv[i][0]!='+' && argv[i][0]!='-') {
			load[load_ind] = argv[i];
			addr[load_ind] = next_addr;
			load_ind++;
		}
	}
	Verilated::commandArgs(argc, argv);
	tb = new TESTBENCH();

	

	// Create an instance of our module under test
	if (trace) {
		Verilated::traceEverOn(true);
		tb->opentrace("trace.vcd");
	}
	if (load_ind == 0) {
		load[0] = "x.bin";
		addr[0] = 0;
		load_ind = 1;
	}
		
	// Tick the clock until we are done
	tb->start(pipe_trace, deep_trace, pipe_trace_enable, &load[0], &addr[0], load_ind, limit, log_start, boot);
	while(!tb->done()) {
		tb->tick();
	}
	exit(EXIT_SUCCESS);
}
