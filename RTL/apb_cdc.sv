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
// Create Date:    01/01/2019                                                 //
// Design Name:    APB CDC                                                    //
// Module Name:    apb_cdc                                                    //
// Project Name:   NONE                                                       //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This Block is a simple APB clocl domain crossin that       //
//                 uses a 4 phases approach. Should not be used if the        //
//                 performance are main concern. Is composed by master        //
//                 and slave part, than can be used separately to be placed   //
//                 in different clock/power domains, then route the asynch    //
//                 signals olver them                                         //
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

module apb_cdc
#(
   parameter int unsigned APB_DATA_WIDTH = 32,
   parameter int unsigned APB_ADDR_WIDTH = 32
)
(
   input logic                              src_clk,
   input logic                              src_rst_n,

   // SLAVE PORT
   input  logic [APB_ADDR_WIDTH-1:0]        src_PADDR_i,
   input  logic [APB_DATA_WIDTH-1:0]        src_PWDATA_i,
   input  logic                             src_PWRITE_i,
   input  logic                             src_PSEL_i,
   input  logic                             src_PENABLE_i,
   output logic [APB_DATA_WIDTH-1:0]        src_PRDATA_o,
   output logic                             src_PREADY_o,
   output logic                             src_PSLVERR_o,

   input logic                              dest_clk,
   input logic                              dest_rst_n,
   output logic [APB_ADDR_WIDTH-1:0]        dest_PADDR_o,
   output logic [APB_DATA_WIDTH-1:0]        dest_PWDATA_o,
   output logic                             dest_PWRITE_o,
   output logic                             dest_PSEL_o,
   output logic                             dest_PENABLE_o,
   input  logic [APB_DATA_WIDTH-1:0]        dest_PRDATA_i,
   input  logic                             dest_PREADY_i,
   input  logic                             dest_PSLVERR_i
);

   logic                             asynch_req;
   logic                             asynch_ack;
   logic [APB_ADDR_WIDTH-1:0]        async_PADDR;
   logic [APB_DATA_WIDTH-1:0]        async_PWDATA;
   logic                             async_PWRITE;
   logic                             async_PSEL;
   logic [APB_DATA_WIDTH-1:0]        async_PRDATA;
   logic                             async_PSLVERR;


  apb_master_asynch
  #(
     .APB_DATA_WIDTH ( APB_DATA_WIDTH ),
     .APB_ADDR_WIDTH ( APB_ADDR_WIDTH )
  )
  i_apb_master_asynch
  (
     .clk             ( src_clk        ),
     .rst_n           ( src_rst_n      ),

     // SLAVE PORT
     .PADDR_i         ( src_PADDR_i    ),
     .PWDATA_i        ( src_PWDATA_i   ),
     .PWRITE_i        ( src_PWRITE_i   ),
     .PSEL_i          ( src_PSEL_i     ),
     .PENABLE_i       ( src_PENABLE_i  ),
     .PRDATA_o        ( src_PRDATA_o   ),
     .PREADY_o        ( src_PREADY_o   ),
     .PSLVERR_o       ( src_PSLVERR_o  ),


     // Mastwe ASYNCH PORT
     .asynch_req_o    ( asynch_req     ),
     .asynch_ack_i    ( asynch_ack     ),
     .async_PADDR_o   ( async_PADDR    ),
     .async_PWDATA_o  ( async_PWDATA   ),
     .async_PWRITE_o  ( async_PWRITE   ),
     .async_PSEL_o    ( async_PSEL     ),
     .async_PRDATA_i  ( async_PRDATA   ),
     .async_PSLVERR_i ( async_PSLVERR  )
  );


  apb_slave_asynch
  #(
     .APB_DATA_WIDTH  ( APB_DATA_WIDTH ),
     .APB_ADDR_WIDTH  ( APB_ADDR_WIDTH )
  )
  i_apb_slave_asynch
  (
     .clk             ( dest_clk        ),
     .rst_n           ( dest_rst_n      ),

     .PADDR_o         ( dest_PADDR_o    ),
     .PWDATA_o        ( dest_PWDATA_o   ),
     .PWRITE_o        ( dest_PWRITE_o   ),
     .PSEL_o          ( dest_PSEL_o     ),
     .PENABLE_o       ( dest_PENABLE_o  ),
     .PRDATA_i        ( dest_PRDATA_i   ),
     .PREADY_i        ( dest_PREADY_i   ),
     .PSLVERR_i       ( dest_PSLVERR_i  ),

     .asynch_req_i    ( asynch_req      ),
     .asynch_ack_o    ( asynch_ack      ),
     .async_PADDR_i   ( async_PADDR     ),
     .async_PWDATA_i  ( async_PWDATA    ),
     .async_PWRITE_i  ( async_PWRITE    ),
     .async_PSEL_i    ( async_PSEL      ),
     .async_PRDATA_o  ( async_PRDATA    ),
     .async_PSLVERR_o ( async_PSLVERR   )
  );

endmodule // apb_cdc