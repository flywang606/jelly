// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module video_mnist_color
		#(
			parameter	RAW_WIDTH       = 10,
			parameter	DATA_WIDTH      = 8,
			parameter	TUSER_WIDTH     = 1,
			parameter	TNUMBER_WIDTH   = 4,
			parameter	TCOUNT_WIDTH    = 4,
		
			parameter	WB_ADR_WIDTH    = 8,
			parameter	WB_DAT_WIDTH    = 32,
			parameter	WB_SEL_WIDTH    = (WB_DAT_WIDTH / 8),
			parameter	INIT_PARAM_MODE = 2'b11,
			parameter	INIT_PARAM_TH   = 5,
			parameter	INIT_PARAM_SEL  = 0
		)
		(
			input	wire							aresetn,
			input	wire							aclk,
			
			input	wire	[TUSER_WIDTH-1:0]		s_axi4s_tuser,
			input	wire							s_axi4s_tlast,
			input	wire	[TNUMBER_WIDTH-1:0]		s_axi4s_tnumber,
			input	wire	[TCOUNT_WIDTH-1:0]		s_axi4s_tcount,
			input	wire	[RAW_WIDTH-1:0]			s_axi4s_traw,
			input	wire	[DATA_WIDTH-1:0]		s_axi4s_tgray,
			input	wire	[3*DATA_WIDTH-1:0]		s_axi4s_trgb,
			input	wire	[0:0]					s_axi4s_tbinary,
			input	wire	[0:0]					s_axi4s_tvalidation,
			input	wire							s_axi4s_tvalid,
			output	wire							s_axi4s_tready,
			
			output	wire	[TUSER_WIDTH-1:0]		m_axi4s_tuser,
			output	wire							m_axi4s_tlast,
			output	wire	[3*DATA_WIDTH-1:0]		m_axi4s_tdata,
			output	wire							m_axi4s_tvalid,
			input	wire							m_axi4s_tready,
			
			input	wire							s_wb_rst_i,
			input	wire							s_wb_clk_i,
			input	wire	[WB_ADR_WIDTH-1:0]		s_wb_adr_i,
			input	wire	[WB_DAT_WIDTH-1:0]		s_wb_dat_i,
			output	wire	[WB_DAT_WIDTH-1:0]		s_wb_dat_o,
			input	wire							s_wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]		s_wb_sel_i,
			input	wire							s_wb_stb_i,
			output	wire							s_wb_ack_o
		);
	
	
	reg		[1:0]					reg_param_mode;
	reg		[TCOUNT_WIDTH-1:0]		reg_param_th;
	reg		[3:0]					reg_param_sel;
	always @(posedge s_wb_clk_i) begin
		if ( s_wb_rst_i ) begin
			reg_param_mode <= INIT_PARAM_MODE;
			reg_param_th   <= INIT_PARAM_TH;
		end
		else begin
			if ( s_wb_stb_i && s_wb_we_i ) begin
				case ( s_wb_adr_i )
				0:	reg_param_mode <= s_wb_dat_i;
				1:	reg_param_th   <= s_wb_dat_i;
				2:	reg_param_sel  <= s_wb_dat_i;
				endcase
			end
		end
	end
	
	assign s_wb_dat_o = (s_wb_adr_i == 0) ? reg_param_mode :
	                    (s_wb_adr_i == 1) ? reg_param_th   :
	                    (s_wb_adr_i == 2) ? reg_param_sel  :
	                    0;
	assign s_wb_ack_o = s_wb_stb_i;
	
	
	(* ASYNC_REG="true" *)	reg			[1:0]				ff0_param_mode, ff1_param_mode;
	(* ASYNC_REG="true" *)	reg			[TCOUNT_WIDTH-1:0]	ff0_param_th,   ff1_param_th;
	(* ASYNC_REG="true" *)	reg			[3:0]				ff0_param_sel,  ff1_param_sel;
	always @(posedge aclk) begin
		ff0_param_mode <= reg_param_mode;
		ff1_param_mode <= ff0_param_mode;
		
		ff0_param_th   <= reg_param_th;
		ff1_param_th   <= ff0_param_th;
		
		ff0_param_sel  <= reg_param_sel;
		ff1_param_sel  <= ff0_param_sel;
	end
	
	
	video_mnist_color_core
			#(
				.RAW_WIDTH			(RAW_WIDTH),
				.DATA_WIDTH			(DATA_WIDTH),
				.TUSER_WIDTH		(TUSER_WIDTH),
				.TNUMBER_WIDTH		(TNUMBER_WIDTH),
				.TCOUNT_WIDTH		(TCOUNT_WIDTH)
			)
		i_video_mnist_color_core
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				
				.param_mode			(ff1_param_mode),
				.param_th			(ff1_param_th),
				.param_sel			(ff1_param_sel),
				
				.s_axi4s_tuser		(s_axi4s_tuser),
				.s_axi4s_tlast		(s_axi4s_tlast),
				.s_axi4s_tnumber	(s_axi4s_tnumber),
				.s_axi4s_tcount		(s_axi4s_tcount),
				.s_axi4s_traw		(s_axi4s_traw),
				.s_axi4s_tgray		(s_axi4s_tgray),
				.s_axi4s_trgb		(s_axi4s_trgb),
				.s_axi4s_tbinary	(s_axi4s_tbinary),
				.s_axi4s_tvalidation(s_axi4s_tvalidation),
				.s_axi4s_tvalid		(s_axi4s_tvalid),
				.s_axi4s_tready		(s_axi4s_tready),
				
				.m_axi4s_tuser		(m_axi4s_tuser),
				.m_axi4s_tlast		(m_axi4s_tlast),
				.m_axi4s_tdata		(m_axi4s_tdata),
				.m_axi4s_tvalid		(m_axi4s_tvalid),
				.m_axi4s_tready		(m_axi4s_tready)
			);
	
	
endmodule



`default_nettype wire



// end of file
