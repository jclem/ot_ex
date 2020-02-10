defmodule OT.Text.JSStringTest do
  alias OT.Text.JSString
  use ExUnit.Case

  doctest(OT.Text.JSString)

  test "it handles unicode values the same way as JavaScript does" do
    assert JSString.length("👩‍❤️‍💋‍👩") == 11
    assert JSString.length("💩") == 2
    assert JSString.length("🎖") == 2
    assert JSString.length("😛") == 2
    assert JSString.length("🤹🏾‍♀️") == 7
    assert JSString.length("é") == 1
    assert JSString.length("❤") == 1
    assert JSString.length("\r\n") == 2
    assert JSString.length("\n") == 1
  end

  test "it can split unicode values the same way as JavaScript does" do
    assert JSString.split_at("👩‍❤️‍💋‍👩👩‍❤️‍💋‍👩", 11) == {"👩‍❤️‍💋‍👩", "👩‍❤️‍💋‍👩"}
    assert JSString.split_at("💩💩", 2) == {"💩", "💩"}

    input = "Emoji: 💩, nice emoji."
    expected = {"Emoji: 💩", ", nice emoji."}

    assert JSString.split_at(input, 9) == expected
  end

  test "it can count exactly like javascript, including emojis and crlf" do
    big_code = File.read!(Path.join(__DIR__, "big_code.txt"))

    assert JSString.length(big_code) == 4_845_204
  end

  test "can do a binary part" do
    code = "\r\n"

    assert {"\r", "\n"} == JSString.split_at(code, 1)
  end
end
