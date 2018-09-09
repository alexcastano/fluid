defmodule FluidTest do
  use ExUnit.Case, async: true
  doctest Fluid

  defmodule Foo do
    use Fluid,
      fields: [
        inserted_at: %Fluid.Field.NaiveDateTime{size: 4},
        node_id: %Fluid.Field.Integer{size: 4}
      ],
      formats: [
        hex: %Fluid.Format.Hexadecimal{
          separator: ?-,
          groups: [1, 1]
        },
        int: %Fluid.Format.Integer{}
      ]
  end

  test "define bit_size" do
    assert Foo.__fluid__(:bit_size) == 8
  end

  test "define field list" do
    assert Foo.__fluid__(:fields) == [:inserted_at, :node_id]
  end

  test "define field instrospection" do
    assert Foo.__fluid__(:field, :inserted_at) == %Fluid.Field.NaiveDateTime{size: 4}
    assert Foo.__fluid__(:field, :node_id) == %Fluid.Field.Integer{size: 4}
  end

  test "define field bit_size" do
    assert Foo.__fluid__(:bit_size, :inserted_at) == 4
    assert Foo.__fluid__(:bit_size, :node_id) == 4
  end

  test "define field functions" do
    assert :eq ==
             NaiveDateTime.compare(Foo.__fluid__(:min, :inserted_at), ~N[2015-01-01 00:00:00.000])

    assert :eq ==
             NaiveDateTime.compare(Foo.__fluid__(:max, :inserted_at), ~N[2015-01-01 00:00:00.015])

    assert Foo.__fluid__(:min, :node_id) == 0
    assert Foo.__fluid__(:max, :node_id) == 15
  end

  test "define format functions" do
    assert {:ok, "0-0"} = Foo.__fluid__(:encode, :hex, <<0::8>>)
    assert {:ok, <<255::8>>} = Foo.__fluid__(:decode, :hex, "f-f")
    assert {:ok, <<255::8>>} = Foo.__fluid__(:decode, "f-f")

    assert {:ok, 0} = Foo.__fluid__(:encode, :int, <<0::8>>)
    assert {:ok, <<127::8>>} = Foo.__fluid__(:decode, :int, 127)
    assert {:ok, <<255::8>>} = Foo.__fluid__(:decode, -1)
  end

  test "define encode" do
    assert {:ok, "f-f"} = Foo.encode(<<255::8>>)
  end

  test "define decode" do
    assert {:ok, <<0::8>>} = Foo.decode("0-0")
    assert {:ok, <<0::8>>} = Foo.decode(0)
  end

  test "define new function" do
    assert {:ok, "0-0"} = Foo.new(%{inserted_at: ~N[2015-01-01 00:00:00.000], node_id: 0})
    assert {:ok, "0-0"} = Foo.new(inserted_at: ~N[2015-01-01 00:00:00.000], node_id: 0)
  end

  test "define get functions" do
    assert {:ok, 3} = Foo.get("a-3", :node_id)
    assert {:ok, ret} = Foo.get("a-3", :inserted_at)
    assert NaiveDateTime.compare(ret, ~N[2015-01-01 00:00:00.010])
  end
end
