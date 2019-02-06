////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Copyright 2018 ETH Zurich and University of Bologna.                       //
// Copyright and related rights are licensed under the Solderpad Hardware     //
// License, Version 0.51 (the "License"); you may not use this file except in //
// compliance with the License.  You may obtain a copy of the License at      //
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law  //
// or agreed to in writing, software, hardware and materials distributed under//
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR     //
// CONDITIONS OF ANY KIND, either express or implied. See the License for the //
// specific language governing permissions and limitations under the License. //
//                                                                            //
// Company:        Micrel Lab @ DEIS - University of Bologna                  //
//                    Viale Risorgimento 2 40136                              //
//                    Bologna - fax 0512093785 -                              //
//                                                                            //
// Engineer:       Igor Loi - igor.loi@unibo.it                               //
//                                                                            //
// Additional contributions by:                                               //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
// Create Date:    01/01/2019                                                 //
// Design Name:    APB CDC                                                    //
// Module Name:    apb_master_asynch                                          //
// Project Name:   NONE                                                       //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    The master part of the apb cdc: the apb transaction        //
//                 and source clock comes, and they are converted with a      //
//                 simple req_o --> ack_i --> !req_o --> !ack_i               //
//                                                                            //
//                                                                            //
//                                                                            //
// Revision:                                                                  //
// Revision v0.1 - 01/01/2019 : File Created                                  //
//                                                                            //
// Additional Comments:                                                       //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


module apb_master_asynch
#(
   parameter int unsigned APB_DATA_WIDTH = 32,
   parameter int unsigned APB_ADDR_WIDTH = 32
)
(
   input logic                              clk,
   input logic                              rst_n,

   // SLAVE PORT
   input  logic [APB_ADDR_WIDTH-1:0]        PADDR_i,
   input  logic [APB_DATA_WIDTH-1:0]        PWDATA_i,
   input  logic                             PWRITE_i,
   input  logic                             PSEL_i,
   input  logic                             PENABLE_i,
   output logic [APB_DATA_WIDTH-1:0]        PRDATA_o,
   output logic                             PREADY_o,
   output logic                             PSLVERR_o,


   // Mastwe ASYNCH PORT
   output logic                             asynch_req_o,
   input  logic                             asynch_ack_i,

   output logic [APB_ADDR_WIDTH-1:0]        async_PADDR_o,
   output logic [APB_DATA_WIDTH-1:0]        async_PWDATA_o,
   output logic                             async_PWRITE_o,
   output logic                             async_PSEL_o,

   input  logic [APB_DATA_WIDTH-1:0]        async_PRDATA_i,
   input  logic                             async_PSLVERR_i
);


    enum logic [1:0] { IDLE, REQ_UP, REQ_DOWN } NS, CS;
    logic ack_sync0, ack_sync;

    always_ff @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            ack_sync0  <= 1'b0;
            ack_sync   <= 1'b0;
            CS         <= IDLE;
        end
        else
        begin
            ack_sync0  <= asynch_ack_i;
            ack_sync   <= ack_sync0;
            CS         <= NS;
        end
    end


    always_comb
    begin
      NS = CS;

      asynch_req_o   = '0;
      PRDATA_o       = async_PRDATA_i;
      PREADY_o       = '0;
      PSLVERR_o      = async_PSLVERR_i;      
      async_PADDR_o  = PADDR_i;
      async_PWDATA_o = PWDATA_i;
      async_PWRITE_o = PWRITE_i;
      async_PSEL_o   = PSEL_i;

      case(CS)
        IDLE: begin
            if(PSEL_i & PENABLE_i)
            begin
              NS = REQ_UP;
            end
            else
            begin
              NS = IDLE;
            end
        end

        REQ_UP:
        begin
            asynch_req_o = 1'b1;
            if(ack_sync)
            begin
              NS       = REQ_DOWN;
              PREADY_o  = 1'b1;
            end
            else
            begin
               NS = REQ_UP;
            end
        end

        REQ_DOWN:
        begin
            asynch_req_o  = 1'b0;
            if(~ack_sync)
            begin
              NS = IDLE;
            end
            else
            begin
              NS = REQ_DOWN;
            end
        end

      default:
      begin
        NS = IDLE;
      end
      endcase // CS

    end

endmodule
