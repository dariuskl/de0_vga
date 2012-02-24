library ieee;
use ieee.std_logic_1164.all;

entity vga_signals is

	port (
		reset				:	in		std_logic;
		clk50				:	in		std_logic;
		px_clk			:	out	std_logic;
		px_clk_locked	:	out	std_logic;
		screen_active	:	out	std_logic;	-- 1: data displayed on screen, 0: data not displayed on screen
		h_sync			:	out	std_logic;
		v_sync			:	out	std_logic
	);

end vga_signals;

architecture default of vga_signals is
	signal s_px_clk				: std_logic;
	signal s_hsync				: std_logic;
	signal s_vsync				: std_logic;
	signal s_hactive			: std_logic;
	signal s_vactive			: std_logic;
	shared variable px_cnt		: integer := 0;
	shared variable line_cnt	: integer := 0;
begin
	
	px_clk_generator : process (reset, clk50) is
	begin
	
		if reset = '1' then
			s_px_clk <= '0';
		elsif rising_edge (clk50) then
			s_px_clk <= not s_px_clk;
		end if;
		
	end process;
	
	px_clk_locked <= not reset;
	px_clk <= s_px_clk;

	-- 800 pixel(= 800 clock ticks) per line with:
	--	  8	pixel front porch
	--	 96	pixel h-sync signal(active low)
	--	 40	pixel back porch
	--	  8	pixel left border
	--	640	pixel displayed data
	--	  8	pixel right border
	
	-- 525 lines per field(= image) with:
	--	  2	lines front porch
	--	  2	lines v-sync signal(active low)
	--	 25	lines back porch
	--	  8	lines top border
	--	480	lines displayed data
	--	  8	lines bottom border

	counter: process(reset, s_px_clk) is
	begin
		if reset = '1' then
			px_cnt := 0;
		elsif s_px_clk'event and s_px_clk = '1' then
			if px_cnt >= 799 then					-- new line
				px_cnt := 0;
				if line_cnt >= 524 then				-- new image
					line_cnt := 0;
				else								-- next line
					line_cnt := line_cnt + 1;
				end if;
			else									-- next pixel in current line
				px_cnt := px_cnt + 1;
			end if;
		end if;
	end process;
	
	sync: process(reset, s_px_clk) is
	begin
		if reset = '1' then
			s_hsync <= '1';
			s_vsync <= '1';
			s_hactive <= '0';
			s_vactive <= '0';
		elsif s_px_clk'event and s_px_clk = '1' then
			s_hsync <= '1';
			s_vsync <= '1';
			s_hactive <= '0';
			s_vactive <= '0';
			if px_cnt > 7 and px_cnt <= 103 then			-- 96 pixel h-sync
				s_hsync <= '0';
			elsif px_cnt > 150 and px_cnt <= 790 then		-- 640 pixel data in 1 line, << 1 wegen Simergebnissen
				s_hactive <= '1';
			end if;
			if line_cnt > 1 and line_cnt <= 3 then			-- 2 lines v-sync
				s_vsync <= '0';
			elsif line_cnt > 36 and line_cnt <= 516 then	-- 480 lines data in 1 field
				s_vactive <= '1';
			end if;
		end if;
	end process;
	
	h_sync <= s_hsync;
	v_sync <= s_vsync;
	screen_active <= s_hactive and s_vactive;

end default;