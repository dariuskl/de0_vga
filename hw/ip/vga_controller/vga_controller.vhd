------------------------------------------------------------------------------------------------------------------------
--! @file	vga_controller.vhd
--! @brief	This file contains the top level entity for the vga_controller component.
------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controller is
	port(
		-- Avalon Clock Sink
		csi_clk_snk_reset			: in	std_logic;								--! system reset
		csi_clk_snk_clk			: in	std_logic;								--! system clock
		
		-- Avalon MM Slave Interface "controll"
		avs_controll_write		: in	std_logic;								--! Control register interface: write
		avs_controll_address		: in	std_logic_vector (0 downto 0); 	--! Control register interface: register address
		avs_controll_writedata	: in	std_logic_vector (31 downto 0);	--! Control register interface: writedata
		
		-- Avalon MM Master Interface "dma"
		avm_dma_waitrequest		: in	std_logic;								--! DMA interface: waitrequest
		avm_dma_readdata			: in	std_logic_vector (63 downto 0);	--! DMA interface: readdata
		avm_dma_readdatavalid	: in	std_logic;								--! DMA interface: readdatavalid
		avm_dma_address			: out	std_logic_vector (31 downto 0);  --! DMA interface: SDRAM address in bytes
		avm_dma_read				: out	std_logic;								--! DMA interface: read
		avm_dma_byteenable		: out	std_logic_vector (7 downto 0);	--! DMA interface: byteenable
		avm_dma_burstcount		: out std_logic_vector (5 downto 0);	--! DMA interface: burstcount
		
		-- VGA outputs
		coe_vga_hs_export			: out	std_logic;								--! VGA H Sync
		coe_vga_vs_export			: out	std_logic;								--! VGA V Sync
		coe_vga_r_export			: out	std_logic_vector (3 downto 0);	--! VGA red component
		coe_vga_g_export			: out	std_logic_vector (3 downto 0);	--! VGA green component
		coe_vga_b_export			: out	std_logic_vector (3 downto 0)		--! VGA blue component
	);
end vga_controller;

architecture default of vga_controller is
	
	component vga_controller_registers
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
	
	component vga_controller_dma_vga_logic
		port(
			reset					: in	std_logic;
			clk50					: in	std_logic;
			ctrl_fb_base		: in	std_logic_vector (31 downto 0);
			vga_px_clk			: in	std_logic;
			vga_screen_act		: in	std_logic;
			R						: out	std_logic_vector (3 downto 0);
			G						: out	std_logic_vector (3 downto 0);
			B						: out	std_logic_vector (3 downto 0);
			dma_waitreq			: in	std_logic;
			dma_readdata		: in	std_logic_vector (63 downto 0);
			dma_readdatavalid	: in	std_logic;
			dma_read				: out	std_logic;
			dma_address			: out	std_logic_vector (31 downto 0);
			dma_burstcount		: out std_logic_vector (5 downto 0);
			dma_byte_en			: out	std_logic_vector (7 downto 0)
		);
	end component;
	
	component vga_controller_vga_signals
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
	
	ctrl: vga_controller_registers
	port map(
			clk50				=> csi_clk_snk_clk,
			reset				=> csi_clk_snk_reset,
			write_req		=> avs_controll_write,
			address			=> avs_controll_address,
			writedata		=> avs_controll_writedata,
			base_address	=> s_base_address,
			control_reg		=> s_control_reg
	);
	
	dma : vga_controller_dma_vga_logic
	port map(
		clk50					=> csi_clk_snk_clk,
		reset					=> not s_control_reg(0) or not s_v_sync,	-- GO-Bit nicht gesetzt oder VSync aktiv
		ctrl_fb_base		=> s_base_address,
		vga_px_clk			=> s_px_clk,
		vga_screen_act		=> s_screen_active,
		R						=> coe_vga_r_export,
		G						=> coe_vga_g_export,
		B						=> coe_vga_b_export,
		dma_waitreq			=> avm_dma_waitrequest,
		dma_readdata		=> avm_dma_readdata,
		dma_readdatavalid	=> avm_dma_readdatavalid,
		dma_read				=> avm_dma_read,
		dma_address			=> avm_dma_address,
		dma_burstcount		=> avm_dma_burstcount,
		dma_byte_en			=>	avm_dma_byteenable
	);
	
	vga_s : vga_controller_vga_signals
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