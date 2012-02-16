library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dma_read_master is
	generic(
		DATAWIDTH	:	integer range 16 to 1024 	:= 64;
		BUFFERWIDTH	:	integer range 8 to 64		:= 32
	);
	port(
		reset				:	in		std_logic;
		clk50				:	in		std_logic;
		ctrl_go			:	in		std_logic;
		ctrl_fb_base	:	in		std_logic_vector(31 downto 0);
		vga_v_sync		:	in		std_logic;
		vga_read			:	in		std_logic;
		vga_data			:	out	std_logic_vector(11 downto 0);
		dma_waitreq		:	in		std_logic;
		dma_data			:	in		std_logic_vector((DATAWIDTH-1) downto 0);
		dma_read			:	out	std_logic;
		dma_address		:	out	std_logic_vector(31 downto 0);
		dma_byte_en		:	out	std_logic_vector(((DATAWIDTH/8)-1) downto 0)
	);
end dma_read_master;

architecture default of dma_read_master is
	constant PXPERREAD	:	integer range DATAWIDTH/12 to DATAWIDTH/12	:= DATAWIDTH/12;
	constant ADDR_INC		:	integer range DATAWIDTH/8 to DATAWIDTH/8		:= DATAWIDTH/8;
	type TFIFO is array(0 to (BUFFERWIDTH-1)) of std_logic_vector((DATAWIDTH-1) downto 0);
	signal fifo			:	TFIFO										:= (others => (others => '0'));
	signal slots_used	:	integer range 0 to BUFFERWIDTH	:= 0;
	signal wp			:	integer range 0 to BUFFERWIDTH	:= 0;
	signal rp			:	integer range 0 to BUFFERWIDTH	:= 0;
	signal prev_rp		:	integer range 0 to BUFFERWIDTH	:= 0;
	signal address		:	unsigned(31 downto 0)				:= (others => '0');
	signal pxcnt		:	integer range 0 to PXPERREAD		:= 0;
	signal prev_pxcnt	:	integer range 0 to PXPERREAD		:= 0;
begin

	dma_byte_en <= (others => '1');

	dma: process(reset,clk50,ctrl_go,ctrl_fb_base,vga_v_sync,vga_read,dma_waitreq,dma_data,fifo,slots_used,wp,rp,prev_rp,address,pxcnt,prev_pxcnt) is
		type TSTATE is (init,request,waiting,complete);
		variable state	:	TSTATE	:= init;
	begin
		if reset = '1' then
			state := init;
		elsif rising_edge(clk50) then
			if prev_rp /= rp then
				slots_used <= slots_used - 1;
			end if;
			prev_rp <= rp;
			if (prev_pxcnt /= pxcnt) and (pxcnt /= 0) then
				fifo(rp) <= "000000000000" & fifo(rp)((DATAWIDTH-1) downto 12);
			end if;
			prev_pxcnt <= pxcnt;
			case state is
				when init =>
					slots_used <= 0;
					wp <= 0;
					prev_rp <= 0;
					address <= unsigned(ctrl_fb_base);
					if ctrl_go = '1' and vga_v_sync = '1' then
						state := request;
					end if;
				when request =>
					if ctrl_go = '0' or vga_v_sync = '0' then
						state := init;
					elsif dma_waitreq = '1' then
						state := waiting;
					end if;
				when waiting =>
					if ctrl_go = '0' or vga_v_sync = '0' then
						state := init;
					elsif dma_waitreq = '0' then
						fifo(wp) <= dma_data;
						if (wp + 1) < BUFFERWIDTH then
							wp <= wp + 1;
						else
							wp <= 0;
						end if;
						slots_used <= slots_used + 1;
						state := complete;
					end if;
				when complete =>
					if ctrl_go = '0' or vga_v_sync = '0' then
						state := init;
					elsif (slots_used + 1) <= BUFFERWIDTH then
						address <= address + ADDR_INC;
						state := request;
					end if;
			end case;
			dma_read <= '0';
			dma_address <= std_logic_vector(address);
			case state is
				when request =>
					dma_read <= '1';
				when waiting =>
					dma_read <= '1';
				when others =>
			end case;
		end if;
	end process;
	
	vga: process(reset,clk50,ctrl_go,ctrl_fb_base,vga_v_sync,vga_read,dma_waitreq,dma_data,fifo,slots_used,wp,rp,prev_rp,address,pxcnt) is
		variable curr_px	:	std_logic_vector(11 downto 0);
	begin
		if (reset = '1') or (vga_v_sync = '0') or (ctrl_go = '0') then
			rp <= 0;
			pxcnt <= 0;
			curr_px := "000000000000";
		elsif rising_edge(vga_read) then
			curr_px := "000000000000";
			if slots_used > 0 then
				curr_px := fifo(rp)(11 downto 0);
				if (pxcnt < (PXPERREAD-1)) then
					pxcnt <= pxcnt + 1;
				else
					pxcnt <= 0;
					if (rp + 1) < BUFFERWIDTH then
						rp <= rp + 1;
					else
						rp <= 0;
					end if;
				end if;
			end if;
		end if;
		vga_data <= curr_px;
	end process;
	
end default;