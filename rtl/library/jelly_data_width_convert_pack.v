// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_data_width_convert_pack
        #(
            parameter NUM_GCD          = 1, // S_NUM と M_NUM の最大公約数(人力)
            parameter S_NUM            = 1,
            parameter M_NUM            = 1,
            parameter UNIT0_WIDTH      = 32,
            parameter UNIT1_WIDTH      = 0,
            parameter UNIT2_WIDTH      = 0,
            parameter UNIT3_WIDTH      = 0,
            parameter UNIT4_WIDTH      = 0,
            parameter UNIT5_WIDTH      = 0,
            parameter UNIT6_WIDTH      = 0,
            parameter UNIT7_WIDTH      = 0,
            parameter UNIT8_WIDTH      = 0,
            parameter UNIT9_WIDTH      = 0,
            parameter S_DATA0_WIDTH    = S_NUM * UNIT0_WIDTH,
            parameter S_DATA1_WIDTH    = S_NUM * UNIT1_WIDTH,
            parameter S_DATA2_WIDTH    = S_NUM * UNIT2_WIDTH,
            parameter S_DATA3_WIDTH    = S_NUM * UNIT3_WIDTH,
            parameter S_DATA4_WIDTH    = S_NUM * UNIT4_WIDTH,
            parameter S_DATA5_WIDTH    = S_NUM * UNIT5_WIDTH,
            parameter S_DATA6_WIDTH    = S_NUM * UNIT6_WIDTH,
            parameter S_DATA7_WIDTH    = S_NUM * UNIT7_WIDTH,
            parameter S_DATA8_WIDTH    = S_NUM * UNIT8_WIDTH,
            parameter S_DATA9_WIDTH    = S_NUM * UNIT9_WIDTH,
            parameter M_DATA0_WIDTH    = M_NUM * UNIT0_WIDTH,
            parameter M_DATA1_WIDTH    = M_NUM * UNIT1_WIDTH,
            parameter M_DATA2_WIDTH    = M_NUM * UNIT2_WIDTH,
            parameter M_DATA3_WIDTH    = M_NUM * UNIT3_WIDTH,
            parameter M_DATA4_WIDTH    = M_NUM * UNIT4_WIDTH,
            parameter M_DATA5_WIDTH    = M_NUM * UNIT5_WIDTH,
            parameter M_DATA6_WIDTH    = M_NUM * UNIT6_WIDTH,
            parameter M_DATA7_WIDTH    = M_NUM * UNIT7_WIDTH,
            parameter M_DATA8_WIDTH    = M_NUM * UNIT8_WIDTH,
            parameter M_DATA9_WIDTH    = M_NUM * UNIT9_WIDTH,
            
            parameter FIRST_FORCE_LAST = 1,  // firstで前方吐き出し時に残変換があれば強制的にlastを付与
            parameter FIRST_OVERWRITE  = 0,  // first時前方に残変換があれば吐き出さずに上書き
            parameter S_REGS           = 1,
            
            // local
            parameter UNIT0_BITS       = UNIT0_WIDTH   > 0 ? UNIT0_WIDTH   : 1,
            parameter UNIT1_BITS       = UNIT1_WIDTH   > 0 ? UNIT1_WIDTH   : 1,
            parameter UNIT2_BITS       = UNIT2_WIDTH   > 0 ? UNIT2_WIDTH   : 1,
            parameter UNIT3_BITS       = UNIT3_WIDTH   > 0 ? UNIT3_WIDTH   : 1,
            parameter UNIT4_BITS       = UNIT4_WIDTH   > 0 ? UNIT4_WIDTH   : 1,
            parameter UNIT5_BITS       = UNIT5_WIDTH   > 0 ? UNIT5_WIDTH   : 1,
            parameter UNIT6_BITS       = UNIT6_WIDTH   > 0 ? UNIT6_WIDTH   : 1,
            parameter UNIT7_BITS       = UNIT7_WIDTH   > 0 ? UNIT7_WIDTH   : 1,
            parameter UNIT8_BITS       = UNIT8_WIDTH   > 0 ? UNIT8_WIDTH   : 1,
            parameter UNIT9_BITS       = UNIT9_WIDTH   > 0 ? UNIT9_WIDTH   : 1,
            parameter S_DATA0_BITS     = S_DATA0_WIDTH > 0 ? S_DATA0_WIDTH : 1,
            parameter S_DATA1_BITS     = S_DATA1_WIDTH > 0 ? S_DATA1_WIDTH : 1,
            parameter S_DATA2_BITS     = S_DATA2_WIDTH > 0 ? S_DATA2_WIDTH : 1,
            parameter S_DATA3_BITS     = S_DATA3_WIDTH > 0 ? S_DATA3_WIDTH : 1,
            parameter S_DATA4_BITS     = S_DATA4_WIDTH > 0 ? S_DATA4_WIDTH : 1,
            parameter S_DATA5_BITS     = S_DATA5_WIDTH > 0 ? S_DATA5_WIDTH : 1,
            parameter S_DATA6_BITS     = S_DATA6_WIDTH > 0 ? S_DATA6_WIDTH : 1,
            parameter S_DATA7_BITS     = S_DATA7_WIDTH > 0 ? S_DATA7_WIDTH : 1,
            parameter S_DATA8_BITS     = S_DATA8_WIDTH > 0 ? S_DATA8_WIDTH : 1,
            parameter S_DATA9_BITS     = S_DATA9_WIDTH > 0 ? S_DATA9_WIDTH : 1,
            parameter M_DATA0_BITS     = M_DATA0_WIDTH > 0 ? M_DATA0_WIDTH : 1,
            parameter M_DATA1_BITS     = M_DATA1_WIDTH > 0 ? M_DATA1_WIDTH : 1,
            parameter M_DATA2_BITS     = M_DATA2_WIDTH > 0 ? M_DATA2_WIDTH : 1,
            parameter M_DATA3_BITS     = M_DATA3_WIDTH > 0 ? M_DATA3_WIDTH : 1,
            parameter M_DATA4_BITS     = M_DATA4_WIDTH > 0 ? M_DATA4_WIDTH : 1,
            parameter M_DATA5_BITS     = M_DATA5_WIDTH > 0 ? M_DATA5_WIDTH : 1,
            parameter M_DATA6_BITS     = M_DATA6_WIDTH > 0 ? M_DATA6_WIDTH : 1,
            parameter M_DATA7_BITS     = M_DATA7_WIDTH > 0 ? M_DATA7_WIDTH : 1,
            parameter M_DATA8_BITS     = M_DATA8_WIDTH > 0 ? M_DATA8_WIDTH : 1,
            parameter M_DATA9_BITS     = M_DATA9_WIDTH > 0 ? M_DATA9_WIDTH : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire                        endian,
            
            input   wire    [UNIT0_BITS-1:0]    padding0,
            input   wire    [UNIT1_BITS-1:0]    padding1,
            input   wire    [UNIT2_BITS-1:0]    padding2,
            input   wire    [UNIT3_BITS-1:0]    padding3,
            input   wire    [UNIT4_BITS-1:0]    padding4,
            input   wire    [UNIT5_BITS-1:0]    padding5,
            input   wire    [UNIT6_BITS-1:0]    padding6,
            input   wire    [UNIT7_BITS-1:0]    padding7,
            input   wire    [UNIT8_BITS-1:0]    padding8,
            input   wire    [UNIT9_BITS-1:0]    padding9,
            
            input   wire                        s_first,
            input   wire                        s_last,
            input   wire    [S_DATA0_BITS-1:0]  s_data0,
            input   wire    [S_DATA1_BITS-1:0]  s_data1,
            input   wire    [S_DATA2_BITS-1:0]  s_data2,
            input   wire    [S_DATA3_BITS-1:0]  s_data3,
            input   wire    [S_DATA4_BITS-1:0]  s_data4,
            input   wire    [S_DATA5_BITS-1:0]  s_data5,
            input   wire    [S_DATA6_BITS-1:0]  s_data6,
            input   wire    [S_DATA7_BITS-1:0]  s_data7,
            input   wire    [S_DATA8_BITS-1:0]  s_data8,
            input   wire    [S_DATA9_BITS-1:0]  s_data9,
            input   wire                        s_valid,
            output  wire                        s_ready,
            
            output  wire                        m_first,
            output  wire                        m_last,
            output  wire    [M_DATA0_BITS-1:0]  m_data0,
            output  wire    [M_DATA1_BITS-1:0]  m_data1,
            output  wire    [M_DATA2_BITS-1:0]  m_data2,
            output  wire    [M_DATA3_BITS-1:0]  m_data3,
            output  wire    [M_DATA4_BITS-1:0]  m_data4,
            output  wire    [M_DATA5_BITS-1:0]  m_data5,
            output  wire    [M_DATA6_BITS-1:0]  m_data6,
            output  wire    [M_DATA7_BITS-1:0]  m_data7,
            output  wire    [M_DATA8_BITS-1:0]  m_data8,
            output  wire    [M_DATA9_BITS-1:0]  m_data9,
            output  wire                        m_valid,
            input   wire                        m_ready
        );
    
    // pack/unpack
    localparam PACK_UNIT    = UNIT0_WIDTH
                            + UNIT1_WIDTH
                            + UNIT2_WIDTH
                            + UNIT3_WIDTH
                            + UNIT4_WIDTH
                            + UNIT5_WIDTH
                            + UNIT6_WIDTH
                            + UNIT7_WIDTH
                            + UNIT8_WIDTH
                            + UNIT9_WIDTH;
    
    localparam S_PACK_WIDTH = S_NUM * PACK_UNIT;
    localparam M_PACK_WIDTH = M_NUM * PACK_UNIT;
    localparam S_PACK_BITS  = S_PACK_WIDTH > 0 ? S_PACK_WIDTH : 1;
    localparam M_PACK_BITS  = M_PACK_WIDTH > 0 ? M_PACK_WIDTH : 1;
    
    wire    [M_PACK_BITS-1:0]   m_pack;
    wire    [S_PACK_BITS-1:0]   s_pack;
    
    jelly_func_pack
            #(
                .N          (S_NUM / NUM_GCD),
                .W0         (UNIT0_WIDTH * NUM_GCD),
                .W1         (UNIT1_WIDTH * NUM_GCD),
                .W2         (UNIT2_WIDTH * NUM_GCD),
                .W3         (UNIT3_WIDTH * NUM_GCD),
                .W4         (UNIT4_WIDTH * NUM_GCD),
                .W5         (UNIT5_WIDTH * NUM_GCD),
                .W6         (UNIT6_WIDTH * NUM_GCD),
                .W7         (UNIT7_WIDTH * NUM_GCD),
                .W8         (UNIT8_WIDTH * NUM_GCD),
                .W9         (UNIT9_WIDTH * NUM_GCD)
            )
        i_func_pack
            (
                .in0        (s_data0),
                .in1        (s_data1),
                .in2        (s_data2),
                .in3        (s_data3),
                .in4        (s_data4),
                .in5        (s_data5),
                .in6        (s_data6),
                .in7        (s_data7),
                .in8        (s_data8),
                .in9        (s_data9),
                .out        (s_pack)
            );
    
    jelly_func_unpack
            #(
                .N          (M_NUM / NUM_GCD),
                .W0         (UNIT0_WIDTH * NUM_GCD),
                .W1         (UNIT1_WIDTH * NUM_GCD),
                .W2         (UNIT2_WIDTH * NUM_GCD),
                .W3         (UNIT3_WIDTH * NUM_GCD),
                .W4         (UNIT4_WIDTH * NUM_GCD),
                .W5         (UNIT5_WIDTH * NUM_GCD),
                .W6         (UNIT6_WIDTH * NUM_GCD),
                .W7         (UNIT7_WIDTH * NUM_GCD),
                .W8         (UNIT8_WIDTH * NUM_GCD),
                .W9         (UNIT9_WIDTH * NUM_GCD)
            )
        i_func_unpack
            (
                .in         (m_pack),
                .out0       (m_data0),
                .out1       (m_data1),
                .out2       (m_data2),
                .out3       (m_data3),
                .out4       (m_data4),
                .out5       (m_data5),
                .out6       (m_data6),
                .out7       (m_data7),
                .out8       (m_data8),
                .out9       (m_data9)
            );
    
    
    
    // padding
    localparam  PADDING0_WIDTH = UNIT0_WIDTH * M_NUM;
    localparam  PADDING1_WIDTH = UNIT1_WIDTH * M_NUM;
    localparam  PADDING2_WIDTH = UNIT2_WIDTH * M_NUM;
    localparam  PADDING3_WIDTH = UNIT3_WIDTH * M_NUM;
    localparam  PADDING4_WIDTH = UNIT4_WIDTH * M_NUM;
    localparam  PADDING5_WIDTH = UNIT5_WIDTH * M_NUM;
    localparam  PADDING6_WIDTH = UNIT6_WIDTH * M_NUM;
    localparam  PADDING7_WIDTH = UNIT7_WIDTH * M_NUM;
    localparam  PADDING8_WIDTH = UNIT8_WIDTH * M_NUM;
    localparam  PADDING9_WIDTH = UNIT9_WIDTH * M_NUM;
    localparam  PADDING0_BITS  = PADDING0_WIDTH > 0 ? PADDING0_WIDTH : 1;
    localparam  PADDING1_BITS  = PADDING1_WIDTH > 0 ? PADDING1_WIDTH : 1;
    localparam  PADDING2_BITS  = PADDING2_WIDTH > 0 ? PADDING2_WIDTH : 1;
    localparam  PADDING3_BITS  = PADDING3_WIDTH > 0 ? PADDING3_WIDTH : 1;
    localparam  PADDING4_BITS  = PADDING4_WIDTH > 0 ? PADDING4_WIDTH : 1;
    localparam  PADDING5_BITS  = PADDING5_WIDTH > 0 ? PADDING5_WIDTH : 1;
    localparam  PADDING6_BITS  = PADDING6_WIDTH > 0 ? PADDING6_WIDTH : 1;
    localparam  PADDING7_BITS  = PADDING7_WIDTH > 0 ? PADDING7_WIDTH : 1;
    localparam  PADDING8_BITS  = PADDING8_WIDTH > 0 ? PADDING8_WIDTH : 1;
    localparam  PADDING9_BITS  = PADDING9_WIDTH > 0 ? PADDING9_WIDTH : 1;
    
    wire    [PADDING0_BITS-1:0]     padding_data0 = {M_NUM{padding0}};
    wire    [PADDING1_BITS-1:0]     padding_data1 = {M_NUM{padding1}};
    wire    [PADDING2_BITS-1:0]     padding_data2 = {M_NUM{padding2}};
    wire    [PADDING3_BITS-1:0]     padding_data3 = {M_NUM{padding3}};
    wire    [PADDING4_BITS-1:0]     padding_data4 = {M_NUM{padding4}};
    wire    [PADDING5_BITS-1:0]     padding_data5 = {M_NUM{padding5}};
    wire    [PADDING6_BITS-1:0]     padding_data6 = {M_NUM{padding6}};
    wire    [PADDING7_BITS-1:0]     padding_data7 = {M_NUM{padding7}};
    wire    [PADDING8_BITS-1:0]     padding_data8 = {M_NUM{padding8}};
    wire    [PADDING9_BITS-1:0]     padding_data9 = {M_NUM{padding9}};
    wire    [M_PACK_BITS-1:0]       padding_pack;
    jelly_func_pack
            #(
                .N          (M_NUM / NUM_GCD),
                .W0         (UNIT0_WIDTH * NUM_GCD),
                .W1         (UNIT1_WIDTH * NUM_GCD),
                .W2         (UNIT2_WIDTH * NUM_GCD),
                .W3         (UNIT3_WIDTH * NUM_GCD),
                .W4         (UNIT4_WIDTH * NUM_GCD),
                .W5         (UNIT5_WIDTH * NUM_GCD),
                .W6         (UNIT6_WIDTH * NUM_GCD),
                .W7         (UNIT7_WIDTH * NUM_GCD),
                .W8         (UNIT8_WIDTH * NUM_GCD),
                .W9         (UNIT9_WIDTH * NUM_GCD)
            )
        i_func_pack_padding
            (
                .in0        (padding_data0),
                .in1        (padding_data1),
                .in2        (padding_data2),
                .in3        (padding_data3),
                .in4        (padding_data4),
                .in5        (padding_data5),
                .in6        (padding_data6),
                .in7        (padding_data7),
                .in8        (padding_data8),
                .in9        (padding_data9),
                .out        (padding_pack)
            );
    
    
    // packing
    jelly_data_packing
            #(
                .UNIT_WIDTH         (PACK_UNIT * NUM_GCD),
                .S_NUM              (S_NUM / NUM_GCD),
                .M_NUM              (M_NUM / NUM_GCD),
                .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                .FIRST_OVERWRITE    (FIRST_OVERWRITE),
                .S_REGS             (S_REGS)
            )
        i_data_packing
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .endian             (endian),
                .padding_data       (padding_pack),
                
                .s_first            (s_first),
                .s_last             (s_last),
                .s_data             (s_pack),
                .s_valid            (s_valid),
                .s_ready            (s_ready),
                
                .m_first            (m_first),
                .m_last             (m_last),
                .m_data             (m_pack),
                .m_valid            (m_valid),
                .m_ready            (m_ready)
            );
    
    
endmodule


`default_nettype wire


// end of file
