defmodule Fluid do
  @moduledoc """
  Documentation for Fluid.
  """

  defmodule Error do
    defexception [:message]

    def exception(message),
      do: %__MODULE__{message: message}
  end

  defmodule Builder do
    @moduledoc false

    def calc_size(opts) do
      fields = Keyword.fetch!(opts, :fields)

      Enum.reduce(fields, 0, fn {_, %{__struct__: module} = data}, acc ->
        acc + module.bit_size(data)
      end)
    end

    defmacro def_bit_size(opts) do
      quote do
        def __fluid__(:bit_size), do: Builder.calc_size(unquote(opts))
      end
    end

    defmacro def_field_list(opts) do
      quote do
        def __fluid__(:fields),
          do: unquote(opts) |> Keyword.fetch!(:fields) |> Enum.map(fn {name, _} -> name end)
      end
    end

    defmacro def_format_list(opts) do
      quote do
        def __fluid__(:formats),
          do: unquote(opts) |> Keyword.fetch!(:formats) |> Enum.map(fn {name, _} -> name end)
      end
    end

    defmacro def_default_format(opts) do
      quote do
        def __fluid__(:default_format),
          do: unquote(opts) |> Keyword.fetch!(:formats) |> hd() |> elem(0)
      end
    end

    defmacro def_field_instrospection(opts) do
      opts
      |> Keyword.fetch!(:fields)
      |> Enum.map(fn {name, data} ->
        quote do
          def __fluid__(:field, unquote(name)), do: unquote(data)
        end
      end)
    end

    defmacro def_format_instrospection(opts) do
      opts
      |> Keyword.fetch!(:formats)
      |> Enum.map(fn {name, data} ->
        quote do
          def __fluid__(:field, unquote(name)), do: unquote(data)
        end
      end)
    end

    defmacro def_field_functions(opts) do
      fields = Keyword.fetch!(opts, :fields)

      Enum.map(fields, fn {name, data} ->
        {:%, _, [module, _]} = data

        quote do
          require unquote(module)
          unquote(module).def_field_functions(unquote(name), unquote(data))
        end
      end)
    end

    defmacro def_format_functions(opts) do
      formats = Keyword.fetch!(opts, :formats)
      fields = Keyword.fetch(opts, :fields)

      {main_format, _} = hd(formats)

      Enum.map(formats, fn {name, data} ->
        {:%, _, [module, _]} = data

        quote do
          require unquote(module)
          @size Builder.calc_size(unquote(opts))
          # If it is default format it defines a cast
          # which if it receives a value with the default_format
          # it is returned directly.
          # Generic cast has to decode and encode the given value always.
          # This is an optimization
          @default_format unquote(main_format) == unquote(name)

          unquote(module).def_format_functions(
            unquote(name),
            unquote(data),
            unquote(fields),
            size: @size,
            default_format: @default_format,
            generic_decode: true
          )
        end
      end)
    end

    defmacro def_get_functions(opts) do
      quote bind_quoted: [opts: opts] do
        opts
        |> Keyword.fetch!(:fields)
        |> Enum.reduce(0, fn {name, data}, acc ->
          size = data.__struct__.bit_size(data)

          def get(id, unquote(name)) do
            with {:ok, bitstring} <- __fluid__(:decode, id),
                 <<_::unquote(acc), encoded::unquote(size), _::bits>> <- bitstring,
                 {:ok, value} <- __fluid__(:load, unquote(name), <<encoded::unquote(size)>>),
                 do: {:ok, value}
          end

          acc + size
        end)
      end
    end

    defmacro def_ecto_functions(opts) do
      if ecto_data = Keyword.get(opts, :ecto) do
        format = {:%, _, [module, _]} = Keyword.fetch!(ecto_data, :format)

        quote do
          @fields Keyword.fetch!(unquote(opts), :fields)
          @size Builder.calc_size(unquote(opts))

          require unquote(module)

          unquote(module).def_format_functions(
            :__ecto__,
            unquote(format),
            @fields,
            size: @size,
            default_format: false,
            generic_decode: false
          )

          @ecto_type Keyword.fetch!(unquote(ecto_data), :type)
          require Fluid.Ecto
          Fluid.Ecto.def_ecto_type(@ecto_type, :__ecto__)
        end
      end
    end
  end

  defmacro __using__(opts) do
    quote do
      require Builder

      Builder.def_bit_size(unquote(opts))
      Builder.def_field_list(unquote(opts))
      Builder.def_format_list(unquote(opts))
      Builder.def_default_format(unquote(opts))
      Builder.def_field_instrospection(unquote(opts))
      Builder.def_format_instrospection(unquote(opts))
      Builder.def_field_functions(unquote(opts))
      Builder.def_format_functions(unquote(opts))
      Builder.def_get_functions(unquote(opts))
      Builder.def_ecto_functions(unquote(opts))

      def cast(value) do
        with {:ok, decoded} <- decode(value), do: encode(decoded)
      end

      def new(values) when is_list(values), do: values |> Enum.into(%{}) |> new()
      def new(values) when is_map(values) do
        __fluid__(:fields)
        |> Enum.reduce(<<>>, fn field_name, acc ->
          with {:ok, value} <- Map.fetch(values, field_name),
               {:ok, encoded} <- __fluid__(:dump, field_name, value) do
            <<acc::bitstring, encoded::bitstring>>
          end
        end)
        |> encode()
      end

      @default_format unquote(opts) |> Keyword.fetch!(:formats) |> hd() |> elem(0)
      def encode(value) do
        __fluid__(:encode, @default_format, value)
      end

      # Formats define all previous generic decode functions
      # It arrives here, it is an error
      def __fluid__(:decode, value), do: :error

      def decode(value) do
        __fluid__(:decode, value)
      end
    end
  end
end
