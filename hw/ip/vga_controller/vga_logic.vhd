library ieee;
use ieee.std_logic_1164.all;

entity vga_logic is

	port (
		-- dma read master inputs
		dma_read_buffer	: out	std_logic;
		dma_buffer_data	: in	std_logic_vector (11 downto 0);
		
		-- vga timing inputs
		px_clk			: in		std_logic;	-- pixel clock
		screen_active	: in		std_logic;	-- quasi nreset, currently in active area of the screen
		
		-- vga signal outputs
		R	: out		std_logic_vector (3 downto 0);
		G	: out		std_logic_vector (3 downto 0);
		B	: out		std_logic_vector (3 downto 0)
	);

end vga_logic;

architecture default of vga_logic is
begin

	dma_read_buffer <= px_clk and screen_active;

	vga: process (px_clk, screen_active) is
	begin
	
		if screen_active = '0' then
		
			R <= "0000";
			G <= "0000";
			B <= "0000";
			
		elsif rising_edge (px_clk) then
		
			R <= dma_buffer_data (11 downto 8);
			G <= dma_buffer_data (7 downto 4);
			B <= dma_buffer_data (3 downto 0);
			
		end if;
		
	end process;

end architecture;
