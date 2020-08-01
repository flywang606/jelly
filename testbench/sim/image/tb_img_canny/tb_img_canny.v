
`timescale 1ns / 1ps
`default_nettype none


module tb_img_canny();
    localparam RATE    = 10.0;
    
    initial begin
        $dumpfile("tb_img_canny.vcd");
        $dumpvars(0, tb_img_canny);
    end
    
    reg     clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    
    reg     reset = 1'b1;
    always #(RATE*100)  reset = 1'b0;
    
    parameter   USER_WIDTH = 1;
    parameter   DATA_WIDTH = 8;
    
    parameter   X_NUM      = 256;
    parameter   Y_NUM      = 256;
    parameter   PGM_FILE   = "BOAT.pgm";
    
    parameter   X_WIDTH    = 10;
    parameter   Y_WIDTH    = 9;
    
    
    wire                        axi4s_src_tlast;
    wire    [0:0]               axi4s_src_tuser;
    wire    [DATA_WIDTH-1:0]    axi4s_src_tdata;
    wire                        axi4s_src_tvalid;
    wire                        axi4s_src_tready;
    
    // master model
    jelly_axi4s_master_model
            #(
                .AXI4S_DATA_WIDTH   (DATA_WIDTH),
                .X_NUM              (X_NUM),
                .Y_NUM              (Y_NUM),
                .PGM_FILE           (PGM_FILE),
                .BUSY_RATE          (0),
                .RANDOM_SEED        (0)
            )
        i_axi4s_master_model
            (
                .aresetn            (~reset),
                .aclk               (clk),
                
                .m_axi4s_tdata      (axi4s_src_tdata),
                .m_axi4s_tlast      (axi4s_src_tlast),
                .m_axi4s_tuser      (axi4s_src_tuser),
                .m_axi4s_tvalid     (axi4s_src_tvalid),
                .m_axi4s_tready     (axi4s_src_tready)
            );
    
    jelly_axi4s_slave_model
            #(
                .COMPONENT_NUM      (1),
                .DATA_WIDTH         (8),
                .FILE_NAME          ("src_%04d.pgm"),
                .BUSY_RATE          (0)
            )
        i_axi4s_slave_model_src
            (
                .aresetn            (~reset),
                .aclk               (clk),
                .aclken             (1'b1),
                
                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                
                .s_axi4s_tuser      (axi4s_src_tuser),
                .s_axi4s_tlast      (axi4s_src_tlast),
                .s_axi4s_tdata      (axi4s_src_tdata),
                .s_axi4s_tvalid     (axi4s_src_tvalid & axi4s_src_tready),
                .s_axi4s_tready     ()
            );
    
    
    
    
    // AXI4 to img
    wire                                axi4s_out_tlast;
    wire    [0:0]                       axi4s_out_tuser;
    wire    [DATA_WIDTH*3-1:0]          axi4s_out_tdata;
    wire                                axi4s_out_tvalid;
    wire                                axi4s_out_tready;
    
    
    wire                                img_cke;
    
    wire                                img_src_line_first;
    wire                                img_src_line_last;
    wire                                img_src_pixel_first;
    wire                                img_src_pixel_last;
    wire                                img_src_de;
    wire    [USER_WIDTH-1:0]            img_src_user;
    wire    [DATA_WIDTH-1:0]            img_src_data;
    wire                                img_src_valid;
    
    wire                                img_sink_line_first;
    wire                                img_sink_line_last;
    wire                                img_sink_pixel_first;
    wire                                img_sink_pixel_last;
    wire                                img_sink_de;
    wire    [USER_WIDTH-1:0]            img_sink_user;
    wire    [DATA_WIDTH*3-1:0]          img_sink_data;
    wire                                img_sink_valid;
    
    jelly_axi4s_img
            #(
                .S_TDATA_WIDTH          (DATA_WIDTH),
                .M_TDATA_WIDTH          (DATA_WIDTH),
                .IMG_Y_NUM              (Y_NUM),
                .IMG_Y_WIDTH            (Y_WIDTH),
                .BLANK_Y_WIDTH          (8),
                .IMG_CKE_BUFG           (0)
            )
        jelly_axi4s_img
            (
                .reset                  (reset),
                .clk                    (clk),
                
                .param_blank_num        (8'hff),
                
                .s_axi4s_tdata          (axi4s_src_tdata),
                .s_axi4s_tlast          (axi4s_src_tlast),
                .s_axi4s_tuser          (axi4s_src_tuser),
                .s_axi4s_tvalid         (axi4s_src_tvalid),     //(axi4s_src_tvalid & !ptn_busy),
                .s_axi4s_tready         (axi4s_src_tready),
                
                .m_axi4s_tdata          (axi4s_out_tdata),
                .m_axi4s_tlast          (axi4s_out_tlast),
                .m_axi4s_tuser          (axi4s_out_tuser),
                .m_axi4s_tvalid         (axi4s_out_tvalid),
                .m_axi4s_tready         (axi4s_out_tready),
                
                
                .img_cke                (img_cke),
                
                .src_img_line_first     (img_src_line_first),
                .src_img_line_last      (img_src_line_last),
                .src_img_pixel_first    (img_src_pixel_first),
                .src_img_pixel_last     (img_src_pixel_last),
                .src_img_de             (img_src_de),
                .src_img_user           (img_src_user),
                .src_img_data           (img_src_data),
                .src_img_valid          (img_src_valid),
                
                .sink_img_line_first    (img_sink_line_first),
                .sink_img_line_last     (img_sink_line_last),
                .sink_img_pixel_first   (img_sink_pixel_first),
                .sink_img_pixel_last    (img_sink_pixel_last),
                .sink_img_de            (img_sink_de),
                .sink_img_user          (img_sink_user),
                .sink_img_data          (img_sink_data),
                .sink_img_valid         (img_sink_valid)
            );
    
    // core
    wire                                img_canny_line_first;
    wire                                img_canny_line_last;
    wire                                img_canny_pixel_first;
    wire                                img_canny_pixel_last;
    wire                                img_canny_de;
    wire    [DATA_WIDTH-1:0]            img_canny_data;
    wire                                img_canny_binary;
    wire    [7:0]                       img_canny_angle;
    wire                                img_canny_valid;
    
    jelly_img_canny
            #(
                .USER_WIDTH             (USER_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH),
                
                .INIT_CTL_CONTROL       (3'b111),
                .INIT_PARAM_TH          (127)
            )
        i_img_canny
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (img_cke),
                
                .s_wb_rst_i             (reset),
                .s_wb_clk_i             (clk),
                .s_wb_adr_i             (0),
                .s_wb_dat_i             (0),
                .s_wb_dat_o             (),
                .s_wb_we_i              (0),
                .s_wb_sel_i             (0),
                .s_wb_stb_i             (0),
                .s_wb_ack_o             (),
                
                .s_img_line_first       (img_src_line_first),
                .s_img_line_last        (img_src_line_last),
                .s_img_pixel_first      (img_src_pixel_first),
                .s_img_pixel_last       (img_src_pixel_last),
                .s_img_de               (img_src_de),
                .s_img_data             (img_src_data),
                .s_img_valid            (img_src_valid),
                
                .m_img_line_first       (img_canny_line_first),
                .m_img_line_last        (img_canny_line_last),
                .m_img_pixel_first      (img_canny_pixel_first),
                .m_img_pixel_last       (img_canny_pixel_last),
                .m_img_de               (img_canny_de),
                .m_img_data             (img_canny_data),
                .m_img_binary           (img_canny_binary),
                .m_img_angle            (img_canny_angle),
                .m_img_valid            (img_canny_valid)
            );
    
    assign img_sink_line_first  = img_canny_line_first;
    assign img_sink_line_last   = img_canny_line_last;
    assign img_sink_pixel_first = img_canny_pixel_first;
    assign img_sink_pixel_last  = img_canny_pixel_last;
    assign img_sink_de          = img_canny_de;
    assign img_sink_data        = {8{img_canny_binary}};
    assign img_sink_valid       = img_canny_valid;
    
    
    jelly_axi4s_slave_model
            #(
                .COMPONENT_NUM      (1),
                .DATA_WIDTH         (8),
                .FILE_NAME          ("img_%04d.pgm"),
                .BUSY_RATE          (0),
                .RANDOM_SEED        (23456)
            )
        i_axi4s_slave_model_data
            (
                .aresetn            (~reset),
                .aclk               (clk),
                .aclken             (1'b1),
                
                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                
                .s_axi4s_tuser      (axi4s_out_tuser),
                .s_axi4s_tlast      (axi4s_out_tlast),
                .s_axi4s_tdata      (axi4s_out_tdata[7:0]),
                .s_axi4s_tvalid     (axi4s_out_tvalid),
                .s_axi4s_tready     (axi4s_out_tready)
            );
    
    
    jelly_axi4s_slave_model
            #(
                .COMPONENT_NUM      (1),
                .DATA_WIDTH         (8),
                .FILE_NAME          ("ang_%04d.pgm"),
                .BUSY_RATE          (0),
                .RANDOM_SEED        (23456)
            )
        i_axi4s_slave_model_angle
            (
                .aresetn            (~reset),
                .aclk               (clk),
                .aclken             (img_cke),
                
                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                
                .s_axi4s_tuser      (img_canny_line_first & img_canny_pixel_first),
                .s_axi4s_tlast      (img_canny_pixel_last),
                .s_axi4s_tdata      (img_canny_angle),
                .s_axi4s_tvalid     (img_canny_de & img_canny_valid),
                .s_axi4s_tready     ()
            );
    
    
endmodule


`default_nettype wire


// end of file
