defmodule Fluid.Format.IntegerTest do
  use ExUnit.Case, async: true

  alias Fluid.Format.Integer
  doctest Integer

  defmodule Foo do
    import Integer

    def_format_functions(:unsigned, %Integer{unsigned: true}, nil,
      size: 8,
      default_format: true,
      generic_decode: false
    )

    def_format_functions(:signed, %Integer{unsigned: false}, nil,
      size: 8,
      default_format: false,
      generic_decode: true
    )

    def_format_functions(:int, %Integer{unsigned: false}, nil,
      size: 32,
      default_format: false,
      generic_decode: false
    )

    def_format_functions(:bigint, %Integer{unsigned: false}, nil,
      size: 64,
      default_format: false,
      generic_decode: false
    )
  end

  test "decode" do
    assert {:ok, <<0>>} = Foo.__fluid__(:decode, :unsigned, 0)
    assert {:ok, <<255>>} = Foo.__fluid__(:decode, :unsigned, 255)

    assert {:ok, <<0>>} = Foo.__fluid__(:decode, :signed, 0)
    assert {:ok, <<128>>} = Foo.__fluid__(:decode, :signed, -128)
    assert {:ok, <<127>>} = Foo.__fluid__(:decode, :signed, 127)

    assert {:ok, <<255, 255, 255, 255>>} = Foo.__fluid__(:decode, :int, -1)
    assert {:ok, <<128, 0, 0, 0>>} = Foo.__fluid__(:decode, :int, -2_147_483_648)
    assert {:ok, <<128, 0, 0, 1>>} = Foo.__fluid__(:decode, :int, -2_147_483_647)
    assert {:ok, <<127, 255, 255, 255>>} = Foo.__fluid__(:decode, :int, 2_147_483_647)

    assert {:ok, <<128, 0, 0, 0, 0, 0, 0, 0>>} =
             Foo.__fluid__(:decode, :bigint, -9_223_372_036_854_775_808)

    assert {:ok, <<127, 255, 255, 255, 255, 255, 255, 255>>} =
             Foo.__fluid__(:decode, :bigint, 9_223_372_036_854_775_807)

    assert {:ok, <<255, 255, 255, 255, 255, 255, 255, 255>>} = Foo.__fluid__(:decode, :bigint, -1)

    assert :error = Foo.__fluid__(:decode, :unsigned, -1)
    assert :error = Foo.__fluid__(:decode, :unsigned, 256)
    assert :error = Foo.__fluid__(:decode, :signed, 128)
    assert :error = Foo.__fluid__(:decode, :signed, -129)
    assert :error = Foo.__fluid__(:decode, :int, -2_147_483_649)
    assert :error = Foo.__fluid__(:decode, :int, 2_147_483_648)
    assert :error = Foo.__fluid__(:decode, :bigint, -9_223_372_036_854_775_809)
    assert :error = Foo.__fluid__(:decode, :bigint, 9_223_372_036_854_775_808)
  end

  test "encode" do
    assert {:ok, 0} = Foo.__fluid__(:encode, :unsigned, <<0::8>>)
    assert {:ok, 255} = Foo.__fluid__(:encode, :unsigned, <<255>>)

    assert {:ok, 0} = Foo.__fluid__(:encode, :signed, <<0::8>>)
    assert {:ok, 127} = Foo.__fluid__(:encode, :signed, <<127::8>>)
    assert {:ok, -128} = Foo.__fluid__(:encode, :signed, <<128::8>>)
    assert {:ok, -1} = Foo.__fluid__(:encode, :signed, <<255>>)

    assert {:ok, -1} = Foo.__fluid__(:encode, :int, <<255, 255, 255, 255>>)
    assert {:ok, -2_147_483_648} = Foo.__fluid__(:encode, :int, <<128, 0, 0, 0>>)
    assert {:ok, -2_147_483_647} = Foo.__fluid__(:encode, :int, <<128, 0, 0, 1>>)
    assert {:ok, 2_147_483_647} = Foo.__fluid__(:encode, :int, <<127, 255, 255, 255>>)

    assert {:ok, -1} = Foo.__fluid__(:encode, :bigint, <<255, 255, 255, 255, 255, 255, 255, 255>>)

    assert {:ok, -9_223_372_036_854_775_808} =
             Foo.__fluid__(:encode, :bigint, <<128, 0, 0, 0, 0, 0, 0, 0>>)

    assert {:ok, -9_223_372_036_854_775_807} =
             Foo.__fluid__(:encode, :bigint, <<128, 0, 0, 0, 0, 0, 0, 1>>)

    assert {:ok, 9_223_372_036_854_775_807} =
             Foo.__fluid__(:encode, :bigint, <<127, 255, 255, 255, 255, 255, 255, 255>>)

    assert :error = Foo.__fluid__(:encode, :unsigned, <<0::9>>)
    assert :error = Foo.__fluid__(:encode, :unsigned, <<0::7>>)
  end

  test "cast" do
    assert {:ok, 100} = Foo.cast(100)

    assert_raise FunctionClauseError, fn ->
      Foo.cast(256)
    end
  end

  test "generic decode" do
    assert {:ok, <<0>>} = Foo.__fluid__(:decode, 0)
    assert {:ok, <<255>>} = Foo.__fluid__(:decode, -1)

    assert_raise FunctionClauseError, fn ->
      Foo.__fluid__(:decode, -129)
    end

    assert_raise FunctionClauseError, fn ->
      Foo.__fluid__(:decode, 128)
    end
  end
end
