`define CXS_LOGIC ((MAX_PKT_PERFLIT == 2'b01) & (DATA_FLITWIDTH == 2'b01))

`define MAX_PKT_PERFLIT 2'b01

`define DATA_FLITWIDTH  2'b01


module top_cxs_pktzr_depktzr_tx(

    input  logic          tx_cxs_clk,      // System clock
    input  logic          tx_cxs_rst_n,    // Active-low asynchronous reset

    input  logic          tx_cxs_valid,			// Indicates valid CXS payload data
	input  logic          rx_ready,				// Receiver ready signal
    input  logic          tx_cxs_last,			// Indicates end of packet
    input  logic          tx_cxs_activereq,		// Request to activate link
    input  logic          tx_cxs_crdrtn,		// Credit return from receiver
    input  logic [2:0]    tx_cxs_prcltype,		// Protocol type field
    input  logic [13:0]   tx_cxs_cntl,			// CXS control field
    input  logic [255:0]  tx_cxs_data,			// 256-bit payload input

    output logic          tx_cxs_activeack,    	// Link activation acknowledge
    output logic          tx_cxs_crdgnt,       	// Credit grant to transmit
    output logic          tx_cxs_deacthint,    	// Hint for link deactivation
	output logic 		  pkt_send_sts_vld, 	// Packet send status valid flag
    output logic          tx_valid,         	// TX ready during activation
    output logic          tx_pkt_vld,       	// Valid packet output
	output logic 		  tx_header_err_vld,	// Header error valid flag (for header integrity check)
	output logic [1:0]    pkt_send_sts,     	// Packet transmission status
    output logic [511:0]  tx_pkt_data       	// 512-bit transmit packet
);

    // =========================================================
    // Internal Signals
    // =========================================================

    logic tx_cxs_activeack_deassert;   	// Used to determine when activation acknowledge must be cleared
	
	logic data_buf_en;					// Enables data buffering when valid data and credit are available

    logic data_buf_valid;    			// Indicates payload buffer contains valid data
	
    logic tx_dp;    					// Data parity (payload parity bit)

    logic tx_cp;    					// Control/header parity bit

    logic [1:0] cxs_tx_max_pkt_perflit;	// Encoded maximum packets per flit

    logic [1:0] cxs_tx_data_flitwidth;	// Encoded flit width configuration

    logic [255:0] tx_header;    		// 256-bit header register

    logic [255:0] data_buf;    			// 256-bit payload buffer

// ============================================================
// 			Parameter Configuration
// ============================================================

parameter MAX_PKT_PERFLIT = 2'b01;   // Max packets allowed per flit
parameter DATA_FLITWIDTH  = 2'b01;   // Encoded flit width (e.g., 256-bit mode)
  
`ifdef CXS_LOGIC

// ============================================================
// 			Link Activation Logic
// ============================================================

// tx_valid indicates that transmitter is ready when activation is requested
 
always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n) 
  if (!tx_cxs_rst_n)	tx_valid <= 1'b0;
  else 					tx_valid <= tx_cxs_activereq;
  
  always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n) 
  if (!tx_cxs_rst_n)	tx_cxs_crdgnt <= 1'b0;
  else 					tx_cxs_crdgnt <= tx_cxs_activereq; 

assign tx_cxs_activeack_deassert = (!(tx_cxs_activereq & tx_valid & rx_ready));
  
// ============================================================
// 			Activation Acknowledge Logic  
// ============================================================
//Case1 — tx_cxs_activeack and tx_cxs_crdgnt same cycle
always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n)
	if (!tx_cxs_rst_n)									tx_cxs_activeack <= 1'b0;
	else if (tx_cxs_activeack_deassert)					tx_cxs_activeack <= 1'b0;
	else if (tx_cxs_activereq & tx_valid & rx_ready)	tx_cxs_activeack <= 1'b1;


// ============================================================
// Deactivation Hint Logic
// ============================================================

always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n)
	if (!tx_cxs_rst_n)	tx_cxs_deacthint <= 1'b0;
	else				tx_cxs_deacthint <= (tx_cxs_activeack & (!tx_cxs_activereq)); 
		
// ============================================================
// Payload Buffer Capture
// ------------------------------------------------------------
// Purpose:
//   Captures incoming 256-bit payload when credit is granted
    
always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n)
  if (!tx_cxs_rst_n)	{data_buf_valid,data_buf} <= 257'h0;
  else					{data_buf_valid,data_buf} <= (data_buf_en) ? {tx_cxs_valid,tx_cxs_data[255:0]} : {data_buf_valid,data_buf};
  
always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n)
  if (!tx_cxs_rst_n)			data_buf_en <= 1'b0;
  else if (! tx_cxs_activereq)	data_buf_en <= 1'b0;
  else if (tx_cxs_crdgnt) 		data_buf_en <= 1'b1;	

