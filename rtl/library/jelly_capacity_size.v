// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// 発行コマンドサイズ管理
module jelly_capacity_size
        #(
            parameter   CAPACITY_WIDTH     = 32,
            parameter   CMD_USER_WIDTH     = 0,
            parameter   CMD_SIZE_WIDTH     = 8,
            parameter   CMD_SIZE_OFFSET    = 1'b0,
            parameter   CHARGE_WIDTH       = CAPACITY_WIDTH,
            parameter   CHARGE_SIZE_OFFSET = 1'b0,
            parameter   S_REGS             = 1,
            parameter   M_REGS             = 1,
            
            // local
            parameter   CMD_USER_BITS      = CMD_USER_WIDTH > 0 ? CMD_USER_WIDTH : 1
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,
            
            input   wire    [CAPACITY_WIDTH-1:0]    initial_capacity,
            output  wire    [CAPACITY_WIDTH-1:0]    current_capacity,
            
            input   wire    [CHARGE_WIDTH-1:0]      s_charge_size,
            input   wire                            s_charge_valid,
            
            input   wire    [CMD_USER_BITS-1:0]     s_cmd_user,
            input   wire    [CMD_SIZE_WIDTH-1:0]    s_cmd_size,
            input   wire                            s_cmd_valid,
            output  wire                            s_cmd_ready,
            
            output  wire    [CMD_USER_BITS-1:0]     m_cmd_user,
            output  wire    [CMD_SIZE_WIDTH-1:0]    m_cmd_size,
            output  wire                            m_cmd_valid,
            input   wire                            m_cmd_ready
        );
    
    // insert FF
    wire    [CMD_USER_BITS-1:0]     ff_s_user;
    wire    [CMD_SIZE_WIDTH-1:0]    ff_s_size;
    wire                            ff_s_valid;
    wire                            ff_s_ready;
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH         (CMD_USER_BITS + CMD_SIZE_WIDTH ),
                .SLAVE_REGS         (S_REGS),
                .MASTER_REGS        (S_REGS)
            )
        i_pipeline_insert_ff_s
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data             ({s_cmd_user, s_cmd_size}),
                .s_valid            (s_cmd_valid),
                .s_ready            (s_cmd_ready),
                
                .m_data             ({ff_s_user, ff_s_size}),
                .m_valid            (ff_s_valid),
                .m_ready            (ff_s_ready),
                
                .buffered           (),
                .s_ready_next       ()
            );
    
    // recieve request
    wire    [CMD_USER_BITS-1:0]     rx_user;
    wire    [CMD_SIZE_WIDTH-1:0]    rx_size;
    wire    [CAPACITY_WIDTH-1:0]    rx_issue;
    wire                            rx_valid;
    wire                            rx_ready;
    generate
    if ( S_REGS ) begin : rx_reg
        reg     [CMD_USER_BITS-1:0]     reg_rx_user;
        reg     [CMD_SIZE_WIDTH-1:0]    reg_rx_size;
        reg     [CAPACITY_WIDTH-1:0]    reg_rx_issue;
        reg                             reg_rx_valid;
        always @(posedge clk) begin
            if ( reset ) begin
                reg_rx_user  <= {CMD_USER_BITS{1'bx}};
                reg_rx_size  <= {CMD_SIZE_WIDTH{1'bx}};
                reg_rx_issue <= {CAPACITY_WIDTH{1'b0}};
                reg_rx_valid <= 1'b0;
            end
            else if ( cke && ff_s_ready ) begin
                reg_rx_user  <= ff_s_user;
                reg_rx_size  <= ff_s_size;
                reg_rx_issue <= ff_s_valid ? ({1'b0, ff_s_size} + CMD_SIZE_OFFSET) : 0;
                reg_rx_valid <= ff_s_valid;
            end
        end
        assign ff_s_ready = (!rx_valid || rx_ready);
        assign rx_user    = reg_rx_user;
        assign rx_size    = reg_rx_size;
        assign rx_issue   = rx_ready ? reg_rx_issue : 0;
        assign rx_valid   = reg_rx_valid;
    end
    else begin : rx_bypass
        assign ff_s_ready = rx_ready;
        assign rx_user    = ff_s_user;
        assign rx_size    = ff_s_size;
        assign rx_issue   = (ff_s_valid & ff_s_ready) ? ({1'b0, ff_s_size} + CMD_SIZE_OFFSET) : 0;
        assign rx_valid   = ff_s_valid;
    end
    endgenerate
    
    
    // capacity control
    reg     [CAPACITY_WIDTH-1:0]    reg_charge;
    wire    [CAPACITY_WIDTH-1:0]    issue_size;
    wire                            issue_valid;
    
    reg     [CAPACITY_WIDTH-1:0]    reg_capacity;
    reg     [CAPACITY_WIDTH-1:0]    reg_capacity_sub;
    reg                             reg_select_sub;
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_charge       <= initial_capacity;
            
            reg_capacity     <= {CAPACITY_WIDTH{1'b0}};
            reg_capacity_sub <= {CAPACITY_WIDTH{1'bx}};
            reg_select_sub   <= 1'b0;
        end
        else begin
            reg_charge       <= s_charge_valid ? ({1'b0, s_charge_size} + CHARGE_SIZE_OFFSET) : 0;
            
            reg_capacity     <= current_capacity + reg_charge;
            reg_capacity_sub <= current_capacity + reg_charge - issue_size;
            reg_select_sub   <= issue_valid;
        end
    end
    
    assign current_capacity = reg_select_sub ? reg_capacity_sub : reg_capacity;
    assign issue_valid      = (current_capacity >= issue_size);
    
    
    // transmit command
    wire    [CMD_USER_BITS-1:0]     tx_user;
    wire    [CMD_SIZE_WIDTH-1:0]    tx_size;
    wire                            tx_valid;
    wire                            tx_ready;
    
    assign issue_size  = rx_issue;
    assign rx_ready    = tx_ready && issue_valid;
    
    assign tx_user     = rx_user;
    assign tx_size     = rx_size;
    assign tx_valid    = rx_valid;
    
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH         (CMD_USER_BITS + CMD_SIZE_WIDTH),
                .SLAVE_REGS         (M_REGS),
                .MASTER_REGS        (M_REGS)
            )
        i_pipeline_insert_ff_m
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data             ({tx_user, tx_size}),
                .s_valid            (tx_valid),
                .s_ready            (tx_ready),
                
                .m_data             ({m_cmd_user, m_cmd_size}),
                .m_valid            (m_cmd_valid),
                .m_ready            (m_cmd_ready),
                
                .buffered           (),
                .s_ready_next       ()
            );
    
    
endmodule


`default_nettype wire


// end of file
