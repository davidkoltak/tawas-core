//
// Spartan bus interface to generic Dual Ported FIFO style interface
// with wait stall input signal and transaction ID output signal.
//
// by
//     David Koltak  03/24/2012
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

module spartan2fifo_i
(
    CLK,
    RST,
    
    SpMBUS,
    SpMVLD,
    SpMRDY,
    
    SpSBUS,
    SpSVLD,
    SpSRDY,
    
    RD_ID,
    RD_RDY,
    RD,
    RD_DATA,
    
    WR_ID,
    WR_RDY,
    WR,
    WR_DATA
);
    parameter BWIDTH = 64;
    parameter ID_WIDTH = 5;
    
    input CLK;
    input RST;
    
    input [BWIDTH+1:0] SpMBUS;
    input SpMVLD;
    output SpMRDY;
    
    output [BWIDTH+1:0] SpSBUS;
    output SpSVLD;
    input SpSRDY;

    output [ID_WIDTH-1:0] RD_ID;
    input RD_RDY;
    output RD;
    input [BWIDTH-1:0] RD_DATA;
    
    output [ID_WIDTH-1:0] WR_ID;
    input WR_RDY;
    output WR;
    output [BWIDTH-1:0] WR_DATA;

    //
    // WRITE ACTIVITY
    //
    
    reg write_resp_pending;
    wire write_request = SpMVLD && (SpMBUS[BWIDTH+1:BWIDTH] == 2'b01) && !write_resp_pending;
    wire write_last = SpMVLD && WR_RDY && (SpMBUS[BWIDTH+1:BWIDTH] == 2'b11);
    wire write_active = SpMVLD && SpMBUS[BWIDTH+1];
    
    reg [BWIDTH-((BWIDTH/8)+41+1):0] write_id;
    
    always @ (posedge CLK)
        if (write_request) write_id <= SpMBUS[BWIDTH-((BWIDTH/8)+1):41];

    //
    // READ STATE MACHINE
    //

    reg read_active;
    reg [3:0] read_cnt;
    
    wire read_request = SpMVLD && (SpMBUS[BWIDTH+1:BWIDTH] == 2'b00) && !read_active && !write_resp_pending;
    wire read_done = read_active && (read_cnt[3:0] == 4'd0) && SpSRDY && RD_RDY;
    
    always @ (posedge CLK or posedge RST)
        if (RST) read_active <= 1'b0;
        else read_active <= ((read_request && SpSRDY) || read_active) && !read_done;

    wire [3:0] read_cnt_nxt = (read_request) ? SpMBUS[35:32] : read_cnt - 4'd1;
    
    always @ (posedge CLK)
        if (read_request || (SpSRDY && RD_RDY)) read_cnt <= read_cnt_nxt;
    
    reg [ID_WIDTH-1:0] read_id;
    
    always @ (posedge CLK)
        if (read_request) read_id <= SpMBUS[ID_WIDTH+40:41];
        
    //
    // DP FIFO BUS SIGNALS
    //
    
    assign RD_ID = read_id[ID_WIDTH-1:0];
    assign RD = (read_active && SpSRDY);
    
    assign WR_ID = write_id[ID_WIDTH-1:0];
    assign WR = write_active;
    assign WR_DATA = SpMBUS[BWIDTH-1:0];

    //
    // RESPONSE
    //
    
    always @ (posedge CLK or posedge RST)
        if (RST) write_resp_pending <= 1'b0;
        else write_resp_pending <= write_last || (write_resp_pending && !(SpSRDY && !read_active));
        
    assign SpSBUS[BWIDTH-1:0] = (read_request) ? {{(BWIDTH/8){1'b0}}, SpMBUS[BWIDTH-((BWIDTH/8)+1):41], {41{1'b0}}} : 
                                 (read_active) ? RD_DATA : 
                                                 {{(BWIDTH/8){1'b0}}, write_id[BWIDTH-((BWIDTH/8)+41+1):0], {41{1'b0}}};
                                                 
    assign SpSBUS[BWIDTH+1:BWIDTH] = (read_request) ? 2'b01 : 
                                      (read_active) ? {1'b1, read_done} : 2'b00;
    
    assign SpSVLD = (write_resp_pending || read_request || (read_active && RD_RDY));
    
    assign SpMRDY = (write_request || (write_active && WR_RDY) || (read_request && SpSRDY));

endmodule