assign cxs_tx_max_pkt_perflit = MAX_PKT_PERFLIT;
assign cxs_tx_data_flitwidth  = DATA_FLITWIDTH;  

assign tx_dp = (^(data_buf[255:0])); 	 //all the datfields ;
assign tx_cp = (^(tx_header[253:0])); 	//all the header fields ;

assign tx_header_err_vld = ((tx_header[253:52]!= 202'h0)	  	| 
                            (tx_header[51:49] != tx_cxs_prcltype)|
                            (tx_header[48:47] != 2'h1)		  	|
                            (tx_header[46:45] != 2'h1)		  	|
                            (tx_header[44]	  != tx_cxs_last)	|
                            (tx_header[43:14] != 30'h0)		  	|
                            (tx_header[13:0]  != tx_cxs_cntl[13:0])
                            );
  
assign tx_header = (data_buf_valid) ? {
  tx_dp,					// [255]
  tx_cp,  					// [254]
  202'h0,           		// [253:52]  (253-52+1 = 202 bits)
  tx_cxs_prcltype,			// [51:49]	 (3 bits)
  cxs_tx_max_pkt_perflit,	// [48:47]   (2 bits)
  cxs_tx_data_flitwidth,	// [46:45]   (2 bits)
  tx_cxs_last,        		// [44]
  30'h0,                  	// [43:14]   (30 bits)
  tx_cxs_cntl             	// [13:0]    (14 bits)
  } : 256'h0;


// ============================================================
// Packet Assembly and Output Stage
// ------------------------------------------------------------
// Purpose:
// Forms 512-bit transmit packet and drives TX interface.  
  
always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n) 
  if (!tx_cxs_rst_n)	{tx_pkt_vld,tx_pkt_data} <= 513'h0;
  else					{tx_pkt_vld,tx_pkt_data} <= (data_buf_valid) ? {1'b1,data_buf[255:0],tx_header[255:0]} : 513'h0;

// ============================================================
// Packet Send Status Generation
// ------------------------------------------------------------
// pkt_send_sts Encoding:
//   2'b00 → Default / Idle state
//   2'b01 → Packet successfully generated
//   2'b10 → Header error detected
//   2'b11 → Reserved
  
always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n)
  if (!tx_cxs_rst_n)	pkt_send_sts <= 2'b00;
  else 					pkt_send_sts <= (tx_header_err_vld) ? 2'b10 : (data_buf_valid) ? 2'b01 : 2'b00;

always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n)
  if (!tx_cxs_rst_n)	pkt_send_sts_vld <= 1'b0;
  else 					pkt_send_sts_vld <= (tx_header_err_vld | data_buf_valid);
  
`else 
  
// ============================================================
// CXS_LOGIC Disabled Mode
// ------------------------------------------------------------
// When CXS_LOGIC is not defined, the transmitter logic is disabled and all outputs are forced to default values.
// Purpose:
//   • Safe stub mode
//   • Integration without active TX logic
//   • Feature gating during development
// ============================================================
  
  
  assign tx_header = 256'h0;
  assign tx_cxs_activeack_deassert = 1'b0;
  assign tx_header_err_vld = 1'b0;
  
  always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n)
   	if (!tx_cxs_rst_n) 	data_tx_cnt <= 2'h0;
  	else 				data_tx_cnt <= 2'h0;
  
  always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n)
    if (!tx_cxs_rst_n) 	{data_buf_valid,data_buf} <= 257'h0;
  	else 				{data_buf_valid,data_buf} <= 257'h0;
  
  always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n) 
  	if (!tx_cxs_rst_n)	{tx_pkt_vld,tx_pkt_data} <= 513'h0;
  	else				{tx_pkt_vld,tx_pkt_data} <= 513'h0;
  
  
  always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n) 
  	if (!tx_cxs_rst_n)	tx_valid <= 1'b0;
  	else  				tx_valid <= 1'b0;
  
  always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n) 
  	if (!tx_cxs_rst_n)	tx_cxs_activeack <= 1'b0;
  	else 				tx_cxs_activeack <= 1'b0;
  
  always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n) 
  	if (!tx_cxs_rst_n)	tx_cxs_crdgnt <= 1'b0;
  	else				tx_cxs_crdgnt <= 1'b0;
  
  always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n) 
    if (!tx_cxs_rst_n) 	tx_cxs_deacthint <= 1'b0;
	else				tx_cxs_deacthint <= 1'b0;
	
   always_ff @(posedge tx_cxs_clk or negedge tx_cxs_rst_n) 
    if (!tx_cxs_rst_n)	pkt_send_sts_vld <= 1'b0;
	else 				pkt_send_sts_vld <= 1'b0;
 
`endif
endmodule