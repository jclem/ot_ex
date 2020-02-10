defmodule OT.Text.Component do
  @moduledoc """
  An individual unit of work to be performed on a piece of text.

  A component represents a retain or modification of the text:

  - `5`:            Retain 5 characters of the text
  - `%{i:"Hello"}`: Insert the string "Hello"
  - `%{d:"World"}`: Delete the string "World"
  """

  alias OT.Text
  alias Text.Operation

  @typedoc """
  A delete component, in which a string of zero or more characters are deleted
  from the text
  """
  @type delete :: %{d: Text.datum()}

  @typedoc """
  An insert component, in which a string of zero or more characters are inserted
  into the text
  """
  @type insert :: %{i: Text.datum()}

  @typedoc """
  A retain component, in which a number of characters in the text are skipped
  over
  """
  @type retain :: non_neg_integer

  @typedoc """
  An atom declaring the type of a component
  """
  @type type :: :delete | :insert | :retain

  @typedoc """
  The result of comparing two components
  """
  @type comparison :: :eq | :gt | :lt

  @typedoc """
  A single unit of "work" performed on a piece of text
  """
  @type t :: delete | insert | retain

  @doc """
  Invert a component.

  ## Examples

      iex> OT.Text.Component.invert(%{i: "Foo"})
      %{d: "Foo"}

      iex> OT.Text.Component.invert(%{d: "Foo"})
      %{i: "Foo"}

      iex> OT.Text.Component.invert(4)
      4
  """
  @spec invert(t) :: t
  def invert(comp) when is_integer(comp), do: comp
  def invert(%{d: del}), do: %{i: del}
  def invert(%{i: ins}), do: %{d: ins}

  @doc """
  Determine the length of a component.

  ## Examples

      iex> OT.Text.Component.length(4)
      4

      iex> OT.Text.Component.length(%{i: "Foo"})
      3
  """
  @spec length(t) :: non_neg_integer
  def length(comp) when is_integer(comp), do: comp
  def length(%{d: del}), do: String.length(del)
  def length(%{i: ins}), do: String.length(ins)

  @doc """
  Determine the type of a component.

  ## Examples

      iex> OT.Text.Component.type(4)
      :retain

      iex> OT.Text.Component.type(%{i: "Foo"})
      :insert

      iex> OT.Text.Component.type(%{d: "Foo"})
      :delete
  """
  @spec type(t) :: type
  def type(comp) when is_integer(comp), do: :retain
  def type(%{d: _}), do: :delete
  def type(%{i: _}), do: :insert

  @doc """
  Compare the length of two components.

  Will return `:gt` if first is greater than second, `:lt` if first is less
  than second, or `:eq` if they span equal lengths.

  ## Example

      iex> OT.Text.Component.compare(%{i: "Foo"}, 1)
      :gt
  """
  @spec compare(t, t) :: comparison
  def compare(comp_a, comp_b) do
    length_a = __MODULE__.length(comp_a)
    length_b = __MODULE__.length(comp_b)

    cond do
      length_a > length_b -> :gt
      length_a < length_b -> :lt
      true -> :eq
    end
  end

  @doc """
  Join two components into an operation, combining them into a single component
  if they are of the same type.

  ## Example

      iex> OT.Text.Component.join(%{i: "Foo"}, %{i: "Bar"})
      [%{i: "FooBar"}]
  """
  @spec join(t, t) :: Operation.t()
  def join(retain_a, retain_b)
      when is_integer(retain_a) and is_integer(retain_b),
      do: [retain_a + retain_b]

  def join(%{i: ins_a}, %{i: ins_b}),
    do: [%{i: ins_a <> ins_b}]

  def join(%{d: del_a}, %{d: del_b}),
    do: [%{d: del_a <> del_b}]

  def join(comp_a, comp_b),
    do: [comp_a, comp_b]

  @doc """
  Determine whether a comopnent is a no-op.

  ## Examples

      iex> OT.Text.Component.no_op?(0)
      true

      iex> OT.Text.Component.no_op?(%{i: ""})
      true
  """
  @spec no_op?(t) :: boolean
  def no_op?(0), do: true
  def no_op?(%{d: ""}), do: true
  def no_op?(%{i: ""}), do: true
  def no_op?(_), do: false

  @doc """
  Split a component at a given index.

  Returns a tuple containing a new component before the index, and a new
  component after the index.

  ## Examples

      iex> OT.Text.Component.split(4, 3)
      {3, 1}

      iex> OT.Text.Component.split(%{i: "Foo"}, 2)
      {%{i: "Fo"}, %{i: "o"}}
  """
  @spec split(t, non_neg_integer) :: {t, t}
  def split(comp, index) when is_integer(comp) do
    {index, comp - index}
  end

  def split(%{d: del}, index) do
    {%{d: String.slice(del, 0, index)}, %{d: String.slice(del, index..-1)}}
  end

  def split(%{i: ins}, index) do
    {%{i: String.slice(ins, 0, index)}, %{i: String.slice(ins, index..-1)}}
  end

  @doc false
  @spec random(Text.datum()) :: t
  def random(text), do: do_random(random_type(), text)

  @spec do_random(type, Text.datum()) :: t
  defp do_random(:delete, text),
    do: %{d: text}

  defp do_random(:insert, _text),
    do: %{i: Text.init_random(:rand.uniform(16))}

  defp do_random(:retain, text),
    do: String.length(text)

  @spec random_type :: type
  defp random_type, do: Enum.random([:delete, :insert, :retain])
end
