defmodule OT.Text do
  @moduledoc """
  A [TP1][tp1] operational transformation implementation based heavily on
  [ot-text][ot_text] by Joseph Gentle, but modified to be invertable.

  In this type, an operation is a list of components that iterate over a piece
  of text. A component represents a retain or modification of the text:

  - `5`:            Retain 5 characters of the text
  - `%{i:"Hello"}`: Insert the string "Hello"
  - `%{d:"World"}`: Delete the string "World"

  [tp1]: https://en.wikipedia.org/wiki/Operational_transformation#Convergence_properties
  [ot_text]: https://github.com/ottypes/text/blob/76870df362a1ecb615b15429f1cd6e6b99349542/lib/text.js
  """

  @behaviour OT.Type

  @typedoc "A string that this OT type can operate on"
  @type datum :: String.t

  @typedoc """
  A delete component, in which a string of zero or more characters are deleted
  from the text datum
  """
  @type delete :: %{d: datum}

  @typedoc """
  An insert component, in which a string of zero or more characters are inserted
  into the text datum
  """
  @type insert :: %{i: datum}

  @typedoc """
  A retain component, in which a number of characters in the text datum are
  skipped over.
  """
  @type retain :: non_neg_integer

  @typedoc """
  A single unit of "work" performed on a piece of text.
  """
  @type component :: delete | insert | retain

  @typedoc """
  An operation, which is a list consisting of `t:retain/0`, `t:insert/0`, and
  `t:delete/0` components
  """
  @type operation :: [component]

  @typedoc """
  The result of an `apply/2` function call, representing either success or error
  to apply an operation.
  """
  @type apply_result :: {:ok, datum}
                      | {:error, :unmatched_delete | :retain_too_long}

  @doc """
  Initialize a blank text datum.
  """
  @spec init :: datum
  def init, do: ""

  @doc """
  Apply an operation to a piece of text.

  This function iterates over each component in an operation and applies them
  to the given text. If the operation is valid, it returns `{:ok, new_state}`
  where `new_state` is a new string with the operation applied to it. Otherwise,
  it returns an `{:error, error_atom}` tuple.

  ## Examples

      iex> OT.Text.apply("Foo", [3, %{i: " Bar"}])
      {:ok, "Foo Bar"}

      iex> OT.Text.apply("Fox Baz",
      ...>               [2, %{d: "x"}, %{i: "o"}, 3, %{d: "z"}, %{i: "r"}])
      {:ok, "Foo Bar"}

      iex> OT.Text.apply("Foo", [%{d: "Foos"}])
      {:error, :unmatched_delete}

      iex> OT.Text.apply("Foo", [4])
      {:error, :retain_too_long}

      iex> OT.Text.apply("Fo", [2, %{i: "o"}, 4])
      {:error, :retain_too_long}

  ## Errors

  - `:unmatched_delete` A delete component did not match the text it would have
    deleted in the text
  - `:retain_too_long` A retain component skipped past the end of the text
  """
  @spec apply(datum, operation) :: apply_result
  def apply(text, op), do: do_apply(text, op)

  @spec do_apply(datum, operation, datum) :: apply_result
  defp do_apply(text, op, result \\ "")

  defp do_apply(_text, [], result) do
    {:ok, result}
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
