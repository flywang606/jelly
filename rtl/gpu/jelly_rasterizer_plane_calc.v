// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// a*x + b*y + c �����X�^�X�L�������Ɍv�Z����
// (�v�͕��ʂ̎��̕����ŁA�����̂ǂ��瑤�̗̈�ɂ��邩���肷��̂Ɏg��)
module jelly_rasterizer_plane_calc
        #(
            parameter   WIDTH = 16
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,
            
            input   wire                            x_first,
            input   wire                            y_first,
            
            input   wire    signed  [WIDTH-1:0]     dx,
            input   wire    signed  [WIDTH-1:0]     dy_stride,
            input   wire    signed  [WIDTH-1:0]     offset,
            
            output  wire    signed  [WIDTH-1:0]     out_value,
            output  wire                            out_sign
        );
    
    reg     signed  [WIDTH-1:0]     reg_value;
    
    always @(posedge clk) begin
//      if ( reset ) begin
//          reg_value <= {WIDTH{1'b0}};
//      end
//      else 
        if ( cke ) begin
            reg_value <= reg_value + dx;
            if ( x_first ) begin
                reg_value <= reg_value + dy_stride;
                if ( y_first ) begin
                    reg_value <= offset;
                end
            end
        end
    end
    
    assign out_value = reg_value;
    assign out_sign  = out_value[WIDTH-1];
    
endmodule


`default_nettype wire


// end of file
