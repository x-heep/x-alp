#include "common.h"

#include "mmio.h"
#include "soc_ctrl.h"
#include "uart.h"
#include "x-alp.h"

#define __keep asm("");

// UART instance brought up by enable_uart() and shared with the rest of the runtime.
static uart_t g_cvm_uart;

/**
 * PRIVATE
 */

// RV PLIC OBJECT

static inline void enable_irq(void) {
  asm volatile("csrs mstatus, 0x8");
  asm volatile("csrrs x0, mie, %0" ::"r"(0x800) :);
}

// Each bit of CFG_SPM reserves one way as scratchpad; the rest stay cache.
// A program linked into the SPM is *running* out of those ways, so they must
// be locked or the cache will allocate over the code executing from them.
// A program linked into DRAM wants the opposite: every way as cache.
#ifdef SPM
#define LLC_SPM_WAYS_LOW 0xFFFFFFFFu
#define LLC_SPM_WAYS_HIGH 0xFFFFFFFFu
#else
#define LLC_SPM_WAYS_LOW 0u
#define LLC_SPM_WAYS_HIGH 0u
#endif

static void enable_llc(void) {
  *reg32(&__base_axi_llc, AXI_LLC_CFG_SPM_LOW_REG_OFFSET) = LLC_SPM_WAYS_LOW;
  *reg32(&__base_axi_llc, AXI_LLC_CFG_SPM_HIGH_REG_OFFSET) = LLC_SPM_WAYS_HIGH;
  *reg32(&__base_axi_llc, AXI_LLC_COMMIT_CFG_REG_OFFSET) = 1;
}

static cvm_common_err_t enable_uart(void) {
  // The peripheral clock is exposed by the SoC controller (SYSTEM_FREQUENCY_HZ),
  // replacing Cheshire's RTC-derived core frequency.
  soc_ctrl_t soc_ctrl;
  soc_ctrl.base_addr = mmio_region_from_addr((uintptr_t)SOC_CTRL_BASE_ADDRESS);

  g_cvm_uart.base_addr = mmio_region_from_addr((uintptr_t)UART_BASE_ADDRESS);
  g_cvm_uart.baudrate = UART_BAUDRATE;
  g_cvm_uart.clk_freq_hz = soc_ctrl_get_frequency(&soc_ctrl);
#ifdef UART_NCO
  g_cvm_uart.nco = UART_NCO;
#else
  g_cvm_uart.nco = ((uint64_t)g_cvm_uart.baudrate << (NCO_WIDTH + 4)) / g_cvm_uart.clk_freq_hz;
#endif

  if (uart_init(&g_cvm_uart) != kErrorOk) { return CVM_COMMON_ERR_UART; }

  return CVM_COMMON_ENOERR;
}

static void enable_plic(void) {
  // No-op on this platform. The original Cheshire bring-up initialized an
  // rv_plic and enabled the ARCANE accelerator interrupt (src 52). Neither the
  // rv_plic nor ARCANE exist here: peripheral interrupts are routed through the
  // fast_intr_ctrl block, and no source needs to be enabled at boot. Global
  // interrupt enable is handled separately by enable_irq().
}

/**
 * PUBLIC
 */

cvm_common_err_t cvm_init(void) {
  cvm_common_err_t err;

  err = enable_uart();
  if (err != CVM_COMMON_ENOERR) { return err; }

  enable_llc();

  enable_plic();

  enable_irq();

  return CVM_COMMON_ENOERR;
}