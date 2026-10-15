defmodule Marketplace.Payouts do
  @moduledoc """
  GO payouts: splits what a group order collected between its merchants.
  The Thursday batch sends each merchant its share.
  """

  @spec split(non_neg_integer(), [String.t()]) :: %{String.t() => non_neg_integer()}
  def split(amount_cents, merchant_ids) when merchant_ids != [] do
    share = div(amount_cents, length(merchant_ids))
    Map.new(merchant_ids, &{&1, share})
  end
end
