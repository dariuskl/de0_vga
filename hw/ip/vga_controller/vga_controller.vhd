library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controller is
	generic (
		DATAWIDTH				:	integer	:= 64;
		BUFFERWIDTH				:	integer	:= 32
	);
	port(
		-- Avalon Clock Sink
		csi_clk_snk_reset			:	in	std_logic;
		csi_clk_snk_clk			:	in	std_logic;
		
		-- Avalon MM Slave Interface "controll"
		avs_controll_write		:	in	std_logic;
		avs_controll_address		:	in	std_logic_vector(0 downto 0);  --slave address as words
		avs_controll_writedata	:	in	std_logic_vector(31 downto 0);
		-- Avalon MM Master Interface "dma"
		avm_dma_waitrequest		:	in	std_logic;
		avm_dma_readdata			:	in	std_logic_vector((DATAWIDTH-1) downto 0);
		avm_dma_address			:	out	std_logic_vector(31 downto 0);  --master address as bytes
		avm_dma_read				:	out	std_logic;
		avm_dma_byteenable		:	out	std_logic_vector(((DATAWIDTH/8)-1) downto 0);
		-- VGA outputs
		coe_vga_hs_export			:	out	std_logic;
		coe_vga_vs_export			:	out	std_logic;
		coe_vga_r_export			:	out	std_logic_vector (3 downto 0);
		coe_vga_g_export			:	out	std_logic_vector (3 downto 0);
		coe_vga_b_export			:	out	std_logic_vector (3 downto 0)
	);
end vga_controller;

architecture default of vga_controller is
	
	component vga_controll_slave
		port(
			clk50				:	in		std_logic;
			reset				:	in		std_logic;
			write_req		:	in		std_logic;
			address			:	in		std_logic_vector(0 downto 0);
			writedata		:	in		std_logic_vector(31 downto 0);
			base_address	:	out	std_logic_vector(31 downto 0);
			control_reg		:	out	std_logic_vector(31 downto 0)
		);
	end component;
	
	component dma_read_master
		generic(
			DATAWIDTH		:	integer := 64;
			BUFFERWIDTH		:	integer	:= 32
		);
		port(
			reset				:	in		std_logic;
			clk50				:	in		std_logic;
			ctrl_fb_base	:	in		std_logic_vector (31 downto 0);
			vga_px_clk		:	in		std_logic;
			vga_screen_act	:	in		std_logic;
			R					:	out	std_logic_vector (3 downto 0);
			G					:	out	std_logic_vector (3 downto 0);
			B					:	out	std_logic_vector (3 downto 0);
			dma_waitreq		:	in		std_logic;
			dma_data			:	in		std_logic_vector((DATAWIDTH-1) downto 0);
			dma_read			:	out	std_logic;
			dma_address		:	out	std_logic_vector(31 downto 0);
			dma_byte_en		:	out	std_logic_vector(((DATAWIDTH/8)-1) downto 0)
		);
	end component;
	
	component vga_signals
		port(
			reset				:	in		std_logic;
			clk50				:	in		std_logic;
			px_clk			:	out	std_logic;
			px_clk_locked	:	out	std_logic;
			screen_active	:	out 	std_logic;
			h_sync			:	out	std_logic;
			v_sync			:	out	std_logic
		);
	end component;
	
	signal s_px_clk			:	std_logic;
	signal s_buffer_data		:	std_logic_vector(11 downto 0);
	signal s_control_reg		:	std_logic_vector(31 downto 0);
	signal s_base_address	:	std_logic_vector(31 downto 0);
	signal s_read_buffer		:	std_logic;
	signal s_screen_active	:	std_logic;
	signal s_v_sync			:	std_logic;
	
begin
	
	ctrl: vga_controll_slave
	port map(
			clk50				=> csi_clk_snk_clk,
			reset				=> csi_clk_snk_reset,
			write_req		=> avs_controll_write,
			address			=> avs_controll_address,
			writedata		=> avs_controll_writedata,
			base_address	=> s_base_address,
			control_reg		=> s_control_reg
	);
	
	dma : dma_read_master
	generic map(
		DATAWIDTH		=> DATAWIDTH,
		BUFFERWIDTH		=> BUFFERWIDTH
	)
	port map(
		clk50				=> csi_clk_snk_clk,
		reset				=> not s_control_reg(0) or not s_v_sync,	-- GO-Bit nicht gesetzt oder VSync aktiv
		ctrl_fb_base	=> s_base_address,
		vga_px_clk		=> s_px_clk,
		vga_screen_act	=> s_screen_active,
		R					=> coe_vga_r_export,
		G					=> coe_vga_g_export,
		B					=> coe_vga_b_export,
		dma_waitreq		=> avm_dma_waitrequest,
		dma_data			=> avm_dma_readdata,
		dma_read			=> avm_dma_read,
		dma_address		=> avm_dma_address,
		dma_byte_en		=>	avm_dma_byteenable
	);
	
	vga_s : vga_signals
	port map(
			reset				=> not s_control_reg (0),
			clk50				=> csi_clk_snk_clk,
			px_clk			=> s_px_clk,
			px_clk_locked	=> open,
			screen_active	=> s_screen_active,
			h_sync			=> coe_vga_hs_export,
			v_sync			=> s_v_sync
	);
	coe_vga_vs_export <= s_v_sync;
end default;