//
// Spartan bus split - one master to two slaves
//
// by
//     David Koltak  03/23/2012
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

module spartan_split
(
    CLK,
    RST,
    
    SpMBUS,
    SpMVLD,
    SpMRDY,
    
    SpSBUS,
    SpSVLD,
    SpSRDY,
    
    SpMBUS_0,
    SpMVLD_0,
    SpMRDY_0,
    
    SpSBUS_0,
    SpSVLD_0,
    SpSRDY_0,

    SpMBUS_1,
    SpMVLD_1,
    SpMRDY_1,
    
    SpSBUS_1,
    SpSVLD_1,
    SpSRDY_1        
);

    parameter ADDR_MASK = 32'hFFFF0000;  // Route to slave 1 if matches, slave 0 otherwise
    parameter ADDR_MTCH = 32'h12340000;
    parameter BWIDTH = 64;

    input CLK;
    input RST;
    
    input [BWIDTH+1:0] SpMBUS;
    input SpMVLD;
    output SpMRDY;
    
    output [BWIDTH+1:0] SpSBUS;
    output SpSVLD;
    input SpSRDY;
    
    output [BWIDTH+1:0] SpMBUS_0;
    output SpMVLD_0;
    input SpMRDY_0;
    
    input [BWIDTH+1:0] SpSBUS_0;
    input SpSVLD_0;
    output SpSRDY_0;

    output [BWIDTH+1:0] SpMBUS_1;
    output SpMVLD_1;
    input SpMRDY_1;
    
    input [BWIDTH+1:0] SpSBUS_1;
    input SpSVLD_1;
    output SpSRDY_1;
      
    reg rst_in;
    
    always @ (posedge CLK)
        rst_in <= RST;
  
    //
    // MASTER BUS ROUTING
    //
    
    wire [BWIDTH+1:0] mbus;
    wire mvld;
    wire mrdy;
    
    spartan_skid #(.DATA_WIDTH(BWIDTH+2)) master_skid
    (
        .CLK(CLK),
        .RST(rst_in),

        .DIN(SpMBUS),
        .DIN_VAL(SpMVLD),
        .DIN_RDY(SpMRDY),

        .DOUT(mbus),
        .DOUT_VAL(mvld),
        .DOUT_RDY(mrdy)
    );

    wire address_match = ((mbus[31:0] & ADDR_MASK) == (ADDR_MTCH & ADDR_MASK));
    
    reg last_target;
    always @ (posedge CLK)
        if (mvld && !mbus[BWIDTH+1]) last_target <= address_match;

    wire trans_target = (mbus[BWIDTH+1]) ? last_target : address_match;
    
    assign SpMBUS_0 = mbus;
    assign SpMVLD_0 = mvld && !trans_target;
    
    assign SpMBUS_1 = mbus;
    assign SpMVLD_1 = mvld && trans_target;
    
    assign mrdy = (trans_target) ? SpMRDY_1 : SpMRDY_0;

    //
    // SLAVE BUS MERGE
    //
    
    wire [BWIDTH+1:0] sbus;
    wire svld;
    wire srdy;
    
    wire last_0 = (SpSBUS_0[BWIDTH+1:BWIDTH] == 2'b00) || (SpSBUS_0[BWIDTH+1:BWIDTH] == 2'b11);
    wire last_1 = (SpSBUS_1[BWIDTH+1:BWIDTH] == 2'b00) || (SpSBUS_1[BWIDTH+1:BWIDTH] == 2'b11);
    wire sel_1;
    
    spartan_arb spartan_arb
    (
        .CLK(CLK),
        .RST(rst_in),

        .VALID_A(SpSVLD_0),
        .LAST_A(last_0),
        .READY_A(SpSRDY_0),

        .VALID_B(SpSVLD_1),
        .LAST_B(last_1),
        .READY_B(SpSRDY_1),

        .VALID(svld),
        .READY(srdy),
        .SEL_A(),
        .SEL_B(sel_1)
    );

    assign sbus = (sel_1) ? SpSBUS_1 : SpSBUS_0;

    spartan_skid #(.DATA_WIDTH(BWIDTH+2)) slave_skid
    (
        .CLK(CLK),
        .RST(rst_in),

        .DIN(sbus),
        .DIN_VAL(svld),
        .DIN_RDY(srdy),

        .DOUT(SpSBUS),
        .DOUT_VAL(SpSVLD),
        .DOUT_RDY(SpSRDY)
    );
    
endmodule
