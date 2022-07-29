defmodule ExHttpTest do
  use ExUnit.Case
  doctest ExHttp

  test "greets the world" do
    assert ExHttp.hello() == :world
  end
end
