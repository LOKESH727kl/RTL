`timescale 1ns/1ps

module tb_cxs_tx_256to512;

    // -------------------------------------------------
    // Clock & Reset
    // -------------------------------------------------
    logic cxs_clk;
    logic cxs_rst_n;

    // -------------------------------------------------
    // DUT Inputs
    // -------------------------------------------------
    logic          cxs_valid;
    logic          cxs_last;
    logic          cxs_activereq;
    logic          cxs_crdrtn;
    logic [1:0]    pkt_send_sts;
    logic [2:0]    cxs_prcltype;
    logic [13:0]   cxs_cntl;
    logic [255:0]  cxs_data;
    logic          rx_ready;

    // -------------------------------------------------
    // DUT Outputs
    // -------------------------------------------------
    logic          tx_valid;
    logic          tx_pkt_vld;
    logic [511:0]  tx_pkt_data;
    logic          cxs_activeack;
    logic          cxs_crdgnt;
    logic          cxs_deacthint;

    // -------------------------------------------------
    // DUT Instance
    // -------------------------------------------------
    cxs_tx_256to512 dut (
        .cxs_clk        (cxs_clk),
        .cxs_rst_n      (cxs_rst_n),
        .cxs_valid      (cxs_valid),
        .cxs_last       (cxs_last),
        .cxs_activereq  (cxs_activereq),
        .cxs_crdrtn     (cxs_crdrtn),
        .pkt_send_sts   (pkt_send_sts),
        .cxs_prcltype   (cxs_prcltype),
        .cxs_cntl       (cxs_cntl),
        .cxs_data       (cxs_data),
        .rx_ready       (rx_ready),
        .tx_valid       (tx_valid),
        .tx_pkt_vld     (tx_pkt_vld),
        .tx_pkt_data    (tx_pkt_data),
        .cxs_activeack  (cxs_activeack),
        .cxs_crdgnt     (cxs_crdgnt),
        .cxs_deacthint  (cxs_deacthint)
    );

    // -------------------------------------------------
    // Clock generation (100 MHz)
    // -------------------------------------------------
    always #5 cxs_clk = ~cxs_clk;
	// -------------------------------------------------
    // TASK: Send data ONLY when interface ready & credit
    // -------------------------------------------------
   task send_cxs_data(input [255:0] data);
    begin
    // Wait until interface is ready AND credit is granted
      wait (cxs_crdgnt);

        @(posedge cxs_clk);
        cxs_valid <= 1'b1;
        cxs_data  <= data;
    end
    endtask

    // -------------------------------------------------
    // Test Sequence
    // -------------------------------------------------
    initial begin
        // Defaults
        cxs_clk        = 0;
        cxs_rst_n      = 0;
        cxs_valid      = 0;
        cxs_last       = 0;
        cxs_activereq  = 0;
        cxs_prcltype   = 3'b000;
        cxs_cntl       = 14'h0;
        cxs_data       = 256'h0;
        rx_ready       = 0;

        // Reset
        #20;
        @(posedge cxs_clk);
        cxs_rst_n = 1;
      

        // -------------------------------------------------
        // TEST 1: Activation request, RX not ready
        // -------------------------------------------------
        $display("TEST1: actreq=1, rx_ready=0");
        @(posedge cxs_clk);
        cxs_last      = 1;
        cxs_activereq = 1;
        rx_ready      = 0;
        #30;

        // -------------------------------------------------
        // TEST 2: RX becomes ready → activation handshake
        // -------------------------------------------------
        $display("TEST2: rx_ready=1 → activeack");
        @(posedge cxs_clk);
        rx_ready = 1;
        //#60;

        // -------------------------------------------------
        // TEST 3: Send data after interface ready & credit
        // -------------------------------------------------
        $display("TEST3: sending data after credit grant");
       		cxs_cntl = 14'h10;	
      		send_cxs_data(256'h10);
//       	send_cxs_data(256'h20);
//       	send_cxs_data(256'h30);
//       	send_cxs_data(256'h40);
//      	send_cxs_data(256'h50);
//       	send_cxs_data(256'h60);
//       	send_cxs_data(256'h70);
		@(posedge cxs_clk);
        cxs_data  <= 256'h0;
      	cxs_cntl <= 14'h0;
        cxs_valid <= 1'b0;

        #40;

        // -------------------------------------------------
        // TEST 4: Deactivation
        // -------------------------------------------------
        $display("TEST4: deactivation");
        @(posedge cxs_clk);
        cxs_activereq = 0;
        #30;

        $display("SIMULATION COMPLETE");
        #30;$finish;
    end

    // -------------------------------------------------
    // Monitor (Checking internal buffer)
    // -------------------------------------------------
    initial begin
        $monitor(
            "T=%0t | actreq=%b rx_ready=%b | ack=%b | crdgnt=%b | cxs_valid=%b | data_buffer=%h,tx_pkt_vld=%b | tx_pkt_data=%h",
            $time,
            cxs_activereq,
            rx_ready,
            cxs_activeack,
            cxs_crdgnt,
            cxs_valid,
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
