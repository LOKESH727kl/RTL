

module up_down_cnt(
		input cnt_clk,
		input cnt_rst_n,
		input up_pulse,
		input down_pulse,
		input load_pulse,
		input load_en,
		//input [16:0] load_value,
		output logic [16:0] count_out,
		output logic out_pulse
);
always_ff @ (posedge cnt_clk or negedge cnt_rst_n)begin
	if(!cnt_rst_n) count_out <= 17'h0;
	else begin 
		if(load_en) begin
			if(load_pulse)			count_out <= 17'h15180;
			else if (down_pulse)	count_out <= (count_out == 17'h0) ?	17'h15180 : count_out - 1'b1;
			else if (count_out == (17'h100)  | count_out == (17'hE10) |count_out == (17'h15180)) 	out_pulse <= 1'b1;
			else out_pulse <= 1'b0;
			end 
		else 
			if(up_pulse)	count_out <= (count_out == 17'h15180) ?	17'h0 : count_out + 1'b1;
			else if (count_out == (17'h100)  | count_out == (17'hE10) |count_out == (17'h15180)) 	out_pulse <= 1'b1;
			else out_pulse <= 1'b0;
	end
end
endmodule



/*
if(up_pulse)
	if(count_out == 17'h0) count_out <= 17'0
	else count_out <= count_out + 1'b1;
	else if (count_out == (17'h100)  | count_out == (17'hE10) |count_out == (17'h15180)) 	out_pulse <= 1'b1;
	else out_pulse <= 1'b0;*/