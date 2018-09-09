defmodule Fluid.Field.IntegerTest do
  use ExUnit.Case, async: true


  defmodule Foo do
    import Fluid.Field.Integer

    def_field_functions(:default, %Fluid.Field.Integer{size: 4})
    def_field_functions(:unsigned, %Fluid.Field.Integer{size: 4, unsigned: true})
    def_field_functions(:signed, %Fluid.Field.Integer{size: 4, unsigned: false})
  end

  test "defines field_size" do
    assert Foo.__fluid__(:bit_size, :default) === 4
    assert Foo.__fluid__(:bit_size, :unsigned) === 4
    assert Foo.__fluid__(:bit_size, :signed) === 4
  end

  test "defines field_max" do
    assert Foo.__fluid__(:max, :default) === 15
    assert Foo.__fluid__(:max, :unsigned) === 15
    assert Foo.__fluid__(:max, :signed) === 7
  end

  test "defines field_min" do
    assert Foo.__fluid__(:min, :default) === 0
    assert Foo.__fluid__(:min, :unsigned) === 0
    assert Foo.__fluid__(:min, :signed) === -8
  end

  test "cast" do
    assert Foo.__fluid__(:cast, :unsigned, 16) == :error
    assert Foo.__fluid__(:cast, :unsigned, 15) == {:ok, 15}
    assert Foo.__fluid__(:cast, :unsigned, 8) == {:ok, 8}
    assert Foo.__fluid__(:cast, :unsigned, 7) == {:ok, 7}
    assert Foo.__fluid__(:cast, :unsigned, 0) == {:ok, 0}
    assert Foo.__fluid__(:cast, :unsigned, -1) == :error
    assert Foo.__fluid__(:cast, :unsigned, nil) == :error

    assert Foo.__fluid__(:cast, :signed, 16) == :error
    assert Foo.__fluid__(:cast, :signed, 8) == :error
    assert Foo.__fluid__(:cast, :signed, 7) == {:ok, 7}
    assert Foo.__fluid__(:cast, :signed, 0) == {:ok, 0}
    assert Foo.__fluid__(:cast, :signed, -1) == {:ok, -1}
    assert Foo.__fluid__(:cast, :signed, -8) == {:ok, -8}
    assert Foo.__fluid__(:cast, :signed, -9) == :error
    assert Foo.__fluid__(:cast, :signed, nil) == :error
  end

  test "load" do
    assert Foo.__fluid__(:load, :unsigned, <<16::5>>) == :error
    assert Foo.__fluid__(:load, :unsigned, <<15::4>>) == {:ok, 15}
    assert Foo.__fluid__(:load, :unsigned, <<8::4>>) == {:ok, 8}
    assert Foo.__fluid__(:load, :unsigned, <<7::4>>) == {:ok, 7}
    assert Foo.__fluid__(:load, :unsigned, <<0::4>>) == {:ok, 0}
    assert Foo.__fluid__(:load, :unsigned, nil) == :error

    assert Foo.__fluid__(:load, :signed, <<16::5>>) == :error
    assert Foo.__fluid__(:load, :signed, <<15::4>>) == {:ok, -1}
    assert Foo.__fluid__(:load, :signed, <<8::4>>) == {:ok, -8}
    assert Foo.__fluid__(:load, :signed, <<7::4>>) == {:ok, 7}
    assert Foo.__fluid__(:load, :signed, <<0::4>>) == {:ok, 0}
    assert Foo.__fluid__(:load, :signed, nil) == :error
  end

  test "dump" do
    assert Foo.__fluid__(:dump, :unsigned, 16) == :error
    assert Foo.__fluid__(:dump, :unsigned, -1) == :error
    assert Foo.__fluid__(:dump, :unsigned, 15) == {:ok, <<15::4>>}
    assert Foo.__fluid__(:dump, :unsigned, 8) == {:ok, <<8::4>>}
    assert Foo.__fluid__(:dump, :unsigned, 7) == {:ok, <<7::4>>}
    assert Foo.__fluid__(:dump, :unsigned, 0) == {:ok, <<0::4>>}
    assert Foo.__fluid__(:dump, :unsigned, nil) == :error

    assert Foo.__fluid__(:dump, :signed, 8) == :error
    assert Foo.__fluid__(:dump, :signed, -9) == :error
    assert Foo.__fluid__(:dump, :signed, -1) == {:ok, <<15::4>>}
    assert Foo.__fluid__(:dump, :signed, -8) == {:ok, <<8::4>>}
    assert Foo.__fluid__(:dump, :signed, 7) == {:ok, <<7::4>>}
    assert Foo.__fluid__(:dump, :signed, 0) == {:ok, <<0::4>>}
    assert Foo.__fluid__(:dump, :signed, nil) == :error
  end
end
