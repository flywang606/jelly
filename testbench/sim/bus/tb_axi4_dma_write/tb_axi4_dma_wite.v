
`timescale 1ns / 1ps
`default_nettype none


module tb_axi4_dma_wite();
    localparam AW_RATE   = 1000.0 / 123.0;
    localparam W_RATE    = 1000.0 / 133.0;
    localparam B_RATE    = 1000.0 / 111.0;
    localparam AXI4_RATE = 1000.0 / 200.0;
    
    
    initial begin
        $dumpfile("tb_axi4_dma_wite.vcd");
        $dumpvars(0, tb_axi4_dma_wite);
        
        #1000000;
            $finish;
    end
    
    
    reg     s_awresetn = 1'b0;
    initial #(AW_RATE*100)      s_awresetn = 1'b1;
    
    reg     s_awclk = 1'b1;
    always #(AW_RATE/2.0)       s_awclk = ~s_awclk;
    
    reg     s_wresetn = 1'b0;
    initial #(W_RATE*100)       s_wresetn = 1'b1;
    
    reg     s_wclk = 1'b1;
    always #(W_RATE/2.0)        s_wclk = ~s_wclk;
    
    reg     s_bresetn = 1'b0;
    initial #(B_RATE*100)       s_bresetn = 1'b1;
    
    reg     s_bclk = 1'b1;
    always #(B_RATE/2.0)        s_bclk = ~s_bclk;
    
    
    reg     m_aresetn = 1'b0;
    initial #(AXI4_RATE*100)    m_aresetn = 1'b1;
    
    reg     m_aclk = 1'b1;
    always #(AXI4_RATE/2.0)     m_aclk = ~m_aclk;
    
    
    
    localparam  RAND_BUSY = 0;
    
    
    
    // -----------------------------------------
    //  Core
    // -----------------------------------------
    
    parameter   AWASYNC              = 1;
    parameter   WASYNC               = 1;
    parameter   BASYNC               = 1;
    parameter   BYTE_WIDTH           = 8;
    
    parameter   AXI4_ID_WIDTH        = 6;
    parameter   AXI4_ADDR_WIDTH      = 49;
    parameter   AXI4_DATA_SIZE       = 5;    // 0:8bit; 1:16bit; 2:32bit ...
    parameter   AXI4_DATA_WIDTH      = (BYTE_WIDTH << AXI4_DATA_SIZE);
    parameter   AXI4_STRB_WIDTH      = AXI4_DATA_WIDTH / BYTE_WIDTH;
    parameter   AXI4_LEN_WIDTH       = 8;
    parameter   AXI4_QOS_WIDTH       = 4;
    parameter   AXI4_AWID            = {AXI4_ID_WIDTH{1'b0}};
    parameter   AXI4_AWSIZE          = AXI4_DATA_SIZE;
    parameter   AXI4_AWBURST         = 2'b01;
    parameter   AXI4_AWLOCK          = 1'b0;
    parameter   AXI4_AWCACHE         = 4'b0001;
    parameter   AXI4_AWPROT          = 3'b000;
    parameter   AXI4_AWQOS           = 0;
    parameter   AXI4_AWREGION        = 4'b0000;
    
    parameter   BYPASS_ALIGN         = 0;
    parameter   AXI4_ALIGN           = 12;
    
    parameter   S_AWADDR_WIDTH       = AXI4_ADDR_WIDTH;
    parameter   S_WDATA_SIZE         = 2;    // 0:8bit; 1:16bit; 2:32bit ...
    parameter   S_WDATA_WIDTH        = (BYTE_WIDTH << S_WDATA_SIZE);
    parameter   S_WSTRB_WIDTH        = S_WDATA_WIDTH / BYTE_WIDTH;
    parameter   S_AWLEN_WIDTH        = 32;
    parameter   S_AWLEN_SIZE         = S_WDATA_SIZE;
    parameter   S_AWLEN_OFFSET       = 1'b1;
    
    parameter   AWFIFO_PTR_WIDTH     = 4;
    parameter   AWFIFO_RAM_TYPE      = "distributed";
    parameter   AWFIFO_LOW_DEALY     = 1;
    parameter   AWFIFO_DOUT_REGS     = 0;
    parameter   AWFIFO_S_REGS        = 1;
    parameter   AWFIFO_M_REGS        = 1;
    
    parameter   WFIFO_PTR_WIDTH      = 9;
    parameter   WFIFO_RAM_TYPE       = "block";
    parameter   WFIFO_LOW_DEALY      = 0;
    parameter   WFIFO_DOUT_REGS      = 1;
    parameter   WFIFO_S_REGS         = 1;
    parameter   WFIFO_M_REGS         = 1;
    
    parameter   BFIFO_PTR_WIDTH      = 5;
    parameter   BFIFO_RAM_TYPE       = "distributed";
    parameter   BFIFO_LOW_DEALY      = 0;
    parameter   BFIFO_DOUT_REGS      = 1;
    parameter   BFIFO_S_REGS         = 1;
    parameter   BFIFO_M_REGS         = 1;
    
    parameter   WCMD_FIFO_PTR_WIDTH  = 4;
    parameter   WCMD_FIFO_RAM_TYPE   = "distributed";
    parameter   WCMD_FIFO_LOW_DEALY  = 1;
    parameter   WCMD_FIFO_DOUT_REGS  = 0;
    parameter   WCMD_FIFO_S_REGS     = 0;
    parameter   WCMD_FIFO_M_REGS     = 1;
    
    parameter   BCMD_FIFO_PTR_WIDTH  = 4;
    parameter   BCMD_FIFO_RAM_TYPE   = "distributed";
    parameter   BCMD_FIFO_LOW_DEALY  = 1;
    parameter   BCMD_FIFO_DOUT_REGS  = 0;
    parameter   BCMD_FIFO_S_REGS     = 0;
    parameter   BCMD_FIFO_M_REGS     = 1;
    
    reg     [S_AWADDR_WIDTH-1:0]        s_awaddr;
    reg     [S_AWLEN_WIDTH-1:0]         s_awlen;
    reg     [AXI4_LEN_WIDTH-1:0]        s_awlen_max;
    reg                                 s_awvalid;
    wire                                s_awready;
    
    reg     [S_WSTRB_WIDTH-1:0]         s_wstrb;
    reg     [S_WDATA_WIDTH-1:0]         s_wdata;
    reg                                 s_wvalid;
    wire                                s_wready;
    
    wire                                s_bvalid;
    reg                                 s_bready;
    
    wire    [AXI4_ID_WIDTH-1:0]         m_axi4_awid;
    wire    [AXI4_ADDR_WIDTH-1:0]       m_axi4_awaddr;
    wire    [AXI4_LEN_WIDTH-1:0]        m_axi4_awlen;
    wire    [2:0]                       m_axi4_awsize;
    wire    [1:0]                       m_axi4_awburst;
    wire    [0:0]                       m_axi4_awlock;
    wire    [3:0]                       m_axi4_awcache;
    wire    [2:0]                       m_axi4_awprot;
    wire    [AXI4_QOS_WIDTH-1:0]        m_axi4_awqos;
    wire    [3:0]                       m_axi4_awregion;
    wire                                m_axi4_awvalid;
    wire                                m_axi4_awready;
    wire    [AXI4_DATA_WIDTH-1:0]       m_axi4_wdata;
    wire    [AXI4_STRB_WIDTH-1:0]       m_axi4_wstrb;
    wire                                m_axi4_wlast;
    wire                                m_axi4_wvalid;
    wire                                m_axi4_wready;
    wire    [AXI4_ID_WIDTH-1:0]         m_axi4_bid;
    wire    [1:0]                       m_axi4_bresp;
    wire                                m_axi4_bvalid;
    wire                                m_axi4_bready;
    
    
    jelly_axi4_dma_write
            #(
                .AWASYNC              (AWASYNC),
                .WASYNC               (WASYNC),
                .BASYNC               (BASYNC),
//                .UNIT_WIDTH           (UNIT_WIDTH),
                .AXI4_ID_WIDTH        (AXI4_ID_WIDTH),
                .AXI4_ADDR_WIDTH      (AXI4_ADDR_WIDTH),
                .AXI4_DATA_SIZE       (AXI4_DATA_SIZE),
                .AXI4_DATA_WIDTH      (AXI4_DATA_WIDTH),
                .AXI4_STRB_WIDTH      (AXI4_STRB_WIDTH),
                .AXI4_LEN_WIDTH       (AXI4_LEN_WIDTH),
                .AXI4_QOS_WIDTH       (AXI4_QOS_WIDTH),
                .AXI4_AWID            (AXI4_AWID),
                .AXI4_AWSIZE          (AXI4_AWSIZE),
                .AXI4_AWBURST         (AXI4_AWBURST),
                .AXI4_AWLOCK          (AXI4_AWLOCK),
                .AXI4_AWCACHE         (AXI4_AWCACHE),
                .AXI4_AWPROT          (AXI4_AWPROT),
                .AXI4_AWQOS           (AXI4_AWQOS),
                .AXI4_AWREGION        (AXI4_AWREGION),
                .BYPASS_ALIGN         (BYPASS_ALIGN),
                .AXI4_ALIGN           (AXI4_ALIGN),
                .S_AWADDR_WIDTH       (S_AWADDR_WIDTH),
                .S_WDATA_SIZE         (S_WDATA_SIZE),
                .S_WDATA_WIDTH        (S_WDATA_WIDTH),
                .S_AWLEN_WIDTH        (S_AWLEN_WIDTH),
                .S_AWLEN_SIZE         (S_AWLEN_SIZE),
                .S_AWLEN_OFFSET       (S_AWLEN_OFFSET),
                .S_WSTRB_WIDTH        (S_WSTRB_WIDTH),
                .AWFIFO_PTR_WIDTH     (AWFIFO_PTR_WIDTH),
                .AWFIFO_RAM_TYPE      (AWFIFO_RAM_TYPE),
                .AWFIFO_LOW_DEALY     (AWFIFO_LOW_DEALY),
                .AWFIFO_DOUT_REGS     (AWFIFO_DOUT_REGS),
                .AWFIFO_S_REGS        (AWFIFO_S_REGS),
                .AWFIFO_M_REGS        (AWFIFO_M_REGS),
                .WFIFO_PTR_WIDTH      (WFIFO_PTR_WIDTH),
                .WFIFO_RAM_TYPE       (WFIFO_RAM_TYPE),
                .WFIFO_LOW_DEALY      (WFIFO_LOW_DEALY),
                .WFIFO_DOUT_REGS      (WFIFO_DOUT_REGS),
                .WFIFO_S_REGS         (WFIFO_S_REGS),
                .WFIFO_M_REGS         (WFIFO_M_REGS),
                .BFIFO_PTR_WIDTH      (BFIFO_PTR_WIDTH),
                .BFIFO_RAM_TYPE       (BFIFO_RAM_TYPE),
                .BFIFO_LOW_DEALY      (BFIFO_LOW_DEALY),
                .BFIFO_DOUT_REGS      (BFIFO_DOUT_REGS),
                .BFIFO_S_REGS         (BFIFO_S_REGS),
                .BFIFO_M_REGS         (BFIFO_M_REGS),
                .WCMD_FIFO_PTR_WIDTH  (WCMD_FIFO_PTR_WIDTH),
                .WCMD_FIFO_RAM_TYPE   (WCMD_FIFO_RAM_TYPE),
                .WCMD_FIFO_LOW_DEALY  (WCMD_FIFO_LOW_DEALY),
                .WCMD_FIFO_DOUT_REGS  (WCMD_FIFO_DOUT_REGS),
                .WCMD_FIFO_S_REGS     (WCMD_FIFO_S_REGS),
                .WCMD_FIFO_M_REGS     (WCMD_FIFO_M_REGS),
                .BCMD_FIFO_PTR_WIDTH  (BCMD_FIFO_PTR_WIDTH),
                .BCMD_FIFO_RAM_TYPE   (BCMD_FIFO_RAM_TYPE),
                .BCMD_FIFO_LOW_DEALY  (BCMD_FIFO_LOW_DEALY),
                .BCMD_FIFO_DOUT_REGS  (BCMD_FIFO_DOUT_REGS),
                .BCMD_FIFO_S_REGS     (BCMD_FIFO_S_REGS),
                .BCMD_FIFO_M_REGS     (BCMD_FIFO_M_REGS)
            )
        i_axi4_dma_write
            (
                .s_awresetn           (s_awresetn),
                .s_awclk              (s_awclk),
                .s_awaddr             (s_awaddr),
                .s_awlen              (s_awlen),
                .s_awlen_max          (s_awlen_max),
                .s_awvalid            (s_awvalid),
                .s_awready            (s_awready),
                .s_wresetn            (s_wresetn),
                .s_wclk               (s_wclk),
                .s_wstrb              (s_wstrb),
                .s_wdata              (s_wdata),
                .s_wvalid             (s_wvalid),
                .s_wready             (s_wready),
                .s_bresetn            (s_bresetn),
                .s_bclk               (s_bclk),
                .s_bvalid             (s_bvalid),
                .s_bready             (s_bready),
                .m_aresetn            (m_aresetn),
                .m_aclk               (m_aclk),
                .m_axi4_awid          (m_axi4_awid),
                .m_axi4_awaddr        (m_axi4_awaddr),
                .m_axi4_awlen         (m_axi4_awlen),
                .m_axi4_awsize        (m_axi4_awsize),
                .m_axi4_awburst       (m_axi4_awburst),
                .m_axi4_awlock        (m_axi4_awlock),
                .m_axi4_awcache       (m_axi4_awcache),
                .m_axi4_awprot        (m_axi4_awprot),
                .m_axi4_awqos         (m_axi4_awqos),
                .m_axi4_awregion      (m_axi4_awregion),
                .m_axi4_awvalid       (m_axi4_awvalid),
                .m_axi4_awready       (m_axi4_awready),
                .m_axi4_wdata         (m_axi4_wdata),
                .m_axi4_wstrb         (m_axi4_wstrb),
                .m_axi4_wlast         (m_axi4_wlast),
                .m_axi4_wvalid        (m_axi4_wvalid),
                .m_axi4_wready        (m_axi4_wready),
                .m_axi4_bid           (m_axi4_bid),
                .m_axi4_bresp         (m_axi4_bresp),
                .m_axi4_bvalid        (m_axi4_bvalid),
                .m_axi4_bready        (m_axi4_bready)
            );
    
    always @(posedge s_awclk) begin
        if ( ~s_awresetn ) begin
            s_awaddr    <= 0;
            s_awlen     <= 1024-1;
            s_awlen_max <= 15;
            s_awvalid   <= 1'b1;
        end
        else begin
            if ( s_awvalid && s_awready ) begin
                s_awvalid <= 0;
            end
        end
    end
    
    reg     s_wenable = 1'b1;
    always @(posedge s_wclk) begin
        if ( ~s_wresetn ) begin
            s_wstrb  <= 8'ha5;
            s_wdata  <= 0;
            s_wvalid <= 0;
        end
        else begin
            if ( s_wvalid && s_wready ) begin
                s_wdata <= s_wdata + 1;
            end
            
            if ( !s_wvalid || s_wready ) begin
                if ( s_wdata == 1024-1 ) begin
                    s_wenable = 0;
                end
                s_wvalid <= s_wenable & 1'b1;
            end
        end
    end
    
    always @(posedge s_bclk) begin
        if ( ~s_bresetn ) begin
            s_bready <= 0;
        end
        else begin
            s_bready <= 1;
        end
    end
    
    
    
    
    // ---------------------------------
    //  dummy memory model
    // ---------------------------------
    
    jelly_axi4_slave_model
            #(
                .AXI_ID_WIDTH           (AXI4_ID_WIDTH),
                .AXI_ADDR_WIDTH         (AXI4_ADDR_WIDTH),
                .AXI_QOS_WIDTH          (AXI4_QOS_WIDTH),
                .AXI_LEN_WIDTH          (AXI4_LEN_WIDTH),
                .AXI_DATA_SIZE          (AXI4_DATA_SIZE),
                .AXI_DATA_WIDTH         (AXI4_DATA_WIDTH),
                .AXI_STRB_WIDTH         (AXI4_DATA_WIDTH/8),
                .MEM_WIDTH              (24),
                
                .READ_DATA_ADDR         (1),
                
                .WRITE_LOG_FILE         ("axi4_write.txt"),
                .READ_LOG_FILE          ("axi4_read.txt"),
                
                .AW_DELAY               (RAND_BUSY ? 64 : 0),
                .AR_DELAY               (RAND_BUSY ? 64 : 0),
                
                .AW_FIFO_PTR_WIDTH      (RAND_BUSY ? 4 : 0),
                .W_FIFO_PTR_WIDTH       (RAND_BUSY ? 4 : 0),
                .B_FIFO_PTR_WIDTH       (RAND_BUSY ? 4 : 0),
                .AR_FIFO_PTR_WIDTH      (0),
                .R_FIFO_PTR_WIDTH       (0),
                
                .AW_BUSY_RATE           (RAND_BUSY ? 80 : 0),
                .W_BUSY_RATE            (RAND_BUSY ? 80 : 0),
                .B_BUSY_RATE            (RAND_BUSY ? 80 : 0),
                .AR_BUSY_RATE           (0),
                .R_BUSY_RATE            (0)
            )
        i_axi4_slave_model
            (
                .aresetn                (m_aresetn),
                .aclk                   (m_aclk),
                
                .s_axi4_awid            (m_axi4_awid),
                .s_axi4_awaddr          (m_axi4_awaddr),
                .s_axi4_awlen           (m_axi4_awlen),
                .s_axi4_awsize          (m_axi4_awsize),
                .s_axi4_awburst         (m_axi4_awburst),
                .s_axi4_awlock          (m_axi4_awlock),
                .s_axi4_awcache         (m_axi4_awcache),
                .s_axi4_awprot          (m_axi4_awprot),
                .s_axi4_awqos           (m_axi4_awqos),
                .s_axi4_awvalid         (m_axi4_awvalid),
                .s_axi4_awready         (m_axi4_awready),
                .s_axi4_wdata           (m_axi4_wdata),
                .s_axi4_wstrb           (m_axi4_wstrb),
                .s_axi4_wlast           (m_axi4_wlast),
                .s_axi4_wvalid          (m_axi4_wvalid),
                .s_axi4_wready          (m_axi4_wready),
                .s_axi4_bid             (m_axi4_bid),
                .s_axi4_bresp           (m_axi4_bresp),
                .s_axi4_bvalid          (m_axi4_bvalid),
                .s_axi4_bready          (m_axi4_bready),
                .s_axi4_arid            (),
                .s_axi4_araddr          (),
                .s_axi4_arlen           (),
                .s_axi4_arsize          (),
                .s_axi4_arburst         (),
                .s_axi4_arlock          (),
                .s_axi4_arcache         (),
                .s_axi4_arprot          (),
                .s_axi4_arqos           (),
                .s_axi4_arvalid         (1'b0),
                .s_axi4_arready         (),
                .s_axi4_rid             (),
                .s_axi4_rdata           (),
                .s_axi4_rresp           (),
                .s_axi4_rlast           (),
                .s_axi4_rvalid          (),
                .s_axi4_rready          (1'b0)
            );
    
    
    
endmodule


`default_nettype wire


// end of file
