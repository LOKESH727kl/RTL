module up_down_cnt_tb;
	logic cnt_clk;
	logic cnt_rst;
	logic cnt_en;
	logic [3:0] count_out;
up_down_cnt dut (
    .cnt_clk(cnt_clk),
    .cnt_rst(cnt_rst),
    .cnt_en(cnt_en),
    .count_out(count_out)
  );
initial begin
    cnt_clk = 0;
    forever #5 cnt_clk = ~cnt_clk;
  end

  initial begin
   // Initialize signals
    cnt_rst = 0;
    cnt_en  = 1;    // start with count-up mode
    #10 cnt_rst = 1;
    #100 cnt_en = 0; // Switch to count-down mode
    #100 cnt_rst = 0;
    #10 cnt_rst = 1;
    #100 $finish;
  end

  initial begin
    $monitor("Time=%0t | Reset=%0b | Enable=%0b | Count=%0d",$time, cnt_rst, cnt_en, count_out);
  end

endmodule












































