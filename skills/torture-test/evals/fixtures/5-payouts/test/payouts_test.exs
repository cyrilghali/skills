defmodule Marketplace.PayoutsTest do
  use ExUnit.Case, async: true

  alias Marketplace.Payouts

  test "splits evenly between merchants" do
    assert Payouts.split(9_000, ["m1", "m2", "m3"]) ==
             %{"m1" => 3_000, "m2" => 3_000, "m3" => 3_000}
  end

  test "a single merchant gets everything" do
    assert Payouts.split(4_250, ["m1"]) == %{"m1" => 4_250}
  end

  test "zero collected pays zero" do
    assert Payouts.split(0, ["m1", "m2"]) == %{"m1" => 0, "m2" => 0}
  end
end
