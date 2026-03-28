// C++ libraries
#include <iostream>
#include <getopt.h>
#include <random>
#include <time.h>

// Verilator libraries
#include <verilated.h>
#include <verilated_fst_c.h>

// DUT header
// todo: create them

// Testbench components
#include "tb_macros.hh"
#include "tb_components.hh"
#include "sw/device/lib/drivers/dma/dma_regs.h"
#include "Vdma_tb_wrapper.h"

// Test data
// todo: make test data

// Defines
// -------
#define FST_FILENAME "logs/tb_dma_waves.fst"
#define END_OF_RESET_TIME 5
#define MAX_SIM_CYCLES 2e6
#define MAX_SIM_TIME (MAX_SIM_CYCLES * 2)
#define WATCHDOG_TIMEOUT 500 // cycles to wait for a program step to complete
#define END_OF_TEST_TIMEOUT 10 // cycles between done assertion and simulation end


// Generate clock and reset
void clkGen(Vdma_tb_wrapper *dut);
void rstDut(Vdma_tb_wrapper *dut, vluint64_t sim_time);

// Run a number of cycles
void runCycles(unsigned int ncycles, Vdma_tb_wrapper *dut, uint8_t gen_waves, VerilatedFstC *trace);

// Generate correct register config for writing
// wstrb is used tell which bytes to actually write 
RegReqTx* genRegWriteReqTx(const vluint32_t addr_offs, const vluint32_t wdata);

// Generate correct register config for reading 
RegReqTx* genRegReadReqTx(const vluint32_t addr_offs); //, const vluint32_t wdata);

// Generate OBI response 
ObiRspTx* genObiRspTx (const vluint32_t rdata);

// Global variables
vluint64_t sim_cycles = 0;
TbLogger logger;    // testbench logger


