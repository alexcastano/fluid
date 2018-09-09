defmodule Fluid.Helper do
  @moduledoc false

  require Integer

  def pow(_, 0), do: 1
  def pow(x, n) when Integer.is_odd(n), do: x * pow(x, n - 1)
  def pow(x, n) do
    result = pow(x, div(n, 2))
    result * result
  end

  def max_int(bit_size), do: pow(2, bit_size) - 1

  defguard is_size(size) when is_integer(size) and size > 0
end
