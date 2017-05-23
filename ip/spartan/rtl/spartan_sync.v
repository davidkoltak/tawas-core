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

module spartan_sync
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
        
    spartan_fifo #(.DATA_WIDTH(BWIDTH+2)) master_fifo
    (
        .CLK(CLK),
        .RST(RST),

        .DIN(SpMBUS_A),
        .DIN_VAL(SpMVLD_A),
        .DIN_RDY(SpMRDY_A),

        .DOUT(SpMBUS_B),
        .DOUT_VAL(SpMVLD_B),
        .DOUT_RDY(SpMRDY_B)
    );

    spartan_fifo #(.DATA_WIDTH(BWIDTH+2)) slave_fifo
    (
        .CLK(CLK),
        .RST(RST),

        .DIN(SpSBUS_B),
        .DIN_VAL(SpSVLD_B),
        .DIN_RDY(SpSRDY_B),

        .DOUT(SpSBUS_A),
        .DOUT_VAL(SpSVLD_A),
        .DOUT_RDY(SpSRDY_A)
    );       
    
endmodule
