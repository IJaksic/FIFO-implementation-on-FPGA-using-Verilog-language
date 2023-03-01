`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:16:43 05/16/2022 
// Design Name: 
// Module Name:    FIFO_2 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module FIFO_2(input clk_slow, reset, wr, rd, clk_internal, r_Rx_Serial, output[7:0] data_in,
output reg[31:0] data_out, output reg empty, full, manjak, error_read, error_write, output w_Tx_Done, w_Tx_Serial
, output reg [2:0] numData, output reg [4:0] fifo_counter); 

//reg [4:0] fifo_counter;
reg [3:0] rd_ptr, wr_ptr;
reg [7:0] buf_mem [15:0];
wire clk;
reg [11:0] c_CLKS_PER_BIT = 2600;
wire r_Tx_DV_debounced;
wire r_Rx_DV;
integer i;
//reg [2:0] numData=0;

debounce db(.pb_1(clk_slow), .clk(clk_internal), .pb_out(clk));

uart_rx UART_RX_INST
    (.i_Clock(clk_internal),
     .i_Rx_Serial(r_Rx_Serial),
     .o_Rx_DV(r_Rx_DV),
     .o_Rx_Byte(data_in),
	  .CLKS_PER_BIT(c_CLKS_PER_BIT)
     );
   
uart_tx_32 UART_TX_INST
    (.i_Clock(clk_internal),
     .i_Tx_DV(clk),
     .i_Tx_Byte(data_out),
     .o_Tx_Active(rd),
	  .numData(numData),
     .o_Tx_Serial(w_Tx_Serial),
     .o_Tx_Done(w_Tx_Done),
	  .CLKS_PER_BIT(c_CLKS_PER_BIT)
     );

always @(fifo_counter) begin
	empty = (fifo_counter==0 || fifo_counter > 16);
	full = (fifo_counter==16);
end

//fifo_counter je brojaè koji broji koliko je puna memorija, u ovom bloku se provjeravaju uvjetu za //empty i full

//blok koji mijenja vrijednost od fifo_counter
always @(posedge clk) 
begin
if(reset)
	fifo_counter<=0;
else if((!full && wr) && (!empty && rd))
	if(fifo_counter>3)
		fifo_counter <= fifo_counter-3;
	else
		fifo_counter <= 1;
		
else if(!full && wr)
	fifo_counter <= fifo_counter + 1;
else if(!empty && rd)
	if(fifo_counter>3)
		fifo_counter <= fifo_counter - 4;
	else
		fifo_counter <= 0;
		
else if(fifo_counter>16)
		fifo_counter<=0;
else
	fifo_counter <= fifo_counter;
end

always@(posedge clk)
begin
	manjak <= (fifo_counter<4 && rd && !empty)?1:0;
end

//blok za èitanje iz memorije
always @(posedge clk)
begin
if(reset)
	begin
	data_out <= 0;
	error_read <= 0;
	numData<=0;
	end
else begin
if(rd && !empty)
	begin
		if(fifo_counter>3) begin
			data_out[7:0] <= buf_mem[rd_ptr];
			data_out[15:8] <= buf_mem[rd_ptr+1];
			data_out[23:16] <= buf_mem[rd_ptr+2];
			data_out[31:24] <= buf_mem[rd_ptr+3];
			numData <= 4;
			error_read <= 0;
		end
		else if(fifo_counter>2) begin
			data_out[7:0] <= buf_mem[rd_ptr];
			//data_out[15:8] <= buf_mem[rd_ptr+1];
			data_out[23:16] <= buf_mem[rd_ptr+1];
			data_out[31:24] <= buf_mem[rd_ptr+2];
			numData <= 3;
			error_read <= 0;
		end
		else if(fifo_counter>1) begin
			data_out[7:0] <= buf_mem[rd_ptr];
			//data_out[15:8] <= buf_mem[rd_ptr+1];
			//data_out[23:16] <= buf_mem[rd_ptr+2];
			data_out[31:24] <= buf_mem[rd_ptr+1];
			numData <= 2;
			error_read <= 0;
		end
		else if(fifo_counter>0) begin
			data_out[7:0] <= buf_mem[rd_ptr];
			//data_out[15:8] <= buf_mem[rd_ptr+1];
			//data_out[23:16] <= buf_mem[rd_ptr+2];
			//data_out[31:24] <= buf_mem[rd_ptr+3];
			numData <= 1;
			error_read <= 0;
		end
	end
else if (rd && empty)
	begin
	data_out[7:0] <= 64;
	numData <= 1;
	error_read <= 1;
	end
else 
	begin
   data_out <= data_out;
	error_read <= 0;
	end
end
end


//Blok za pisanje u memoriju
always @(posedge clk) begin
if (reset)
begin
	for(i=0;i<16;i=i+1)
			buf_mem[i]<=0;
	error_write <= 0;
end
else if(wr && !full)
	begin
	buf_mem[wr_ptr] <= data_in;
	error_write <= 0;
	end
else if(wr && full)
	begin
	buf_mem[wr_ptr] <= buf_mem[wr_ptr];
	error_write <= 1;
	end
else 
	begin
	buf_mem[wr_ptr] <= buf_mem[wr_ptr];
	error_write <= 0;
	end
end

//Blok za mijenjanje write pointer i read pointer
always @(posedge clk)
begin
if(reset)
begin
	wr_ptr <= 0;
	rd_ptr <= 0;
end
else begin
if(!full && wr)
	wr_ptr <= wr_ptr + 1;
else
	wr_ptr <= wr_ptr;
if(!empty && rd)
	begin
	if(fifo_counter>3)
		rd_ptr <= rd_ptr + 4;
	else
		rd_ptr <= rd_ptr + fifo_counter;
	end
else
	rd_ptr <= rd_ptr;
end
end


endmodule
