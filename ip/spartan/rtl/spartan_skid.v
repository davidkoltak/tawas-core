//
// Spartan bus skid buffer
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

module spartan_skid
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

    parameter DATA_WIDTH = 1;
    
    input CLK;
    input RST;
    
    input [DATA_WIDTH-1:0] DIN;
    input DIN_VAL;
    output DIN_RDY;
    
    output [DATA_WIDTH-1:0] DOUT;
    output DOUT_VAL;
    input DOUT_RDY;
    
    reg dout_valid;
    reg [DATA_WIDTH-1:0] dout_reg;
    
    reg skid_active;
    reg skid_valid;
    reg [DATA_WIDTH-1:0] skid_buf;
    
    assign DIN_RDY = !skid_active;
    assign DOUT[DATA_WIDTH-1:0] = dout_reg[DATA_WIDTH-1:0];
    assign DOUT_VAL = dout_valid;
    
    always @ (posedge CLK or posedge RST)
        if (RST) skid_active <= 1'b0;
        else skid_active <= dout_valid && !DOUT_RDY && (DIN_VAL || skid_active);
        
        
    always @ (posedge CLK)
        if (!DOUT_RDY && !skid_active)
            skid_buf[DATA_WIDTH-1:0] <= DIN[DATA_WIDTH-1:0];
            
    always @ (posedge CLK)
        if (!DOUT_RDY && !skid_active)
            skid_valid <= DIN_VAL;
            
            
    always @ (posedge CLK)
        if (DOUT_RDY || !dout_valid)
            dout_reg[DATA_WIDTH-1:0] <= (skid_active) ? skid_buf[DATA_WIDTH-1:0] : DIN[DATA_WIDTH-1:0];
        
    always @ (posedge CLK or posedge RST)
        if (RST) dout_valid <= 1'b0;
        else if (DOUT_RDY || !dout_valid) dout_valid <= (skid_active) ? skid_valid : DIN_VAL;

endmodule