int main (int argc, char *argv[]){
 
    // Define command-line options
    const option longopts[] = {
        {"log_level", required_argument, NULL, 'l'},
        {"gen_waves", required_argument, NULL, 'w'},
        {"seed", required_argument, NULL, 's'},
        {NULL, 0, NULL, 0}
    };

    // Process command-line options
    // ----------------------------
    int opt; // current option
    int prg_seed = time(NULL);
    bool gen_waves = true;
    while ((opt = getopt_long(argc, argv, "l:w:", longopts, NULL)) >= 0)
    {
        switch (opt)
        {
        case 'l': // set the log level
            logger.setLogLvl(optarg);
            TB_CONFIG("Log level set to %s", optarg);
            break;
        case 'w': // generate waves
            if (!strcmp(optarg, "true")) {
                gen_waves = 1;
                TB_CONFIG("Waves enabled");
            }
            else {
                gen_waves = 0;
                TB_CONFIG("Waves disabled");
            }
            break;
        case 's': // set the seed
            prg_seed = atoi(optarg);
            TB_CONFIG("Seed set to %d", prg_seed);
            break;
        default:
            TB_ERR("ERROR: unrecognised option %c.\n", opt);
            exit(EXIT_FAILURE);
        }
    }
    
    // Create Verilator simulation context
    VerilatedContext *cntx = new VerilatedContext;

    // Pass simulation context to the logger
    logger.setSimContext(cntx);

    if (gen_waves)
    {
        Verilated::mkdir("logs");
        cntx->traceEverOn(true);
    }

    // Instantiate DUT
    Vdma_tb_wrapper* dut = new Vdma_tb_wrapper(cntx);

    // Set the file to store the waveforms in
    VerilatedFstC *trace = NULL;
    if (gen_waves)
    {
        trace = new VerilatedFstC;
        dut->trace(trace, 10);
        trace->open(FST_FILENAME);
    }

     // TB components
    Drv *drv = new Drv(dut);
    Scb *scb = new Scb();
    ReqMonitor *reqMon = new ReqMonitor(dut, scb);
    RspMonitor *rspMon = new RspMonitor(dut, scb);

    // Initialize PRG
    srand(prg_seed);

    // Simulation program
    // ------------------

  
    // Define simulation program variables
    vluint32_t src_ptr = 0x20;
    vluint32_t dst_ptr = 0xDD;
    vluint32_t d1_size = 0xA;
    vluint32_t d2_stride = 0xAA;
    vluint32_t d2_size = 0x2;
    vluint32_t mock_value = 0xAF;
    // comes from host -> shouldn't be needed
    ObiReqTx *obi_req = NULL;

    // comes from device
    ObiRspTx* obi_read_rsp = NULL;
    ObiRspTx* obi_write_rsp = NULL;
    vluint32_t obi_rdata = 0;
    uint32_t obi_data = 0;
    uint32_t obi_addr = 0;
    unsigned int data_size = 0;
    bool obi_accepted = 0;

    // unsure on these
    RegReqTx *reg_req = NULL;
    vluint32_t reg_rdata = 0;
    bool reg_accepted = false;

    // on these as well
    bool irq_received = 0;

    // used to check reads
    bool reg_check_req = false;
    vluint32_t reg_check_data = 0;
    

    bool end_of_test = false;
    unsigned int exit_timer = 0;
    unsigned int watchdog = 0;
    unsigned int prev_step_cnt = 0;
    unsigned int step_cnt = 0;
    
    TB_LOG(LOG_LOW, "Starting simulation...");
    
    while (!cntx->gotFinish() && cntx->time() < MAX_SIM_TIME)
    {
        // Generate clock and reset
        rstDut(dut, cntx->time());
        clkGen(dut);

        // Evaluate simulation step
        dut->eval();

        if (dut->clk_i == 1 && cntx->time() > END_OF_RESET_TIME)
        {

             // Reset check schedule requests
            reg_check_req = false;

            switch (step_cnt)
            {
            // TO BE REWRITTEN FOR DMA

            
            case 0:
                if (!reg_accepted) {
                    TB_LOG(LOG_HIGH, "## Writing '%x' to address '%x'", src_ptr, DMA_SRC_PTR_REG_OFFSET);
                    reg_req = genRegWriteReqTx(
                        DMA_SRC_PTR_REG_OFFSET, // which reg to write to
                        src_ptr            // what to write to
                    );
                    break;
                }
                reg_accepted=false;
                step_cnt++; //fall through 

            // test if writing went ok
            case 1:
                if (!reg_accepted) {
                    TB_LOG(LOG_HIGH, "## Reading reg at address '%x'", DMA_SRC_PTR_REG_OFFSET);
                    reg_req = genRegReadReqTx(
                        DMA_SRC_PTR_REG_OFFSET // which reg to read from
                    );
                    reg_check_req = true;
                    reg_check_data = src_ptr;
                    break;
                }
                reg_accepted=false;
                step_cnt++; // fall through 


            case 2:
                if (!reg_accepted) {
                    TB_LOG(LOG_HIGH, "## Writing '%x' to address '%x'", dst_ptr, DMA_DST_PTR_REG_OFFSET);
                    reg_req = genRegWriteReqTx(
                        DMA_DST_PTR_REG_OFFSET, // which reg to write to
                        dst_ptr            // what to write to
                    );
                    break;
                }
                reg_accepted=false;
                step_cnt++; //fall through 

            // test if writing went ok
            case 3:
                if (!reg_accepted) {
                    TB_LOG(LOG_HIGH, "## Reading reg at address '%x'", DMA_DST_PTR_REG_OFFSET);
                    reg_req = genRegReadReqTx(
                        DMA_DST_PTR_REG_OFFSET // which reg to read from
                    );
                    reg_check_req = true;
                    reg_check_data = dst_ptr;
                    break;
                }
                reg_accepted=false;
                step_cnt++; // fall through 

            /* Write d2 stride */ 
            case 4:
                if (!reg_accepted){
                    TB_LOG(LOG_HIGH, "## Writing reg at address '%x'", DMA_SRC_PTR_INC_D2_REG_OFFSET);
                    reg_req = genRegWriteReqTx(
                        DMA_SRC_PTR_INC_D2_REG_OFFSET, // which reg to read from
                        d2_stride
                    );
                    break;
                }
                reg_accepted=false;
                step_cnt++; // fall through

            
            /* Write d2 size */ 
            case 5:
                if (!reg_accepted){
                    TB_LOG(LOG_HIGH, "## Writing reg at address '%x'", DMA_SIZE_D2_REG_OFFSET);
                    reg_req = genRegWriteReqTx(
                        DMA_SIZE_D2_REG_OFFSET, // which reg to read from
                        d2_size
                    );
                    break;
                }
                reg_accepted=false;
                step_cnt++; // fall through

            /* Write Dim Config to set 2D trans*/
            case 6:
                if (!reg_accepted){
                    TB_LOG(LOG_HIGH, "## Writing reg at address '%x'", DMA_DIM_CONFIG_REG_OFFSET);
                    reg_req = genRegWriteReqTx(
                        DMA_DIM_CONFIG_REG_OFFSET, // which reg to read from
                        true
                    );
                    break;
                }
                reg_accepted=false;
                step_cnt++; // fall through

            /* Write d1 size to START DMA */ 
            case 7:
                if (!reg_accepted){
                    TB_LOG(LOG_HIGH, "## Writing reg at address '%x'", DMA_SIZE_D1_REG_OFFSET);
                    reg_req = genRegWriteReqTx(
                        DMA_SIZE_D1_REG_OFFSET, // which reg to read from
                        d1_size
                    );
                    break;
                }
                reg_accepted=false;
                step_cnt++; // fall through

            /* Wait some cycles*/
            case 8 ... 11:
                step_cnt++;
                break;

            /* Generate OBI response from mocked mem*/
            case 12:
                TB_LOG(LOG_HIGH, "## Writing OBI response with value '%x'", mock_value);
                obi_read_rsp = genObiRspTx (mock_value++);
                obi_write_rsp = genObiRspTx(mock_value);
                
                step_cnt++; // fall through

            /* Let DMA work and change mock value */
            case 13 ... 30:
                step_cnt++;
                obi_read_rsp = genObiRspTx (mock_value++);
                obi_write_rsp = genObiRspTx(mock_value);
                break;
    
           
            default:
                // Set simulation exit flag
                end_of_test = true;
                break;
            }
            
            // Drive DUT inputs 
            drv->drive(reg_req);

            // Read OBI responses from devices
            drv->drive(obi_read_rsp, obi_write_rsp);

            delete obi_read_rsp;
            delete obi_write_rsp;
            delete reg_req;
            obi_read_rsp = NULL;
            obi_write_rsp = NULL;
            reg_req = NULL;

            // Update input signals
            dut->eval();

            // Monitor DUT signals
            reqMon->monitor();
            rspMon->monitor();
            
            irq_received = rspMon->irq();
            
            // should not be used since DMA is host 
            // obi_accepted = reqMon->acceptedObi();
            reg_accepted = reqMon->acceptedReg();

            // Get register data (to be used in the test program above)
            if (reg_accepted) {
                reg_rdata = rspMon->getRegData();
                if (reg_check_req) scb->scheduleRegCheck(reg_check_data);
            }
            if (rspMon->isDataReadyObi()) obi_rdata = rspMon->getObiData();

            // Trigger scheduled checks
            if (scb->checkData() != 0) end_of_test = true;

            // Check for exit conditions
            if (prev_step_cnt != step_cnt) watchdog = 0;
            else watchdog++;
            if (watchdog > WATCHDOG_TIMEOUT) {
                TB_WARN("Watchdog timeout reached: terminating simulation.");
                scb->notifyError();
                break;
            }
            prev_step_cnt = step_cnt;
            if (end_of_test)
            {
                if (exit_timer++ == END_OF_TEST_TIMEOUT) {
                    TB_LOG(LOG_MEDIUM, "End of simulation reached: terminating.");
                    break;
                }
            }
        }

        // Dump waveforms and advance simulation time
        if (gen_waves) trace->dump(cntx->time());
        if (dut->clk_i == 1) sim_cycles++;
        cntx->timeInc(1);
    }

    // Simulation complete
    dut->final();

    // Print simulation summary
    if (scb->getErrNum() > 0)
    {
        TB_ERR("CHECKS FAILED > errors: %u/%u", scb->getErrNum(), scb->getTxNum());
        if (gen_waves) trace->close();
        exit(EXIT_SUCCESS);
    }
    else if (!scb->isDone())
    {
        TB_ERR("CHECKS PENDING > errors: %u/%u", scb->getErrNum(), scb->getTxNum());
        if (gen_waves) trace->close();
        exit(EXIT_SUCCESS);
    }
    TB_SUCCESS(LOG_LOW, "CHECKS PASSED > errors: %u (checked %u transactions)", scb->getErrNum(), scb->getTxNum());

    // Clean up and exit
    if (gen_waves) trace->close();
    delete dut;
    delete cntx;
    delete obi_read_rsp;
    delete obi_write_rsp;
    delete reg_req;

    return 0;

}


