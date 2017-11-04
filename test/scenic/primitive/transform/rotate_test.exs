#
#  Created by Boyd Multerer on 11/02/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.RotateTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Transform.Rotate

  @data_1   1.0
  @data_3   { 1.0, 2.0, 3.0 }

  @bin_1_native     <<
      0.0 :: float-size(32)-native,
      0.0 :: float-size(32)-native,
      1.0 :: float-size(32)-native,
    >>

  @bin_3_native     <<
      1.0 :: float-size(32)-native,
      2.0 :: float-size(32)-native,
      3.0 :: float-size(32)-native,
    >>

  @bin_1_big   <<
      0.0 :: float-size(32)-big,
      0.0 :: float-size(32)-big,
      1.0 :: float-size(32)-big,
    >>

  @bin_3_big   <<
      1.0 :: float-size(32)-big,
      2.0 :: float-size(32)-big,
      3.0 :: float-size(32)-big,
    >>

  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Rotate.verify( @data_1 ) == true
    assert Rotate.verify( @data_3 ) == true
  end

  test "verify fails invalid data" do
    assert Rotate.verify( {1.1, 1.2} )            == false
    assert Rotate.verify( {1.1, 1.2, 1.3, 1.4} )  == false
    assert Rotate.verify( {1.1, 1.2, :banana} )   == false
    assert Rotate.verify( :banana )               == false
  end

  #============================================================================
  # serialization

  #============================================================================
  # serialization

  test "serialize 1 native works" do
    assert Rotate.serialize(@data_1)            == {:ok, @bin_1_native}
    assert Rotate.serialize(@data_1, :native)   == {:ok, @bin_1_native}
  end

  test "serialize 3 native works" do
    assert Rotate.serialize(@data_3)            == {:ok, @bin_3_native}
    assert Rotate.serialize(@data_3, :native)   == {:ok, @bin_3_native}
  end

  test "serialize 1 big works" do
    assert Rotate.serialize(@data_1, :big)      == {:ok, @bin_1_big}
  end

  test "serialize 3 big works" do
    assert Rotate.serialize(@data_3, :big)      == {:ok, @bin_3_big}
  end

  test "deserialize 1 native works" do
    assert assert Rotate.deserialize(@bin_1_native)          == {:ok, {0.0,0.0,@data_1}, ""}
    assert assert Rotate.deserialize(@bin_1_native, :native) == {:ok, {0.0,0.0,@data_1}, ""}
  end

  test "deserialize 3 native works" do
    assert assert Rotate.deserialize(@bin_3_native)          == {:ok, @data_3, ""}
    assert assert Rotate.deserialize(@bin_3_native, :native) == {:ok, @data_3, ""}
  end

  test "deserialize 1 big works" do
    assert assert Rotate.deserialize(@bin_1_big, :big) == {:ok, {0.0,0.0,@data_1}, ""}
  end

  test "deserialize 3 big works" do
    assert assert Rotate.deserialize(@bin_3_big, :big) == {:ok, @data_3, ""}
  end

end
