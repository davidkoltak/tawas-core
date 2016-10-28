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

module spartan_pinx_out
(
    CLK,
    RST,
    
    BUS_IN,
    BUS_VLD,
    BUS_RDY,
    
    PINX_OUT,
    PINX_VLD,
    PINX_TOK
);
    parameter BUS_WIDTH = 66;
    
    input CLK;
    input RST;
    
    input [BUS_WIDTH-1:0] BUS_IN;
    input BUS_VLD;
    output BUS_RDY;
    
    output [BUS_WIDTH-1:0] PINX_OUT;
    output PINX_VLD;
    input PINX_TOK;
    
    reg rst_in;
    
    always @ (posedge CLK)
        rst_in <= RST;

    reg [1:0] token_in;
    reg [3:0] token_cnt;
    wire token_avail = |token_cnt;
    wire token_max = &token_cnt;
    
    always @ (posedge CLK or posedge rst_in)
        if (rst_in) token_in <= 2'd0;
        else token_in <= {PINX_TOK, token_in[1]};
    
    always @ (posedge CLK or posedge rst_in)
        if (rst_in) token_cnt <= 4'hF;
        else
        begin
            case ({token_max, token_avail, token_in[0], BUS_VLD})
            4'b0010: token_cnt <= token_cnt + 4'd1;
            4'b0110: token_cnt <= token_cnt + 4'd1;
            4'b0101: token_cnt <= token_cnt - 4'd1;
            4'b1101: token_cnt <= token_cnt - 4'd1;
            default: ;
            endcase
        end
        
    assign BUS_RDY = (token_avail || token_in[0]);  
    
        
    reg [BUS_WIDTH-1:0] pipe_out_0;
    reg [BUS_WIDTH-1:0] pipe_out_1;
    reg [1:0] pipe_vld;
    
    always @ (posedge CLK)
    begin
        pipe_out_1 <= BUS_IN;
        pipe_out_0 <= pipe_out_1;
        
        pipe_vld[1] <= BUS_VLD && (token_avail || token_in[0]);
        pipe_vld[0] <= pipe_vld[1];
    end

    assign PINX_OUT = pipe_out_0;
    assign PINX_VLD = pipe_vld[0];
    
endmodule
