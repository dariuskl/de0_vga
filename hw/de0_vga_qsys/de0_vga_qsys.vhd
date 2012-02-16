library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity de0_vga_qsys is

	port (
		CLOCK_50		: in 		std_logic;
		KEY			: in 		std_logic_vector (2 downto 0);
		LEDG			: out		std_logic_vector (9 downto 0);
		VGA_R			: out		std_logic_vector (3 downto 0);
		VGA_G			: out		std_logic_vector (3 downto 0);
		VGA_B			: out		std_logic_vector (3 downto 0);
		VGA_HS		: out		std_logic;
		VGA_VS		: out		std_logic;
		DRAM_CLK		: out 	std_logic;
		DRAM_CKE		: out 	std_logic;
		DRAM_ADDR	: out 	std_logic_vector (11 downto 0);
		DRAM_BA		: out 	std_logic_vector (1 downto 0);
		DRAM_CS_N	: out 	std_logic;
		DRAM_CAS_N	: out		std_logic;
		DRAM_RAS_N	: out		std_logic;
		DRAM_WE_N	: out 	std_logic;
		DRAM_DQ		: inout 	std_logic_vector (15 downto 0);
		DRAM_UDQM	: buffer std_logic;
		DRAM_LDQM	: buffer std_Logic
	);

end de0_vga_qsys;

architecture default of de0_vga_qsys is

	component system is
		port (
			-- global signals
			clk_clk			: in	std_logic;
			reset_reset_n	: in	std_logic;
			sysclks_areset_conduit_export		: in	std_logic;
			sysclks_locked_conduit_export		: out	std_logic;
			sysclks_phasedone_conduit_export	: out	std_logic;
			clk_sdram_clk	: out	std_logic;
			
			-- vga_0
			vga_0_hs_export	: out	std_logic;
			vga_0_vs_export	: out	std_logic;
			vga_0_r_export		: out	std_logic_vector (3 downto 0);
			vga_0_g_export		: out	std_logic_vector (3 downto 0);
			vga_0_b_export		: out	std_logic_vector (3 downto 0);
			
			-- sdram_0
			sdram_0_wire_addr		: out		std_logic_vector (11 downto 0);
			sdram_0_wire_ba 		: out		std_logic_vector (1 downto 0);
			sdram_0_wire_cas_n	: out 	std_logic;
			sdram_0_wire_cke		: out 	std_logic;
			sdram_0_wire_cs_n		: out 	std_logic;
			sdram_0_wire_dq		: inout	std_logic_vector (15 downto 0);
			sdram_0_wire_dqm		: out		std_logic_vector (1 downto 0);
			sdram_0_wire_ras_n	: out		std_logic;
			sdram_0_wire_we_n		: out		std_logic
		);
	end component;

	signal dqm : std_logic_vector (1 downto 0);
	
begin

	DRAM_UDQM <= dqm(1);
	DRAM_LDQM <= dqm(0);
	
	qsys_system_0 : system
		port map(
			-- global signals
			clk_clk									=> CLOCK_50,
			reset_reset_n							=> KEY (0),
			sysclks_areset_conduit_export		=> not KEY (0),
			sysclks_locked_conduit_export		=> LEDG (9),
			sysclks_phasedone_conduit_export	=> LEDG (8),
			clk_sdram_clk							=> DRAM_CLK,
			
			-- vga_0
			vga_0_hs_export		=> VGA_HS,
			vga_0_vs_export		=> VGA_VS,
			vga_0_r_export			=> VGA_R,
			vga_0_g_export			=> VGA_G,
			vga_0_b_export			=> VGA_B,
			
			-- the_sdram_0
			sdram_0_wire_addr		=> DRAM_ADDR,
			sdram_0_wire_ba 		=> DRAM_BA,
			sdram_0_wire_cas_n	=> DRAM_CAS_N,
			sdram_0_wire_cke		=> DRAM_CKE,
			sdram_0_wire_cs_n		=> DRAM_CS_N,
			sdram_0_wire_dq		=> DRAM_DQ,
			sdram_0_wire_dqm		=> dqm,
			sdram_0_wire_ras_n	=> DRAM_RAS_N,
			sdram_0_wire_we_n		=> DRAM_WE_N
		);
	
	LEDG (7 downto 0) <= "00000000";

end default;