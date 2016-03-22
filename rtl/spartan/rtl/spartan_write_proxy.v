//
// Write transaction proxy for Spartan bus.  Send write acks to master (with no error indiction) and
// suppress any write responses from slaves.  This modules is used to speed up busses with high
// write latency.
//
// by
//     David Koltak 03/23/2012
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

module spartan_write_proxy
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

    wire [BWIDTH+1:0] spmbus;
    wire spmvld;
    wire spmrdy;
    
    wire [BWIDTH+1:0] spsbus;
    wire spsvld;
    wire spsrdy;
    
    spartan_sync2 #(.BWIDTH(BWIDTH)) spartan_sync2
    (
        .CLK(CLK),
        .RST(RST),

        .SpMBUS_A(SpMBUS_A),
        .SpMVLD_A(SpMVLD_A),
        .SpMRDY_A(SpMRDY_A),

        .SpSBUS_A(SpSBUS_A),
        .SpSVLD_A(SpSVLD_A),
        .SpSRDY_A(SpSRDY_A),

        .SpMBUS_B(spmbus),
        .SpMVLD_B(spmvld),
        .SpMRDY_B(spmrdy),

        .SpSBUS_B(spsbus),
        .SpSVLD_B(spsvld),
        .SpSRDY_B(spsrdy)   
    );

    //
    // WRITE ACTIVITY
    //
    
    wire write_request = spmvld && (spmbus[BWIDTH+1:BWIDTH] == 2'b01);
    wire write_last = spmvld && (spmbus[BWIDTH+1:BWIDTH] == 2'b11);
    
    reg [BWIDTH-((BWIDTH/8)+41+1):0] write_id;
    
    always @ (posedge CLK)
        if (write_request) write_id <= spmbus[BWIDTH-((BWIDTH/8)+1):41];
    
    wire allow_write_request = SpMRDY_B && spsrdy && !SpSVLD_B;
    
    //
    // COMMAND
    //
    
    assign spmrdy = (write_last) ? allow_write_request : SpMRDY_B;
    
    assign SpMBUS_B = spmbus;
    assign SpMVLD_B = (write_last) ? allow_write_request : spmvld;
    
    //
    // RESPONSE
    //
    
    assign spsbus[BWIDTH-1:0] = (SpSVLD_B) ? SpSBUS_B[BWIDTH-1:0] : {{(BWIDTH/8){1'b0}}, write_id[BWIDTH-((BWIDTH/8)+41+1):0], {41{1'b0}}};
    assign spsbus[BWIDTH+1:BWIDTH] = (SpSVLD_B) ? SpSBUS_B[BWIDTH+1:BWIDTH] : 2'b00;
    assign spsvld = (SpSVLD_B && (SpSBUS_B[BWIDTH+1:BWIDTH] != 2'b00)) || (write_last && allow_write_request && SpMRDY_B);
    
    assign SpSRDY_B = spsrdy;

endmodule
