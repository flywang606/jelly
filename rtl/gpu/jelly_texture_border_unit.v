// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// border
module jelly_texture_border_unit
		#(
			parameter	USER_WIDTH   = 0,
			parameter	ADDR_X_WIDTH = 10,
			parameter	ADDR_Y_WIDTH = 10,
			parameter	X_WIDTH      = 12,
			parameter	Y_WIDTH      = 12,
			parameter	M_REGS       = 0
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			input	wire			[ADDR_X_WIDTH-1:0]	param_width,
			input	wire			[ADDR_Y_WIDTH-1:0]	param_height,
			input	wire			[2:0]				param_x_op,
			input	wire			[2:0]				param_y_op,
			
			input	wire			[USER_BITS-1:0]		s_user,
			input	wire	signed	[X_WIDTH-1:0]		s_x,
			input	wire	signed	[Y_WIDTH-1:0]		s_y,
			input	wire								s_valid,
			output	wire								s_ready,
			
			output	wire			[USER_BITS-1:0]		m_user,
			output	wire								m_border,
			output	wire			[ADDR_X_WIDTH-1:0]	m_addrx,
			output	wire			[ADDR_Y_WIDTH-1:0]	m_addry,
			output	wire								m_valid,
			input	wire								m_ready
		);
	
	// 加算フェーズが LUT5 に収まるように 2stage で op を最適化
	// ISEだと最適化してくれないが、Vivadoだとコンパクトに収まる模様
	//
	//
	// op:3'b000 BORDER_TRANSPARENT	borderフラグを立ててスルー(後段でケア)
	// op:3'b000 BORDER_CONSTANT		borderフラグを立ててスルー(後段でケア)
	// op:3'b100 BORDER_REPLICATE
	//		overflow  : param_width - 1                             : w - ((w-x-1) + 1)  n  :  w-0 n  (st1_op:3'b110)
	//		underflow : 0                                           : 0 - ((0    ) + 0)  c  :  0-X c  (st1_op:3'b101)
	// op:3'b101 BORDER_REFLECT
	//		overflow  : (param_width - 1) - (x - param_width)       : w + ((w-x-1) + 0)  n  :  w+X n  (st1_op:3'b010)
	//		underflow : -x-1                                        : 0 - ((0+x  ) + 1)  n  :  0-X n  (st1_op:3'b100)
	// op:3'b110 BORDER_REFLECT101 (width には 1小さい数を設定すること)
	//		overflow  : (param_width - 1) - (x - param_width) - 1   : w + ((w-x-1) + 1)  c  :  w+X c  (st1_op:3'b011)
	//		underflow : -x                                          : 0 - ((0+x  ) + 0)  c  :  0-X c  (st1_op:3'b101)
	// op:3'b111 BORDER_WRAP
	//		overflow  : x - param_width                             : 0 - ((w-x-1) + 1)  n  :  0-X n  (st1_op:3'b100)
	//		underflow : x + param_width                             : w + ((0+x  ) + 0)  n  :  w+X n  (st1_op:3'b010)
	// BORDER以外の箇所
	//                  x                                           : w - ((w-x-1) + 1)  n  :  w-X n  (st1_op:3'b000)
	
	
	
	// -------------------------------------
	//  local parameter
	// -------------------------------------
	
	localparam	USER_BITS = USER_WIDTH > 0 ? USER_WIDTH : 1;
	
	wire	signed	[X_WIDTH-1:0]		image_width  = {1'b0, param_width};
	wire	signed	[Y_WIDTH-1:0]		image_height = {1'b0, param_height};
	
	
	
	// -------------------------------------
	//  pipeline control
	// -------------------------------------
	
	localparam	PIPELINE_STAGES = 2;
	
	wire			[PIPELINE_STAGES-1:0]	stage_cke;
	wire			[PIPELINE_STAGES-1:0]	stage_valid;
	
	
	wire			[USER_BITS-1:0]			src_user;
	wire	signed	[X_WIDTH-1:0]			src_x;
	wire	signed	[Y_WIDTH-1:0]			src_y;
	
	wire			[USER_BITS-1:0]			sink_user;
	wire									sink_border;
	wire			[ADDR_X_WIDTH-1:0]		sink_addrx;
	wire			[ADDR_Y_WIDTH-1:0]		sink_addry;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(PIPELINE_STAGES),
				.S_DATA_WIDTH		(USER_BITS+X_WIDTH+Y_WIDTH),
				.M_DATA_WIDTH		(USER_BITS+1+ADDR_X_WIDTH+ADDR_Y_WIDTH),
				.AUTO_VALID			(1),
				.MASTER_IN_REGS		(M_REGS),
				.MASTER_OUT_REGS	(M_REGS)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1),
				
				.s_data				({s_user, s_x, s_y}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({m_user, m_border, m_addrx, m_addry}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			({PIPELINE_STAGES{1'bx}}),
				.src_data			({src_user, src_x, src_y}),
				.src_valid			(),
				.sink_data			({sink_user, sink_border, sink_addrx, sink_addry}),
				.buffered			()
			);
	
	
	
	// -------------------------------------
	//  calculate
	// -------------------------------------
	
	reg									src_x_under;
	reg									src_x_over;
	reg		signed	[X_WIDTH-1:0]		src_x0;
	reg		signed	[X_WIDTH-1:0]		src_x1;
	reg		signed	[X_WIDTH-1:0]		src_xx;
	reg				[2:0]				src_x_op;
	
	reg									src_y_under;
	reg									src_y_over;
	reg		signed	[Y_WIDTH-1:0]		src_y0;
	reg		signed	[Y_WIDTH-1:0]		src_y1;
	reg		signed	[X_WIDTH-1:0]		src_yy;
	reg				[2:0]				src_y_op;
	
	always @* begin
		// X
		src_x_under = 1'bx;
		src_x_over  = 1'bx;
		src_x0      = {X_WIDTH{1'bx}};
		src_x1      = {X_WIDTH{1'bx}};
		src_xx      = {X_WIDTH{1'bx}};
		src_x_op    = 3'bxxx;
		
		src_x_under = src_x[X_WIDTH-1];
		
		case ( {param_x_op[1:0], src_x_under} )
		3'b00_0:	begin	src_x0 = image_width;     src_x1 = ~src_x;          end  // REPLICATE
		3'b00_1:	begin	src_x0 = {X_WIDTH{1'b0}}; src_x1 = {X_WIDTH{1'b0}}; end  // REPLICATE(underflow)
		3'b01_0:	begin	src_x0 = image_width;     src_x1 = ~src_x;          end  // REFLECT
		3'b01_1:	begin	src_x0 = {X_WIDTH{1'b0}}; src_x1 = src_x; 		    end  // REFLECT(underflow)
		3'b10_0:	begin	src_x0 = image_width;     src_x1 = ~src_x;          end  // REFLECT101
		3'b10_1:	begin	src_x0 = {X_WIDTH{1'b0}}; src_x1 = src_x; 		    end  // REFLECT101(underflow)
		3'b11_0:	begin	src_x0 = image_width;     src_x1 = ~src_x;          end  // REFLECT101
		3'b11_1:	begin	src_x0 = {X_WIDTH{1'b0}}; src_x1 = src_x; 		    end  // REFLECT101(underflow)
		endcase
		
		src_xx      = src_x0 + src_x1;
		src_x_over  = src_xx[X_WIDTH-1];
		
		casex ( {param_x_op[1:0], src_x_under, src_x_over} )
		4'b00_01:	begin	src_x_op = 3'b110;	end		// BORDER_REPLICATE(overflow)
		4'b00_1x:	begin	src_x_op = 3'b101;	end		// BORDER_REPLICATE(underflow)
		4'b01_01:	begin	src_x_op = 3'b010;	end		// BORDER_REFLECT(overflow)
		4'b01_1x:	begin	src_x_op = 3'b100;	end		// BORDER_REFLECT(underflow)
		4'b10_01:	begin	src_x_op = 3'b011;	end		// BORDER_REFLECT101(overflow)
		4'b10_1x:	begin	src_x_op = 3'b101;	end		// BORDER_REFLECT101(underflow)
		4'b11_01:	begin	src_x_op = 3'b100;	end		// BORDER_WRAP(overflow)
		4'b11_1x:	begin	src_x_op = 3'b010;	end		// BORDER_WRAP(underflow)
		4'bxx_00:	begin	src_x_op = 3'b000;	end
		endcase
		
		
		// Y
		src_y_under = 1'bx;
		src_y_over  = 1'bx;
		src_y0      = {Y_WIDTH{1'bx}};
		src_y1      = {Y_WIDTH{1'bx}};
		src_yy      = {Y_WIDTH{1'bx}};
		src_y_op    = 3'bxxx;
		
		src_y_under = src_y[Y_WIDTH-1];
		
		case ( {param_y_op[1:0], src_y_under} )
		3'b00_0:	begin	src_y0 = image_height;    src_y1 = ~src_y;          end		// REPLICATE
		3'b00_1:	begin	src_y0 = {Y_WIDTH{1'b0}}; src_y1 = {Y_WIDTH{1'b0}}; end		// REPLICATE(underflow)
		3'b01_0:	begin	src_y0 = image_height;    src_y1 = ~src_y;          end		// REFLECT
		3'b01_1:	begin	src_y0 = {Y_WIDTH{1'b0}}; src_y1 = src_y; 		    end		// REFLECT(underflow)
		3'b10_0:	begin	src_y0 = image_height;    src_y1 = ~src_y;          end		// REFLECT101
		3'b10_1:	begin	src_y0 = {Y_WIDTH{1'b0}}; src_y1 = src_y; 		    end		// REFLECT101(underflow)
		3'b11_0:	begin	src_y0 = image_height;    src_y1 = ~src_y;          end		// REFLECT101
		3'b11_1:	begin	src_y0 = {Y_WIDTH{1'b0}}; src_y1 = src_y; 		    end		// REFLECT101(underflow)
		endcase
		
		src_yy      = src_y0 + src_y1;
		src_y_over  = src_yy[Y_WIDTH-1];
		
		casex ( {param_y_op[1:0], src_y_under, src_y_over} )
		4'b00_01:	begin	src_y_op = 3'b110;	end		// BORDER_REPLICATE(overflow)
		4'b00_1x:	begin	src_y_op = 3'b101;	end		// BORDER_REPLICATE(underflow)
		4'b01_01:	begin	src_y_op = 3'b010;	end		// BORDER_REFLECT(overflow)
		4'b01_1x:	begin	src_y_op = 3'b100;	end		// BORDER_REFLECT(underflow)
		4'b10_01:	begin	src_y_op = 3'b011;	end		// BORDER_REFLECT101(overflow)
		4'b10_1x:	begin	src_y_op = 3'b101;	end		// BORDER_REFLECT101(underflow)
		4'b11_01:	begin	src_y_op = 3'b100;	end		// BORDER_WRAP(overflow)
		4'b11_1x:	begin	src_y_op = 3'b010;	end		// BORDER_WRAP(underflow)
		4'bxx_00:	begin	src_y_op = 3'b000;	end
		endcase
	end
	
	reg		signed	[USER_BITS-1:0]	st0_user;
	reg								st0_border;
	
	reg		signed	[X_WIDTH-1:0]	st0_x;
	reg				[2:0]			st0_x_op;
	
	reg		signed	[Y_WIDTH-1:0]	st0_y;
	reg				[2:0]			st0_y_op;
	
	
	always @(posedge clk) begin
		if ( stage_cke[0] ) begin
			st0_user   <= src_user;
			
			st0_border <= ((~param_x_op[2] && (src_x_under || src_x_over)) || (~param_y_op[2] && (src_y_under || src_y_over)));
			
			st0_x      <= src_xx;
			st0_x_op   <= src_x_op;
			
			st0_y      <= src_yy;
			st0_y_op   <= src_y_op;
		end
	end
	
	
	reg		signed	[X_WIDTH-1:0]	st0_x0;
	reg		signed	[X_WIDTH-1:0]	st0_x1;
	reg								st0_x_carry;
	
	reg		signed	[Y_WIDTH-1:0]	st0_y0;
	reg		signed	[Y_WIDTH-1:0]	st0_y1;
	reg								st0_y_carry;
	
	always @* begin
		// X
		st0_x0      = {X_WIDTH{1'bx}};
		st0_x1      = {X_WIDTH{1'bx}};
		st0_x_carry = 1'bx;
		case ( st0_x_op )
		3'b000:	begin	st0_x0 = image_width;     st0_x1 = ~st0_x;          st0_x_carry = 1'b0;	end
		3'b010:	begin	st0_x0 = image_width;     st0_x1 = st0_x;           st0_x_carry = 1'b0;	end
		3'b011:	begin	st0_x0 = image_width;     st0_x1 = st0_x;           st0_x_carry = 1'b1;	end
		3'b100:	begin	st0_x0 = {X_WIDTH{1'b0}}; st0_x1 = ~st0_x;          st0_x_carry = 1'b0;	end
		3'b101:	begin	st0_x0 = {X_WIDTH{1'b0}}; st0_x1 = ~st0_x;          st0_x_carry = 1'b1;	end
		3'b110:	begin	st0_x0 = image_width;     st0_x1 = {X_WIDTH{1'b1}}; st0_x_carry = 1'b0;	end
		endcase
		
		// Y
		st0_y0      = {Y_WIDTH{1'bx}};
		st0_y1      = {Y_WIDTH{1'bx}};
		st0_y_carry = 1'bx;
		case ( st0_y_op )
		3'b000:	begin	st0_y0 = image_height;    st0_y1 = ~st0_y;          st0_y_carry = 1'b0;	end
		3'b010:	begin	st0_y0 = image_height;    st0_y1 = st0_y;           st0_y_carry = 1'b0;	end
		3'b011:	begin	st0_y0 = image_height;    st0_y1 = st0_y;           st0_y_carry = 1'b1;	end
		3'b100:	begin	st0_y0 = {X_WIDTH{1'b0}}; st0_y1 = ~st0_y;          st0_y_carry = 1'b0;	end
		3'b101:	begin	st0_y0 = {X_WIDTH{1'b0}}; st0_y1 = ~st0_y;          st0_y_carry = 1'b1;	end
		3'b110:	begin	st0_y0 = image_height;    st0_y1 = {Y_WIDTH{1'b1}}; st0_y_carry = 1'b0;	end
		endcase
	end
	
	
	reg				[USER_BITS-1:0]	st1_user;
	reg								st1_border;
	reg		signed	[X_WIDTH-1:0]	st1_x;
	reg		signed	[Y_WIDTH-1:0]	st1_y;
	
	always @(posedge clk) begin
		if ( stage_cke[1] ) begin
			st1_user   <= st0_user;
			
			st1_border <= st0_border;
			
			st1_x      <= st0_x0 + st0_x1 + st0_x_carry;
			st1_y      <= st0_y0 + st0_y1 + st0_y_carry;
		end
	end
	
	
	assign sink_user   = st1_user;
	assign sink_border = st1_border;
	assign sink_addrx  = st1_x;
	assign sink_addry  = st1_y;
	
	
endmodule


`default_nettype wire


// end of file
