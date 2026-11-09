defmodule Feed.Cursor do
  @moduledoc """
  Opaque pagination cursor for the public `GET /posts?after=<cursor>` endpoint.

  A cursor points at the last row of the previous page: the row's sort key
  (the post title, the list is sorted by title) and its integer id as a
  tie-breaker. Clients receive the cursor in `next_cursor` and send it back
  verbatim to fetch the following page.
  """

  @type t :: %{title: String.t(), id: pos_integer()}

  @spec encode(t()) :: String.t()
  def encode(%{title: title, id: id}) do
    Base.url_encode64("#{title}|#{id}", padding: false)
  end

  @spec decode(String.t()) :: {:ok, t()} | {:error, :invalid_cursor}
  def decode(cursor) do
    with {:ok, raw} <- Base.url_decode64(cursor, padding: false),
         [title, id] <- String.split(raw, "|"),
         {id, ""} <- Integer.parse(id) do
      {:ok, %{title: title, id: id}}
    else
      _ -> {:error, :invalid_cursor}
    end
  end
end
