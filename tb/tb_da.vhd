-- Engineer     : Jackson Miller
-- Date         : 04/17/2025
-- Name of file : tb_da.vhd
-- Description  : test bench for da.vhd

library std;
  use std.env.all;
  use std.textio.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;
  use ieee.std_logic_textio.all;


entity TB_DA is
  generic (
    INPUT_FILE_STR   : string := "input_seq.txt";
    OUTPUT_FILE_STR  : string := "output.txt";
    OUTPUT_CYCLE_STR : string := "output_cycle.txt"
  );
end entity TB_DA;

architecture TB_ARCH of TB_DA is

  constant WIDTH : POSITIVE := 4; -- 4 bit input and coefficients
  subtype input_t is signed(WIDTH - 1 downto 0);
  subtype output_t is signed((2 + WIDTH * 2) - 1 downto 0);

  -- -------- Coefficients -------- --
  -- Must fit in INPUT_WIDTH bits (signed 2's complement)
  constant A0 : integer := 7;  -- Coefficient 0
  constant A1 : integer := 3;  -- Coefficient 1
  constant A2 : integer := -8; -- Coefficient 2
  constant A3 : integer := -5;  -- Coefficient 3

  -- signals local only to the present ip
  signal clk, rst        : std_logic;
  signal data_in_0       : input_t;
  signal data_in_1       : input_t;
  signal data_in_2       : input_t;
  signal data_in_3       : input_t;
  signal in_valid        : std_logic := '0';
  signal next_in         : std_logic;
  signal data_out        : output_t;
  signal out_valid       : std_logic;
  -- signals related to the file operations
  file input_data_file   : text;
  file output_file       : text;
  file output_cycle_file : text;
  -- time
  constant t             : time := 20 ns;
  signal   cycle_count   : integer;
  signal   hanged_count  : integer;

begin

  DUT: entity work.da
   generic map(
      WIDTH => WIDTH,
      A0 => A0,
      A1 => A1,
      A2 => A2,
      A3 => A3
  )
   port map(
      CLK => clk,
      RST => rst,
      DATA_IN_0 => data_in_0,
      DATA_IN_1 => data_in_1,
      DATA_IN_2 => data_in_2,
      DATA_IN_3 => data_in_3,
      IN_VALID => in_valid,
      NEXT_IN => next_in,
      DATA_OUT => data_out,
      OUT_VALID => out_valid
  );

  P_CLK : process is
  begin

    clk <= '0';
    wait for t / 2;
    clk <= '1';
    wait for t / 2;

  end process P_CLK;

  -- counting cycles
  P_CYCLE : process (clk) is
  begin

    if (rising_edge(clk)) then
      if (rst = '1') then
        cycle_count <= 0;
      else
        cycle_count <= cycle_count + 1;
      end if;
    end if;

  end process P_CYCLE;

  -- counting hang cycles
  P_HANG_CYCLE : process (clk) is
  begin

    if (rising_edge(clk)) then
      if (rst = '1' or out_valid = '1') then
        hanged_count <= 0;
      else
        hanged_count <= hanged_count + 1;
      end if;
    end if;

  end process P_HANG_CYCLE;

  -- SIMULATION STARTS
  P_READ_DATA : process is

    variable input_data_line   : line;
    variable term_in_valid     : std_logic;
    variable term_data_in_0    : std_logic_vector(3 downto 0);
    variable term_data_in_1    : std_logic_vector(3 downto 0);
    variable term_data_in_2    : std_logic_vector(3 downto 0);
    variable term_data_in_3    : std_logic_vector(3 downto 0);
    variable char_comma        : character;
    variable output_line       : line;
    variable output_cycle_line : line;

  begin

    file_open(input_data_file, INPUT_FILE_STR, read_mode);
    file_open(output_file, OUTPUT_FILE_STR, write_mode);
    file_open(output_cycle_file, OUTPUT_CYCLE_STR, write_mode);
    -- write the header
    write(output_line, string'("data_out when valid"), left, 20);
    writeline(output_file, output_line);

    write(output_cycle_line, string'("valid cycle"), left, 11);
    writeline(output_cycle_file, output_cycle_line);

    rst <= '1';
    wait until rising_edge(clk);
    rst <= '1';
    wait until rising_edge(clk);
    rst <= '0';

    while not endfile(input_data_file) loop

      -- read from input
      readline(input_data_file, input_data_line);
      read(input_data_line, term_in_valid);
      read(input_data_line, char_comma);
      read(input_data_line, term_data_in_0);
      read(input_data_line, char_comma);
      read(input_data_line, term_data_in_1);
      read(input_data_line, char_comma);
      read(input_data_line, term_data_in_2);
      read(input_data_line, char_comma);
      read(input_data_line, term_data_in_3);



      if (in_valid = '0') then
        -- drive the DUT
        in_valid  <= term_in_valid;
        data_in_0 <= signed(term_data_in_0);
        data_in_1 <= signed(term_data_in_1);
        data_in_2 <= signed(term_data_in_2);
        data_in_3 <= signed(term_data_in_3);
      else

        while (next_in /= '1') loop

          wait until rising_edge(clk);

        end loop;

        -- drive the DUT
        in_valid  <= term_in_valid;
        data_in_0 <= signed(term_data_in_0);
        data_in_1 <= signed(term_data_in_1);
        data_in_2 <= signed(term_data_in_2);
        data_in_3 <= signed(term_data_in_3);
      end if;

      wait until rising_edge(clk);

    end loop;

    -- end generating input ...
    if (in_valid = '1') then

      while (next_in /= '1') loop

        wait until rising_edge(clk);

      end loop;

    end if;

    in_valid <= '0';
    wait;

  end process P_READ_DATA;

  -- sampling the output
  P_SAMPLE : process (clk) is

    variable output_line       : line;
    variable output_cycle_line : line;

  begin

    if (rising_edge(clk)) then
      if (rst = '0' and out_valid = '1') then
        -- sample and write to output file
        write(output_line, data_out, left, 10);
        writeline(output_file, output_line);
        write(output_cycle_line, cycle_count, left, 11);
        writeline(output_cycle_file, output_cycle_line);
      end if;
    end if;

  end process P_SAMPLE;

  -- end simulation
  P_ENDSIM : process (clk) is
  begin

    if (rising_edge(clk)) then
      if (hanged_count >= 300) then
        file_close(input_data_file);
        file_close(output_cycle_file);
        file_close(output_file);
        report "Test completed";
        stop(0);
      end if;
    end if;

  end process P_ENDSIM;

end architecture TB_ARCH;
