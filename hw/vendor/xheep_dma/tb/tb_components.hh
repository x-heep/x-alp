// Copyright 2024 Politecnico di Torino.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// File: tb_components.hh
// Author(s):
//   Luigi Giuffrida
//   Michele Caon
// Date: 08/11/2024
// Description: Testbench components

#if !defined(TB_COMPONENTS_HH_)
#define TB_COMPONENTS_HH_

#include <verilated.h>
#include "Vdma_tb_wrapper.h"
#include "obi.hh"
#include "reg.hh"

class ObiReqTx
{
public:
    obi_req_t obi_req;

    ObiReqTx();
    ~ObiReqTx();

    void reset();
};

class ObiRspTx
{
public:
    obi_rsp_t obi_rsp;

    ObiRspTx();
    ~ObiRspTx();
};

class RegReqTx
{
public:
    reg_req_t reg_req;

    RegReqTx();
    ~RegReqTx();

    void reset();
};

class RegRspTx
{
public:
    reg_rsp_t reg_rsp;

    RegRspTx();
    ~RegRspTx();
};

class Drv
{
private:
    Vdma_tb_wrapper *dut;

public:
    Drv(Vdma_tb_wrapper *dut);
    ~Drv();

    void drive(ObiReqTx *obi_req, RegReqTx *reg_req);
    
    // overloading function
    void drive(RegReqTx *reg_req);
    void drive (ObiRspTx* obi_read_rsp, ObiRspTx* obi_write_rsp); 
    void drive (ObiRspTx* obi_read_rsp, ObiRspTx* obi_write_rsp, RegReqTx* reg_req_t);

};

class Scb
{
private:
    std::deque<ObiReqTx *> obi_req_q;
    std::deque<ObiRspTx *> obi_rsp_q;
    std::deque<vluint32_t> obi_exp_q;
    std::deque<RegReqTx *> reg_req_q;
    std::deque<RegRspTx *> reg_rsp_q;
    std::deque<vluint32_t> reg_exp_q;
    unsigned int tx_num;
    unsigned int err_num;

    int checkObiData();
    int checkRegData();

public:
    Scb();
    ~Scb();

    void writeObiReq(ObiReqTx *req);
    void writeObiRsp(ObiRspTx *rsp);
    void writeRegReq(RegReqTx *req);
    void writeRegRsp(RegRspTx *rsp);

    bool scheduleObiCheck(vluint32_t exp_value);
    bool scheduleRegCheck(vluint32_t exp_value);
    int checkData();
    int isDone();

    void clearQueues();
    void popObiReq();
    void popRegReq();
    
    void notifyError();
    unsigned int getTxNum();
    unsigned int getErrNum();
};

class ReqMonitor
{
private:
    Vdma_tb_wrapper *dut;
    Scb *scb;

    void monitorObi();
    void monitorReg();

public:
    ReqMonitor(Vdma_tb_wrapper *dut, Scb *scb);
    ~ReqMonitor();

    void monitor();
    bool acceptedObi();
    bool acceptedReg();
};

class RspMonitor
{
private:
    Vdma_tb_wrapper *dut;
    Scb *scb;
    bool obi_pending_read[2]; // at most two outstanding requests

    void monitorObi();
    void monitorReg();

public:
    RspMonitor(Vdma_tb_wrapper *dut, Scb *scb);
    ~RspMonitor();

    void monitor();
    bool isDataReadyObi();
    bool irq();
    vluint32_t getObiData();
    vluint32_t getRegData();
};

#endif // TB_COMPONENTS_HH_
