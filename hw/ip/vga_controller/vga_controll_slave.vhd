library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controll_slave is
	port(
		clk50				: in	std_logic;
		reset				: in	std_logic;
		write_req		: in	std_logic;
		address			: in	std_logic_vector(0 downto 0);
		writedata		: in	std_logic_vector(31 downto 0);
		base_address	: out	std_logic_vector(31 downto 0);
		control_reg		: out	std_logic_vector(31 downto 0)
	);
end vga_controll_slave;

architecture default of vga_controll_slave is
	type t_reg is array(0 to 1) of std_logic_vector(31 downto 0);
	signal registers : t_reg;
begin

	regs: process(clk50,reset,write_req,address,writedata) is
	begin
		if reset = '1' then
			registers(0) <= std_logic_vector(to_unsigned(0,32));  --register for framebuffer base address
			registers(1) <= std_logic_vector(to_unsigned(0,32));  --control
		elsif rising_edge(clk50) then
			if write_req = '1' then
				case address is
					when "0" =>  --framebuffer base address
						registers(0) <= writedata;
					when "1" =>  --controll
						registers(1) <= writedata;
				end case;
			end if;
		end if;
	end process;
	
	base_address <= registers(0);
	control_reg <= registers(1);
	
end default;