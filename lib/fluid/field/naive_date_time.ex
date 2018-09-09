defmodule Fluid.Field.NaiveDateTime do
  alias Fluid.Helper

  defstruct size: nil, time_unit: :millisecond, epoch: ~N[2015-01-01 00:00:00]

  def bit_size(%{size: size}), do: size

  defmacro def_field_functions(field_name, opts) do
    quote bind_quoted: [opts: opts, field_name: field_name] do
      Fluid.Field.NaiveDateTime.verify_opts(opts)

      @size Fluid.Field.NaiveDateTime.bit_size(opts)
      @max_encoded_value Helper.max_int(@size)
      @time_unit opts.time_unit
      @epoch NaiveDateTime.truncate(opts.epoch, @time_unit)

      def __fluid__(:bit_size, unquote(field_name)), do: @size

      def __fluid__(:max, unquote(field_name)),
        do: NaiveDateTime.add(@epoch, @max_encoded_value, @time_unit)

      def __fluid__(:min, unquote(field_name)),
        do: @epoch

      def __fluid__(:cast, unquote(field_name), value)
          when is_integer(value) and value >= 0 and value <= @max_encoded_value,
          do: NaiveDateTime.add(@epoch, value, @time_unit)

      def __fluid__(:cast, unquote(field_name), _value), do: :error

      def __fluid__(:load, unquote(field_name), <<value::@size>>),
          do: {:ok, NaiveDateTime.add(@epoch, value, @time_unit)}

      def __fluid__(:load, unquote(field_name), _value), do: :error

      def __fluid__(:dump, unquote(field_name), %{ __struct__: NaiveDateTime } = value) do
        ret = NaiveDateTime.diff(value, @epoch, @time_unit)
        if ret >= 0 and ret <= @max_encoded_value, do: {:ok, <<ret::@size>>}, else: :error
      end

      def __fluid__(:dump, unquote(field_name), _value), do: :error
    end
  end

  defguardp is_time_unit(tu) when tu in [:second, :millisecond, :microsecond]
  defguardp is_size(size) when is_integer(size) and size > 0

  def verify_opts(%__MODULE__{size: size, epoch: %NaiveDateTime{}, time_unit: tu})
      when is_size(size) and is_time_unit(tu),
      do: :ok

  def verify_opts(%{size: size}) when not is_size(size),
    do:
      raise(ArgumentError, """
      Invalid size: #{inspect(size)}
      size should be an integer > 0
      """)

  def verify_opts(%__MODULE__{time_unit: tu})
      when not is_time_unit(tu),
      do:
        raise(ArgumentError, """
        Invalid type for time_unit: #{inspect(tu)}
        time_unit should be :second, :millisecond or :microsecond
        """)

  def verify_opts(%{epoch: epoch}),
    do:
      raise(ArgumentError, """
      Invalid type for epoch: #{inspect(epoch)}
      epoch should be NaiveDateTime
      """)

  def dump(
        %__MODULE__{size: size, time_unit: time_unit, epoch: epoch},
        %{
          __struct__: NaiveDateTime
        } = value
      ) do
    ret = NaiveDateTime.diff(value, NaiveDateTime.truncate(epoch, time_unit), time_unit)

    if ret < 0 or ret > Helper.max_int(size), do: :error, else: ret
  end

  def dump(%__MODULE__{}, _value), do: :error
end
