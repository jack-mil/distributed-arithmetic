-- Engineer     : Junyoung Hwang
-- Date         : 04/02/2025
-- Name of file : da.vhd
-- Description  : implements a signed Distributed Arithmetic,
--                with 4 signed input vectors. Each is 4-bit wide.
--                The coefs are also 4-bit wide signed numbers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity da is
  port (
       -- input side
       clk, rst       : in  std_logic;
       data_in_0      : in  signed (3 downto 0);
       data_in_1      : in  signed (3 downto 0);
       data_in_2      : in  signed (3 downto 0);
       data_in_3      : in  signed (3 downto 0);
       in_valid       : in  std_logic;
       next_in        : out std_logic;
       -- output side
       data_out       : out signed (9 downto 0);
       out_valid      : out std_logic
       );
end da;
-- DO NOT MODIFY PORT NAMES ABOVE

architecture arch of da is
  -- ----------------- Define Intermediate Signals -----------------
  type array16x5b_t  is array (0 to 15) of signed (4 downto 0);
  -- --------- ROM ----------
  --TODO (Fill the array)
  signal ROM : array16x5b_t := (


  );

  -- --------- Stage 1 --------
  signal data_0_p1 : signed (3 downto 0);
  signal data_1_p1 : signed (3 downto 0);
  signal data_2_p1 : signed (3 downto 0);
  signal data_3_p1 : signed (3 downto 0);
  signal valid_p1  : std_logic;
  signal stall_p1  : std_logic;
  signal count_p1  : unsigned (1 downto 0);

  signal addr          : unsigned (3 downto 0);
  signal data_lut      : signed (4 downto 0);

  -- --------- Stage 2 --------
  signal acc_sig     : signed (9 downto 0);
  signal acc_p2      : signed (9 downto 0);
  signal count_equ_3 : std_logic;
  signal valid_p2    : std_logic;

begin
  -- --------- Stage 1 --------
  process (clk) 
  begin
    if (rising_edge(clk)) then 
      if (rst = '1') then
        valid_p1 <= '0';
      elsif (stall_p1 = '0') then
        valid_p1 <= in_valid;
        if (in_valid = '1') then
          data_0_p1 <= data_in_0;
          data_1_p1 <= data_in_1;
          data_2_p1 <= data_in_2;
          data_3_p1 <= data_in_3;
        end if;
      end if;
    end if;
  end process;

  -- reset counter as part of the valid path
  process (clk) 
  begin
    if (rising_edge(clk)) then 
      if (rst = '1') then
        count_p1 <= (others => '0');
      elsif (valid_p1 = '1') then
        count_p1 <= count_p1 + 1;
      end if;
    end if;
  end process;

  -- generating stall signal
  process (valid_p1, count_p1)
  begin
    --TODO


  end process;

  -- --------- Stage 2 --------

  -- Generating the addr
  --TODO



  process (count_p1, data_lut, acc_p2) 
  begin 
    --TODO


  end process;

  -- we use a dedicated signal here because the conversion from boolean to std_logic is bit complicated 
  -- in VHDL for the '*' line below
  count_equ_3 <= '1' when count_p1 = to_unsigned(3,2) else '0';

  process (clk) 
  begin
    --TODO


    
  end process;

  -- --------- Output --------
  next_in   <= not stall_p1;
  data_out  <= acc_p2;
  out_valid <= valid_p2;

end arch;

