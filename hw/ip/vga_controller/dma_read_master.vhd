library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dma_read_master is

	generic(
		DATAWIDTH	:	integer range 16 to 1024 	:= 64
	);

	port(
		reset				: in	std_logic;
		clk50				: in	std_logic;
		
		-- control and status registers
		ctrl_fb_base	: in	std_logic_vector (31 downto 0);	-- frame buffer base address
		
		-- vga timing inputs
		vga_px_clk		: in	std_logic;	-- pixel clock
		vga_screen_act	: in	std_logic;	-- currenlty in active screen area, real pixel data must be phased out
		
		-- vga signal outputs
		R	: out		std_logic_vector (3 downto 0);
		G	: out		std_logic_vector (3 downto 0);
		B	: out		std_logic_vector (3 downto 0);
		
		-- read master
		dma_waitreq			: in	std_logic;
		dma_readdata		: in	std_logic_vector ((DATAWIDTH-1) downto 0);
		dma_readdatavalid	: in	std_logic;
		dma_read				: out	std_logic;
		dma_address			: out	std_logic_vector (31 downto 0);
		dma_burstcount		: out std_logic_vector (5 downto 0);
		dma_byte_en			: out	std_logic_vector (((DATAWIDTH/8)-1) downto 0)
	);

end dma_read_master;

architecture default of dma_read_master is

	component fifo port
		(
			aclr		: in	std_logic;
			data		: in	std_logic_vector (63 downto 0);
			rdclk		: in	std_logic;
			rdreq		: in	std_logic;
			wrclk		: in	std_logic;
			wrreq		: in	std_logic;
			q			: out	std_logic_vector (63 downto 0);
			rdempty	: out	std_logic;
			wrfull	: out	std_logic;
			wrusedw	: out std_logic_vector (5 DOWNTO 0)
		);
	end component;
	
	constant PXPERREAD	:	integer range DATAWIDTH/12 to DATAWIDTH/12	:= DATAWIDTH/12;
	constant ADDR_INC		:	integer range DATAWIDTH/8 to DATAWIDTH/8		:= DATAWIDTH/8;
	-- the currently configured size of the FIFO
	constant BUFFERWIDTH	:	integer range 8 to 64		:= 63;
	
	-- fifo signals
	signal fifo_write, fifo_read, fifo_empty : std_logic;
	signal fifo_used : std_logic_vector (5 downto 0);
	signal q_sig : std_logic_vector (63 downto 0);
	
	-- dma_read_master_fsm signals
	type t_dma_state is (idle, nospace, reading, complete);
	signal dma_state	: t_dma_state := idle;
	signal address				: std_logic_vector (31 downto 0)	:= (others => '0');
	signal pending_reads		: integer range 0 to BUFFERWIDTH := BUFFERWIDTH/2;
	signal burstcount 		: integer range 0 to BUFFERWIDTH := BUFFERWIDTH/2;
	
	-- vga_fsm
	type t_vga_state is (idle, running);
	signal vga_state	: t_vga_state := idle;
	signal curr_segment : std_logic_vector ((DATAWIDTH-1) downto 0);
	signal pxcnt : integer range 0 to PXPERREAD		:= 0;

begin

	----------------------
	-- Instantiate FIFO
	---
	fifo_inst : fifo port map (
		aclr		=> reset,
		data	 	=> dma_readdata,
		rdclk		=> vga_px_clk,
		rdreq	 	=> fifo_read,
		wrclk		=> clk50,
		wrreq	 	=> fifo_write,
		q	 		=> q_sig,
		rdempty	=> fifo_empty,
		wrfull	=> open,
		wrusedw	=>	fifo_used
	);
	
	----------------------
	-- DMA MM-Read-Master
	---

	dma_read_master_fsm : process (reset, clk50, ctrl_fb_base) is
	begin
	
		if reset = '1' then
		
			dma_state <= idle;
			address <= ctrl_fb_base;
			pending_reads <= 0;
			
		elsif rising_edge(clk50) then
		
			-- ALWAYS decrement pending reads on received data
			if dma_readdatavalid = '1' then
				pending_reads <= pending_reads - 1;
			end if;
			
			case dma_state is
			
				when idle =>
					address <= ctrl_fb_base;
					dma_state <= nospace;
				
				when nospace =>
					if fifo_empty = '1' then
						burstcount <= BUFFERWIDTH;
						dma_state <= reading;
					elsif unsigned (fifo_used) <= BUFFERWIDTH/2 then
						burstcount <= (BUFFERWIDTH/2);
						dma_state <= reading;
					end if;
				
				when reading =>
					if dma_waitreq /= '1' then
						-- address += Word size in bytes * num of words bursted
						address <= std_logic_vector (unsigned (address) + (ADDR_INC * burstcount));
						
						-- check for valid readdata, adjust pending reads accordingly
						if dma_readdatavalid = '0' then
							pending_reads <= burstcount;
						else
							pending_reads <= burstcount - 1;
						end if;
						
						dma_state <= complete;
						
					end if;
				
				when complete =>
					if dma_readdatavalid = '1' then	-- a read returns
						if pending_reads = 1 then	-- last one?
							dma_state <= nospace;	-- wait for new space
						end if;
					end if;
			
			end case;
			
		end if;	-- edge-synchronous if
		
	end process;
	
	-- read when in running state and fifo not full
	dma_read <= '1' when dma_state = reading else '0';
	-- all bytes enabled
	dma_byte_en <= (others => '1');
	-- map internal address to ext. port
	dma_address <= address;
	-- number of words to burst
	dma_burstcount <= std_logic_vector (to_unsigned (burstcount, dma_burstcount'length));
	-- write data into fifo as it arrives, there MUST be space
	fifo_write <= dma_readdatavalid;
	
	----------------------
	-- VGA FSM
	---
	
	vga_fsm : process (vga_screen_act, vga_px_clk) is
	begin
	
		if (vga_screen_act = '0') then
		
			pxcnt <= 0;
			vga_state <= idle;
			
		elsif rising_edge (vga_px_clk) then
		
			vga_state <= running;
			
			if pxcnt /= 0 then
				-- rightshift current Segment by one px
				curr_segment <= "000000000000" & curr_segment ((DATAWIDTH-1) downto 12);
			end if;
			
			-- when first pixel requested and fifo not empty
			if pxcnt = 0 then
				if fifo_empty /= '1' then
					curr_segment <= q_sig;		-- get new segment
					pxcnt <= pxcnt + 1;
				end if;
			-- when last pixel requested
			elsif pxcnt < (PXPERREAD-1) then
				pxcnt <= pxcnt + 1;
			else
				pxcnt <= 0;
			end if;

		end if;
		
	end process;
		
	fifo_read <= '1' when vga_state = running and fifo_empty = '0' and pxcnt = 0 else '0';
	
	R	<= "0000" when vga_state = idle else	-- inactive screen area
			"1111" when fifo_empty = '1' and vga_state = running else	-- underflow
			curr_segment (11 downto 8);
	G	<= "0000" when vga_state = idle else	-- inactive screen area
			"0000" when fifo_empty = '1' and vga_state = running else	-- underflow
			curr_segment (7 downto 4);
	B	<= "0000" when vga_state = idle else	-- inactive screen area
			"0000" when fifo_empty = '1' and vga_state = running else	-- underflow
			curr_segment (3 downto 0);
	
end default;