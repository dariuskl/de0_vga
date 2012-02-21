library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
	port(
		aclr	:	in	std_logic;
		data	:	in	std_logic_vector(63 downto 0);
		rdclk	:	in	std_logic;
		rdreq	:	in	std_logic;
		wrclk	:	in	std_logic;
		wrreq	:	in	std_logic;
		q		:	out	std_logic_vector(63 downto 0);
		rdempty	:	out	std_logic;
		wrusedw	:	out	std_logic_vector(5 downto 0)
	);
end fifo;

architecture default of fifo is
	signal fifo_queue	:	array (0 to 31) of std_logic_vector(63 downto 0) := (others => (others => '0'));
	signal wp			:	integer	:=	0;
	signal prev_wp		:	integer	:=	0;
	signal rp			:	integer	:=	0;
	signal prev_rp		:	integer	:=	0;
	signal s_wrusedw	:	integer	:=	0;
	signal curr_rd		:	std_logic_vector(63 downto 0) := (others => '0');
begin
	wrusedw_calc : process(aclr,wp,rp,s_wrusedw) is
	begin
		if aclr = '1' then
			prev_wp <= 0;
			prev_rp <= 0;
			s_wrusedw <= 0;
		else
			if prev_wp /= wp then
				s_wrusedw <= s_wrusedw + 1;
			end if;
			prev_wp <= wp;
			if prev_rp /= rp then
				s_wrusedw <= s_wrusedw - 1;
			end if;
			prev_rp <= rp;
			if s_wrusedw = 32 then
				wrfull <= '1';
				rdempty <= '0'
			elsif s_wrusedw = 0 then
				wrfull <= '0';
				rdempty <= '1';
			else
				wrfull <= '0';
				rdempty <= '0';
			end if;
	end process;

	wrp : process(aclr,wrclk,wrreq) is
	begin
		if aclr = '1' then
			wp <= 0;
		elsif rising_edge(wrclk) then
			if wrreq = '1' then
				fifo_queue(wp) <= data;
				if wp = 31 then
					wp <= 0;
				else
					wp <= wp + 1;
				end if;
			end if;
		end if;
	end process;
	
	rdp : process(aclr,rdclk,rdreq) is
	begin
		if aclr = '1' then
			rp <= 0;
		elsif rising_edge(rdclk) then
			if rdreq = '1' then
				curr_rd <= fifo_queue(rp);
				if rp = 31 then
					rp <= 0;
				else
					rp <= rp + 1;
				end if;
			end if;
		end if;
	end process;
	
	q <= curr_rd;
	wrusedw <= std_logic_vector(to_unsigned(s_wrusedw,wrusedw'length));
	
end default;