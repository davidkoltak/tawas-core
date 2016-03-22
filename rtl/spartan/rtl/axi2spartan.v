//
// Convert AXI master to Spartan bus protocol
//
// by
//     David Koltak  03/22/2012
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

module axi2spartan
(
    CLK,
    RST,
    
    AWID,
    AWADDR,
    AWLEN,
    AWSIZE,
    AWBURST,
    AWLOCK,
    AWCACHE,
    AWPROT,
    AWVALID,
    AWREADY,

    WID,
    WDATA,
    WSTRB,
    WLAST,
    WVALID,
    WREADY,
    
    BID,
    BRESP,
    BVALID,
    BREADY,
    
    ARID,
    ARADDR,
    ARLEN,
    ARSIZE,
    ARBURST,
    ARLOCK,
    ARCACHE,
    ARPROT,
    ARVALID,
    ARREADY,

    RID,
    RDATA,
    RRESP,
    RLAST,
    RVALID,
    RREADY,
    
    SpMBUS,
    SpMVLD,
    SpMRDY,
    
    SpSBUS,
    SpSVLD,
    SpSRDY
);

    parameter ID_WIDTH = 5;
    parameter BWIDTH = 64;
    
    input CLK;
    input RST;
    
    input [ID_WIDTH-1:0] AWID;
    input [31:0] AWADDR;
    input [3:0] AWLEN;
    input [2:0] AWSIZE;
    input [1:0] AWBURST;
    input [1:0] AWLOCK;
    input [3:0] AWCACHE;
    input [2:0] AWPROT;
    input AWVALID;
    output AWREADY;

    input [ID_WIDTH-1:0] WID;
    input [BWIDTH-1:0] WDATA;
    input [(BWIDTH/8)-1:0] WSTRB;
    input WLAST;
    input WVALID;
    output WREADY;
    
    output [ID_WIDTH-1:0] BID;
    output [1:0] BRESP;
    output BVALID;
    input BREADY;
    
    input [ID_WIDTH-1:0] ARID;
    input [31:0] ARADDR;
    input [3:0] ARLEN;
    input [2:0] ARSIZE;
    input [1:0] ARBURST;
    input [1:0] ARLOCK;
    input [3:0] ARCACHE;
    input [2:0] ARPROT;
    input ARVALID;
    output ARREADY;

    output [ID_WIDTH-1:0] RID;
    output [BWIDTH-1:0] RDATA;
    output [1:0] RRESP;
    output RLAST;
    output RVALID;
    input RREADY;

    output [BWIDTH+1:0] SpMBUS;
    output SpMVLD;
    input SpMRDY;
    
    input [BWIDTH+1:0] SpSBUS;
    input SpSVLD;
    output SpSRDY;
    
    //
    // READ/WRITE REQUEST ARBITRATION
    //
    
    reg write_active;
    wire write_request = AWVALID && WVALID && !ARVALID && !write_active;
    wire write_done = WVALID && WLAST && SpMRDY;
    
    wire read_request = ARVALID && !write_active;
    
    always @ (posedge CLK or posedge RST)
        if (RST) write_active <= 1'b0;
        else write_active <= (write_request && SpMRDY) || (write_active && !(write_done));
    
    assign AWREADY = write_request && SpMRDY;
    assign WREADY = write_active && SpMRDY;
    assign ARREADY = read_request && SpMRDY;
    
    //
    // SPARTAN MASTER OUT ENCODE
    //

    assign SpMBUS[BWIDTH-1:0] = (write_request) ? {WSTRB[(BWIDTH/8)-1:0], {BWIDTH-(ID_WIDTH+(BWIDTH/8)+41){1'b0}}, AWID[ID_WIDTH-1:0], AWBURST[1:0], AWSIZE[2:0], AWLEN[3:0], AWADDR[31:0]} :
                                 (read_request) ? {{BWIDTH-(ID_WIDTH+41){1'b0}}, ARID[ID_WIDTH-1:0], ARBURST[1:0], ARSIZE[2:0], ARLEN[3:0], ARADDR[31:0]}
                                                  : WDATA;
                    
    assign SpMBUS[BWIDTH+1:BWIDTH] = (write_request) ? 2'b01 : (write_active) ? {1'b1, WLAST} : 2'b00;
    assign SpMVLD = (read_request || write_request || (write_active && WVALID));
    
    //
    // AXI SLAVE OUT DECODE
    //
    
    wire write_response = SpSVLD && (SpSBUS[BWIDTH+1:BWIDTH] == 2'b00);
    
    assign BID = SpSBUS[(ID_WIDTH-1)+41:41];
    assign BRESP = SpSBUS[1:0];
    assign BVALID = write_response;
    
    wire read_response = SpSVLD && (SpSBUS[BWIDTH+1:BWIDTH] == 2'b01);
    
    reg [ID_WIDTH-1:0] read_rid;
    reg [1:0] read_rresp;
    
    always @ (posedge CLK)
        if (read_response)
        begin
            read_rid <= SpSBUS[(ID_WIDTH-1)+41:41];
            read_rresp <= SpSBUS[1:0];
        end
    
    wire read_active = SpSVLD && SpSBUS[BWIDTH+1];
    
    assign RID = read_rid;
    assign RDATA = SpSBUS[BWIDTH-1:0];
    assign RRESP = read_rresp;
    assign RLAST = (SpSBUS[BWIDTH+1:BWIDTH] == 2'b11);
    assign RVALID = read_active;
    
    assign SpSRDY = (write_response && BREADY) || read_response || (read_active && RREADY);
    
endmodule
