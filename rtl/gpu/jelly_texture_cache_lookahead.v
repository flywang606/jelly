// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_lookahead
		#(
			parameter	COMPONENT_NUM        = 1,
			parameter	COMPONENT_DATA_WIDTH = 24,
			
			parameter	PARALLEL_SIZE        = 0,
			parameter	ADDR_X_WIDTH         = 12,
			parameter	ADDR_Y_WIDTH         = 12,
			parameter	BLK_X_SIZE           = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	BLK_Y_SIZE           = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	TAG_ADDR_WIDTH       = 6,
			parameter	TAG_RAM_TYPE         = "distributed",
			parameter	MEM_RAM_TYPE         = "block",
			
			parameter	USE_S_RREADY         = 1,	// 0: s_rready is always 1'b1.   1: handshake mode.
			parameter	USE_M_RREADY         = 0,	// 0: m_rready is always 1'b1.   1: handshake mode.
			
			parameter	S_USER_WIDTH         = 1,
			parameter	S_DATA_SIZE          = 0,
			parameter	S_BLK_X_NUM          = 1,
			parameter	S_BLK_Y_NUM          = 1,
			
			parameter	M_DATA_SIZE          = 1,
			parameter	M_INORDER            = 1,
			parameter	M_INORDER_DATA_FIRST = 0,
			
			parameter	USE_BORDER           = 1,
			parameter	BORDER_DATA          = {S_DATA_WIDTH{1'b0}},
			
			parameter	QUE_FIFO_PTR_WIDTH   = BLK_Y_SIZE + BLK_X_SIZE,
			parameter	QUE_FIFO_RAM_TYPE    = "distributed",
			
			parameter	AR_FIFO_PTR_WIDTH    = 0,
			parameter	AR_FIFO_RAM_TYPE     = "distributed",
			
			parameter	R_FIFO_PTR_WIDTH     = 1 + BLK_Y_SIZE + BLK_X_SIZE - M_DATA_SIZE,
			parameter	R_FIFO_RAM_TYPE      = "distributed",
			
			parameter	LOG_ENABLE           = 0,
			parameter	LOG_FILE             = "cache_log.txt",
			parameter	LOG_ID               = 0
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							endian,
			
			input	wire							clear_start,
			output	wire							clear_busy,
			
			input	wire	[ADDR_X_WIDTH-1:0]		param_width,
			input	wire	[ADDR_Y_WIDTH-1:0]		param_height,
			
			output	wire							status_idle,
			output	wire							status_stall,
			output	wire							status_access,
			output	wire							status_hit,
			output	wire							status_miss,
			output	wire							status_range_out,
			
			input	wire	[S_USER_WIDTH-1:0]		s_aruser,
			input	wire	[ADDR_X_WIDTH-1:0]		s_araddrx,
			input	wire	[ADDR_Y_WIDTH-1:0]		s_araddry,
			input	wire							s_arvalid,
			output	wire							s_arready,
			output	wire	[S_USER_WIDTH-1:0]		s_ruser,
			output	wire							s_rlast,
			output	wire	[S_DATA_WIDTH-1:0]		s_rdata,
			output	wire							s_rvalid,
			input	wire							s_rready,
			
			
			output	wire	[ADDR_X_WIDTH-1:0]		m_araddrx,
			output	wire	[ADDR_Y_WIDTH-1:0]		m_araddry,
			output	wire							m_arvalid,
			input	wire							m_arready,
			input	wire							m_rlast,
			input	wire	[M_STRB_WIDTH-1:0]		m_rstrb,
			input	wire	[M_DATA_WIDTH-1:0]		m_rdata,
			input	wire							m_rvalid,
			output	wire							m_rready
		);
	
	genvar	i;
	
	// ---------------------------------
	//  localparam
	// ---------------------------------

	localparam	S_DATA_WIDTH         = ((COMPONENT_NUM * COMPONENT_DATA_WIDTH) << S_DATA_SIZE);
	localparam	M_DATA_WIDTH         = ((COMPONENT_NUM * COMPONENT_DATA_WIDTH) << M_DATA_SIZE);
	localparam	M_STRB_WIDTH         = COMPONENT_NUM;
	
//	localparam	M_DATA_X_WIDE_SIZE   = M_DATA_WIDE_SIZE > BLK_X_SIZE         ? BLK_X_SIZE : M_DATA_WIDE_SIZE;
//	localparam	M_DATA_Y_WIDE_SIZE   = M_DATA_WIDE_SIZE > M_DATA_X_WIDE_SIZE ? M_DATA_WIDE_SIZE - M_DATA_X_WIDE_SIZE : 0;
	
	localparam	PIX_ADDR_X_WIDTH     = BLK_X_SIZE;
	localparam	PIX_ADDR_Y_WIDTH     = BLK_Y_SIZE;
	localparam	BLK_ADDR_X_WIDTH     = ADDR_X_WIDTH - BLK_X_SIZE;
	localparam	BLK_ADDR_Y_WIDTH     = ADDR_Y_WIDTH - BLK_Y_SIZE;
	
	
	// ---------------------------------
	//  TAG-RAM access
	// ---------------------------------
	
	wire		[S_USER_WIDTH-1:0]		tag_user;
	wire		[TAG_ADDR_WIDTH-1:0]	tag_tag_addr;
	wire		[PIX_ADDR_X_WIDTH-1:0]	tag_pix_addrx;
	wire		[PIX_ADDR_Y_WIDTH-1:0]	tag_pix_addry;
	wire		[BLK_ADDR_X_WIDTH-1:0]	tag_blk_addrx;
	wire		[BLK_ADDR_Y_WIDTH-1:0]	tag_blk_addry;
	wire								tag_range_out;
	wire								tag_cache_hit;
	wire								tag_valid;
	wire								tag_ready;
	
	jelly_texture_cache_tag
			#(
				.USER_WIDTH				(S_USER_WIDTH),
				
				.ADDR_X_WIDTH			(ADDR_X_WIDTH),
				.ADDR_Y_WIDTH			(ADDR_Y_WIDTH),
				
				.PARALLEL_SIZE			(PARALLEL_SIZE),
				.TAG_ADDR_WIDTH			(TAG_ADDR_WIDTH),
				.BLK_X_SIZE				(BLK_X_SIZE),
				.BLK_Y_SIZE				(BLK_Y_SIZE),
				.RAM_TYPE				(TAG_RAM_TYPE),
				.USE_BORDER				(USE_BORDER),
				
				.LOG_ENABLE				(0),
				.LOG_FILE				(""),
				.LOG_ID					(0)
			)
		i_texture_cache_tag
			(
				.reset					(reset),
				.clk					(clk),
				
				.clear_start			(clear_start),
				.clear_busy				(),
				
				.param_width			(param_width),
				.param_height			(param_height),
				
				.s_user					(s_aruser),
				.s_addrx				(s_araddrx),
				.s_addry				(s_araddry),
				.s_valid				(s_arvalid),
				.s_ready				(s_arready),
				
				.m_user					(tag_user),
				.m_tag_addr				(tag_tag_addr),
				.m_pix_addrx			(tag_pix_addrx),
				.m_pix_addry			(tag_pix_addry),
				.m_blk_addrx			(tag_blk_addrx),
				.m_blk_addry			(tag_blk_addry),
				.m_cache_hit			(tag_cache_hit),
				.m_range_out			(tag_range_out),
				.m_valid				(tag_valid),
				.m_ready				(tag_ready)
			);
	
	
	
	// ---------------------------------
	//  memmory acess fifo
	// ---------------------------------
	
	// AR FIFO
	wire	[ADDR_X_WIDTH-1:0]		arfifo_s_araddrx;
	wire	[ADDR_Y_WIDTH-1:0]		arfifo_s_araddry;
	wire							arfifo_s_arvalid;
	wire							arfifo_s_arready;
	
	wire	[ADDR_X_WIDTH-1:0]		arfifo_m_araddrx;
	wire	[ADDR_Y_WIDTH-1:0]		arfifo_m_araddry;
	wire							arfifo_m_arvalid;
	wire							arfifo_m_arready;
	
	jelly_fifo_fwtf
			#(
				.DATA_WIDTH			(ADDR_X_WIDTH+ADDR_Y_WIDTH),
				.PTR_WIDTH			(AR_FIFO_PTR_WIDTH),
				.RAM_TYPE			(AR_FIFO_RAM_TYPE),
				.MASTER_REGS		(0)
			)
		i_fifo_fwtf_ar
			(
				.reset				(reset),
				.clk				(clk),
				
				.s_data				({arfifo_s_araddrx, arfifo_s_araddry}),
				.s_valid			(arfifo_s_arvalid),
				.s_ready			(arfifo_s_arready),
				.s_free_count		(),
				
				.m_data				({arfifo_m_araddrx, arfifo_m_araddry}),
				.m_valid			(arfifo_m_arvalid),
				.m_ready			(arfifo_m_arready),
				.m_data_count		()
			);
	
	
	// R FIFO
	localparam	M_COMPONENT_DATA_WIDTH = (COMPONENT_DATA_WIDTH << M_DATA_SIZE);
	
	wire	[M_STRB_WIDTH-1:0]		rfifo_s_ready;
	
	wire	[M_STRB_WIDTH-1:0]		rfifo_array_rlast;
	wire	[M_DATA_WIDTH-1:0]		rfifo_array_rdata;
	wire	[M_STRB_WIDTH-1:0]		rfifo_array_rvalid;
	wire	[M_STRB_WIDTH-1:0]		rfifo_array_rready;
	
	generate
	for ( i = 0; i < M_STRB_WIDTH; i = i+1 ) begin : loop_r_fifo
		jelly_fifo_fwtf
				#(
					.DATA_WIDTH			(1+M_COMPONENT_DATA_WIDTH),
					.PTR_WIDTH			(R_FIFO_PTR_WIDTH),
					.RAM_TYPE			(R_FIFO_RAM_TYPE),
					.MASTER_REGS		(0)
				)
			i_fifo_fwtf_r
				(
					.reset				(reset),
					.clk				(clk),
					
					.s_data				({m_rlast, m_rdata[i*M_COMPONENT_DATA_WIDTH +: M_COMPONENT_DATA_WIDTH]}),
					.s_valid			(m_rvalid & m_rstrb[i]),
					.s_ready			(rfifo_s_ready[i]),
					.s_free_count		(),
					
					.m_data				({rfifo_array_rlast[i], rfifo_array_rdata[i*M_COMPONENT_DATA_WIDTH +: M_COMPONENT_DATA_WIDTH]}),
					.m_valid			(rfifo_array_rvalid[i]),
					.m_ready			(rfifo_array_rready[i]),
					.m_data_count		()
				);
	end
	endgenerate
	
	assign m_rready = &rfifo_s_ready;
	
	
	wire							rfifo_m_rlast;
	wire	[M_DATA_WIDTH-1:0]		rfifo_m_rdata;
	wire							rfifo_m_rvalid;
	wire							rfifo_m_rready;
	
	jelly_stream_combiner
			#(
				.NUM			(M_STRB_WIDTH),
				.DATA_WIDTH		(M_COMPONENT_DATA_WIDTH),
				.S_REGS			(M_STRB_WIDTH > 1),
				.M_REGS			(M_STRB_WIDTH > 1)
			)
		i_stream_combiner
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(1'b1),
				
				.s_last			(rfifo_array_rlast),
				.s_data			(rfifo_array_rdata),
				.s_valid		(rfifo_array_rvalid),
				.s_ready		(rfifo_array_rready),
				
				.m_last			(rfifo_m_rlast),
				.m_data			(rfifo_m_rdata),
				.m_valid		(rfifo_m_rvalid),
				.m_ready		(rfifo_m_rready)
			);
	
	
	
	
	
	// ---------------------------------
	//  basic cache unit
	// ---------------------------------
	
	wire	[S_USER_WIDTH-1:0]		base_s_aruser;
	wire	[ADDR_X_WIDTH-1:0]		base_s_araddrx;
	wire	[ADDR_Y_WIDTH-1:0]		base_s_araddry;
	wire							base_s_arvalid;
	wire							base_s_arready;
	
	wire							base_m_arvalid;
	
	wire							base_m_rlast;
	wire	[M_STRB_WIDTH-1:0]		base_m_rstrb;
	wire	[M_DATA_WIDTH-1:0]		base_m_rdata;
	wire							base_m_rvalid;
	
	jelly_texture_cache_basic
			#(
				.COMPONENT_NUM			(COMPONENT_NUM),
				.COMPONENT_DATA_WIDTH	(COMPONENT_DATA_WIDTH),
				
				.PARALLEL_SIZE			(PARALLEL_SIZE),
				.ADDR_X_WIDTH			(ADDR_X_WIDTH),
				.ADDR_Y_WIDTH			(ADDR_Y_WIDTH),
				.BLK_X_SIZE				(BLK_X_SIZE),
				.BLK_Y_SIZE				(BLK_Y_SIZE),
				.TAG_ADDR_WIDTH			(TAG_ADDR_WIDTH),
				.TAG_RAM_TYPE			(TAG_RAM_TYPE),
				.MEM_RAM_TYPE			(MEM_RAM_TYPE),
				
				.USE_S_RREADY			(USE_S_RREADY),
				.USE_M_RREADY			(0),
				
				.S_USER_WIDTH			(S_USER_WIDTH),
				.S_DATA_SIZE			(S_DATA_SIZE),
