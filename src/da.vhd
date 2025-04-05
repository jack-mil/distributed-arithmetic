-- Engineer     : Jackson Miller
-- Date         : 04/11/2025
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
       CLK            : in  std_logic; -- system clock
       RST            : in  std_logic; -- synchronous active-high reset
       DATA_IN_0      : in  signed(3 downto 0); -- multiplies with coef_0
       DATA_IN_1      : in  signed(3 downto 0); -- multiplies with coef_1
       DATA_IN_2      : in  signed(3 downto 0); -- multiplies with coef_2
       DATA_IN_3      : in  signed(3 downto 0); -- multiplies with coef_3
       IN_VALID       : in  std_logic; -- indicate all input data is valid
       NEXT_IN        : out std_logic; -- high if ready to get valid data. low if busy
       -- output side
       DATA_OUT       : out signed(9 downto 0); -- output of sum-of-products
       OUT_VALID      : out std_logic -- high when output is complete
       );
end da;
-- DO NOT MODIFY PORT NAMES ABOVE

architecture arch of da is
  -- ----------------- Define Internal Signals -----------------
  -- --------- ROM ----------
  -- A0=7, A1=3, A2=-8, A3=-5
  constant A0 : signed(3 downto 0) := to_signed(7, 4);
  constant A1 : signed(3 downto 0) := to_signed(3, 4);
  constant A2 : signed(3 downto 0) := to_signed(-8, 4);
  constant A3 : signed(3 downto 0) := to_signed(-5, 4);

  function ROM(addr : unsigned(3 downto 0)) return signed is
    variable result : signed(4 downto 0);
  begin
      case addr is
          when "0000" => result := "00000";
          when "0001" => result := A3;
          when "0010" => result := A2;
          when "0011" => result := A2 + A3;
          when "0100" => result := A1;
          when "0101" => result := A1 + A3;
          when "0110" => result := A1 + A2;
          when "0111" => result := A1 + A2 + A3;
          when "1000" => result := A0;
          when "1001" => result := A0 + A3;
          when "1010" => result := A0 + A2;
          when "1011" => result := A0 + A2 + A3;
          when "1100" => result := A0 + A1;
          when "1101" => result := A0 + A1 + A3;
          when "1110" => result := A0 + A1 + A2;
          when "1111" => result := A0 + A1 + A2 + A3;
          when others => result := "00000";
      end case;
      return result;
  end function;

  -- type array16x5b_t is array (0 to 15) of signed(4 downto 0);
  -- constant ROM : array16x5b_t := (
  --       0, -- 0000
  --       -5, -- 0001
  --       -8, -- 0010
  --       -13, -- 0011
  --       3, -- 0100
  --       -2, -- 0101
  --       -5, -- 0110
  --       -10, -- 0111
  --       7, -- 1000
  --       2, -- 1001
  --       -1, -- 1010
  --       -6, -- 1011
  --       10, -- 1100
  --       5, -- 1101
  --       2, -- 1110
  --       -3  -- 1111
  -- );

  -- --------- Stage 1 --------
  signal data_0_p1 : signed (3 downto 0) := (others => '0');
  signal data_1_p1 : signed (3 downto 0) := (others => '0');
  signal data_2_p1 : signed (3 downto 0) := (others => '0');
  signal data_3_p1 : signed (3 downto 0) := (others => '0');
  signal valid_p1  : std_logic := '0'; -- stage one data is valid
  signal stall_p1  : std_logic := '0'; -- prevent more input while processing
  signal count_p1  : unsigned (1 downto 0) := "00";

  signal addr      : unsigned(3 downto 0); -- current input bits
  signal data_lut  : signed(4 downto 0); -- look-up data

  -- --------- Stage 2 --------
  signal acc_sig     : signed (9 downto 0);
  signal acc_p2      : signed (9 downto 0) := (others => '0');
  signal count_equ_3 : std_logic;
  signal valid_p2    : std_logic := '0';

begin
  -- --------- Stage 1 --------
  DATA_IN_p : process (CLK) is
  begin
    if rising_edge(CLK) then
      if (RST = '1') then
        valid_p1 <= '0';
      elsif (stall_p1 = '0') then -- if not waiting
        valid_p1 <= IN_VALID;
        if (IN_VALID = '1') then -- latch input when valid
          data_0_p1 <= DATA_IN_0;
          data_1_p1 <= DATA_IN_1;
          data_2_p1 <= DATA_IN_2;
          data_3_p1 <= DATA_IN_3;
        end if;
      end if;
    end if;
  end process DATA_IN_p;

  -- counter increments for every clock cycle data is valid
  COUNT_BITS : process (CLK) is
  begin
    if rising_edge(CLK) then
      if (RST = '1') then
        count_p1 <= (others => '0');
      elsif (valid_p1 = '1') then
        count_p1 <= count_p1 + 1; -- automatically rolls over
      end if;
    end if;
  end process COUNT_BITS;

  -- prevent more input until N (4) cycles of valid data
  GEN_STALL : process (valid_p1, count_p1)
  begin
    if valid_p1='1' and count_p1 /= "00" then -- starting
      stall_p1 <= '1';
    else
      stall_p1 <= '0';
    end if;
  end process GEN_STALL;

  -- --------- Stage 2 --------

  -- Generating the addr
  process (count_p1, data_lut, acc_p2)
    variable addr : unsigned(3 downto 0);
  begin
    case count_p1 is
      when "00" => addr := data_3_p1(0) & data_2_p1(0) & data_1_p1(0) & data_0_p1(0);
      when "01" => addr := data_3_p1(1) & data_2_p1(1) & data_1_p1(1) & data_0_p1(1);
      when "10" => addr := data_3_p1(2) & data_2_p1(2) & data_1_p1(2) & data_0_p1(2);
      when "11" => addr := data_3_p1(3) & data_2_p1(3) & data_1_p1(3) & data_0_p1(3);
      when others => null; -- shouldn't happen
    end case;
    data_lut <= ROM(addr);
    -- acc_p2 <= acc_p2 + data_lut;

  end process;

  -- we use a dedicated signal here because the conversion from boolean to std_logic is bit complicated
  -- in VHDL for the '*' line below ('*' line ???)
  count_equ_3 <= '1' when count_p1 = to_unsigned(3, 2) else '0';

  DATA_OUT_p : process (CLK) is
  begin
      if rising_edge(CLK) then
        if (RST = '1') then
          valid_p2 <= '0';
        else
          valid_p2 <= count_equ_3;
        end if;
      end if;
  end process DATA_OUT_p;

  -- --------- Output --------
  NEXT_IN   <= not stall_p1;
  DATA_OUT  <= acc_p2;
  OUT_VALID <= valid_p2;

end arch;
