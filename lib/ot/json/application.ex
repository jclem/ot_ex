defmodule OT.JSON.Application do
  @moduledoc """
  The application of a JSON operation to a JSON datum.
  """

  alias OT.{JSON, Text}
  alias JSON.{Component, Operation}

  @typedoc """
  The result of an `apply/2` function call, representing either success or error
  in applying an operation.
  """
  @type apply_result :: {:ok, OT.JSON.datum}
                      | Text.Application.apply_result

  @typedoc "An argument to the implicit function call of a component"
  @type argument :: {JSON.value, JSON.value} | JSON.value | Component.index

  @typep component_function
         :: ((JSON.datum, Component.path, argument) -> JSON.datum)

  @doc """
  Apply an operation to a JSON datum.

  Given the JSON datum and an operation, iterate over each component in the
  operation and apply it to the given JSON datum. Where nested types are found,
  their respective modules will be used to apply components.

  If the operation is valid, the function will return `{:ok, new_state}` where
  `new_state` is the JSON datum with the operation applied. If the application
  fails, an `{:error, atom}` tuple will be returned.

  ## Examples

      iex> OT.JSON.Application.apply(["Bar"], [%{p: [0], ld: "Bar", li: "Baz"}])
      ["Baz"]

      iex> OT.JSON.Application.apply([], [%{p: [0], li: "Baz"}])
      ["Baz"]

      iex> OT.JSON.Application.apply(["Bar"], [%{p: [0], ld: "Bar"}])
      []

      iex> OT.JSON.Application.apply([1, 3, 2], [%{p: [1], lm: 2}])
      [1, 2, 3]

      iex> OT.JSON.Application.apply(%{"Bar" => "Baz"},
      ...>                           [%{p: ["Bar"], od: "Baz", oi: "Qux"}])
      %{"Bar" => "Qux"}

      iex> OT.JSON.Application.apply(%{},
      ...>                           [%{p: ["Bar"], oi: "Qux"}])
      %{"Bar" => "Qux"}

      iex> OT.JSON.Application.apply(%{"Bar" => "Baz"},
      ...>                           [%{p: ["Bar"], od: "Baz"}])
      %{}

      iex> OT.JSON.Application.apply([], [%{p: [0], li: "Baz"}])
      ["Baz"]

      iex> OT.JSON.Application.apply(["Bar"], [%{p: [0], ld: "Bar"}])
      []

      iex> OT.JSON.Application.apply([0], [%{p: [0], na: 1}])
      [1]

      iex> OT.JSON.Application.apply(
      ...>   ["Foo"], [%{p: [0], t: "text", o: [3, %{i: "Bar"}]}])
      ["FooBar"]
  """
  @spec apply(JSON.datum, Operation.t) :: apply_result
  def apply(json, op), do: Enum.reduce(op, json, &do_apply/2)

  @spec apply!(JSON.datum, Operation.t) :: JSON.datum | no_return
  def apply!(json, op) do
    with {:ok, result} <- __MODULE__.apply(json, op) do
      result
    else
      {:error, error} -> raise to_string(error)
    end
  end

  @spec do_apply(Component.t, JSON.datum) :: JSON.datum | no_return
  defp do_apply(%{p: path, ld: del_object, li: ins_object}, json),
    do: apply_in(json, path, {del_object, ins_object}, &list_replace/3)
  defp do_apply(%{p: path, ld: del_object}, json),
    do: apply_in(json, path, del_object, &list_delete/3)
  defp do_apply(%{p: path, li: ins_object}, json),
    do: apply_in(json, path, ins_object, &list_insert/3)
  defp do_apply(%{p: path, lm: index}, json),
    do: apply_in(json, path, index, &list_move/3)
  defp do_apply(%{p: path, od: del_object, oi: ins_object}, json),
    do: apply_in(json, path, {del_object, ins_object}, &object_replace/3)
  defp do_apply(%{p: path, od: del_object}, json),
    do: apply_in(json, path, del_object, &object_delete/3)
  defp do_apply(%{p: path, oi: ins_object}, json),
    do: apply_in(json, path, ins_object, &object_insert/3)
  defp do_apply(%{p: path, na: number}, json),
    do: apply_in(json, path, number, &numeric_add/3)
  defp do_apply(%{p: path, t: type, o: op}, json),
    do: apply_in(json, path, {type, op}, &apply_subtype/3)

  @spec apply_in(JSON.datum, Component.path, argument, component_function)
                 :: JSON.datum | no_return
  defp apply_in(json, [path_segment], arg, func),
    do: func.(json, path_segment, arg)

  defp apply_in(json, path, arg, func) do
    update_in(json, build_path_keys(Enum.slice(path, 0..-2), json), fn target ->
      func.(target, List.last(path), arg)
    end)
  end

  @spec apply_subtype(JSON.datum, Component.key | Component.index,
                      {String.t, list}) :: JSON.datum
  defp apply_subtype(value, index, {"text", op}) when is_list(value) do
    old_string = Enum.at(value, index)
    new_string = Text.apply!(old_string, op)
    list_replace(value, index, {old_string, new_string})
  end

  defp apply_subtype(value, key, {"text", op}) when is_map(value) do
    old_string = Map.get(value, key)
    new_string = Text.apply!(old_string, op)
    object_replace(value, key, {old_string, new_string})
  end

  @spec list_replace(JSON.json_list, Component.index, {JSON.value, JSON.value})
        :: JSON.json_list
  defp list_replace(list, index, {del, ins}) do
    list
    |> list_delete(index, del)
    |> list_insert(index, ins)
  end

  @spec list_delete(JSON.json_list, Component.index, JSON.value)
        :: JSON.json_list
  defp list_delete(list, index, _value) do
    # TODO: Verify the object being deleted is correct
    List.delete_at(list, index)
  end

  @spec list_insert(JSON.json_list, Component.index, JSON.value)
        :: JSON.json_list
  defp list_insert(list, index, value) do
    List.insert_at(list, index, value)
  end

  @spec list_move(JSON.json_list, Component.index, Component.index)
        :: JSON.json_list
  defp list_move(list, old_index, new_index) do
    value = Enum.at(list, old_index)

    list
    |> List.delete_at(old_index)
    |> List.insert_at(new_index, value)
  end

  @spec object_replace(JSON.json_map, Component.key, {JSON.value, JSON.value})
        :: JSON.json_map
  defp object_replace(map, key, {del, ins}) do
    map
    |> object_delete(key, del)
    |> object_insert(key, ins)
  end

  @spec object_delete(JSON.json_map, Component.key, JSON.value) :: JSON.json_map
  defp object_delete(map, key, _value) do
    # TODO: Verify the object being deleted is correct
    Map.delete(map, key)
  end

  @spec object_insert(JSON.json_map, Component.key, JSON.value) :: JSON.json_map
  defp object_insert(map, key, value) do
    Map.put(map, key, value)
  end

  @spec numeric_add(JSON.datum, Component.index | Component.key, number)
        :: JSON.datum
  defp numeric_add(value, index, increment) when is_list(value) do
    old_value = Enum.at(value, index)
    new_value = old_value + increment
    list_replace(value, index, {old_value, new_value})
  end

  defp numeric_add(value, key, increment) when is_map(value) do
    old_value = Map.get(value, key)
    new_value = old_value + increment
    object_replace(value, key, {old_value, new_value})
  end

  @spec build_path_keys(Component.path, JSON.datum) :: [(... -> any) | String.t]
  defp build_path_keys(path, json) do
    path
    |> Enum.reduce({json, []}, &do_build_path_keys/2)
    |> elem(1)
    |> Enum.reverse
  end

  @spec do_build_path_keys(Component.key | Component.index,
                           {JSON.datum, Component.path})
        :: {JSON.datum, [(... -> any)| String.t]}
  defp do_build_path_keys(key, {json, keys}) when is_list(json) do
    {Enum.at(json, key), [Access.at(key) | keys]}
  end

  defp do_build_path_keys(key, {json, keys}) when is_map(json) do
    {Map.get(json, key), [key | keys]}
  end
end