//				.S_DATA_WIDTH			(S_DATA_WIDTH),
				.S_BLK_X_NUM			(S_BLK_X_NUM),
				.S_BLK_Y_NUM			(S_BLK_Y_NUM),
				
				.M_DATA_SIZE			(M_DATA_SIZE),
//				.M_DATA_WIDTH			(M_DATA_WIDTH),
//				.M_STRB_WIDTH			(M_STRB_WIDTH),
				
				.USE_BORDER				(USE_BORDER),
				.BORDER_DATA			(BORDER_DATA),
				
				.QUE_FIFO_PTR_WIDTH		(QUE_FIFO_PTR_WIDTH),
				.QUE_FIFO_RAM_TYPE		(QUE_FIFO_RAM_TYPE),
				
				.LOG_ENABLE				(LOG_ENABLE),
				.LOG_FILE				(LOG_FILE),
				.LOG_ID					(LOG_ID)
			)
		i_texture_cache_basic
			(
				.reset					(reset),
				.clk					(clk),
				
				.endian					(endian),
				
				.clear_start			(clear_start),
				.clear_busy				(clear_busy),
				
				.param_width			(param_width),
				.param_height			(param_height),
				
				.status_idle			(status_idle),
				.status_stall			(status_stall),
				.status_access			(status_access),
				.status_hit				(status_hit),
				.status_miss			(status_miss),
				.status_range_out		(status_range_out),
				
				.s_aruser				(base_s_aruser),
				.s_araddrx				(base_s_araddrx),
				.s_araddry				(base_s_araddry),
				.s_arvalid				(base_s_arvalid),
				.s_arready				(base_s_arready),
				.s_ruser				(s_ruser),
				.s_rlast				(s_rlast),
				.s_rdata				(s_rdata),
				.s_rvalid				(s_rvalid),
				.s_rready				(s_rready),
				
				.m_araddrx				(),
				.m_araddry				(),
				.m_arvalid				(base_m_arvalid),
				.m_arready				(1'b1),
				.m_rlast				(base_m_rlast),
				.m_rstrb				(base_m_rstrb),
				.m_rdata				(base_m_rdata),
				.m_rvalid				(base_m_rvalid),
				.m_rready				()
			);
	
	
	
	// ---------------------------------
	//  memory access control
	// ---------------------------------
	
	
	// read addr command
	localparam	LOOK_AHEAD_NUM         = (1 << (R_FIFO_PTR_WIDTH - (BLK_Y_SIZE + BLK_X_SIZE - M_DATA_SIZE)));
	
	// limitter for FIFO size
	wire	base_limit_arready;
	jelly_texture_cache_limitter
			#(
				.LIMIT_NUM		(LOOK_AHEAD_NUM),
				.PACKET_FIRST	(0)
			)
		i_texture_cache_limitter_base
			(
				.reset			(reset),
				.clk			(clk),
				
				.arvalid		(m_arvalid),
				.arready		(m_arready),
				.rlast			(base_m_rlast),
				.rvalid			(base_m_rvalid),
				.rready			(1'b1),
				
				.limit_arready	(base_limit_arready)
			);
	
	
	// limitter for in-order packet
	wire	m_limit_arready;
	jelly_texture_cache_limitter
			#(
				.LIMIT_NUM		(M_INORDER ? 1 : 0),
				.PACKET_FIRST	(M_INORDER_DATA_FIRST)
			)
		i_texture_cache_limitter_m
			(
				.reset			(reset),
				.clk			(clk),
				
				.arvalid		(m_arvalid),
				.arready		(m_arready),
				.rlast			(m_rlast),
				.rvalid			(m_rvalid),
				.rready			(m_rready),
				
				.limit_arready	(m_limit_arready)
			);
	
	
	
	/*
	
	localparam	LOOK_AHEAD_COUNT_WIDTH = LOOK_AHEAD_NUM <   1 ? 1 :
	                                     LOOK_AHEAD_NUM <   3 ? 2 :
	                                     LOOK_AHEAD_NUM <   7 ? 3 :
	                                     LOOK_AHEAD_NUM <  15 ? 4 :
	                                     LOOK_AHEAD_NUM <  31 ? 5 :
	                                     LOOK_AHEAD_NUM <  63 ? 6 :
	                                     LOOK_AHEAD_NUM < 127 ? 7 : 8;
	
	
	wire					mem_arready;
	
	generate
	if ( M_IN_ORDER ) begin : blk_inorder
		reg				reg_mem_arready;
		reg				reg_mem_rfirst;
		
		always @(posedge clk) begin
			if ( reset ) begin
				reg_mem_rfirst  <= 1'b1;
				reg_mem_arready <= 1'b1;
			end
			else begin
				if ( m_rvalid && m_rready ) begin
					reg_mem_rfirst <= m_rlast;
				end
				
				if ( m_arvalid && m_arready ) begin
					reg_mem_arready <= 1'b0;
				end
				else if ( m_rvalid && m_rready & reg_mem_rfirst ) begin
					reg_mem_arready <= 1'b1;
				end
			end
		end
		
		assign mem_arready = reg_mem_arready;
	end
	else begin : blk_limitter
		reg		[LOOK_AHEAD_COUNT_WIDTH-1:0]	reg_mem_limit,   next_mem_limit;
		reg		[LOOK_AHEAD_COUNT_WIDTH-1:0]	reg_mem_count,   next_mem_count;
		reg										reg_mem_arready, next_mem_arready;
		
		always @* begin
			next_mem_limit   = reg_mem_limit;
			next_mem_count   = reg_mem_count;
			next_mem_arready = reg_mem_arready;
			
			if ( m_arvalid && m_arready ) begin
				next_mem_count = next_mem_count + 1'b1;
			end
			
			if ( base_m_arvalid ) begin
				next_mem_limit = next_mem_limit + 1'b1;
			end
			
			if ( base_m_rvalid & base_m_rlast ) begin
				next_mem_count = next_mem_count - 1'b1;
				next_mem_limit = next_mem_limit - 1'b1;
			end
			
			next_mem_arready = (next_mem_count < next_mem_limit);
		end
		
		always @(posedge clk) begin
			if ( reset ) begin
				reg_mem_limit   <= LOOK_AHEAD_NUM;
				reg_mem_count   <= {LOOK_AHEAD_COUNT_WIDTH{1'b0}};
				reg_mem_arready <= 1'b1;
			end
			else begin
				reg_mem_limit   <= next_mem_limit;
				reg_mem_count   <= next_mem_count;
				reg_mem_arready <= next_mem_arready;
			end
		end
		
		assign mem_arready = reg_mem_arready;
	end
	endgenerate
	*/
	
	
	assign arfifo_s_araddrx = (tag_blk_addrx << BLK_X_SIZE);
	assign arfifo_s_araddry = (tag_blk_addry << BLK_Y_SIZE);
	assign arfifo_s_arvalid = ((tag_valid & ~(tag_cache_hit | tag_range_out)) & base_s_arready);
	
	assign base_s_aruser    = tag_user;
	assign base_s_araddrx   = {tag_blk_addrx, tag_pix_addrx};
	assign base_s_araddry   = {tag_blk_addry, tag_pix_addry};
	assign base_s_arvalid   = (tag_valid & ((tag_cache_hit | tag_range_out) | arfifo_s_arready));
	
	assign tag_ready        = (base_s_arvalid & base_s_arready);
	
	
	assign m_araddrx        = arfifo_m_araddrx;
	assign m_araddry        = arfifo_m_araddry;
	assign m_arvalid        = (arfifo_m_arvalid & base_limit_arready & m_limit_arready);
	
	assign arfifo_m_arready = (m_arready        & base_limit_arready & m_limit_arready);
	
	
	
	// read data
	reg		reg_mem_rready;
	always @(posedge clk) begin
		if ( reset ) begin
			reg_mem_rready <= 1'b0;
		end
		else begin
			if ( base_m_rvalid & base_m_rlast ) begin
				reg_mem_rready <= 1'b0;
			end
			
			if ( base_m_arvalid ) begin
				reg_mem_rready <= 1'b1;
			end
		end
	end
	
	assign base_m_rlast     = rfifo_m_rlast;
	assign base_m_rstrb     = {M_STRB_WIDTH{1'b1}};
	assign base_m_rdata     = rfifo_m_rdata;
	assign base_m_rvalid    = (rfifo_m_rvalid & reg_mem_rready);
	
//	assign base_m_rvalid    = (|rfifo_m_rvalid & reg_mem_rready);
	
	assign rfifo_m_rready   = reg_mem_rready;
	
	
endmodule



`default_nettype wire


// end of file
