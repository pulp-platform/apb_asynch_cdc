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
// Module Name:    apb_slave_asynch                                           //
// Project Name:   NONE                                                       //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    The slave part of the apb cdc: the asynch apb transaction  //
//                 comes and this is converted in a synch apb transaction     //
//                 using the destination clock                                //
//                 req_i --> ack_o --> !req_i --> !ack_o                      //
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


module apb_slave_asynch
#(
   parameter int unsigned APB_DATA_WIDTH = 32,
   parameter int unsigned APB_ADDR_WIDTH = 32
)
(
   input logic                              clk,
   input logic                              rst_n,

   // MASTER PORT
   output logic [APB_ADDR_WIDTH-1:0]        PADDR_o,
   output logic [APB_DATA_WIDTH-1:0]        PWDATA_o,
   output logic                             PWRITE_o,
   output logic                             PSEL_o,
   output logic                             PENABLE_o,
   input  logic [APB_DATA_WIDTH-1:0]        PRDATA_i,
   input  logic                             PREADY_i,
   input  logic                             PSLVERR_i,


   // Slave ASYNCH PORT
   input  logic                             asynch_req_i,
   output logic                             asynch_ack_o,

   input  logic [APB_ADDR_WIDTH-1:0]        async_PADDR_i,
   input  logic [APB_DATA_WIDTH-1:0]        async_PWDATA_i,
   input  logic                             async_PWRITE_i,
   input  logic                             async_PSEL_i,

   output logic [APB_DATA_WIDTH-1:0]        async_PRDATA_o,
   output logic                             async_PSLVERR_o
);

    enum logic [1:0] { IDLE, WAIT_PREADY, ACK_UP  } NS, CS;
    logic req_sync0, req_sync, sample_req, sample_resp;

    always_ff @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            req_sync0  <= 1'b0;
            req_sync   <= 1'b0;
            CS         <= IDLE;

              PADDR_o        <='0;
              PWDATA_o       <='0;
              PWRITE_o       <='0;
              PSEL_o         <='0;
              async_PRDATA_o <='0;
              async_PSLVERR_o<='0; 

        end
        else
        begin
            req_sync0  <= asynch_req_i;
            req_sync   <= req_sync0;
            CS         <= NS;

            if(sample_req)
            begin
              PADDR_o  <= async_PADDR_i;
              PWDATA_o <= async_PWDATA_i;
              PWRITE_o <= async_PWRITE_i;
              PSEL_o   <= async_PSEL_i;
            end

            if(sample_resp)
            begin
              async_PRDATA_o  <= PRDATA_i;
              async_PSLVERR_o <= PSLVERR_i;  
            end
        end

    end




    always_comb
    begin

      sample_req  = 1'b0;
      sample_resp = 1'b0;

      PENABLE_o  = 1'b0;

      asynch_ack_o   = '0;    
      
      NS = CS;

      case(CS)
        IDLE: begin
            sample_req = req_sync;

            if(req_sync)
            begin
              NS = WAIT_PREADY;
            end
            else
            begin
              NS = IDLE;
            end
        end

        WAIT_PREADY:
        begin
            PENABLE_o   = 1'b1;
            sample_resp = PREADY_i; 
            if(PREADY_i)
            begin
              NS       = ACK_UP;
            end
            else
            begin
               NS = WAIT_PREADY;
            end
        end

        ACK_UP:
        begin
            asynch_ack_o  = 1'b1;
            if(~req_sync)
            begin
              NS = IDLE;
            end
            else
            begin
              NS = ACK_UP;
            end
        end

        default:
        begin
          NS = IDLE;
        end

      endcase // CS

    end


endmodule // apb_slave_asynch