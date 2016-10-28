//
// Spartan bus dual port ram wrapper
//
// by
//     David Koltak  03/22/2016
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

// synopsys translate_off
`timescale 1 ns / 1 ns
// synopsys translate_on

module spartan_dpram
(
    clock_a,
    ce_a,
    address_a,
    wren_a,
    byteena_a,
    data_a,
    q_a,
    
    clock_b,
    ce_b,
    address_b,
    wren_b,
    byteena_b,
    data_b,
    q_b
);
    parameter NUMWORDS = 256;
    parameter ADDRW = 8;
    parameter DATAW = 8;
    
    input   [ADDRW-1:0]     address_a;
    input   [ADDRW-1:0]     address_b;
    input   [DATAW-1:0]     byteena_a;
    input   [DATAW-1:0]     byteena_b;
    input                   clock_a;
    input                   clock_b;
    input                   ce_a;
    input                   ce_b;
    input   [DATAW-1:0]     data_a;
    input   [DATAW-1:0]     data_b;
    input                   wren_a;
    input                   wren_b;
    output  [DATAW-1:0]     q_a;
    output  [DATAW-1:0]     q_b;

    // Wires / Registers / Variables
    integer                 index;
    reg     [DATAW-1:0]     r_mem_array[NUMWORDS-1:0];
    reg     [DATAW-1:0]     r_data1_out_d1;
    reg     [DATAW-1:0]     r_data2_out_d1;
    
    // Port Assignments    
    assign q_a[DATAW-1:0] = r_data1_out_d1[DATAW-1:0];
    assign q_b[DATAW-1:0] = r_data2_out_d1[DATAW-1:0];
  
    // SIDE A WRITE
    always @ (posedge clock_a)
        if (wren_a & ce_a) 
            r_mem_array[address_a[ADDRW-1:0]] <= (data_a[DATAW-1:0] & byteena_a[DATAW-1:0]) |
                (r_mem_array[address_a[ADDRW-1:0]] & ~byteena_a[DATAW-1:0]);
    
    // SIDE A READ
    always @ (posedge clock_a) 
        if (ce_a) r_data1_out_d1[DATAW-1:0] <= r_mem_array[address_a[ADDRW-1:0]];
    
    // SIDE B WRITE
    always @ (posedge clock_b)
        if (wren_b & ce_b) 
            r_mem_array[address_b[ADDRW-1:0]] <= (data_b[DATAW-1:0] & byteena_b[DATAW-1:0]) |
                (r_mem_array[address_b[ADDRW-1:0]] & ~byteena_b[DATAW-1:0]);
    
    // SIDE B READ
    always @ (posedge clock_b) 
        if (ce_b) r_data2_out_d1[DATAW-1:0] <= r_mem_array[address_b[ADDRW-1:0]];

endmodule
