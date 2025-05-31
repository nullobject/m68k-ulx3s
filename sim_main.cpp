#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vgpu.h"

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  Vgpu *dut = new Vgpu{ contextp };
  contextp->traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC;
  dut->trace(m_trace, 5);
  m_trace->open("waveform.vcd");
  contextp->commandArgs(argc, argv);

  vluint64_t time = 0;

  dut->clk = 0;

  while (time < 100000) {
    dut->rst = time < 4;
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
