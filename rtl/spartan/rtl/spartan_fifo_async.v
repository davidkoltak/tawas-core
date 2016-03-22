//
// Spartan bus async (16+2)-entry fifo buffer
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

module spartan_fifo_async
(
    CLKIN,
    RST,
    
    DIN,
    DIN_VAL,
    DIN_RDY,
    
    CLKOUT,
    
    DOUT,
    DOUT_VAL,
    DOUT_RDY
);

    parameter DATA_WIDTH = 1;
    
    input CLKIN;
    input RST;
    
    input [DATA_WIDTH-1:0] DIN;
    input DIN_VAL;
    output DIN_RDY;
    
    input CLKOUT;
    
    output [DATA_WIDTH-1:0] DOUT;
    output DOUT_VAL;
    input DOUT_RDY;

    reg rst_in;
    reg rst_out;
    
    always @ (posedge CLKIN)
        rst_in <= RST;
        
    always @ (posedge CLKOUT)
        rst_out <= RST;
        

    // Head/Tail pointers
    reg [3:0] head_ptr;
    wire [3:0] tail_ptr;
    reg [3:0] tail_ptr_last;
        
    wire fifo_full;
    wire fifo_empty;
    wire skid_rdy;
    
    assign DIN_RDY = !fifo_full;
    
    always @ (posedge CLKIN or posedge rst_in)
        if (rst_in) head_ptr <= 4'd0;
        else if (DIN_VAL && !fifo_full) head_ptr <= head_ptr + 4'd1;
        
    assign tail_ptr = (!fifo_empty && skid_rdy) ? tail_ptr_last + 4'd1 : tail_ptr_last;
    
    always @ (posedge CLKOUT or posedge rst_out)
        if (rst_out) tail_ptr_last <= 4'd0;
        else tail_ptr_last <= tail_ptr;
 
 
    // Clock domain crossing state machine
    reg [1:0] cin_state;
    reg [1:0] cout_state;
    
    always @ (posedge CLKIN or posedge rst_in)
        if (rst_in) cin_state[1:0] <= 2'b00;
        else
        begin
            case (cout_state[1:0])
            2'b00: cin_state[1:0] <= 2'b01;
            2'b01: cin_state[1:0] <= 2'b11;
            2'b11: cin_state[1:0] <= 2'b10;
            default: cin_state[1:0] <= 2'b00;
            endcase
        end
        
    always @ (posedge CLKOUT or posedge rst_out)
        if (rst_out) cout_state[1:0] <= 2'b00;
        else cout_state[1:0] <= cin_state[1:0];
    

    // Pass pointers accross domains and figure FIFO FULL/EMPTY
    reg [3:0] head_clkin;
    reg [3:0] head_clkout;
    
    always @ (posedge CLKIN or posedge rst_in)
        if (rst_in) head_clkin <= 4'd0;
        else if (cin_state == 2'b01) head_clkin <= head_ptr;
    
    always @ (posedge CLKOUT or posedge rst_out)
        if (rst_out) head_clkout <= 4'd0;
        else if (cout_state == 2'b10) head_clkout <= head_clkin;
        
    assign fifo_empty = (tail_ptr_last == head_clkout);

    reg [3:0] tail_clkout;
    reg [3:0] tail_clkin;
    
    always @ (posedge CLKOUT or posedge rst_out)
        if (rst_out) tail_clkout <= 4'd0;
        else if (cout_state == 2'b01) tail_clkout <= tail_ptr_last;
    
    always @ (posedge CLKIN or posedge rst_in)
        if (rst_in) tail_clkin <= 4'd0;
        else if (cin_state == 2'b10) tail_clkin <= tail_clkout;
        
    assign fifo_full = ((head_ptr + 4'd1) == tail_clkin);
    
    
    // Memory Instance
    wire [DATA_WIDTH-1:0] skid_data;
    
    spartan_dpram #(.NUMWORDS(16), .ADDRW(4), .DATAW(DATA_WIDTH)) fifo_ram
    (
        .clock_a(CLKIN),
        .ce_a(DIN_VAL && !fifo_full),
        .address_a(head_ptr),
        .wren_a(1'b1),
        .byteena_a({DATA_WIDTH{1'b1}}),
        .data_a(DIN),
        .q_a(),

        .clock_b(CLKOUT),
        .ce_b(1'b1),
        .address_b(tail_ptr),
        .wren_b(1'b0),
        .byteena_b({DATA_WIDTH{1'b0}}),
        .data_b({DATA_WIDTH{1'b0}}),
        .q_b(skid_data)
    );
    
    spartan_skid #(.DATA_WIDTH(DATA_WIDTH)) spartan_skid
    (
        .CLK(CLKOUT),
        .RST(rst_out),

        .DIN(skid_data),
        .DIN_VAL(!fifo_empty),
        .DIN_RDY(skid_rdy),

        .DOUT(DOUT),
        .DOUT_VAL(DOUT_VAL),
        .DOUT_RDY(DOUT_RDY)
    );
        
endmodule
