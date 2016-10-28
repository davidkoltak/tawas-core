//
// Spartan bus interface to generic RAM style interface.
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

module spartan2ram
(
    CLK,
    RST,
    
    SpMBUS,
    SpMVLD,
    SpMRDY,
    
    SpSBUS,
    SpSVLD,
    SpSRDY,
    
    CS,
    WE,
    ADDR,
    MASK,
    WR_DATA,
    RD_DATA
);
    parameter BWIDTH = 64;
    
    input CLK;
    input RST;
    
    input [BWIDTH+1:0] SpMBUS;
    input SpMVLD;
    output SpMRDY;
    
    output [BWIDTH+1:0] SpSBUS;
    output SpSVLD;
    input SpSRDY;

    output CS;
    output WE;
    output [31:0] ADDR;
    output [BWIDTH-1:0] MASK;
    output [BWIDTH-1:0] WR_DATA;
    input [BWIDTH-1:0] RD_DATA;

    //
    // WRITE ACTIVITY
    //
    
    wire trans_active;
    reg write_resp_pending;
    wire write_request = SpMVLD && (SpMBUS[BWIDTH+1:BWIDTH] == 2'b01) && !trans_active;
    wire write_last = SpMVLD && (SpMBUS[BWIDTH+1:BWIDTH] == 2'b11);
    wire write_active = SpMVLD && SpMBUS[BWIDTH+1];
    
    reg [BWIDTH-((BWIDTH/8)+41+1):0] write_id;
    reg [(BWIDTH/8)-1:0] write_mask;
    reg [BWIDTH-1:0] write_mask_full;
    
    reg write_first;
    
    always @ (posedge CLK)
        if (write_request) write_id <= SpMBUS[BWIDTH-((BWIDTH/8)+1):41];

    always @ (posedge CLK)
        if (write_request) write_mask <= SpMBUS[BWIDTH-1:BWIDTH-(BWIDTH/8)];
    
    integer x;
    integer y;
    always @ *
    begin
        for (x = 0; x < (BWIDTH/8); x = x + 1)
            for (y = 0; y < 8; y = y + 1)
                write_mask_full[(x * 8) + y] = write_mask[x];
    end
    
    always @ (posedge CLK or posedge RST)
        if (RST) write_first <= 1'b0;
        else write_first <= write_request || (write_first && !write_active);
    
    always @ (posedge CLK or posedge RST)
        if (RST) write_resp_pending <= 1'b0;
        else write_resp_pending <= write_last || (write_resp_pending && !SpSRDY);

    reg write_addr_inc;
    
    always @ (posedge CLK)
        if (write_request) write_addr_inc <= (SpMBUS[40:39] != 2'd0);

    //
    // READ STATE MACHINE
    //

    reg read_active;
    reg [3:0] read_cnt;
    
    wire read_request = SpMVLD && (SpMBUS[BWIDTH+1:BWIDTH] == 2'b00) && !trans_active;
    wire read_done = read_active && (read_cnt[3:0] == 4'd0) && SpSRDY;
    
    always @ (posedge CLK or posedge RST)
        if (RST) read_active <= 1'b0;
        else read_active <= ((read_request && SpSRDY) || read_active) && !read_done;

    wire [3:0] read_cnt_nxt = (read_request) ? SpMBUS[35:32] : read_cnt - 4'd1;
    
    always @ (posedge CLK)
        if (SpSRDY) read_cnt <= read_cnt_nxt;
    
    assign trans_active = write_active || write_resp_pending || read_active;
    
    reg read_addr_inc;
    
    always @ (posedge CLK)
        if (read_request) read_addr_inc <= (SpMBUS[40:39] != 2'd0);
    
    //
    // ADDRESS GENERATION
    //
    
    reg [31:16] addr_base;
    reg [15:0] write_offset;
    wire [31:0] addr_write = {addr_base[31:16], write_offset[15:0]};
    wire [15:0] read_offset;
    wire [31:0] addr_read;
    
    wire [15:0] addr_inc_val = (BWIDTH >= 256) ? 16'd32 : (BWIDTH >= 128) ? 16'd16 : 16'd8;
    
    assign addr_read[31:16] = (read_request) ? SpMBUS[31:16] : addr_base[31:16];
    assign addr_read[15:0] = {read_offset[15:0]};
    
    always @ (posedge CLK)
        if (write_request || read_request) addr_base <= SpMBUS[31:16];
    
    wire [15:0] write_offset_nxt = (write_request) ? SpMBUS[15:0] :
                                   (write_active && SpMVLD && write_addr_inc) ? write_offset + addr_inc_val : write_offset;
    
    always @ (posedge CLK)
        write_offset <= write_offset_nxt;

    reg [15:0] read_offset_last;
    always @ (posedge CLK)
        read_offset_last <= read_offset;
        
    assign read_offset = (read_request) ? SpMBUS[15:0] :
                         (read_active && SpSRDY && read_addr_inc) ? read_offset_last + addr_inc_val : read_offset_last;
    
    //
    // RAM BUS SIGNALS
    //
    
    assign CS = (write_active || read_request || (read_active && SpSRDY));
    assign WE = write_active;
    assign ADDR = (write_active) ? addr_write : addr_read;
    assign MASK = (write_first) ? write_mask_full : {BWIDTH{1'b1}};
    assign WR_DATA = SpMBUS[BWIDTH-1:0];

    //
    // RESPONSE
    //
    
    assign SpSBUS[BWIDTH-1:0] = (read_request) ? {{(BWIDTH/8){1'b0}}, SpMBUS[BWIDTH-((BWIDTH/8)+1):41], {41{1'b0}}} : 
                                 (read_active) ? RD_DATA : 
                                                 {{(BWIDTH/8){1'b0}}, write_id[BWIDTH-((BWIDTH/8)+41+1):0], {41{1'b0}}};
                                                 
    assign SpSBUS[BWIDTH+1:BWIDTH] = (read_request) ? 2'b01 : 
                                      (read_active) ? {1'b1, read_done} : 2'b00;
                                      
    assign SpSVLD = (write_resp_pending || read_request || read_active);
    
    assign SpMRDY = (write_request || write_active || (read_request && SpSRDY));

endmodule

