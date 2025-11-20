module up_down_cnt(
		input cnt_clk,
		input cnt_rst,
		input cnt_en,
		output logic [3:0] count_out
);
always_ff @ (posedge cnt_clk or negedge cnt_rst)begin
	if(!cnt_rst) count_out <= 4'h0;
	else begin 
		if(cnt_en) begin
			if(count_out == 4'hf)  count_out <= 4'h0;
			else count_out <= count_out + 4'h1;
		end

		else begin
			if(count_out == 4'h0)  count_out <= 4'hf;
			else count_out <= count_out - 4'h1;
		end
	end
end
endmodule
