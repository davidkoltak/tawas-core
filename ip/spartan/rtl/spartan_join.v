//
// Spartan bus join - two masters to one slave
//
// NOTE: ID_WIDTH is for input, output will have an addition bit of ID for response routing
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

module spartan_join
(
    CLK,
    RST,
    
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
    SpSRDY_1,
    
    SpMBUS,
    SpMVLD,
    SpMRDY,
    
    SpSBUS,
    SpSVLD,
    SpSRDY       
);

    parameter ID_WIDTH = 5;
    parameter BWIDTH = 64;
    
    input CLK;
    input RST;
    
    input [BWIDTH+1:0] SpMBUS_0;
    input SpMVLD_0;
    output SpMRDY_0;
    
    output [BWIDTH+1:0] SpSBUS_0;
    output SpSVLD_0;
    input SpSRDY_0;

    input [BWIDTH+1:0] SpMBUS_1;
    input SpMVLD_1;
    output SpMRDY_1;
    
    output [BWIDTH+1:0] SpSBUS_1;
    output SpSVLD_1;
    input SpSRDY_1;
    
    output [BWIDTH+1:0] SpMBUS;
    output SpMVLD;
    input SpMRDY;
    
    input [BWIDTH+1:0] SpSBUS;
    input SpSVLD;
    output SpSRDY;

    reg rst_in;
    
    always @ (posedge CLK)
        rst_in <= RST;
        
    //
    // MASTER BUS MERGE
    //
    
    wire [BWIDTH+1:0] mbus;
    wire mvld;
    wire mrdy;
    
    wire last_0 = (SpMBUS_0[BWIDTH+1:BWIDTH] == 2'b00) || (SpMBUS_0[BWIDTH+1:BWIDTH] == 2'b11);
    wire last_1 = (SpMBUS_1[BWIDTH+1:BWIDTH] == 2'b00) || (SpMBUS_1[BWIDTH+1:BWIDTH] == 2'b11);
    wire sel_1;
    
    spartan_arb spartan_arb
    (
        .CLK(CLK),
        .RST(rst_in),

        .VALID_A(SpMVLD_0),
        .LAST_A(last_0),
        .READY_A(SpMRDY_0),

        .VALID_B(SpMVLD_1),
        .LAST_B(last_1),
        .READY_B(SpMRDY_1),

        .VALID(mvld),
        .READY(mrdy),
        .SEL_A(),
        .SEL_B(sel_1)
    );

    assign mbus = (sel_1) ? SpMBUS_1 : SpMBUS_0;
    wire [BWIDTH+1:0] mbus_id = {mbus[BWIDTH+1:42+ID_WIDTH], sel_1, mbus[40+ID_WIDTH:0]};
    
    spartan_skid #(.DATA_WIDTH(BWIDTH+2)) master_skid
    (
        .CLK(CLK),
        .RST(rst_in),

        .DIN((mbus[BWIDTH+1]) ? mbus : mbus_id),
        .DIN_VAL(mvld),
        .DIN_RDY(mrdy),

        .DOUT(SpMBUS),
        .DOUT_VAL(SpMVLD),
        .DOUT_RDY(SpMRDY)
    );
    
    //
    // SLAVE BUS ROUTE
    //

    wire [BWIDTH+1:0] sbus;
    wire svld;
    wire srdy;
    
    spartan_skid #(.DATA_WIDTH(BWIDTH+2)) slave_skid
    (
        .CLK(CLK),
        .RST(rst_in),

        .DIN(SpSBUS),
        .DIN_VAL(SpSVLD),
        .DIN_RDY(SpSRDY),

        .DOUT(sbus),
        .DOUT_VAL(svld),
        .DOUT_RDY(srdy)
    );
    
    reg last_target;
    always @ (posedge CLK)
        if (svld && !sbus[BWIDTH+1]) last_target <= sbus[41+ID_WIDTH];

    wire trans_target = (sbus[BWIDTH+1]) ? last_target : sbus[41+ID_WIDTH];

    assign SpSBUS_0 = sbus;
    assign SpSVLD_0 = svld && !trans_target;
    
    assign SpSBUS_1 = sbus;
    assign SpSVLD_1 = svld && trans_target;
    
    assign srdy = (trans_target) ? SpSRDY_1 : SpSRDY_0;
        
endmodule
