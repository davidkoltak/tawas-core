//
// Send spartan bus accross pins using fifo and token based throttle. Allows 
// for up to 15 fifo slots on Rx side.
//
// by
//     David Koltak  09/06/2012
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

module spartan_pinx_in
(
    CLK,
    RST,
    
    PINX_IN,
    PINX_VLD,
    PINX_TOK,
    
    BUS_OUT,
    BUS_VLD,
    BUS_RDY
);
    parameter BUS_WIDTH = 66;
    
    input CLK;
    input RST;
    
    input [BUS_WIDTH-1:0] PINX_IN;
    input PINX_VLD;
    output PINX_TOK;
    
    output [BUS_WIDTH-1:0] BUS_OUT;
    output BUS_VLD;
    input BUS_RDY;
    
    reg rst_in;
    
    always @ (posedge CLK)
        rst_in <= RST;

        
    reg [1:0] token_out;
    reg [3:0] token_cnt;
    wire token_avail = (token_cnt != 4'b1111);
    wire fifo_vld;
    
    always @ (posedge CLK or posedge rst_in)
        if (rst_in) token_out <= 2'd0;
        else token_out <= {token_avail, token_out[1]};
    
    assign PINX_TOK = token_out[0];
    
    always @ (posedge CLK or posedge rst_in)
        if (rst_in) token_cnt <= 4'hF;
        else
        begin
            case ({token_avail, (fifo_vld && BUS_RDY)})
            2'b01: token_cnt <= token_cnt - 4'd1;
            2'b10: token_cnt <= token_cnt + 4'd1;
            default: ;
            endcase
        end

        
    reg [BUS_WIDTH-1:0] pipe_in_0;
    reg [BUS_WIDTH-1:0] pipe_in_1;
    reg [1:0] pipe_vld;
    
    always @ (posedge CLK)
    begin
        pipe_in_1 <= PINX_IN;
        pipe_in_0 <= pipe_in_1;
        
        pipe_vld[1] <= PINX_VLD;
        pipe_vld[0] <= pipe_vld[1];
    end
    
    
    spartan_fifo #(.DATA_WIDTH(BUS_WIDTH)) spartan_fifo
    (
        .CLK(CLK),
        .RST(RST),

        .DIN(pipe_in_0),
        .DIN_VAL(pipe_vld[0]),
        .DIN_RDY(),

        .DOUT(BUS_OUT),
        .DOUT_VAL(fifo_vld),
        .DOUT_RDY(BUS_RDY)
    );

    assign BUS_VLD = fifo_vld;

endmodule
