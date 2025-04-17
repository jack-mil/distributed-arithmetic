package util is
  function clog2 (X : in POSITIVE) return NATURAL;
end package;

library ieee;
  use IEEE.math_real.ceil;
  use IEEE.math_real.log2;

package body util is
  function clog2 (X : in POSITIVE) return NATURAL is
    -- Description:
    --        Compute the ceiling( log_2( X ) )
  begin
    return integer(ceil(log2(real(X))));
  end function;
end package body;
