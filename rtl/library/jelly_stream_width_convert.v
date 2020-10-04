// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_stream_width_convert
        #(
            parameter UNIT_WIDTH          = 32,
            parameter S_NUM               = 1,
            parameter M_NUM               = 2,
            parameter HAS_FIRST           = 0,                          // first を備える
            parameter HAS_LAST            = 0,                          // last を備える
            parameter AUTO_FIRST          = (HAS_LAST & !HAS_FIRST),    // last の次を自動的に first とする
            parameter HAS_ALIGN_S         = 0,                          // slave 側のアライメントを指定する
            parameter HAS_ALIGN_M         = 0,                          // master 側のアライメントを指定する
            parameter FIRST_OVERWRITE     = 0,  // first時前方に残変換があれば吐き出さずに上書き
            parameter FIRST_FORCE_LAST    = 0,  // first時前方に残変換があれば強制的にlastを付与(残が無い場合はlastはつかない)
            parameter ALIGN_S_WIDTH       = S_NUM <=   2 ? 1 :
                                            S_NUM <=   4 ? 2 :
                                            S_NUM <=   8 ? 3 :
                                            S_NUM <=  16 ? 4 :
                                            S_NUM <=  32 ? 5 :
                                            S_NUM <=  64 ? 6 :
                                            S_NUM <= 128 ? 7 :
                                            S_NUM <= 256 ? 8 :
                                            S_NUM <= 512 ? 9 : 10,
            parameter ALIGN_M_WIDTH       = M_NUM <=   2 ? 1 :
                                            M_NUM <=   4 ? 2 :
                                            M_NUM <=   8 ? 3 :
                                            M_NUM <=  16 ? 4 :
                                            M_NUM <=  32 ? 5 :
                                            M_NUM <=  64 ? 6 :
                                            M_NUM <= 128 ? 7 :
                                            M_NUM <= 256 ? 8 :
                                            M_NUM <= 512 ? 9 : 10,
            parameter USER_F_WIDTH        = 0,
            parameter USER_L_WIDTH        = 0,
            parameter S_REGS              = 0, // (S_NUM != M_NUM),
            
            // local
            parameter S_DATA_WIDTH        = S_NUM*UNIT_WIDTH,
            parameter M_DATA_WIDTH        = M_NUM*UNIT_WIDTH,
            parameter USER_F_BITS         = USER_F_WIDTH > 0 ? USER_F_WIDTH : 1,
            parameter USER_L_BITS         = USER_L_WIDTH > 0 ? USER_L_WIDTH : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire                        endian,
            input   wire    [UNIT_WIDTH-1:0]    padding,
            
            input   wire    [ALIGN_S_WIDTH-1:0] s_align_s,
            input   wire    [ALIGN_M_WIDTH-1:0] s_align_m,
            input   wire                        s_first,        // アライメント先頭
            input   wire                        s_last,         // アライメント末尾
            input   wire    [S_DATA_WIDTH-1:0]  s_data,
            input   wire    [USER_F_BITS-1:0]   s_user_f,       // アライメント先頭前提で伝搬するユーザーデータ
            input   wire    [USER_L_BITS-1:0]   s_user_l,       // アライメント末尾前提で伝搬するユーザーデータ
            input   wire                        s_valid,
            output  wire                        s_ready,
            
            output  wire                        m_first,
            output  wire                        m_last,
            output  wire    [M_DATA_WIDTH-1:0]  m_data,
            output  wire    [USER_F_BITS-1:0]   m_user_f,
            output  wire    [USER_L_BITS-1:0]   m_user_l,
            output  wire                        m_valid,
            input   wire                        m_ready
        );
    
    
    // -----------------------------------------
    //  localparam
    // -----------------------------------------
    
    localparam  BUF_NUM     = S_NUM + M_NUM - 1;
    localparam  BUF_WIDTH   = BUF_NUM * UNIT_WIDTH;
    localparam  COUNT_WIDTH = BUF_NUM <     2 ?  1 :
                              BUF_NUM <     4 ?  2 :
                              BUF_NUM <     8 ?  3 :
                              BUF_NUM <    16 ?  4 :
                              BUF_NUM <    32 ?  5 :
                              BUF_NUM <    64 ?  6 :
                              BUF_NUM <   128 ?  7 :
                              BUF_NUM <   256 ?  8 :
                              BUF_NUM <   512 ?  9 :
                              BUF_NUM <  1024 ? 10 :
                              BUF_NUM <  2048 ? 11 :
                              BUF_NUM <  4096 ? 12 :
                              BUF_NUM <  8192 ? 13 :
                              BUF_NUM < 16384 ? 14 :
                              BUF_NUM < 32768 ? 15 : 16;
    
    
    // -----------------------------------------
    //  slave align
    // -----------------------------------------
    
    // auto first flag
    reg     reg_auto_first;
    always @(posedge clk ) begin
        if ( reset ) begin
            reg_auto_first <= 1'b1;
        end
        else if ( cke ) begin
            if ( s_valid && s_ready ) begin
                reg_auto_first <= s_last;
            end
        end
    end
    wire    auto_first = (AUTO_FIRST && reg_auto_first);
    
    
    // align
    reg     [S_DATA_WIDTH-1:0]  s_data_align;
    always @* begin
        s_data_align = s_data;
        if ( HAS_ALIGN_S && (s_first || auto_first) ) begin
            if ( endian ) begin
                s_data_align = s_data << (s_align_s * UNIT_WIDTH);
            end
            else begin
                s_data_align = s_data >> (s_align_s * UNIT_WIDTH);
            end
        end
    end
    
    
    
    
    // -----------------------------------------
    //  insert FF
    // -----------------------------------------
    
    wire    [ALIGN_S_WIDTH-1:0]     ff_s_align_s;
    wire    [ALIGN_M_WIDTH-1:0]     ff_s_align_m;
    wire                            ff_s_first;
    wire                            ff_s_last;
    wire    [S_DATA_WIDTH-1:0]      ff_s_data;
    wire                            ff_s_valid;
    wire    [USER_F_BITS-1:0]       ff_s_user_f;
    wire    [USER_L_BITS-1:0]       ff_s_user_l;
    wire                            ff_s_ready;
    
    jelly_data_ff_pack
            #(
                .DATA0_WIDTH    (1),
                .DATA1_WIDTH    (1),
                .DATA2_WIDTH    (S_DATA_WIDTH),
                .DATA3_WIDTH    (USER_F_WIDTH),
                .DATA4_WIDTH    (USER_L_WIDTH),
                .DATA5_WIDTH    (ALIGN_S_WIDTH),
                .DATA6_WIDTH    (ALIGN_M_WIDTH),
                .S_REGS         (S_REGS),
                .M_REGS         (HAS_ALIGN_S)
            )
        i_data_ff_pack_s
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data0        ((HAS_LAST  ? s_last  : 1'b0)),
                .s_data1        ((HAS_FIRST ? s_first : 1'b0) | auto_first),
                .s_data2        (s_data_align),
                .s_data3        (s_user_f),
                .s_data4        (s_user_l),
                .s_data5        (s_align_s),
                .s_data6        (s_align_m),
                .s_valid        (s_valid),
                .s_ready        (s_ready),
                
                .m_data0        (ff_s_last),
                .m_data1        (ff_s_first),
                .m_data2        (ff_s_data),
                .m_data3        (ff_s_user_f),
                .m_data4        (ff_s_user_l),
                .m_data5        (ff_s_align_s),
                .m_data6        (ff_s_align_m),
                .m_valid        (ff_s_valid),
                .m_ready        (ff_s_ready)
            );
    
    
    // -----------------------------------------
    //  convert
    // -----------------------------------------
    
    generate
    if ( S_DATA_WIDTH != M_DATA_WIDTH || HAS_ALIGN_S || HAS_ALIGN_M ) begin : blk_packing
        integer                     i;
        
        wire    [M_DATA_WIDTH-1:0]  padding_data = {M_NUM{padding}};
        
        reg     [COUNT_WIDTH-1:0]   reg_count, next_count;
        reg     [BUF_WIDTH-1:0]     reg_buf,   next_buf;
        reg                         reg_final, next_final;
        reg                         reg_lflag, next_lflag;
        
        reg                         sig_ready;
        
        reg                         reg_first, next_first;
        reg                         reg_last,  next_last;
        reg     [M_DATA_WIDTH-1:0]  sig_data;
        
        reg    [USER_F_BITS-1:0]    reg_user_f, next_user_f;
        reg    [USER_L_BITS-1:0]    reg_user_l, next_user_l;
        
        reg                         reg_valid, next_valid;
        
        always @(posedge clk) begin
            if ( reset ) begin
                reg_count  <= 0;
                reg_buf    <= {BUF_WIDTH{1'bx}};
                reg_final  <= 1'b0;
                reg_lflag  <= 1'b0;
                reg_first  <= 1'b0;
                reg_last   <= 1'b0;
                reg_user_f <= {USER_F_BITS{1'bx}};
                reg_user_l <= {USER_L_BITS{1'bx}};
                reg_valid  <= 1'b0;
            end
            else if ( cke ) begin
                reg_count  <= next_count;
                reg_buf    <= next_buf;
                reg_final  <= next_final;
                reg_lflag  <= next_lflag;
                reg_first  <= next_first;
                reg_last   <= next_last;
                reg_user_f <= next_user_f;
                reg_user_l <= next_user_l;
                reg_valid  <= next_valid;
            end
        end
        
        always @* begin
            next_count  = reg_count;
            next_buf    = reg_buf;
            next_final  = reg_final;
            next_lflag  = reg_lflag;
            next_first  = reg_first;
            next_last   = reg_last;
            next_user_f = reg_user_f;
            next_user_l = reg_user_l;
            next_valid  = reg_valid;
            
            // 出力完了処理
            if ( m_ready ) begin
                next_valid = 1'b0;
                
                if ( m_valid  ) begin
                    // 出力実施の場合
                    next_first = 1'b0;
                    if ( reg_last ) begin
                        // 最後なら初期化
                        next_final = 1'b0;
                        next_lflag = 1'b0;
                        next_buf   = {BUF_WIDTH{1'bx}};
                        next_count = 0;
                    end
                    else begin
                        // データシフト
                        if ( endian ) begin
                            next_buf = {next_buf, {M_DATA_WIDTH{1'bx}}};                    // big endian
                        end
                        else begin
                            next_buf = {{M_DATA_WIDTH{1'bx}}, next_buf} >> M_DATA_WIDTH;    // little endian
                        end
                        next_count = next_count - M_NUM;
                    end
                end
            end
            
            
            // 入力データ受付可否
            if ( FIRST_OVERWRITE ) begin
                // last なしで first が来た時は残があっても受け入れ(上書き)
                sig_ready = (!next_final && (BUF_NUM - next_count >= S_NUM) || ((!m_valid || m_ready) && ff_s_valid && ff_s_first));
            end
            else begin
                // last なしで first が来た時は残があれば吐き出し待ち
                if ( HAS_FIRST && ff_s_valid && ff_s_first && next_count > 0 ) begin
                    next_final = 1'b1;
                    if ( FIRST_FORCE_LAST ) begin
                        next_lflag = 1'b1;
                    end
                end
                sig_ready = (!next_final && (BUF_NUM - next_count >= S_NUM));
            end
            
            // 入力受付
            if ( ff_s_valid && sig_ready ) begin
                if ( ff_s_first ) begin
                    // 初期化
                    next_first = 1'b1;
                    next_count = HAS_ALIGN_M ? ff_s_align_m : 0;
                    next_buf   = {M_NUM{padding}};
                end
                if ( HAS_LAST && ff_s_last ) begin
                    next_final = 1'b1;
                    next_lflag = 1'b1;
                end
                
                // user データ
                if ( next_count == 0 ) begin
                    next_user_f = ff_s_user_f;  // 先頭に詰め込むときだけ更新
                end
                next_user_l = ff_s_user_l;      // user_l は常に最後(最新)のものを出しておけばOK
                
                // データ格納
                if ( endian ) begin
                    next_buf[(BUF_WIDTH-1) - (next_count*UNIT_WIDTH) -: S_DATA_WIDTH] = ff_s_data;  // big endian
                end
                else begin
                    next_buf[next_count*UNIT_WIDTH +: S_DATA_WIDTH] = ff_s_data;                    // little endian
                end
                next_count = next_count + S_NUM;
                
                // s_align
                if ( ff_s_first && HAS_ALIGN_S ) begin
                    next_count = next_count - ff_s_align_s;
                end
            end
            
            
            // 残部分をパディング
            for ( i = 0; i < M_DATA_WIDTH; i = i+1 ) begin
                if ( i >= next_count*UNIT_WIDTH ) begin
                    if ( endian ) begin
                        next_buf[BUF_WIDTH-1 - i] = padding_data[M_DATA_WIDTH-1 - i];
                    end
                    else begin
                        next_buf[i] = padding_data[i];
                    end
                end
            end
            
            // 出力判定
            if ( next_count >= M_NUM || next_final ) begin
                next_last  = (next_count <= M_NUM) && next_final;
                next_valid = 1'b1;
            end
        end
        
        assign ff_s_ready = sig_ready;
        assign m_first    = reg_first;
        assign m_last     = reg_last & reg_lflag;
        assign m_data     = endian ? reg_buf[BUF_WIDTH-1 -: M_DATA_WIDTH] : reg_buf[0 +: M_DATA_WIDTH];
        assign m_user_f   = reg_user_f;
        assign m_user_l   = reg_user_l;
        assign m_valid    = reg_valid;
    end
    else begin : blk_bypass
        assign ff_s_ready = m_ready;
        assign m_first    = ff_s_first || auto_first;
        assign m_last     = ff_s_last;
        assign m_data     = ff_s_data;
        assign m_user_f   = ff_s_user_f;
        assign m_user_l   = ff_s_user_l;
        assign m_valid    = ff_s_valid;
    end
    endgenerate
    
    
endmodule


`default_nettype wire


// end of file
