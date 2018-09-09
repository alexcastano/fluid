defmodule Fluid.Format.HexadecimalTest do
  use ExUnit.Case, async: true

  alias Fluid.Format.Hexadecimal
  doctest Hexadecimal

  defmodule Foo do
    import Hexadecimal
    def_format_functions(:hex, %Hexadecimal{
      separator: ?-,
      groups: [2, 2, 2, 2]},
      nil,
      size: 32,
      default_format: true,
      generic_decode: true
    )
  end

  test "decode argument list" do
    assert [:a1, :a2, ?-, :b1, :b2, ?-, :c1, :c2, ?-, :d1, :d2] ==
     Fluid.Format.Hexadecimal.decode_argument_variables(?-, [2, 2, 2, 2])
  end

  test "encode argument list" do
    assert [:a1, :a2, :b1, :b2, :c1, :c2, :d1, :d2] ==
     Fluid.Format.Hexadecimal.encode_argument_variables([2, 2, 2, 2])
  end


  test "decode" do
    assert {:ok, <<0, 0, 0, 0>>} = Foo.__fluid__(:decode, :hex, "00-00-00-00")
    assert {:ok, <<255, 255, 255, 255>>} = Foo.__fluid__(:decode, :hex, "ff-ff-ff-ff")
    assert {:ok, <<255, 255, 255, 255>>} = Foo.__fluid__(:decode, :hex, "FF-FF-FF-FF")

    assert :error = Foo.__fluid__(:decode, :hex, "g0-00-00-00")
    assert :error = Foo.__fluid__(:decode, :hex, "00000000")
  end

  test "encode" do
    assert {:ok, "00-00-00-00"} = Foo.__fluid__(:encode, :hex, <<0::32>>)
    assert {:ok, "ff-ff-ff-ff"} = Foo.__fluid__(:encode, :hex, <<255, 255, 255, 255>>)

    assert :error = Foo.__fluid__(:encode, :hex, <<0::33>>)
    assert :error = Foo.__fluid__(:encode, :hex, <<0::31>>)
  end

  test "verify_data!" do
    assert_raise ArgumentError, ~r/multiple/, fn ->
      Hexadecimal.verify_data!(%Hexadecimal{}, 7)
    end

    assert_raise ArgumentError, ~r/Maximum is 3/, fn ->
      Hexadecimal.verify_data!(%Hexadecimal{groups: 4}, 12)
    end

    assert %Hexadecimal{
      groups: [2, 1],
    } = Hexadecimal.verify_data!(%Hexadecimal{groups: 2}, 12)

    assert_raise ArgumentError, ~r/Invalid/, fn ->
      Hexadecimal.verify_data!(%Hexadecimal{groups: [2, 2]}, 12)
    end
  end
end
