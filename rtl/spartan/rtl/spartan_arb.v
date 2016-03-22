//
// Spartan bus round robin arbitration logic.
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

module spartan_arb
(
    CLK,
    RST,

    VALID_A,
    LAST_A,
    READY_A,

    VALID_B,
    LAST_B,
    READY_B,

    VALID,
    READY,
    SEL_A,
    SEL_B
);

    input CLK;
    input RST;

    input VALID_A;
    input LAST_A;
    output READY_A;

    input VALID_B;
    input LAST_B;
    output READY_B;

    output VALID;
    input READY;
    output SEL_A;
    output SEL_B;

    reg priority_sel;
    reg stretch_a;
    reg stretch_b;

    always @ (posedge CLK or posedge RST)
        if (RST) stretch_a <= 1'b0;
        else stretch_a <= (VALID_A || stretch_a) && !(VALID_A && LAST_A);

    always @ (posedge CLK or posedge RST)
        if (RST) stretch_b <= 1'b0;
        else stretch_b <= (VALID_B || stretch_b) && !(VALID_B && LAST_B);

    wire req_a = VALID_A || stretch_a;
    wire req_b = VALID_B || stretch_b;
    
    wire win_a = (priority_sel) ? req_a && !req_b : req_a;
    wire win_b = (priority_sel) ? req_b           : req_b && !req_a;

    always @ (posedge CLK or posedge RST)
        if (RST)
            priority_sel <= 1'b0;
        else
            case ({priority_sel, req_a, req_b})
            3'b001: priority_sel <= 1'b1;
            3'b110: priority_sel <= 1'b0;

            3'b010: priority_sel <= (VALID_A && LAST_A && READY);
            3'b011: priority_sel <= (VALID_A && LAST_A && READY);

            3'b101: priority_sel <= !(VALID_B && LAST_B && READY);
            3'b111: priority_sel <= !(VALID_B && LAST_B && READY);
            default: ;
            endcase

    assign READY_A = win_a && READY;
    assign READY_B = win_b && READY;
    assign VALID = (win_a && VALID_A) || (win_b && VALID_B);
    assign SEL_A = win_a;
    assign SEL_B = win_b;

endmodule

