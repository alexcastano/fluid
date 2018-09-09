defmodule Fluid.Field.Integer do

  defstruct size: nil, unsigned: true

  alias Fluid.Helper
  require Helper

  def bit_size(%{size: size}), do: size

  defmacro def_field_functions(field_name, opts) do
    quote bind_quoted: [opts: opts, field_name: field_name] do
      Fluid.Field.Integer.verify_opts(opts)

      @size Fluid.Field.Integer.bit_size(opts)
      @max_encoded_value Helper.max_int(@size)

      def __fluid__(:bit_size, unquote(field_name)), do: @size

      if opts.unsigned do
        @min_value 0
        @max_value @max_encoded_value

        def __fluid__(:max, unquote(field_name)), do: @max_value
        def __fluid__(:min, unquote(field_name)), do: 0

        def __fluid__(:cast, unquote(field_name), value)
            when value >= @min_value and value <= @max_value,
            do: {:ok, value}

        def __fluid__(:load, unquote(field_name), <<value::@size>>), do: {:ok, value}

        def __fluid__(:dump, unquote(field_name), value)
            when value >= @min_value and value <= @max_value,
            do: {:ok, <<value::@size>>}
      else
        @min_value -Helper.max_int(@size - 1) - 1
        @max_value Helper.max_int(@size - 1)

        def __fluid__(:max, unquote(field_name)), do: @max_value
        def __fluid__(:min, unquote(field_name)), do: @min_value

        def __fluid__(:cast, unquote(field_name), value)
            when value >= @min_value and value <= @max_value do
          <<ret::signed-size(@size)>> = <<value::@size>>
          {:ok, ret}
        end

        def __fluid__(:load, unquote(field_name), <<value::integer-signed-size(@size)>>),
          do: {:ok, value}

        def __fluid__(:dump, unquote(field_name), value)
            when value >= @min_value and value <= @max_value,
            do: {:ok, <<value::signed-size(@size)>>}
      end

      def __fluid__(:cast, unquote(field_name), _value), do: :error
      def __fluid__(:load, unquote(field_name), _value), do: :error
      def __fluid__(:dump, unquote(field_name), _value), do: :error
    end
  end

  def verify_opts(%__MODULE__{size: size, unsigned: unsigned})
      when Helper.is_size(size) and is_boolean(unsigned),
      do: :ok

  def verify_opts(%{size: size}) when not Helper.is_size(size),
    do:
      raise(ArgumentError, """
      Invalid size: #{inspect(size)}
      size should be an integer > 0
      """)

  def verify_opts(%{unsigned: unsigned}) when not is_boolean(unsigned),
    do:
      raise(ArgumentError, """
      Invalid unsigned: #{inspect(unsigned)}
      unsigned should be a boolean
      """)
end
