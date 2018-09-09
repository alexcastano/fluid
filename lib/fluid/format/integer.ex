defmodule Fluid.Format.Integer do
  defstruct unsigned: false

  defmacro def_format_functions(formatter_name, data, _fields, opts) do
    quote bind_quoted: [data: data, formatter_name: formatter_name, opts: opts] do
      alias Fluid.Helper
      require Helper

      @size Keyword.fetch!(opts, :size)

      if data.unsigned do
        @min_value 0
        @max_value Helper.max_int(@size)

        def __fluid__(:encode, unquote(formatter_name), <<value::unquote(@size)>>),
          do: {:ok, value}
      else
        @min_value -Helper.max_int(@size - 1) - 1
        @max_value Helper.max_int(@size - 1)

        def __fluid__(:encode, unquote(formatter_name), <<value::signed-size(unquote(@size))>>),
          do: {:ok, value}
      end

      def __fluid__(:decode, unquote(formatter_name), value)
          when value >= @min_value and value <= @max_value,
          do: {:ok, <<value::unquote(@size)>>}

      def __fluid__(:encode, unquote(formatter_name), _), do: :error
      def __fluid__(:decode, unquote(formatter_name), _), do: :error

      if Keyword.fetch!(opts, :generic_decode) do
        def __fluid__(:decode, value)
            when value >= @min_value and value <= @max_value,
            do: __fluid__(:decode, unquote(formatter_name), value)
      end

      if Keyword.fetch!(opts, :default_format) do
        def cast(value)
            when value >= @min_value and value <= @max_value,
            do: {:ok, value}
      end
    end
  end
end
