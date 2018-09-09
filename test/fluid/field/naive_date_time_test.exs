defmodule Fluid.Field.NaiveDateTimeTest do
  use ExUnit.Case, async: true

  alias Fluid.Field.NaiveDateTime, as: Subject

  defmodule Foo do
    require Subject

    Subject.def_field_functions(:inserted_at, %Subject{
      size: 4,
      epoch: ~N[2015-01-01 00:00:00.999],
      time_unit: :second
    })

    Subject.def_field_functions(:deleted_at, %Subject{size: 4})
  end

  test "defines field_bit_size" do
    assert Foo.__fluid__(:bit_size, :inserted_at) === 4
    assert Foo.__fluid__(:bit_size, :deleted_at) === 4
  end

  test "defines field_max" do
    assert :eq ==
             NaiveDateTime.compare(Foo.__fluid__(:max, :inserted_at), ~N[2015-01-01 00:00:15])

    assert :eq ==
             NaiveDateTime.compare(Foo.__fluid__(:max, :deleted_at), ~N[2015-01-01 00:00:00.015])
  end

  test "defines field_min" do
    assert :eq ==
             NaiveDateTime.compare(Foo.__fluid__(:min, :inserted_at), ~N[2015-01-01 00:00:00])

    assert :eq == NaiveDateTime.compare(Foo.__fluid__(:min, :deleted_at), ~N[2015-01-01 00:00:00])
  end

  describe "verify_opts" do
    test "checks size is correct" do
      assert :ok == Subject.verify_opts(%Subject{size: 32})

      assert_raise ArgumentError, ~r/nil/, fn ->
        Subject.verify_opts(%Subject{})
      end
    end

    test "checks timeunit is correct" do
      assert :ok == Subject.verify_opts(%Subject{size: 32, time_unit: :millisecond})

      assert_raise ArgumentError, ~r/seconds/, fn ->
        Subject.verify_opts(%Subject{size: 32, time_unit: :seconds})
      end
    end

    test "checks epoch is correct" do
      assert :ok == Subject.verify_opts(%Subject{size: 32, epoch: ~N[1970-01-01 00:00:00]})

      assert_raise ArgumentError, ~r/nil/, fn ->
        Subject.verify_opts(%Subject{size: 32, epoch: nil})
      end
    end
  end

  test "cast" do
    assert NaiveDateTime.compare(Foo.__fluid__(:cast, :inserted_at, 3), ~N[2015-01-01 00:00:03]) == :eq
    assert Foo.__fluid__(:cast, :inserted_at, 32) == :error
    assert Foo.__fluid__(:cast, :inserted_at, -1) == :error
    assert Foo.__fluid__(:cast, :inserted_at, nil) == :error
  end

  test "load" do
    assert {:ok, ret} = Foo.__fluid__(:load, :inserted_at, <<3::4>>)
    assert NaiveDateTime.compare(ret, ~N[2015-01-01 00:00:03]) == :eq

    assert Foo.__fluid__(:load, :inserted_at, <<32>>) == :error
    assert Foo.__fluid__(:load, :inserted_at, nil) == :error
  end

  test "dump" do
    assert Foo.__fluid__(:dump, :inserted_at, ~N[2015-01-01 00:00:03]) == {:ok, <<3::4>>}
    assert Foo.__fluid__(:dump, :inserted_at, ~N[2015-01-01 00:00:32]) == :error
    assert Foo.__fluid__(:dump, :inserted_at, nil) == :error
  end
end
