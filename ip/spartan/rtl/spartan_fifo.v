//
// Spartan bus sync (16+2)-entry fifo buffer
//
// by
//     David Koltak  11/13/2012
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

module spartan_fifo
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
    

    reg rst_in;
    
    always @ (posedge CLK)
        rst_in <= RST;
        

    // Head/Tail pointers
    reg [3:0] head_ptr;
    reg [3:0] head_ptr_last;
    wire [3:0] tail_ptr;
    reg [3:0] tail_ptr_last;
        
    wire fifo_full = ((head_ptr + 4'd1) == tail_ptr_last);
    wire fifo_empty = (head_ptr_last == tail_ptr_last);
    wire skid_rdy;
    
    
    always @ (posedge CLK or posedge rst_in)
        if (rst_in) head_ptr <= 4'd0;
        else if (DIN_VAL && !fifo_full) head_ptr <= head_ptr + 4'd1;
    
    always @ (posedge CLK)
        head_ptr_last <= head_ptr;
        
    assign tail_ptr = (!fifo_empty && skid_rdy) ? tail_ptr_last + 4'd1 : tail_ptr_last;
    
    always @ (posedge CLK or posedge rst_in)
        if (rst_in) tail_ptr_last <= 4'd0;
        else tail_ptr_last <= tail_ptr;
    
    
    assign DIN_RDY = !fifo_full;
    
    
    // Memory Instance
    wire [DATA_WIDTH-1:0] skid_data;
    
    spartan_dpram #(.NUMWORDS(16), .ADDRW(4), .DATAW(DATA_WIDTH)) fifo_ram
    (
        .clock_a(CLK),
        .ce_a(DIN_VAL && !fifo_full),
        .address_a(head_ptr),
        .wren_a(1'b1),
        .byteena_a({DATA_WIDTH{1'b1}}),
        .data_a(DIN),
        .q_a(),

        .clock_b(CLK),
        .ce_b(1'b1),
        .address_b(tail_ptr),
        .wren_b(1'b0),
        .byteena_b({DATA_WIDTH{1'b0}}),
        .data_b({DATA_WIDTH{1'b0}}),
        .q_b(skid_data)
    );
    
    spartan_skid #(.DATA_WIDTH(DATA_WIDTH)) spartan_skid
    (
        .CLK(CLK),
        .RST(rst_in),

        .DIN(skid_data),
        .DIN_VAL(!fifo_empty),
        .DIN_RDY(skid_rdy),

        .DOUT(DOUT),
        .DOUT_VAL(DOUT_VAL),
        .DOUT_RDY(DOUT_RDY)
    );
        
endmodule
