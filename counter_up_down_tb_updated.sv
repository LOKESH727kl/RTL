module up_down_cnt_tb;
	logic cnt_clk;
	logic cnt_rst;
	logic cnt_in0;
	logic cnt_in1;
	logic [3:0] count_out;

up_down_cnt dut (
    	.cnt_clk(cnt_clk),
    	.cnt_rst(cnt_rst),
	.cnt_in0(cnt_in0),
 	.cnt_in1(cnt_in1),
   	.count_out(count_out)
  );
initial begin
    cnt_clk = 0;
    forever #5 cnt_clk = ~cnt_clk;
  end

initial begin
	cnt_rst = 0;
    	cnt_in0 = 0;
  	cnt_in1 = 0;
  #10 @(posedge cnt_clk)  cnt_rst = 1;
  #100 @(posedge cnt_clk) cnt_in0 = 0; 
         		  cnt_in1 = 1;
  #100 @(posedge cnt_clk) cnt_in0 = 1; 
         		  cnt_in1 = 0;
  #100 @(posedge cnt_clk) cnt_in0 = 1; 
         		  cnt_in1 = 1;
  #10 @(posedge cnt_clk)  cnt_rst = 1;
  #100 @(posedge cnt_clk)  $finish;
  end

initial begin
  $monitor("Time=%0t | Reset=%0b | in0=%0b |in1 =%0b| Count=%0d ",$time, cnt_rst, cnt_in0,cnt_in1,count_out);
end
initial begin
  $dumpfile("dump.vcd"); $dumpvars;
end
endmodule
