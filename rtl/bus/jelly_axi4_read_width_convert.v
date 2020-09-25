// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// AXI4 メモリ読み出しコア データ幅変換部
module jelly_axi4_read_width_convert
        #(
            parameter   ARASYNC           = 1,
            parameter   RASYNC            = 1,
            parameter   RBASYNC           = 1,
            parameter   BYTE_WIDTH        = 8,
            parameter   BYPASS_GATE       = 0,
            
            parameter   ALLOW_UNALIGNED   = 0,
            
            parameter   HAS_S_WFIRST      = 0,
            parameter   HAS_S_WLAST       = 0,
            parameter   HAS_M_WFIRST      = 0,
            parameter   HAS_M_WLAST       = 0,
            
            parameter   ARADDR_WIDTH      = 32,
            parameter   ARUSER_WIDTH      = 0,
            
            parameter   S_RDATA_WIDTH     = 32,  // 8の倍数であること
            parameter   S_RUSER_WIDTH     = 0,
            parameter   S_ARLEN_WIDTH     = 32,
            parameter   S_ARLEN_OFFSET    = 1'b1,
            parameter   S_ARUSER_WIDTH    = 0,
            
            parameter   M_RDATA_SIZE      = 3,   // log2 (0:8bit, 1:16bit, 2:32bit ...)
            parameter   M_RDATA_WIDTH     = (BYTE_WIDTH << M_RDATA_SIZE),
            parameter   M_RUSER_WIDTH     = S_RUSER_WIDTH * M_RDATA_WIDTH / S_RDATA_WIDTH,
            parameter   M_ARLEN_WIDTH     = 32,
            parameter   M_ARLEN_OFFSET    = 1'b1,
            parameter   M_ARUSER_WIDTH    = 0,
            
            parameter   RFIFO_PTR_WIDTH   = 9,
            parameter   RFIFO_RAM_TYPE    = "block",
            parameter   RFIFO_LOW_DEALY   = 0,
            parameter   RFIFO_DOUT_REGS   = 1,
            parameter   RFIFO_S_REGS      = 0,
            parameter   RFIFO_M_REGS      = 1,
            
            parameter   ARFIFO_PTR_WIDTH  = 4,
            parameter   ARFIFO_RAM_TYPE   = "distributed",
            parameter   ARFIFO_LOW_DEALY  = 1,
            parameter   ARFIFO_DOUT_REGS  = 0,
            parameter   ARFIFO_S_REGS     = 0,
            parameter   ARFIFO_M_REGS     = 0,
            
            parameter   SRFIFO_PTR_WIDTH = 4,
            parameter   SRFIFO_RAM_TYPE  = "distributed",
            parameter   SRFIFO_LOW_DEALY = 1,
            parameter   SRFIFO_DOUT_REGS = 0,
            parameter   SRFIFO_S_REGS    = 0,
            parameter   SRFIFO_M_REGS    = 0,
            
            parameter   MRFIFO_PTR_WIDTH = 4,
            parameter   MRFIFO_RAM_TYPE  = "distributed",
            parameter   MRFIFO_LOW_DEALY = 1,
            parameter   MRFIFO_DOUT_REGS = 0,
            parameter   MRFIFO_S_REGS    = 0,
            parameter   MRFIFO_M_REGS    = 0,
            
            parameter   CONVERT_S_REGS    = 0,
            parameter   POST_CONVERT      = (M_RDATA_WIDTH >= S_RDATA_WIDTH),
            
            // local
            parameter   ARUSER_BITS       = ARUSER_WIDTH  > 0 ? ARUSER_WIDTH  : 1,
            parameter   S_RUSER_BITS      = S_RUSER_WIDTH > 0 ? S_RUSER_WIDTH : 1,
            parameter   M_RUSER_BITS      = M_RUSER_WIDTH > 0 ? M_RUSER_WIDTH : 1
        )
        (
            input   wire                            endian,
            
            input   wire                            s_arresetn,
            input   wire                            s_arclk,
            input   wire    [ARADDR_WIDTH-1:0]      s_araddr,
            input   wire    [S_ARLEN_WIDTH-1:0]     s_arlen,
            input   wire    [ARUSER_BITS-1:0]       s_aruser,
            input   wire                            s_arvalid,
            output  wire                            s_arready,
            
            input   wire                            s_rresetn,
            input   wire                            s_rclk,
            output  wire                            s_rfirst,
            output  wire                            s_rlast,
            output  wire    [S_RDATA_WIDTH-1:0]     s_rdata,
            output  wire    [S_RUSER_BITS-1:0]      s_ruser,
            output  wire                            s_rvalid,
            input   wire                            s_rready,
            output  wire    [RFIFO_PTR_WIDTH:0]     rfifo_data_count,
            output  wire                            rfifo_rd_signal,
            
            input   wire                            s_rbresetn,
            input   wire                            s_rbclk,
            output  wire                            s_rbvalid,
            input   wire                            s_rbready,
            
            input   wire                            m_arresetn,
            input   wire                            m_arclk,
            output  wire    [ARADDR_WIDTH-1:0]      m_araddr,
            output  wire    [M_ARLEN_WIDTH-1:0]     m_arlen,
            output  wire    [ARUSER_BITS-1:0]       m_aruser,
            output  wire                            m_arvalid,
            input   wire                            m_arready,
            
            input   wire                            m_rresetn,
            input   wire                            m_rclk,
            input   wire    [M_RDATA_WIDTH-1:0]     m_rdata,
            input   wire                            m_rfirst,
            input   wire                            m_rlast,
            input   wire    [M_RUSER_BITS-1:0]      m_ruser,
            input   wire                            m_rvalid,
            output  wire                            m_rready,
            output  wire    [RFIFO_PTR_WIDTH:0]     rfifo_free_count,
            output  wire                            rfifo_wr_signal
        );
    
    
    // ---------------------------------
    //  localparam
    // ---------------------------------
    
    localparam ALIGN_WIDTH = M_RDATA_SIZE;
    localparam ALIGN_BITS  = ALIGN_WIDTH > 0 ? ALIGN_WIDTH : 1;
    
    
    
    // ---------------------------------
    //  s_ar
    // ---------------------------------
    
    // address convert
    wire    [ARADDR_WIDTH-1:0]      adrcnv_araddr;
    wire    [ALIGN_BITS-1:0]        adrcnv_align;
    wire    [S_ARLEN_WIDTH-1:0]     adrcnv_arlen_s;
    wire    [M_ARLEN_WIDTH-1:0]     adrcnv_arlen_m;
    wire    [ARUSER_BITS-1:0]       adrcnv_aruser;
    wire                            adrcnv_arvalid;
    wire                            adrcnv_arready;
    
    jelly_address_width_convert
            #(
                .ALLOW_UNALIGNED    (ALLOW_UNALIGNED),
                .ADDR_WIDTH         (ARADDR_WIDTH),
                .USER_WIDTH         (ARUSER_BITS + S_ARLEN_WIDTH),
                .S_UNIT             (S_RDATA_WIDTH / BYTE_WIDTH),
                .M_UNIT_SIZE        (M_RDATA_SIZE),
                .S_LEN_WIDTH        (S_ARLEN_WIDTH),
                .S_LEN_OFFSET       (S_ARLEN_OFFSET),
                .M_LEN_WIDTH        (M_ARLEN_WIDTH),
                .M_LEN_OFFSET       (M_ARLEN_OFFSET)
            )
        i_address_width_conver
            (
                .reset              (~s_arresetn),
                .clk                (s_arclk),
                .cke                (1'b1),
                
                .s_addr             (s_araddr),
                .s_len              (s_arlen),
                .s_user             ({s_aruser, s_arlen}),
                .s_valid            (s_arvalid),
                .s_ready            (s_arready),
                
                .m_addr             (adrcnv_araddr),
                .m_align            (adrcnv_align),
                .m_len              (adrcnv_arlen_m),
                .m_user             ({adrcnv_aruser, adrcnv_arlen_s}),
                .m_valid            (adrcnv_arvalid),
                .m_ready            (adrcnv_arready)
            );
    
    
    // アドレスコマンドと、データ制御用に分岐
    wire    [ARADDR_WIDTH-1:0]      ar_araddr;
    wire    [M_ARLEN_WIDTH-1:0]     ar_arlen;
    wire    [ARUSER_BITS-1:0]       ar_aruser;
    wire                            ar_arvalid;
    wire                            ar_arready;
    
    wire    [M_ARLEN_WIDTH-1:0]     mr_arlen;
    wire    [ALIGN_BITS-1:0]        mr_align;
    wire                            mr_arvalid;
    wire                            mr_arready;
    
    wire    [S_ARLEN_WIDTH-1:0]     sr_arlen;
    wire    [ALIGN_BITS-1:0]        sr_align;
    wire                            sr_arvalid;
    wire                            sr_arready;
    
    jelly_data_split_pack2
            #(
                .NUM                (3),
                
                .DATA0_0_WIDTH      (ARADDR_WIDTH),
                .DATA0_1_WIDTH      (M_ARLEN_WIDTH),
                .DATA0_2_WIDTH      (ARUSER_WIDTH),
                
                .DATA1_0_WIDTH      (M_ARLEN_WIDTH),
                .DATA1_1_WIDTH      (ALIGN_WIDTH),
                
                .DATA2_0_WIDTH      (S_ARLEN_WIDTH),
                
                .S_REGS             (0),
                .M_REGS             (0)
            )
        i_data_split_pack2_ar
            (
                .reset              (~s_arresetn),
                .clk                (s_arclk),
                .cke                (1'b1),
                
                .s_data0_0          (adrcnv_araddr),
                .s_data0_1          (adrcnv_arlen_m),
                .s_data0_2          (adrcnv_aruser),
                .s_data1_0          (adrcnv_arlen_m),
                .s_data1_1          (adrcnv_align),
                .s_data2_0          (adrcnv_arlen_s),
                .s_valid            (adrcnv_arvalid),
                .s_ready            (adrcnv_arready),
                
                .m0_data0           (ar_araddr),
                .m0_data1           (ar_arlen),
                .m0_data2           (ar_aruser),
                .m0_valid           (ar_arvalid),
                .m0_ready           (ar_arready),
                
                .m1_data0           (mr_arlen),
                .m1_data1           (mr_align),
                .m1_valid           (mr_arvalid),
                .m1_ready           (mr_arready),
                
                .m2_data0           (sr_arlen),
                .m2_valid           (sr_arvalid),
                .m2_ready           (sr_arready)
            );
    
    
    
    // ---------------------------------
    //  address command
    // ---------------------------------
    
    // master 側にクロック載せ替え
    jelly_fifo_pack
            #(
                .ASYNC              (ARASYNC),
                .DATA0_WIDTH        (ARADDR_WIDTH),
                .DATA1_WIDTH        (M_ARLEN_WIDTH),
                .DATA2_WIDTH        (ARUSER_WIDTH),
                
                .PTR_WIDTH          (ARFIFO_PTR_WIDTH),
                .DOUT_REGS          (ARFIFO_DOUT_REGS),
                .RAM_TYPE           (ARFIFO_RAM_TYPE),
                .LOW_DEALY          (ARFIFO_LOW_DEALY),
                .S_REGS             (ARFIFO_S_REGS),
                .M_REGS             (ARFIFO_M_REGS)
            )
        i_fifo_pack_cmd_ar
            (
                .s_reset            (~s_arresetn),
                .s_clk              (s_arclk),
                .s_data0            (ar_araddr),
                .s_data1            (ar_arlen),
                .s_data2            (ar_aruser),
                .s_valid            (ar_arvalid),
                .s_ready            (ar_arready),
                
                .m_reset            (~m_arresetn),
                .m_clk              (m_arclk),
                .m_data0            (m_araddr),
                .m_data1            (m_arlen),
                .m_data2            (m_aruser),
                .m_valid            (m_arvalid),
                .m_ready            (m_arready)
            );
    
    
    
    // ---------------------------------
    //  rdata
    // ---------------------------------
    
    // m_r 側のクロックに載せ替え
    wire    [M_ARLEN_WIDTH-1:0]     mrfifo_arlen;
    wire    [ALIGN_BITS-1:0]        mrfifo_align;
    wire                            mrfifo_arvalid;
    wire                            mrfifo_arready;
    
    jelly_fifo_pack
            #(
                .ASYNC              (ARASYNC | RASYNC),
                .DATA0_WIDTH        (S_ARLEN_WIDTH),
                .DATA1_WIDTH        (ALIGN_WIDTH),
                
                .PTR_WIDTH          (MRFIFO_PTR_WIDTH),
                .DOUT_REGS          (MRFIFO_DOUT_REGS),
                .RAM_TYPE           (MRFIFO_RAM_TYPE),
                .LOW_DEALY          (MRFIFO_LOW_DEALY),
                .S_REGS             (MRFIFO_S_REGS),
                .M_REGS             (MRFIFO_M_REGS)
            )
        i_fifo_pack_dat
            (
                .s_reset            (~s_arresetn),
                .s_clk              (s_arclk),
                .s_data0            (mr_arlen),
                .s_data1            (mr_align),
                .s_valid            (mr_arvalid),
                .s_ready            (mr_arready),
                
                .m_reset            (~m_rresetn),
                .m_clk              (m_rclk),
                .m_data0            (mrfifo_arlen),
                .m_data1            (mrfifo_align),
                .m_valid            (mrfifo_arvalid),
                .m_ready            (mrfifo_arready)
            );
    
    
    // gate (アライン補正の為、上位のアクセス単位で last をつけ直してalignをつける)
    wire    [ALIGN_BITS-1:0]        gate_align;
    wire    [M_RDATA_WIDTH-1:0]     gate_rdata;
    wire    [M_RUSER_BITS-1:0]      gate_ruser;
    wire                            gate_rlast;
    wire                            gate_rvalid;
    wire                            gate_rready;
    
    jelly_stream_gate
            #(
                .BYPASS             (!ALLOW_UNALIGNED && BYPASS_GATE),
                .DETECTOR_ENABLE    (0),
                .DATA_WIDTH         (M_RUSER_BITS + M_RDATA_WIDTH),
                .LEN_WIDTH          (S_ARLEN_WIDTH),
                .LEN_OFFSET         (S_ARLEN_OFFSET),
                .USER_WIDTH         (ALIGN_WIDTH),
                .S_PERMIT_REGS      (0),
                .S_REGS             (0),
                .M_REGS             (1)
            )
        i_stream_gate_m
            (
                .reset              (~m_rresetn),
                .clk                (m_rclk),
                .cke                (1'b1),
                
                .skip               (1'b0),
                .detect_first       (1'b0),
                .detect_last        (1'b0),
                .padding_en         (1'b0),
                .padding_data       (1'b0),
                .padding_skip       (1'b0),
                
                .s_permit_first     (1'b1),
                .s_permit_last      (1'b1),
                .s_permit_len       (mrfifo_arlen),
                .s_permit_user      (mrfifo_align),
                .s_permit_valid     (mrfifo_arvalid),
                .s_permit_ready     (mrfifo_arready),
                
                .s_first            (1'b0),
                .s_last             (m_rlast),
                .s_data             ({m_ruser, m_rdata}),
                .s_valid            (m_rvalid),
                .s_ready            (m_rready),
                
                .m_first            (),
                .m_last             (gate_rlast),
                .m_data             ({gate_ruser, gate_rdata}),
                .m_user             (gate_align),
                .m_valid            (gate_rvalid),
                .m_ready            (gate_rready)
            );
    
    
    // read response channel
    jelly_signal_transfer
            #(
                .ASYNC              (RBASYNC),
                .CAPACITY_WIDTH     (RFIFO_PTR_WIDTH)
            )
        i_signal_transfer
            (
                .s_reset            (~m_rresetn),
                .s_clk              (m_rclk),
                .s_valid            (gate_rvalid & gate_rready),
                
                .m_reset            (~s_rbresetn),
                .m_clk              (s_rbclk),
                .m_valid            (s_rbvalid),
                .m_ready            (s_rbready)
            );
    
    
    // fifo with width convert
    wire    [S_RDATA_WIDTH-1:0]     conv_rdata;
    wire                            conv_rfirst;
    wire                            conv_rlast;
    wire    [S_RUSER_BITS-1:0]      conv_ruser;
    wire                            conv_rvalid;
    wire                            conv_rready;
    jelly_axi4s_fifo_width_convert
            #(
                .ASYNC              (RASYNC),
                .FIFO_PTR_WIDTH     (RFIFO_PTR_WIDTH),
                .FIFO_RAM_TYPE      (RFIFO_RAM_TYPE),
                .FIFO_LOW_DEALY     (RFIFO_LOW_DEALY),
                .FIFO_DOUT_REGS     (RFIFO_DOUT_REGS),
                .FIFO_S_REGS        (RFIFO_S_REGS),
                .FIFO_M_REGS        (RFIFO_M_REGS),
                
                .HAS_STRB           (0),
                .HAS_KEEP           (0),
                .HAS_FIRST          (0),
                .HAS_LAST           (ALLOW_UNALIGNED),
                .HAS_ALIGN_S        (ALLOW_UNALIGNED),
                .HAS_ALIGN_M        (0),
                
                .S_TDATA_WIDTH      (M_RDATA_WIDTH),
                .M_TDATA_WIDTH      (S_RDATA_WIDTH),
                .S_TUSER_WIDTH      (M_RUSER_WIDTH),
                .FIRST_FORCE_LAST   (0),
                .FIRST_OVERWRITE    (0),
                .ALIGN_S_WIDTH      (ALIGN_BITS),
                .ALIGN_M_WIDTH      (1),
                
                .CONVERT_S_REGS     (CONVERT_S_REGS),
                .POST_CONVERT       (POST_CONVERT)
            )
        i_axi4s_fifo_width_convert
            (
                .endian             (endian),
                
                .s_aresetn          (m_rresetn),
                .s_aclk             (m_rclk),
                .s_align_s          (gate_align),
                .s_align_m          (1'b0),
                .s_axi4s_tdata      (gate_rdata),
                .s_axi4s_tstrb      ({(M_RDATA_WIDTH/8){1'b1}}),
                .s_axi4s_tkeep      ({(M_RDATA_WIDTH/8){1'b1}}),
                .s_axi4s_tfirst     (1'b0),
                .s_axi4s_tlast      (gate_rlast),
                .s_axi4s_tuser      (gate_ruser),
                .s_axi4s_tvalid     (gate_rvalid),
                .s_axi4s_tready     (gate_rready),
                .fifo_free_count    (rfifo_free_count),
                .fifo_wr_signal     (rfifo_wr_signal),
                
                .m_aresetn          (s_rresetn),
                .m_aclk             (s_rclk),
                .m_axi4s_tdata      (conv_rdata),
                .m_axi4s_tstrb      (),
                .m_axi4s_tkeep      (),
                .m_axi4s_tfirst     (conv_rfirst),
                .m_axi4s_tlast      (conv_rlast),
                .m_axi4s_tuser      (conv_ruser),
                .m_axi4s_tvalid     (conv_rvalid),
                .m_axi4s_tready     (conv_rready),
                .fifo_data_count    (rfifo_data_count),
                .fifo_rd_signal     (rfifo_rd_signal)
            );
    
    
    
    
    // s_r 側のクロックに載せ替え
    wire    [S_ARLEN_WIDTH-1:0]     srfifo_arlen;
    wire    [ALIGN_BITS-1:0]        srfifo_align;
    wire                            srfifo_arvalid;
    wire                            srfifo_arready;
    
    jelly_fifo_pack
            #(
                .ASYNC              (ARASYNC | RASYNC),
                .DATA0_WIDTH        (S_ARLEN_WIDTH),
                
                .PTR_WIDTH          (SRFIFO_PTR_WIDTH),
                .DOUT_REGS          (SRFIFO_DOUT_REGS),
                .RAM_TYPE           (SRFIFO_RAM_TYPE),
                .LOW_DEALY          (SRFIFO_LOW_DEALY),
                .S_REGS             (SRFIFO_S_REGS),
                .M_REGS             (SRFIFO_M_REGS)
            )
        i_fifo_pack_sr
            (
                .s_reset            (~s_arresetn),
                .s_clk              (s_arclk),
                .s_data0            (sr_arlen),
                .s_valid            (sr_arvalid),
                .s_ready            (sr_arready),
                
                .m_reset            (~s_rresetn),
                .m_clk              (s_rclk),
                .m_data0            (srfifo_arlen),
                .m_valid            (srfifo_arvalid),
                .m_ready            (srfifo_arready)
            );
    
    // gate (アライン補正の余分をカット)
    jelly_stream_gate
            #(
                .BYPASS             (!ALLOW_UNALIGNED && BYPASS_GATE),
                .DETECTOR_ENABLE    (1),
                .DATA_WIDTH         (S_RUSER_BITS + S_RDATA_WIDTH),
                .LEN_WIDTH          (S_ARLEN_WIDTH),
                .LEN_OFFSET         (S_ARLEN_OFFSET),
                .USER_WIDTH         (ALIGN_WIDTH),
                .S_PERMIT_REGS      (0),
                .S_REGS             (0),
                .M_REGS             (1)
            )
        i_stream_gate_s
            (
                .reset              (~s_rresetn),
                .clk                (s_rclk),
                .cke                (1'b1),
                
                .skip               (1'b0),
                .detect_first       (1'b0),
                .detect_last        (1'b1),
                .padding_en         (1'b0),
                .padding_data       (1'b0),
                .padding_skip       (1'b0),
                
                .s_permit_first     (1'b1),
                .s_permit_last      (1'b1),
                .s_permit_len       (srfifo_arlen),
                .s_permit_user      (1'b0),
                .s_permit_valid     (srfifo_arvalid),
                .s_permit_ready     (srfifo_arready),
                
                .s_first            (conv_rfirst),
                .s_last             (conv_rlast),
                .s_data             ({conv_ruser, conv_rdata}),
                .s_valid            (conv_rvalid),
                .s_ready            (conv_rready),
                
                .m_first            (s_rfirst),
                .m_last             (s_rlast),
                .m_data             ({s_ruser, s_rdata}),
                .m_user             (),
                .m_valid            (s_rvalid),
                .m_ready            (s_rready)
            );
    
    
endmodule


`default_nettype wire


// end of file
