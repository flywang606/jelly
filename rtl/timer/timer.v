// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    Timmer
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


`define TIMER_ADR_CONTROL	2'b00
`define TIMER_ADR_COMPARE	2'b01
`define TIMER_ADR_COUNTER	2'b11


module jelly_timer
		(
			reset, clk,
			interrupt_req,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	
	parameter	WB_ADR_WIDTH  = 2;
	parameter	WB_DAT_WIDTH  = 32;
	localparam	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8);
	
	// system
	input						clk;
	input						reset;
	
	// irq
	output						interrupt_req;
	
	// control port (wishbone)
	input	[WB_ADR_WIDTH-1:0]	wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]	wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_dat_i;
	input						wb_we_i;
	input	[WB_SEL_WIDTH-1:0]	wb_sel_i;
	input						wb_stb_i;
	output						wb_ack_o;
	
	reg					reg_enable;
	reg					reg_clear;
	reg		[31:0]		reg_counter;
	reg		[31:0]		reg_compare;
	reg					interrupt_req;
	
	wire				compare_match;
	assign compare_match = (reg_counter == reg_compare);
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_enable    <= 1'b0;
			reg_clear     <= 1'b0;
			reg_counter   <= 0;
			reg_compare   <= 50000 - 1;
			interrupt_req <= 1'b0;
		end
		else begin
			// control
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `TIMER_ADR_CONTROL) ) begin
				reg_enable <= wb_dat_i[0];
				reg_clear  <= wb_dat_i[1];
			end
			else begin
				reg_clear  <= 1'b0;		// auto clear;
			end
			
			// compare
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `TIMER_ADR_COMPARE) ) begin
				reg_compare <= wb_dat_i;
			end
			
			// counter
			if ( compare_match | reg_clear ) begin
				reg_counter <= 0;
			end
			else begin
				reg_counter <= reg_counter + reg_enable;
			end
			
			// interrupt
			if ( compare_match ) begin
				interrupt_req <= reg_enable;
			end
			else begin
				interrupt_req <= 1'b0;
			end
		end
	end
	
	reg		[WB_DAT_WIDTH-1:0]	wb_dat_o;
	always @* begin
		case ( wb_adr_i )
		`TIMER_ADR_CONTROL:	wb_dat_o <= {reg_clear, reg_enable};
		`TIMER_ADR_COMPARE:	wb_dat_o <= reg_compare;
		`TIMER_ADR_COUNTER:	wb_dat_o <= reg_counter;
		default:			wb_dat_o <= {WB_DAT_WIDTH{1'b0}};
		endcase
	end
		
	assign wb_ack_o = 1'b1;
	
endmodule
