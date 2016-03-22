//
// Spartan bus join (3) - three masters to one slave
//
// NOTE: ID_WIDTH is for input, output will have two addition bits of ID for response routing
//       Also, master 0 will win 50%, master 1 & 2 each win 25%
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

module spartan_join3
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
    
    SpMBUS_2,
    SpMVLD_2,
    SpMRDY_2,
    
    SpSBUS_2,
    SpSVLD_2,
    SpSRDY_2,
    
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

    input [BWIDTH+1:0] SpMBUS_2;
    input SpMVLD_2;
    output SpMRDY_2;
    
    output [BWIDTH+1:0] SpSBUS_2;
    output SpSVLD_2;
    input SpSRDY_2;
        
    output [BWIDTH+1:0] SpMBUS;
    output SpMVLD;
    input SpMRDY;
    
    input [BWIDTH+1:0] SpSBUS;
    input SpSVLD;
    output SpSRDY;

    //
    // JOIN 1 & 2
    //
    
    wire [BWIDTH+1:0] mbus;
    wire mvld;
    wire mrdy;
    
    wire [BWIDTH+1:0] sbus;
    wire svld;
    wire srdy;
    
    spartan_join #(.ID_WIDTH(ID_WIDTH), .BWIDTH(BWIDTH)) join_1_2
    (
        .CLK(CLK),
        .RST(RST),

        .SpMBUS_0(SpMBUS_1),
        .SpMVLD_0(SpMVLD_1),
        .SpMRDY_0(SpMRDY_1),

        .SpSBUS_0(SpSBUS_1),
        .SpSVLD_0(SpSVLD_1),
        .SpSRDY_0(SpSRDY_1),

        .SpMBUS_1(SpMBUS_2),
        .SpMVLD_1(SpMVLD_2),
        .SpMRDY_1(SpMRDY_2),

        .SpSBUS_1(SpSBUS_2),
        .SpSVLD_1(SpSVLD_2),
        .SpSRDY_1(SpSRDY_2),

        .SpMBUS(mbus),
        .SpMVLD(mvld),
        .SpMRDY(mrdy),

        .SpSBUS(sbus),
        .SpSVLD(svld),
        .SpSRDY(srdy)
    );

    //
    // JOIN 0 with 1 & 2
    //
    
    spartan_join #(.ID_WIDTH(ID_WIDTH+1), .BWIDTH(BWIDTH)) join_0_x
    (
        .CLK(CLK),
        .RST(RST),

        .SpMBUS_0(SpMBUS_0),
        .SpMVLD_0(SpMVLD_0),
        .SpMRDY_0(SpMRDY_0),

        .SpSBUS_0(SpSBUS_0),
        .SpSVLD_0(SpSVLD_0),
        .SpSRDY_0(SpSRDY_0),

        .SpMBUS_1(mbus),
        .SpMVLD_1(mvld),
        .SpMRDY_1(mrdy),

        .SpSBUS_1(sbus),
        .SpSVLD_1(svld),
        .SpSRDY_1(srdy),

        .SpMBUS(SpMBUS),
        .SpMVLD(SpMVLD),
        .SpMRDY(SpMRDY),

        .SpSBUS(SpSBUS),
        .SpSVLD(SpSVLD),
        .SpSRDY(SpSRDY)
    );

endmodule
