//
// Generic bus 2x reducer... 
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

module spartan_reduce
(
    CLK,
    RST,
    
    DIN,
    DIN_VAL,
    DIN_RDY,
    
    DOUT,
    DOUT_VAL,
    DOUT_RDY
);
    parameter OUTPUT_WIDTH = 32;
    
    input CLK;
    input RST;
    
    input [(2*OUTPUT_WIDTH)-1:0] DIN;
    input DIN_VAL;
    output DIN_RDY;
    
    output [OUTPUT_WIDTH-1:0] DOUT;
    output DOUT_VAL;
    input DOUT_RDY;
        
    reg half_val;
    wire [OUTPUT_WIDTH-1:0] half_data = (half_val) ? DIN[(2*OUTPUT_WIDTH)-1:OUTPUT_WIDTH] : DIN[OUTPUT_WIDTH-1:0];
    
    always @ (posedge CLK or posedge RST)
        if (RST) half_val <= 1'b0;
        else if (DIN_VAL && DOUT_RDY) half_val <= ~half_val;
    
    assign DIN_RDY = DOUT_RDY && half_val;
    assign DOUT = half_data;
    assign DOUT_VAL = DIN_VAL;

endmodule

