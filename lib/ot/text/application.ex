defmodule OT.Text.Application do
  @moduledoc """
  The application of a text operation to a text datum.
  """

  alias OT.Text, as: Text

  @typedoc """
  The result of an `apply/2` function call, representing either success or error
  to apply an operation.
  """
  @type apply_result :: {:ok, OT.Text.datum}
                      | {:error, :unmatched_delete | :retain_too_long}


  @doc """
  Apply an operation to a piece of text.

  Given a piece of text and an operation, iterate over each component in the
  operation and apply it to the given text. If the operation is valid, the
  function will return `{:ok, new_state}` where `new_state` is the text with
  the operation applied to it. If the operation is invalid, an
  `{:error, atom}` tuple will be returned.

  ## Examples

      iex> OT.Text.Application.apply("Foo", [3, %{i: " Bar"}])
      {:ok, "Foo Bar"}

      iex> OT.Text.Application.apply(
      ...>   "Fox Baz", [2, %{d: "x"}, %{i: "o"}, 3, %{d: "z"}, %{i: "r"}])
      {:ok, "Foo Bar"}

      iex> OT.Text.Application.apply("Foo Baz", [3, %{i: " Bar"}])
      {:ok, "Foo Bar Baz"}

      iex> OT.Text.Application.apply("Foo", [%{d: "Foos"}])
      {:error, :unmatched_delete}

      iex> OT.Text.Application.apply("Foo", [4])
      {:error, :retain_too_long}

      iex> OT.Text.Application.apply("Fo", [2, %{i: "o"}, 4])
      {:error, :retain_too_long}

  ## Errors

  - `:unmatched_delete` A delete component did not match the text it would have
    deleted in the text
  - `:retain_too_long` A retain component skipped past the end of the text
  """
  @spec apply(Text.datum, Text.operation) :: apply_result
  def apply(text, op), do: do_apply(text, op)

  @spec do_apply(Text.datum, Text.operation, Text.datum) :: apply_result
  defp do_apply(text, op, result \\ "")

  defp do_apply(text, [], result) do
    {:ok, result <> text}
  end

  defp do_apply(text, [%{d: del} | op], result) do
    deleted = String.slice(text, 0..String.length(del) - 1)

    if del == deleted do
      text
      |> String.slice(String.length(del)..-1)
      |> do_apply(op, result)
    else
      {:error, :unmatched_delete}
    end
  end

  defp do_apply(text, [%{i: ins} | op], result) do
    text
    |> do_apply(op, result <> ins)
  end

  defp do_apply(text, [ret | op], result) when is_integer(ret) do
    if ret <= String.length(text) do
      text
      |> String.slice(ret..-1)
      |> do_apply(op, result <> String.slice(text, 0..ret - 1))
    else
      {:error, :retain_too_long}
    end
  end
end
