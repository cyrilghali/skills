defmodule Feed.CursorTest do
  use ExUnit.Case, async: true

  alias Feed.Cursor

  test "round-trips a simple cursor" do
    cursor = %{title: "Hello world", id: 42}
    assert Cursor.decode(Cursor.encode(cursor)) == {:ok, cursor}
  end

  test "round-trips accented titles" do
    cursor = %{title: "Café résumé", id: 7}
    assert Cursor.decode(Cursor.encode(cursor)) == {:ok, cursor}
  end

  test "round-trips an empty title" do
    cursor = %{title: "", id: 1}
    assert Cursor.decode(Cursor.encode(cursor)) == {:ok, cursor}
  end

  test "rejects garbage" do
    assert Cursor.decode("not base64!!") == {:error, :invalid_cursor}
  end

  test "rejects a non-integer id" do
    assert Cursor.decode(Base.url_encode64("title|abc", padding: false)) ==
             {:error, :invalid_cursor}
  end
end
