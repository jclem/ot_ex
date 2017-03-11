defmodule OT.JSON.Component do
  @moduledoc """
  An individual unit of work to be performed on a JSON datum.

  A component has a path and one of several edits:

  - `ld` and `li`: Replace a value in a list
  - `ld`:          Delete a value from a list
  - `li`:          Insert a value into a list
  - `lm`:          Move a value within a list
  - `od` and `oi`: Replace a value in an object
  - `od`:          Delete a value from an object
  - `oi`:          Insert a value into an object
  - `na`:          Increment a numeric value (use negative to subtract)
  - `t` and `o`:   Use subtype `t` to apply operation `o` to a value
  """

  alias OT.{JSON, Text}
  alias JSON.Operation
  alias Text.Operation, as: TextOperation

  @typedoc "A key pointing to a location in an object"
  @type key :: String.t

  @typedoc "A number pointing to an index in a list"
  @type index :: non_neg_integer

  @typedoc "A path pointing to a specific place in a JSON datum"
  @type path :: [key | index]

  @typedoc """
  A list replace component, in which a value is replaced in a list
  """
  @type list_replace :: %{p: path, ld: JSON.datum, li: JSON.datum}

  @typedoc """
  A list delete component, in which a value is deleted from a list
  """
  @type list_delete :: %{p: path, ld: JSON.datum}

  @typedoc """
  A list insert component, in which a value is inserted into a list
  """
  @type list_insert :: %{p: path, li: JSON.datum}

  @typedoc """
  A list move component, in which a value moved within a list
  """
  @type list_move :: %{p: path, lm: JSON.datum}

  @typedoc """
  An object replace component, in which a value is replaced in an object
  """
  @type object_replace :: %{p: path, od: JSON.datum, oi: JSON.datum}

  @typedoc """
  An object delete component, in which a value is deleted from an object
  """
  @type object_delete :: %{p: path, od: JSON.datum}

  @typedoc """
  An object insert component, in which a value is inserted into an object
  """
  @type object_insert :: %{p: path, oi: JSON.datum}

  @typedoc """
  A numeric add component, in which a value is added to
  """
  @type numeric_add :: %{p: path, na: number}

  @typedoc """
  A subtype component, in which a subtype operation is performed
  """
  @type subtype :: %{p: path, t: String.t, o: list}

  @typedoc """
  An atom declaring the type of a component
  """
  @type type :: :list_replace | :list_delete | :list_insert | :list_move
              | :object_replace | :object_delete | :object_insert | :numeric_add
              | :subtype

  @typedoc """
  A single unit of work performed on a JSON datum.
  """
  @type t :: list_replace | list_delete | list_insert | list_move
             | object_replace | object_delete | object_insert | numeric_add
             | subtype

  @doc """
  Invert a single component.

  ## Example

      iex> OT.JSON.Component.invert(%{p: [0], ld: 1})
      %{p: [0], li: 1}
  """
  @spec invert(t) :: t
  def invert(%{p: p, ld: ld, li: li}),
    do: %{p: p, ld: li, li: ld}
  def invert(%{p: p, ld: ld}),
    do: %{p: p, li: ld}
  def invert(%{p: p, li: li}),
    do: %{p: p, ld: li}
  def invert(%{p: p, lm: lm}),
    do: %{p: Enum.slice(p, 0..-2) ++ [lm], lm: List.last(p)}
  def invert(%{p: p, od: od, oi: oi}),
    do: %{p: p, od: oi, oi: od}
  def invert(%{p: p, od: od}),
    do: %{p: p, oi: od}
  def invert(%{p: p, oi: oi}),
    do: %{p: p, od: oi}
  def invert(%{p: p, na: na}),
    do: %{p: p, na: na * -1}
  def invert(%{p: p, t: "text", o: o}),
    do: %{p: p, t: "text", o: TextOperation.invert(o)}

  @doc """
  Join two components into an operation, possibly combining them into a single
  component.
  """
  @spec join(t, t) :: Operation.t

  # text/text
  def join(%{p: p, t: "text", o: o_a}, %{p: p, t: "text", o: o_b}),
    do: [%{p: p, t: "text", o: Text.compose(o_a, o_b)}]

  # na/na
  def join(%{p: p, na: na_a}, %{p: p, na: na_b}),
    do: [%{p: p, na: na_a + na_b}]

  # list replace/list replace
  def join(%{p: p, ld: ld, li: li}, %{p: p, ld: li, li: li_b}),
    do: [%{p: p, ld: ld, li: li_b}]

  # list replace/list delete
  def join(%{p: p, ld: ld, li: li}, %{p: p, ld: li}),
    do: [%{p: p, ld: ld}]

  # list replace/list insert
  def join(%{p: p, ld: ld, li: li}, %{p: p, li: li_b}),
    do: [%{p: p, ld: ld, li: li}, %{p: p, li: li_b}]

  # list delete/list replace
  def join(comp_a = %{p: p, ld: _}, comp_b = %{p: p, ld: _, li: _}),
    do: [comp_a, comp_b]

  # list delete/list delete
  def join(comp_a = %{p: p, ld: _}, comp_b = %{p: p, ld: _}),
    do: [comp_a, comp_b]

  # list delete/list insert
  def join(%{p: p, ld: ld}, %{p: p, li: li}),
    do: [%{p: p, ld: ld, li: li}]

  # list insert/list replace
  def join(%{p: p, li: li}, %{p: p, ld: li, li: li_b}),
    do: [%{p: p, li: li_b}]

  # list insert/list delete
  def join(%{p: p, li: li}, %{p: p, ld: li}),
    do: []

  # list insert/list insert
  def join(comp_a = %{p: p, li: _}, comp_b = %{p: p, li: _}),
    do: [comp_a, comp_b]

  # object replace/object replace
  def join(%{p: p, od: od, oi: oi}, %{p: p, od: oi, oi: oi_b}),
    do: [%{p: p, od: od, oi: oi_b}]

  # object replace/object delete
  def join(%{p: p, od: od, oi: oi}, %{p: p, od: oi}),
    do: [%{p: p, od: od}]

  # object replace/object insert
  def join(comp_a = %{p: p, od: _, oi: _}, comp_b = %{p: p, oi: _}),
    do: [comp_a, comp_b]

  # object delete/object replace
  def join(comp_a = %{p: p, od: _}, comp_b = %{p: p, od: _, oi: _}),
    do: [comp_a, comp_b]

  # object delete/object delete
  def join(comp_a = %{p: p, od: _}, comp_b = %{p: p, od: _}),
    do: [comp_a, comp_b]

  # object delete/object insert
  def join(%{p: p, od: od}, %{p: p, oi: oi}),
    do: [%{p: p, od: od, oi: oi}]

  # object insert/object replace
  def join(%{p: p, oi: oi}, %{p: p, od: oi, oi: oi_b}),
    do: [%{p: p, oi: oi_b}]

  # object insert/object delete
  def join(%{p: p, oi: oi}, %{p: p, od: oi}),
    do: []

  # object insert/object insert
  def join(comp_a = %{p: p, oi: _}, comp_b = %{p: p, oi: _}),
    do: [comp_a, comp_b]

  # else
  def join(comp_a, comp_b),
    do: [comp_a, comp_b]
end
