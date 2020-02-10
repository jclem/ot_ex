defmodule OT.Text.JSString do
  @moduledoc """
  Responsible for providing the string utilities that are compatible
  with JavaScript UTF-16LE formatting. Eg. an emoji is 2 bytes in JS,
  while it's 4 in Elixir.
  """
  import Kernel, except: [length: 1]

  defmodule Convert do
    @spec utf16le_to_utf8(binary) :: bitstring
    def utf16le_to_utf8(binary), do: utf16le_to_utf8(binary, "")

    defp utf16le_to_utf8(<<codepoint::utf16-little, rest::binary>>, acc) do
      utf16le_to_utf8(rest, <<acc::binary, codepoint::utf8>>)
    end

    defp utf16le_to_utf8("", acc), do: acc

    @spec utf8_to_utf16le(binary) :: bitstring
    def utf8_to_utf16le(binary), do: utf8_to_utf16le(binary, "")

    defp utf8_to_utf16le(<<codepoint::utf8, rest::binary>>, acc) do
      utf8_to_utf16le(rest, <<acc::binary, codepoint::utf16-little>>)
    end

    defp utf8_to_utf16le("", acc), do: acc
  end

  defp js_to_elixir(s) do
    :iconv.convert("utf-8", "utf-16le", s)

    # Enable if we suspect that iconv is a problem
    # Convert.utf8_to_utf16le(s)
  end

  defp elixir_to_js(s) do
    :iconv.convert("utf-16le", "utf-8", s)

    # Enable if we suspect that iconv is a problem
    # Convert.utf16le_to_utf8(s)
  end

  defp binary_split_at(binary, position) do
    binary_size = byte_size(binary)
    remainder = binary_size - position
    start = binary_part(binary, 0, position)
    last = binary_part(binary, position, remainder)

    {start, last}
  end

  # Takes into account double carriage returns as 2 bytes (so \r\n is 2 chars) and the JS
  # way of handling unicode characters, where JS has a maximum of 65535 (2 bytes) for a character, and
  # elixir supports higher.
  def length(s) do
    ceil((s |> js_to_elixir() |> byte_size()) / 2)
  end

  @doc """
    Takes into account double carriage returns as 2 bytes (so \r\n is 2 chars) and the way JS
    handles unicode values.

    ## Examples
      iex> OT.Text.JSString.split_at("aa", 1)
      {"a", "a"}
  """
  @spec split_at(binary, non_neg_integer) :: {binary, binary}
  def split_at(s, ret) do
    bytes = js_to_elixir(s)
    byte_ret = ret * 2
    {start, last} = binary_split_at(bytes, byte_ret)

    {elixir_to_js(start), elixir_to_js(last)}
  end

  @spec slice(binary, integer, integer) :: binary

  def slice(_, _, 0) do
    ""
  end

  def slice(string, 0, -1) do
    string
  end

  def slice(string, 0, len) when len >= 0 do
    {start, _end} = split_at(string, len)
    start
  end

  def slice(string, start, -1) do
    {_start, last} = split_at(string, start)
    last
  end

  def slice(string, start, len) when start >= 0 and len >= 0 do
    case String.Unicode.split_at(string, start) do
      {_, nil} ->
        ""

      {start_bytes, rest} ->
        {len_bytes, _} = String.Unicode.split_at(rest, len)
        binary_part(string, start_bytes, len_bytes)
    end
  end

  def slice(string, start, len) when start < 0 and len >= 0 do
    start = length(string) + start

    case start >= 0 do
      true -> slice(string, start, len)
      false -> ""
    end
  end
end
