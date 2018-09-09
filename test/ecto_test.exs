defmodule Fluid.EctoTest do
  use ExUnit.Case, async: true
  doctest Fluid

  defmodule Foo do
    use Fluid,
      fields: [
        node_id: %Fluid.Field.Integer{unsigned: false, size: 64}
      ],
      formats: [
        hex: %Fluid.Format.Hexadecimal{
          separator: ?-,
          groups: 4
        },
      ],
      ecto: [
        type: :integer,
        format: %Fluid.Format.Integer{}
      ]
  end

  test "type" do
    assert Foo.type() == :integer
  end

  test "cast" do
    assert {:ok, "ffff-ffff-ffff-ffff"} = Foo.cast("FFFF-FFFF-FFFF-FFFF")
    assert {:ok, "ffff-ffff-ffff-ffff"} = Foo.cast("ffff-ffff-ffff-ffff")
    assert :error = Foo.cast("ffff-ffff-ffff-fffg")
  end

  test "load" do
    assert {:ok, "ffff-ffff-ffff-ffff"} = Foo.load(-1)
    assert {:ok, "0000-0000-0000-0000"} = Foo.load(0)
    assert :error = Foo.load(9_223_372_036_854_775_808)
  end

  test "dump" do
    assert {:ok, -1} = Foo.dump("ffff-ffff-ffff-ffff")
    assert {:ok, 0} = Foo.dump("0000-0000-0000-0000")
    assert :error = Foo.dump("0000-0000-0000-000g")
  end
end
