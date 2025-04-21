library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

use work.util.clog2;

entity LUT is
  generic (
    WIDTH : positive := 4;
    constant DEPTH : positive := 4;

    A0    : signed(WIDTH - 1 downto 0);
    A1    : signed(WIDTH - 1 downto 0);
    A2    : signed(WIDTH - 1 downto 0);
    A3    : signed(WIDTH - 1 downto 0)
  );
  port (
    ADDR_i : in    std_logic_vector(DEPTH - 1 downto 0);
    DATA_o : out   signed((clog2(DEPTH) + WIDTH)-1 downto 0)
  );
end entity LUT;

architecture RTL of LUT is

begin

  with ADDR_i select DATA_o <=
    (others => '0')   when "0000",
    resize(A3               , DATA_o'length) when "0001",
    resize(A2               , DATA_o'length) when "0010",
    resize(A2 + A3          , DATA_o'length) when "0011",
    resize(A1               , DATA_o'length) when "0100",
    resize(A1 + A3          , DATA_o'length) when "0101",
    resize(A1 + A2          , DATA_o'length) when "0110",
    resize(A1 + A2 + A3     , DATA_o'length) when "0111",
    resize(A0               , DATA_o'length) when "1000",
    resize(A0 + A3          , DATA_o'length) when "1001",
    resize(A0 + A2          , DATA_o'length) when "1010",
    resize(A0 + A2 + A3     , DATA_o'length) when "1011",
    resize(A0 + A1          , DATA_o'length) when "1100",
    resize(A0 + A1 + A3     , DATA_o'length) when "1101",
    resize(A0 + A1 + A2     , DATA_o'length) when "1110",
    resize(A0 + A1 + A2 + A3, DATA_o'length) when "1111",
    (others => '0')   when others;

end architecture RTL;
