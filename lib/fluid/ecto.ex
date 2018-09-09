defmodule Fluid.Ecto do
  @moduledoc false

  defmacro def_ecto_type(type, format_name) do
    quote bind_quoted: [type: type, format_name: format_name] do
      @behaviour Ecto.Type

      def type(), do: unquote(type)

      def load(value) do
        with {:ok, bitstring} <- __fluid__(:decode, unquote(format_name), value) do
          encode(bitstring)
        end
      end

      def dump(value) do
        with {:ok, bitstring} <- decode(value) do
          __fluid__(:encode, unquote(format_name), bitstring)
        end
      end
    end
  end
end