void clkGen(Vdma_tb_wrapper *dut)
{
    dut->clk_i ^= 1;
}


void rstDut(Vdma_tb_wrapper *dut, vluint64_t sim_time)
{
    dut->rst_ni = 1;
    if (sim_time > 1 && sim_time < END_OF_RESET_TIME)
    {
        dut->rst_ni = 0;
    }
}



void runCycles(unsigned int ncycles, Vdma_tb_wrapper *dut, uint8_t gen_waves, VerilatedFstC *trace)
{
    VerilatedContext *cntx = dut->contextp();
    for (unsigned int i = 0; i < (2 * ncycles); i++)
    {
        // Generate clock
        clkGen(dut);

        // Evaluate the DUT
        dut->eval();

        // Save waveforms
        if (gen_waves)
            trace->dump(cntx->time());
        if (dut->clk_i == 1)
            sim_cycles++;
        cntx->timeInc(1);
    }
}


// Issue register interface transaction
RegReqTx *genRegWriteReqTx(const vluint32_t addr_offs, const vluint32_t wdata)
{
    RegReqTx *req = new RegReqTx;

    // DMA transaction request
    req->reg_req.valid = 1;
    req->reg_req.write = 1;
    req->reg_req.wstrb = 0xff; //mask
    req->reg_req.addr = addr_offs;
    req->reg_req.wdata = wdata;

    return req;
}


// Issue read register interface transaction
RegReqTx *genRegReadReqTx(const vluint32_t addr_offs)
{
    RegReqTx *req = new RegReqTx;

    // dma regs read request
    req->reg_req.valid = 1;
    req->reg_req.write = 0;
    req->reg_req.wstrb = 0xf;
    req->reg_req.addr = addr_offs;
    req->reg_req.wdata = 0;

    return req;
}

RegReqTx *genRegIdleTx(){
    
    RegReqTx *req = new RegReqTx;

    // dma regs read request
    req->reg_req.valid = 0;
    req->reg_req.write = 0;
    req->reg_req.wstrb = 0xf;
    req->reg_req.addr = 0;
    req->reg_req.wdata = 0;

    return req;

} 

ObiRspTx* genObiRspTx (const vluint32_t rdata){

    ObiRspTx* req = new ObiRspTx;

    req->obi_rsp.gnt    = 1;    
    req->obi_rsp.rvalid = 1;
    req->obi_rsp.rdata  = rdata;

    return req;
}