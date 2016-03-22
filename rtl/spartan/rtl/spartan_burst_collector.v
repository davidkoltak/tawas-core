//
// Sync gasket for Spartan bus
//
// by
//     David Koltak  05/27/2012
//
// The MIT License (MIT)
// 
// Copyright (c) 2016 David M. Koltak
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// 

module spartan_burst_collector
(
    CLK,
    RST,
    
    SpMBUS_A,
    SpMVLD_A,
    SpMRDY_A,
    
    SpSBUS_A,
    SpSVLD_A,
    SpSRDY_A,
    
    SpMBUS_B,
    SpMVLD_B,
    SpMRDY_B,
    
    SpSBUS_B,
    SpSVLD_B,
    SpSRDY_B    
);
    parameter BWIDTH = 64;
    
    input CLK;
    input RST;
    
    input [BWIDTH+1:0] SpMBUS_A;
    input SpMVLD_A;
    output SpMRDY_A;
    
    output [BWIDTH+1:0] SpSBUS_A;
    output SpSVLD_A;
    input SpSRDY_A;

    output [BWIDTH+1:0] SpMBUS_B;
    output SpMVLD_B;
    input SpMRDY_B;
    
    input [BWIDTH+1:0] SpSBUS_B;
    input SpSVLD_B;
    output SpSRDY_B;
    
    wire spmrdy_in;
    assign SpMRDY_A = spmrdy_in;
    
    wire spmvld_out;
    wire [BWIDTH+1:0] spmbus_out;
    assign SpMBUS_B = spmbus_out;
    
    wire spsrdy_in;
    assign SpSRDY_B = spsrdy_in;
    
    wire spsvld_out;
    wire [BWIDTH+1:0] spsbus_out;
    assign SpSBUS_A = spsbus_out;
   
    
    reg [2:0] spm_wr_hdr_cnt;
    reg [2:0] spm_wr_lst_cnt;
    wire spm_stall = (spmbus_out[BWIDTH+1:BWIDTH] == 2'b01) ? (spm_wr_lst_cnt == spm_wr_hdr_cnt) : 1'b0;
    
    always @ (posedge CLK or posedge RST)
        if (RST) spm_wr_lst_cnt <= 3'd0;
        else if ((SpMBUS_A[BWIDTH+1:BWIDTH] == 2'b11) && SpMVLD_A && spmrdy_in) spm_wr_lst_cnt <= spm_wr_lst_cnt + 3'd1;
        
    always @ (posedge CLK or posedge RST)
        if (RST) spm_wr_hdr_cnt <= 3'd0;
        else if ((spmbus_out[BWIDTH+1:BWIDTH] == 2'b01) && spmvld_out && !spm_stall && SpMRDY_B) spm_wr_hdr_cnt <= spm_wr_hdr_cnt + 3'd1;


    reg [2:0] sps_rd_hdr_cnt;
    reg [2:0] sps_rd_lst_cnt;
    wire sps_stall = (spsbus_out[BWIDTH+1:BWIDTH] == 2'b01) ? (sps_rd_lst_cnt == sps_rd_hdr_cnt) : 1'b0;
    
    always @ (posedge CLK or posedge RST)
        if (RST) sps_rd_lst_cnt <= 3'd0;
        else if ((SpSBUS_B[BWIDTH+1:BWIDTH] == 2'b11) && SpSVLD_B && spsrdy_in) sps_rd_lst_cnt <= sps_rd_lst_cnt + 3'd1;
        
    always @ (posedge CLK or posedge RST)
        if (RST) sps_rd_hdr_cnt <= 3'd0;
        else if ((spsbus_out[BWIDTH+1:BWIDTH] == 2'b01) && spsvld_out && !sps_stall && SpSRDY_A) sps_rd_hdr_cnt <= sps_rd_hdr_cnt + 3'd1;
        
        
    spartan_fifo #(.DATA_WIDTH(BWIDTH+2)) master_fifo
    (
        .CLK(CLK),
        .RST(RST),

        .DIN(SpMBUS_A),
        .DIN_VAL(SpMVLD_A),
        .DIN_RDY(spmrdy_in),

        .DOUT(spmbus_out),
        .DOUT_VAL(spmvld_out),
        .DOUT_RDY(SpMRDY_B && !spm_stall)
    );

    assign SpMVLD_B = spmvld_out && !spm_stall;


    spartan_fifo #(.DATA_WIDTH(BWIDTH+2)) slave_fifo
    (
        .CLK(CLK),
        .RST(RST),

        .DIN(SpSBUS_B),
        .DIN_VAL(SpSVLD_B),
        .DIN_RDY(spsrdy_in),

        .DOUT(spsbus_out),
        .DOUT_VAL(spsvld_out),
        .DOUT_RDY(SpSRDY_A && !sps_stall)
    );    
    
    assign SpSVLD_A = spsvld_out && !sps_stall;
        
endmodule
