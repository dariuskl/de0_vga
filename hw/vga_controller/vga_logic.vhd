library ieee;
use ieee.std_logic_1164.all;

entity vga_logic is

	port (
		
		reset		:	in		std_logic;
		
		ctrl_go		:	in	std_logic;
		
		-- dma read master inputs
		dma_read_buffer	:	out	std_logic;
		dma_buffer_data	:	in		std_logic_vector (11 downto 0);
		
		-- vga timing inputs
		px_clk			:	in		std_logic;	-- pixel clock
		data_active		:	in		std_logic;
		
		-- vga signal outputs
		R				:	out		std_logic_vector (3 downto 0);
		G				:	out		std_logic_vector (3 downto 0);
		B				:	out		std_logic_vector (3 downto 0)
		
	);

end vga_logic;

architecture default of vga_logic is
begin

	dma_read_buffer <= px_clk and data_active;

	vga: process (reset, px_clk, data_active, ctrl_go) is
		variable s_r : std_logic_vector(3 downto 0);
		variable s_g : std_logic_vector(3 downto 0);
		variable s_b : std_logic_vector(3 downto 0);
	begin
	
		if reset = '1' or ctrl_go = '0' then
			s_r := "0000";
			s_g := "0000";
			s_b := "0000";
		elsif px_clk'event and px_clk = '1' then
			s_r := "0000";
			s_g := "0000";
			s_b := "0000";
			if data_active = '1' then
				s_r := dma_buffer_data (11 downto 8);
				s_g := dma_buffer_data (7 downto 4);
				s_b := dma_buffer_data (3 downto 0);
			end if;
		end if;
		
		R <= s_r;
		G <= s_g;
		B <= s_b;
		
	end process;

end architecture;
