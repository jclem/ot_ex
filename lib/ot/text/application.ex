defmodule OT.Text.Application do
  @moduledoc """
  The application of a text operation to a text datum.
  """

  alias OT.Text, as: Text
  alias Text.Operation

  @typedoc """
  The result of an `apply/2` function call, representing either success or error
  to apply an operation.
  """
  @type apply_result :: {:ok, OT.Text.datum}
                      | {:error, :delete_mismatch | :retain_too_long}

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

      iex> OT.Text.Application.apply("Foo", [%{d: "Foos"}])
      {:error, :delete_mismatch}

  ## Errors

  - `:delete_mismatch` A delete component did not match the text it would have
    deleted in the text
  - `:retain_too_long` A retain component skipped past the end of the text
  """
  @spec apply(Text.datum, Operation.t) :: apply_result
  def apply(text, op), do: do_apply(text, op)

  @spec do_apply(Text.datum, Operation.t, Text.datum) :: apply_result
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
      {:error, :delete_mismatch}
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
