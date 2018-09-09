# defmodule Fluid.Field.Boolean do

#   use Private

#   @default_opts []

#   defmacro def_field_functions(field_name, 1, opts \\ []) do
#     opts = Keyword.merge(@default_opts, opts)

#     def_field_size = String.to_atom("#{field_name}_size")
#     quote do
#       def unquote(def_field_size)(), do: unquote(size)
#     end
#   end

#   defmacro def_field_functions(name, size, _) do
#     raise ArgumentError, """
#     Invalid size for #{__MODULE__} field `#{name}`: #{inspect(size)}
#     Only valid value is 1
#     """
#   end
# end
