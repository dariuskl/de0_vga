library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_px_clk_pll is
	port(
		areset	:	in	std_logic;
		inclk0	:	in	std_logic;
		c0		:	out	std_logic
	);
end vga_px_clk_pll;

architecture default of vga_px_clk_pll is
	signal clk25	:	std_logic	:= '0';
begin
	process(areset,inclk0) is
	begin
		if areset = '1' then
			clk25 <= '0';
		elsif rising_edge(inclk0) then
			clk25 <= not clk25;
		end if;
	end process;
	c0 <= clk25;
end default;