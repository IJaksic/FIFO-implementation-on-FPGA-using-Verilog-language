`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
//////////////////////////////////////////////////////////////////////
// This file contains the UART Transmitter.  This transmitter is able
// to transmit 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When transmit is complete o_Tx_done will be
// driven high for one clock cycle.
//
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87

  
module uart_tx_32
  (
   input       i_Clock,
   input       i_Tx_DV,
   input [31:0] i_Tx_Byte, 
	input [11:0] CLKS_PER_BIT,	
   input      o_Tx_Active,
	input [2:0] numData,
   output reg  o_Tx_Serial,
   output      o_Tx_Done
   );
  
  parameter s_IDLE         = 3'b000;
  parameter s_TX_START_BIT = 3'b001;
  parameter s_TX_DATA_BITS = 3'b010;
  parameter s_TX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;
   
  reg [2:0]    r_SM_Main     = 0;
  reg [11:0]    r_Clock_Count = 0;
  reg [2:0]    r_Bit_Index   = 0;
  reg [7:0]    r_Tx_Data     = 0;
  reg          r_Tx_Done     = 0;
  reg          r_Tx_Active   = 0;
  reg [1:0]    brojac        = 0;
  reg          i_Tx_DV_prethodni;
     
  always @(posedge i_Clock)
    begin
       
      case (r_SM_Main)
        s_IDLE :
          begin
            o_Tx_Serial   <= 1'b1;         // Drive Line High for Idle
            r_Tx_Done     <= 1'b0;
            r_Clock_Count <= 0;
            r_Bit_Index   <= 0;
             
            if (i_Tx_DV == 1'b1 && i_Tx_DV_prethodni == 1'b0 && o_Tx_Active ==1)
              begin
                r_Tx_Active <= 1'b1;
                r_Tx_Data   <= i_Tx_Byte [7:0];
                r_SM_Main   <= s_TX_START_BIT;
              end
				else if(brojac == 1)
						begin
						r_Tx_Active <= 1'b1;
                  r_Tx_Data   <= i_Tx_Byte [15:8];
                  r_SM_Main   <= s_TX_START_BIT;
						end
				else if (brojac == 2)
						begin
						r_Tx_Active <= 1'b1;
                  r_Tx_Data   <= i_Tx_Byte [23:16];
                  r_SM_Main   <= s_TX_START_BIT;
						end
				else if(brojac == 3)
						begin
						r_Tx_Active <= 1'b1;
                  r_Tx_Data   <= i_Tx_Byte [31:24];
                  r_SM_Main   <= s_TX_START_BIT;
						end
            else
              r_SM_Main <= s_IDLE;
          end // case: s_IDLE
         
         
        // Send out Start Bit. Start bit = 0
        s_TX_START_BIT :
          begin
            o_Tx_Serial <= 1'b0;
             
            // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_START_BIT;
              end
            else
              begin
                r_Clock_Count <= 0;
                r_SM_Main     <= s_TX_DATA_BITS;
              end
          end // case: s_TX_START_BIT
         
         
        // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
        s_TX_DATA_BITS :
          begin
            o_Tx_Serial <= r_Tx_Data[r_Bit_Index];
             
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_DATA_BITS;
              end
            else
              begin
                r_Clock_Count <= 0;
                 
                // Check if we have sent out all bits
                if (r_Bit_Index < 7)
                  begin
                    r_Bit_Index <= r_Bit_Index + 1;
                    r_SM_Main   <= s_TX_DATA_BITS;
                  end
                else
                  begin
                    r_Bit_Index <= 0;
                    r_SM_Main   <= s_TX_STOP_BIT;
                  end
              end
          end // case: s_TX_DATA_BITS
         
         
        // Send out Stop bit.  Stop bit = 1
        s_TX_STOP_BIT :
          begin
            o_Tx_Serial <= 1'b1;
             
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_STOP_BIT;
              end
            else
              begin
                r_Tx_Done     <= 1'b1;
                r_Clock_Count <= 0;
                r_SM_Main     <= s_CLEANUP;
                r_Tx_Active   <= 1'b0;
              end
          end // case: s_Tx_STOP_BIT
         
         
        // Stay here 1 clock
        s_CLEANUP :
          begin
				if(brojac == 0)
					begin
						o_Tx_Serial   <= 1'b1;         // Drive Line High for Idle
						r_Tx_Done     <= 1'b0;
						r_Clock_Count <= 0;
						r_Bit_Index   <= 0;
						if (numData == 4)
							brojac = 1;
						else if(numData == 1) begin
							brojac = 0;
							r_Tx_Done <= 1'b1;
							r_SM_Main <= s_IDLE;
						end
						else
							brojac = brojac+(5-numData);
							
						r_Tx_Done <= 1'b1;
						r_SM_Main <= s_IDLE;
					end
				else if(brojac == 1)
					begin
						brojac = 2;
						r_Tx_Done <= 1'b1;
						r_SM_Main <= s_IDLE;
					end
				else if(brojac == 2)
					begin
						brojac = 3;
						r_Tx_Done <= 1'b1;
						r_SM_Main <= s_IDLE;
					end
				else
					begin
					brojac = 0;
					r_Tx_Done <= 1'b1;
					r_SM_Main <= s_IDLE;
					end
          end
         
         
        default :
          r_SM_Main <= s_IDLE;
         
      endcase
		i_Tx_DV_prethodni <= i_Tx_DV;
    end
 
  assign o_Tx_Done   = r_Tx_Done;
   
endmodule