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

  int i = 0;

  while (time < 1000000) {
    dut->rst_n = time >= 4;

    dut->char_ram_we = i < 64 ? 0b11 : 0b00;
    dut->char_ram_addr = i;
    dut->char_ram_data = 0x20 | (i < 32 ? 0x8000 : 0);
    if (dut->clk)
      i++;

    dut->eval();
    m_trace->dump(time);
    dut->clk = !dut->clk;
    time++;
  }

  dut->final();
  m_trace->close();

  contextp->statsPrintSummary();

  delete dut;
  delete contextp;

  return 0;
}
