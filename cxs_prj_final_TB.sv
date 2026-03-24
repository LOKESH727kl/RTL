// ============================================================
// 							TEST-BENCH
// ============================================================

`timescale 1ns/1ps

module tb_cxs_tx_256to512;

    // -------------------------------------------------
    // Clock & Reset
    // -------------------------------------------------
    logic tx_cxs_clk;
    logic tx_cxs_rst_n;

    // -------------------------------------------------
    // DUT Inputs
    // -------------------------------------------------
    logic          tx_cxs_valid;
    logic          tx_cxs_last;
    logic          tx_cxs_activereq;
    logic          tx_cxs_crdrtn;
    logic [1:0]    pkt_send_sts;
    logic [2:0]    tx_cxs_prcltype;
    logic [13:0]   tx_cxs_cntl;
    logic [255:0]  tx_cxs_data;
    logic          rx_ready;

    // -------------------------------------------------
    // DUT Outputs
    // -------------------------------------------------
    logic          tx_valid;
    logic          tx_pkt_vld;
    logic [511:0]  tx_pkt_data;
    logic          tx_cxs_activeack;
    logic          tx_cxs_crdgnt;
    logic          tx_cxs_deacthint;

    // -------------------------------------------------
    // DUT Instance
    // -------------------------------------------------
    cxs_tx_256to512 dut (
        .tx_cxs_clk        (tx_cxs_clk),
        .tx_cxs_rst_n      (tx_cxs_rst_n),
        .tx_cxs_valid      (tx_cxs_valid),
        .tx_cxs_last       (tx_cxs_last),
        .tx_cxs_activereq  (tx_cxs_activereq),
        .tx_cxs_crdrtn     (tx_cxs_crdrtn),
        .pkt_send_sts   (pkt_send_sts),
        .tx_cxs_prcltype   (tx_cxs_prcltype),
        .tx_cxs_cntl       (tx_cxs_cntl),
        .tx_cxs_data       (tx_cxs_data),
        .rx_ready       (rx_ready),
        .tx_valid       (tx_valid),
        .tx_pkt_vld     (tx_pkt_vld),
        .tx_pkt_data    (tx_pkt_data),
        .tx_cxs_activeack  (tx_cxs_activeack),
        .tx_cxs_crdgnt     (tx_cxs_crdgnt),
        .tx_cxs_deacthint  (tx_cxs_deacthint)
    );

    // -------------------------------------------------
    // Clock generation (100 MHz)
    // -------------------------------------------------
    always #5 tx_cxs_clk = ~tx_cxs_clk;
	// -------------------------------------------------
    // TASK: Send data ONLY when interface ready & credit
    // -------------------------------------------------
   task send_tx_cxs_data(input [255:0] data);
    begin
    // Wait until interface is ready AND credit is granted
      wait (tx_cxs_crdgnt);

        @(posedge tx_cxs_clk);
        tx_cxs_valid <= 1'b1;
        //rx_ready = 0;
        tx_cxs_data  <= data;
    end
    endtask

    // -------------------------------------------------
    // Test Sequence
    // -------------------------------------------------
    initial begin
        // Defaults
        tx_cxs_clk        = 0;
        tx_cxs_rst_n      = 0;
        tx_cxs_valid      = 0;
        tx_cxs_last       = 0;
        tx_cxs_activereq  = 0;
        tx_cxs_prcltype   = 3'b000;
        tx_cxs_cntl       = 14'h0;
        tx_cxs_data       = 256'h0;
        rx_ready       = 0;

        // Reset
        #20;
        @(posedge tx_cxs_clk);
        tx_cxs_rst_n = 1;
      

        // -------------------------------------------------
        // TEST 1: Activation request, RX not ready
        // -------------------------------------------------
        $display("TEST1: actreq=1, rx_ready=0");
        @(posedge tx_cxs_clk);
        tx_cxs_last      = 1;
        tx_cxs_activereq = 1;
        rx_ready      = 0;
        #30;

        // -------------------------------------------------
        // TEST 2: RX becomes ready → activation handshake
        // -------------------------------------------------
        $display("TEST2: rx_ready=1 → activeack");
        @(posedge tx_cxs_clk);
        rx_ready = 1;
        #110
      	@(posedge tx_cxs_clk);
        rx_ready = 0;
      
        // -------------------------------------------------
        // TEST 3: Send data after interface ready & credit
        // -------------------------------------------------
        $display("TEST3: sending data after credit grant");
       		tx_cxs_cntl = 14'h25;
      		send_tx_cxs_data(256'h10);
			send_tx_cxs_data(256'h30);
//       	send_tx_cxs_data(256'h40);
//      	send_tx_cxs_data(256'h50);
//       	send_tx_cxs_data(256'h60);
//       	send_tx_cxs_data(256'h70);
		@(posedge tx_cxs_clk);
        tx_cxs_data  <= 256'h0;
        tx_cxs_valid <= 1'b0;

        #40;

        // -------------------------------------------------
        // TEST 4: Deactivation
        // -------------------------------------------------
        $display("TEST4: deactivation");
        @(posedge tx_cxs_clk);
        tx_cxs_activereq = 0;
        #30;

        $display("SIMULATION COMPLETE");
        #30;$finish;
    end

    // -------------------------------------------------
    // Monitor (Checking internal buffer)
    // -------------------------------------------------
    initial begin
        $monitor(
            "T=%0t | actreq=%b rx_ready=%b | ack=%b | crdgnt=%b | tx_cxs_valid=%b | data_buffer=%h,tx_pkt_vld=%b | tx_pkt_data=%h",
            $time,
            tx_cxs_activereq,
            rx_ready,
            tx_cxs_activeack,
            tx_cxs_crdgnt,
            tx_cxs_valid,
            dut.data_buf,
          	tx_pkt_vld,
          	tx_pkt_data
        );
    end

    // -------------------------------------------------
    // Dump waves
    // -------------------------------------------------
    initial begin
        $dumpfile("cxs_tx_256to512.vcd");
        $dumpvars(0, tb_cxs_tx_256to512);
    end

endmodule
