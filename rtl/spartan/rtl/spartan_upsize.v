//
// Take Spartan bus from downsizer and expand it back to full size
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

module spartan_upsize
(
    CLK,
    RST,
    
    SpMBUS_HALF,
    SpMVLD_HALF,
    SpMRDY_HALF,
    
    SpSBUS_HALF,
    SpSVLD_HALF,
    SpSRDY_HALF,
    
    SpMBUS_FULL,
    SpMVLD_FULL,
    SpMRDY_FULL,
    
    SpSBUS_FULL,
    SpSVLD_FULL,
    SpSRDY_FULL
);
    parameter BWIDTH = 64;
    
    input CLK;
    input RST;
    
    input [(BWIDTH/2):0] SpMBUS_HALF;
    input SpMVLD_HALF;
    output SpMRDY_HALF;
    
    output [(BWIDTH/2):0] SpSBUS_HALF;
    output SpSVLD_HALF;
    input SpSRDY_HALF;
    
    output [BWIDTH+1:0] SpMBUS_FULL;
    output SpMVLD_FULL;
    input SpMRDY_FULL;
    
    input [BWIDTH+1:0] SpSBUS_FULL;
    input SpSVLD_FULL;
    output SpSRDY_FULL;
    
    reg rst_in;
    
    always @ (posedge CLK)
        rst_in <= RST;
        
    //
    // EXPAND MASTER
    //
    
    spartan_expand #(.INPUT_WIDTH((BWIDTH+2)/2)) master_expand
    (
        .CLK(CLK),
        .RST(rst_in),

        .DIN(SpMBUS_HALF),
        .DIN_VAL(SpMVLD_HALF),
        .DIN_RDY(SpMRDY_HALF),

        .DOUT(SpMBUS_FULL),
        .DOUT_VAL(SpMVLD_FULL),
        .DOUT_RDY(SpMRDY_FULL)
    );

    //
    // REDUCE SLAVE
    //
    
    spartan_reduce #(.OUTPUT_WIDTH((BWIDTH+2)/2)) slave_reduce
    (
        .CLK(CLK),
        .RST(rst_in),

        .DIN(SpSBUS_FULL),
        .DIN_VAL(SpSVLD_FULL),
        .DIN_RDY(SpSRDY_FULL),

        .DOUT(SpSBUS_HALF),
        .DOUT_VAL(SpSVLD_HALF),
        .DOUT_RDY(SpSRDY_HALF)
    );

endmodule
