defmodule Fluid.Format.Hexadecimal do
  defstruct groups: nil, separator: ?-

  alias Fluid.Helper
  require Helper

  defmacro def_format_functions(formatter_name, data, _fields, opts) do
    quote bind_quoted: [data: data, formatter_name: formatter_name, opts: opts] do
      alias Fluid.Format.Hexadecimal
      @size Keyword.fetch!(opts, :size)
      data = Hexadecimal.verify_data!(data, @size)

      @separator data.separator
      @groups data.groups
      encode_arg = Hexadecimal.encode_argument(@groups)
      decode_arg = Hexadecimal.decode_argument(@separator, @groups)

      @min_encoded_value 0
      @max_encoded_value Helper.max_int(@size)

      # cast optimization cannot be performed here (opts.default_format)

      def __fluid__(:decode, unquote(formatter_name), unquote(decode_arg)) do
        try do
          unquote(
            {:<<>>, [],
             Hexadecimal.decode_argument_variables(@separator, @groups)
             |> Enum.filter(&is_atom(&1))
             |> Enum.map(&{:::, [], [{:d, [], [{&1, [], Elixir}]}, 4]})}
          )
        catch
          :error -> :error
        else
          decode -> {:ok, decode}
        end
      end

      def __fluid__(:decode, unquote(formatter_name), _), do: :error

      if Keyword.fetch!(opts, :generic_decode) do
        def __fluid__(:decode, unquote(decode_arg) = value),
          do: __fluid__(:decode, unquote(formatter_name), value)
      end

      defp d(?0), do: 0
      defp d(?1), do: 1
      defp d(?2), do: 2
      defp d(?3), do: 3
      defp d(?4), do: 4
      defp d(?5), do: 5
      defp d(?6), do: 6
      defp d(?7), do: 7
      defp d(?8), do: 8
      defp d(?9), do: 9
      defp d(?A), do: 10
      defp d(?B), do: 11
      defp d(?C), do: 12
      defp d(?D), do: 13
      defp d(?E), do: 14
      defp d(?F), do: 15
      defp d(?a), do: 10
      defp d(?b), do: 11
      defp d(?c), do: 12
      defp d(?d), do: 13
      defp d(?e), do: 14
      defp d(?f), do: 15
      defp d(_), do: throw(:error)

      @compile {:inline, d: 1}

      def __fluid__(:encode, unquote(formatter_name), unquote(encode_arg)) do
        try do
          unquote(
            {:<<>>, [],
             Hexadecimal.encode_argument_variables(@groups)
             |> Enum.map(&{:e, [], [{&1, [], Elixir}]})
             |> Hexadecimal.insert_in(@separator, @groups)}
          )
        catch
          :error -> :error
        else
          encoded -> {:ok, encoded}
        end
      end

      def __fluid__(:encode, unquote(formatter_name), _), do: :error

      @compile {:inline, e: 1}

      defp e(0), do: ?0
      defp e(1), do: ?1
      defp e(2), do: ?2
      defp e(3), do: ?3
      defp e(4), do: ?4
      defp e(5), do: ?5
      defp e(6), do: ?6
      defp e(7), do: ?7
      defp e(8), do: ?8
      defp e(9), do: ?9
      defp e(10), do: ?a
      defp e(11), do: ?b
      defp e(12), do: ?c
      defp e(13), do: ?d
      defp e(14), do: ?e
      defp e(15), do: ?f
    end
  end

  @abc for n <- ?a..?z, do: <<n::utf8>>

  def decode_argument_variables(separator, groups) do
    l = length(groups)

    @abc
    |> Enum.slice(0..l)
    |> Enum.zip(groups)
    |> Enum.map(fn {letter, size} ->
      for n <- 1..size, do: String.to_atom("#{letter}#{n}")
    end)
    |> Enum.intersperse([separator])
    |> List.flatten()
  end

  def decode_argument(separator, groups) do
    arg =
      decode_argument_variables(separator, groups)
      |> Enum.map(fn
        x when is_atom(x) -> {x, [], Elixir}
        x when is_integer(x) -> x
      end)

    {:<<>>, [], arg}
  end

  def encode_argument_variables(groups) do
    l = length(groups)

    @abc
    |> Enum.slice(0..l)
    |> Enum.zip(groups)
    |> Enum.flat_map(fn {letter, size} ->
      for n <- 1..size, do: String.to_atom("#{letter}#{n}")
    end)
  end

  def encode_argument(groups) do
    arg =
      groups
      |> encode_argument_variables()
      |> Enum.map(&{:::, [], [{&1, [], Elixir}, 4]})

    {:<<>>, [], arg}
  end

  # @compile {:inline, c: 1}

  # defp c(?0), do: ?0
  # defp c(?1), do: ?1
  # defp c(?2), do: ?2
  # defp c(?3), do: ?3
  # defp c(?4), do: ?4
  # defp c(?5), do: ?5
  # defp c(?6), do: ?6
  # defp c(?7), do: ?7
  # defp c(?8), do: ?8
  # defp c(?9), do: ?9
  # defp c(?A), do: ?a
  # defp c(?B), do: ?b
  # defp c(?C), do: ?c
  # defp c(?D), do: ?d
  # defp c(?E), do: ?e
  # defp c(?F), do: ?f
  # defp c(?a), do: ?a
  # defp c(?b), do: ?b
  # defp c(?c), do: ?c
  # defp c(?d), do: ?d
  # defp c(?e), do: ?e
  # defp c(?f), do: ?f
  # defp c(_),  do: throw(:error)

  def verify_data!(_, size) when rem(size, 4) != 0 do
    raise(ArgumentError, """
    Hexdecimal format only can be used for multiples of 4 bit_size: #{inspect(size)}
    """)
  end

  def verify_data!(%__MODULE__{groups: group_size, separator: separator} = data, size)
      when Helper.is_size(group_size) and Helper.is_size(size) and is_integer(separator) and
             separator >= 0 do
    groups = calc_groups(size, group_size)

    %{data | groups: groups}
    |> verify_data!(size)
  end

  def verify_data!(%__MODULE__{groups: groups, separator: separator} = data, size)
      when is_list(groups) and is_integer(size) and size > 0 and is_integer(separator) and
             separator >= 0 do
    verify_groups_and_size!(size, groups)
    data
  end

  def verify_data!(_, size) when not Helper.is_size(size), do: :error

  defp calc_groups(id_bit_size, group_hex_size) when group_hex_size * 4 > id_bit_size,
    do:
      raise(ArgumentError, """
      group_size is too big.
      Maximum is #{div(id_bit_size, 4)} = #{id_bit_size}/4
      Given: #{inspect(group_hex_size)}
      """)

  defp calc_groups(id_bit_size, group_hex_size) do
    id_hex_size = div(id_bit_size, 4)
    groups = List.duplicate(group_hex_size, div(id_hex_size, group_hex_size))

    case rem(id_hex_size, group_hex_size) do
      0 -> groups
      rem -> List.insert_at(groups, -1, rem)
    end
  end

  defp verify_groups_and_size!(size, groups) do
    hex_size = Enum.sum(groups)
    bit_size = hex_size * 4

    if bit_size == size do
      :ok
    else
      raise(ArgumentError, """
      Invalid groups for the given size: #{inspect(groups)}
      Size: #{inspect(size)}
      Sum of the group elements: #{hex_size}
      The sum of the group elements should be equal to the size / 4 = #{div(size, 4)}
      """)
    end
  end

  def insert_in(enum, separator, groups) do
    {splited, []} =
      Enum.reduce(groups, {[], enum}, fn spliter, {acc, rest} ->
        {group, rest} = Enum.split(rest, spliter)
        {List.insert_at(acc, -1, group), rest}
      end)

    splited
    |> Enum.intersperse([separator])
    |> Enum.concat()
  end
end
