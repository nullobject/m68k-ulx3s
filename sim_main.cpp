#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Voled.h"

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  Voled *dut = new Voled{ contextp };
  contextp->traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC;
  dut->trace(m_trace, 5);
  m_trace->open("waveform.vcd");
  contextp->commandArgs(argc, argv);

  vluint64_t time = 0;

  dut->clk = 0;
  dut->rst = 0;

  while (!dut->done) {
    dut->clk = !dut->clk;
    dut->eval();
    m_trace->dump(time);
    time++;
  }

  dut->final();
  m_trace->close();

  contextp->statsPrintSummary();

  delete dut;
  delete contextp;

  return 0;
}
