defmodule OT.Text.Application do
  @moduledoc """
  The application of a text operation to a piece of text.

  CodeSandbox custom version to ignore error_mismatch, as JS doesn't provide the deletion material
  """

  alias OT.Text, as: Text
  alias Text.Operation

  @typedoc """
  The result of an `apply/2` function call, representing either success or error
  in application of an operation
  """
  @type apply_result ::
          {:ok, OT.Text.datum()}
          | {:error, binary}

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
      {:error, "The operation's base length must be equal to the string's length. String length: 3, base length: 4"}

  ## Errors
  - `:delete_mismatch` A delete component did not match the text it would have
    deleted in the text
  - `:retain_too_long` A retain component skipped past the end of the text
  """
  @spec apply(Text.datum(), Operation.t()) :: apply_result
  def apply(text, op) do
    Elixir.Rust.OT.apply(text, op)
  end
end
