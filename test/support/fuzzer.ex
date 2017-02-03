defmodule OT.Fuzzer do
  @moduledoc """
  Provides fuzzing functions for fuzz testing OT functions.
  """

  defmacro composition_fuzz(mod, length \\ 1_000) do
    quote do
      for _ <- 1..unquote(length) do
        initial_value = unquote(mod).init_random(64)

        # Edit the document
        op_a = unquote(mod).random_op(initial_value)
        data_a = unquote(mod).apply!(initial_value, op_a)

        # Make a subsequent edit
        op_b = unquote(mod).random_op(data_a)
        data_b = unquote(mod).apply!(data_a, op_b)

        # Compose the edits
        op_c = unquote(mod).compose(op_a, op_b)
        data_c = unquote(mod).apply!(initial_value, op_c)

        assert data_b == data_c
      end
    end
  end

  defmacro invert_fuzz(mod, length \\ 1_000) do
    quote do
      for _ <- 1..unquote(length) do
        initial_value = unquote(mod).init_random(64)

        # Make an edit
        op_a = unquote(mod).random_op(initial_value)

        # Apply the edit
        data_a = unquote(mod).apply!(initial_value, op_a)

        # Make a subsequent edit
        op_b = unquote(mod).random_op(data_a)

        # Apply the edit
        data_a_b = unquote(mod).apply!(data_a, op_b)

        # Invert the first edit
        op_a_i = unquote(mod).invert(op_a)

        # Transform the undo against subsequent edits
        op_a_i_p = unquote(mod).transform(op_a_i, op_b, :left)

        # Apply the undo
        data_a_b_aip = unquote(mod).apply!(data_a_b, op_a_i_p)

        # Transform the subsequent edit over the undo
        op_b_p = unquote(mod).transform(op_b, op_a_i, :right)

        # Apply the transformed subsequent edit
        data_bp = unquote(mod).apply!(initial_value, op_b_p)

        assert data_a_b_aip == data_bp
      end
    end
  end

  defmacro transformation_fuzz(mod, length \\ 1_000) do
    quote do
      for _ <- 1..unquote(length) do
        initial_value = unquote(mod).init_random(64)

        # Make to concurrent edits
        op_a = unquote(mod).random_op(initial_value)
        op_b = unquote(mod).random_op(initial_value)

        side = Enum.random([:left, :right])
        other_side = if side == :left, do: :right, else: :left

        # Transform the edits
        op_a_prime = unquote(mod).transform(op_a, op_b, side)
        op_b_prime = unquote(mod).transform(op_b, op_a, other_side)

        data_a = initial_value
                 |> unquote(mod).apply!(op_a)
                 |> unquote(mod).apply!(op_b_prime)
        data_b = initial_value
                 |> unquote(mod).apply!(op_b)
                 |> unquote(mod).apply!(op_a_prime)

        assert data_a == data_b
      end
    end
  end
end
