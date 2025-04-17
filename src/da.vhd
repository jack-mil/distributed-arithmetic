-- Engineer     : Jackson Miller
-- Date         : 04/11/2025
-- Name of file : da.vhd
-- Description  : implements a signed Distributed Arithmetic,
--                with 4 signed input vectors. Each is 4-bit wide.
--                The coefs are also 4-bit wide signed numbers

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

use work.util.clog2;

entity da is
  generic (
    WIDTH : positive := 4; -- should be a power of 2 word-size (e.g. 4/8/16)

    -- Filter coefficients. Identity filter by default (y[n]=x[n])
    A0 : integer := 1; -- Coefficient 0
    A1 : integer := 0; -- Coefficient 1
    A2 : integer := 0; -- Coefficient 2
    A3 : integer := 0  -- Coefficient 3
  );
  port (
    -- input side
    CLK       : in    std_logic;          -- system clock
    RST       : in    std_logic;          -- synchronous active-high reset
    DATA_IN_0 : in    signed(WIDTH - 1 downto 0); -- multiplies with coef_0
    DATA_IN_1 : in    signed(WIDTH - 1 downto 0); -- multiplies with coef_1
    DATA_IN_2 : in    signed(WIDTH - 1 downto 0); -- multiplies with coef_2
    DATA_IN_3 : in    signed(WIDTH - 1 downto 0); -- multiplies with coef_3
    IN_VALID  : in    std_logic;          -- indicate all input data is valid
    NEXT_IN   : out   std_logic;          -- high if ready to get valid data. low if busy
    -- output side
    DATA_OUT  : out   signed((2+WIDTH*2) - 1 downto 0); -- output of sum-of-products (4 sums of 4x4 multiplication = log2(4)+8 bits = 10bits)
    OUT_VALID : out   std_logic           -- high when output is complete
  );
end entity da;


architecture arch of da is

  constant DEPTH : POSITIVE := 4; -- number of inputs (4)

  constant LUT_SIZE : positive := clog2(DEPTH) + WIDTH;

  constant MAX : natural := WIDTH - 1;

  -- --------- ROM LUT ----------
  function ROM(addr : unsigned(DEPTH-1 downto 0)) return signed is
    -- additional bits required for DEPTH sums of WIDTH bits
    variable result : integer;
  begin
    case addr is
      when "0000" => result := 0;
      when "0001" => result := A3;                -- -5
      when "0010" => result := A2;                -- -8
      when "0011" => result := A2 + A3;           -- -13
      when "0100" => result := A1;                -- +3
      when "0101" => result := A1 + A3;           -- -2
      when "0110" => result := A1 + A2;           -- -5
      when "0111" => result := A1 + A2 + A3;      -- -10
      when "1000" => result := A0;                -- +7
      when "1001" => result := A0 + A3;           -- +2
      when "1010" => result := A0 + A2;           -- -1
      when "1011" => result := A0 + A2 + A3;      -- -6
      when "1100" => result := A0 + A1;           -- +10
      when "1101" => result := A0 + A1 + A3;      -- +5
      when "1110" => result := A0 + A1 + A2;      -- +2
      when "1111" => result := A0 + A1 + A2 + A3; -- -3
      when others => result := 0;
    end case;
    return to_signed(result, LUT_SIZE);
  end function;

  -- ----------------- Define Internal Signals -----------------

  -- --------- Stage 1 --------
  signal data_0_p1 : signed(MAX downto 0) := (others => '0');
  signal data_1_p1 : signed(MAX downto 0) := (others => '0');
  signal data_2_p1 : signed(MAX downto 0) := (others => '0');
  signal data_3_p1 : signed(MAX downto 0) := (others => '0');
  signal valid_p1  : std_logic            := '0'; -- stage one data is valid
  signal stall_p1  : std_logic            := '0'; -- prevent more input while processing
  signal count_p1  : natural range 0 to MAX := 0; -- count N=WIDTH bits at a time

  signal addr      : unsigned(DEPTH-1 downto 0);        -- current input bits
  signal data_lut  : signed(LUT_SIZE-1 downto 0); -- look-up data

  -- --------- Stage 2 --------
  signal acc_p2      : signed(DATA_OUT'range) := (others => '0'); -- output accumulator
  signal valid_p2    : std_logic              := '0'; -- second stage (output) complete when '1'
  signal count_equ_3 : std_logic;                 -- internal flag

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
        count_p1 <= 0;
      elsif (valid_p1 = '1') then
        if count_p1 = MAX then
          count_p1 <= 0;
        else
          count_p1 <= count_p1 + 1;
        end if;
      end if;
    end if;
  end process COUNT_BITS;

  -- prevent more input until N (4) cycles of valid data
  GEN_STALL : process (valid_p1, count_p1)
  begin
    if count_p1 = MAX then -- finished
      stall_p1 <= '0';
    elsif valid_p1='1' then -- starting
      stall_p1 <= '1';
    else
      stall_p1 <= '0';
    end if;
  end process GEN_STALL;

  -- --------- Stage 2 --------

  -- Generate the addr according to the current cycle
  -- MSB is bit from data_0, LSB is bit from data_3
  with count_p1 select addr <=
    data_0_p1(0) & data_1_p1(0) & data_2_p1(0) & data_3_p1(0) when 0,
    data_0_p1(1) & data_1_p1(1) & data_2_p1(1) & data_3_p1(1) when 1,
    data_0_p1(2) & data_1_p1(2) & data_2_p1(2) & data_3_p1(2) when 2,
    data_0_p1(3) & data_1_p1(3) & data_2_p1(3) & data_3_p1(3) when 3,
    (others => '0') when others;

  -- current bits drive the lut output
  data_lut <= ROM(addr);

  -- we use a dedicated signal here because the conversion from boolean to std_logic is bit complicated
  count_equ_3 <= '1' when count_p1 = MAX else
                 '0';

  -- Perform the shift and accumulate operation
  -- to generate the output signal
  SHIFT_AND_SUM : process (CLK, RST) is
    variable data_lut_shift : signed(acc_p2'range);
  begin
    if rising_edge(CLK) then
      if (RST = '1') then
        valid_p2 <= '0';
        acc_p2 <= (others => '0');
      else
        valid_p2 <= count_equ_3;
        data_lut_shift := resize(data_lut, data_lut_shift'length);
        data_lut_shift := shift_left(data_lut_shift, count_p1);
        if (count_p1 = 0) then
          acc_p2 <= data_lut_shift; -- reset old data
        elsif (count_p1 = MAX) then
          acc_p2 <= acc_p2 - data_lut_shift; -- reverse sign of final sum
        else
          acc_p2 <= acc_p2 + data_lut_shift; -- normal accumulate for middle cycles
        end if;
      end if;
    end if;
  end process SHIFT_AND_SUM;

  -- --------- Output --------
  NEXT_IN   <= not stall_p1;
  DATA_OUT  <= acc_p2;
  OUT_VALID <= valid_p2;

end arch;
