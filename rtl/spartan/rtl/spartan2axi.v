//
// Convert Spartan bus protocol to AXI slave
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

module spartan2axi
(
    CLK,
    RST,
    
    SpMBUS,
    SpMVLD,
    SpMRDY,
    
    SpSBUS,
    SpSVLD,
    SpSRDY,
    
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
    RREADY
);

    parameter ID_WIDTH = 5;
    parameter BWIDTH = 64;
    
    input CLK;
    input RST;
    
    output [ID_WIDTH-1:0] AWID;
    output [31:0] AWADDR;
    output [3:0] AWLEN;
    output [2:0] AWSIZE;
    output [1:0] AWBURST;
    output [1:0] AWLOCK;
    output [3:0] AWCACHE;
    output [2:0] AWPROT;
    output AWVALID;
    input AWREADY;

    output [ID_WIDTH-1:0] WID;
    output [BWIDTH-1:0] WDATA;
    output [(BWIDTH/8)-1:0] WSTRB;
    output WLAST;
    output WVALID;
    input WREADY;
    
    input [ID_WIDTH-1:0] BID;
    input [1:0] BRESP;
    input BVALID;
    output BREADY;
    
    output [ID_WIDTH-1:0] ARID;
    output [31:0] ARADDR;
    output [3:0] ARLEN;
    output [2:0] ARSIZE;
    output [1:0] ARBURST;
    output [1:0] ARLOCK;
    output [3:0] ARCACHE;
    output [2:0] ARPROT;
    output ARVALID;
    input ARREADY;

    input [ID_WIDTH-1:0] RID;
    input [BWIDTH-1:0] RDATA;
    input [1:0] RRESP;
    input RLAST;
    input RVALID;
    output RREADY;

    input [BWIDTH+1:0] SpMBUS;
    input SpMVLD;
    output SpMRDY;
    
    output [BWIDTH+1:0] SpSBUS;
    output SpSVLD;
    input SpSRDY;

    //
    // AXI MASTER OUT DECODE
    //
    
    wire write_request = SpMVLD && (SpMBUS[BWIDTH+1:BWIDTH] == 2'b01);
    
    reg [ID_WIDTH-1:0] write_wid;
    reg [(BWIDTH/8)-1:0] write_wmask;
    always @ (posedge CLK)
        if (write_request)
        begin
            write_wid <= SpMBUS[(ID_WIDTH-1)+41:41];
            write_wmask <= SpMBUS[BWIDTH-1:BWIDTH-1-(BWIDTH/8)];
        end
                                                                   
    assign AWID = SpMBUS[(ID_WIDTH-1)+41:41];
    assign AWADDR = SpMBUS[31:0];
    assign AWLEN = SpMBUS[35:32];
    assign AWSIZE = SpMBUS[38:36];
    assign AWBURST = SpMBUS[40:39];
    assign AWLOCK = 2'b00;
    assign AWCACHE = 4'b0000;
    assign AWPROT = 3'b000;
    assign AWVALID = write_request;
    
    wire write_active = SpMVLD && SpMBUS[BWIDTH+1];
    
    reg write_first;
    always @ (posedge CLK or posedge RST)
        if (RST) write_first <= 1'b0;
        else write_first <= write_request || (write_first && !WREADY);

    assign WID = write_wid;
    assign WDATA = SpMBUS[BWIDTH-1:0];
    assign WSTRB = (write_first) ? write_wmask : {(BWIDTH/8){1'b1}};
    assign WLAST = SpMBUS[BWIDTH];
    assign WVALID = write_active;
    
    wire read_request = SpMVLD && (SpMBUS[BWIDTH+1:BWIDTH] == 2'b00);
                                             
    assign ARID = SpMBUS[(ID_WIDTH-1)+41:41];
    assign ARADDR = SpMBUS[31:0];
    assign ARLEN = SpMBUS[35:32];
    assign ARSIZE = SpMBUS[38:36];
    assign ARBURST = SpMBUS[40:39];
    assign ARLOCK = 2'b00;
    assign ARCACHE = 4'b0000;
    assign ARPROT = 3'b000;
    assign ARVALID = read_request;
    
    assign SpMRDY = (write_request && AWREADY) || (write_active && WREADY) || (read_request && ARREADY);

    //
    // RESPONSE ARBITRATION
    //
    
    reg read_active;
    wire read_response = RVALID && !BVALID;
    wire read_done = RVALID && RLAST && SpSRDY;
    
    wire write_response = BVALID && !read_active;
    
    always @ (posedge CLK or posedge RST)
        if (RST) read_active <= 1'b0;
        else read_active <= (read_response && SpSRDY) || (read_active && !read_done);
    
    assign BREADY = write_response && SpSRDY;
    assign RREADY = read_active && SpSRDY;
    
    //
    // SPARTAN SLAVE OUT ENCODE
    //

    assign SpSBUS[BWIDTH-1:0] = (read_active) ? RDATA :
                           (read_response) ? {{BWIDTH-(ID_WIDTH+41){1'b0}}, RID[ID_WIDTH-1:0], 39'd0, RRESP[1:0]} :
                                             {{BWIDTH-(ID_WIDTH+41){1'b0}}, BID[ID_WIDTH-1:0], 39'd0, BRESP[1:0]};
                    
    assign SpSBUS[BWIDTH+1:BWIDTH] = (read_active) ? {1'b1, RLAST} : (read_response) ? 2'b01 : 2'b00;
    assign SpSVLD = (write_response || read_response || (read_active && RVALID));
            
endmodule
