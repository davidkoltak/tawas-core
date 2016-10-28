//
// Reduce Spartan bus to half width ... to be expanded with upsizer
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

module spartan_downsize
(
    CLK,
    RST,
    
    SpMBUS_FULL,
    SpMVLD_FULL,
    SpMRDY_FULL,
    
    SpSBUS_FULL,
    SpSVLD_FULL,
    SpSRDY_FULL,
    
    SpMBUS_HALF,
    SpMVLD_HALF,
    SpMRDY_HALF,
    
    SpSBUS_HALF,
    SpSVLD_HALF,
    SpSRDY_HALF
);
    parameter BWIDTH = 64;

    input CLK;
    input RST;
    
    input [BWIDTH+1:0] SpMBUS_FULL;
    input SpMVLD_FULL;
    output SpMRDY_FULL;
    
    output [BWIDTH+1:0] SpSBUS_FULL;
    output SpSVLD_FULL;
    input SpSRDY_FULL;
    
    output [(BWIDTH/2):0] SpMBUS_HALF;
    output SpMVLD_HALF;
    input SpMRDY_HALF;
    
    input [(BWIDTH/2):0] SpSBUS_HALF;
    input SpSVLD_HALF;
    output SpSRDY_HALF;
    
    reg rst_in;
    
    always @ (posedge CLK)
        rst_in <= RST;

    //
    // REDUCE MASTER
    //
    
    spartan_reduce #(.OUTPUT_WIDTH((BWIDTH+2)/2)) master_reduce
    (
        .CLK(CLK),
        .RST(rst_in),

        .DIN(SpMBUS_FULL),
        .DIN_VAL(SpMVLD_FULL),
        .DIN_RDY(SpMRDY_FULL),

        .DOUT(SpMBUS_HALF),
        .DOUT_VAL(SpMVLD_HALF),
        .DOUT_RDY(SpMRDY_HALF)
    );
    
    //
    // EXPAND SLAVE
    //
    
    spartan_expand #(.INPUT_WIDTH((BWIDTH+2)/2)) slave_expand
    (
        .CLK(CLK),
        .RST(rst_in),

        .DIN(SpSBUS_HALF),
        .DIN_VAL(SpSVLD_HALF),
        .DIN_RDY(SpSRDY_HALF),

        .DOUT(SpSBUS_FULL),
        .DOUT_VAL(SpSVLD_FULL),
        .DOUT_RDY(SpSRDY_FULL)
    );

endmodule
