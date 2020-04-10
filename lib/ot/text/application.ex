defmodule OT.Text.Application do
  @moduledoc """
  The application of a text operation to a piece of text.

  CodeSandbox custom version to ignore error_mismatch, as JS doesn't provide the deletion material
  """

  alias OT.Text, as: Text
  alias Text.Operation
  alias Text.JSString

  @typedoc """
  The result of an `apply/2` function call, representing either success or error
  in application of an operation
  """
  @type apply_result ::
          {:ok, OT.Text.datum()}
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
  @spec apply(Text.datum(), Operation.t()) :: apply_result
  def apply(text, op) do
    target_length = count_length(op)

    with {:ok, result} <- do_apply(text, op) do
      result_length = JSString.length(result)

      if result_length == target_length do
        {:ok, result}
      else
        {:error, {:length_mismatch, result_length, target_length}}
      end
    end
  end

  @spec count_length(Operation.t(), number) :: number
  def count_length(op, result \\ 0)

  def count_length([], result) do
    result
  end

  def count_length([%{d: _del} | op], result) do
    count_length(op, result)
  end

  def count_length([%{i: ins} | op], result) do
    count_length(op, result + JSString.length(ins))
  end

  def count_length([ret | op], result) do
    count_length(op, result + ret)
  end

  @spec count_base_length(Operation.t(), number) :: number
  def count_base_length(op, result \\ 0)

  def count_base_length([], result) do
    result
  end

  def count_base_length([%{d: del} | op], result) do
    count_base_length(op, result + JSString.length(del))
  end

  def count_base_length([%{i: _ins} | op], result) do
    count_base_length(op, result)
  end

  def count_base_length([ret | op], result) do
    count_base_length(op, result + ret)
  end

  @doc """
  Same as `apply/2`, but raises if the application fails.
  """
  @spec apply!(Text.datum(), Operation.t()) :: Text.datum() | no_return
  def apply!(text, op) do
    with {:ok, result} <- __MODULE__.apply(text, op) do
      result
    else
      {:error, error} -> raise to_string(error)
    end
  end

  @spec do_apply(Text.datum(), Operation.t(), Text.datum()) :: apply_result
  defp do_apply(text, op, result \\ "")

  defp do_apply(text, [], result) do
    {:ok, result <> text}
  end

  defp do_apply(text, [%{d: del} | op], result) when is_integer(del) do
    if del <= JSString.length(text) do
      {_deleted, text} = JSString.split_at(text, del)

      text
      |> do_apply(op, result)
    else
      {:error, :delete_mismatch}
    end
  end

  # Add support for d: "aaaa" usecases, is deprecated in CSB now
  defp do_apply(text, [%{d: del} | op], result) do
    do_apply(text, [%{d: JSString.length(del)} | op], result)
  end

  defp do_apply(text, [%{i: ins} | op], result) do
    text
    |> do_apply(op, result <> ins)
  end

  defp do_apply(text, [ret | op], result) when is_integer(ret) do
    if ret <= JSString.length(text) do
      {retained, text} = JSString.split_at(text, ret)

      text
      |> do_apply(op, result <> retained)
    else
      {:error, :retain_too_long}
    end
  end
end
