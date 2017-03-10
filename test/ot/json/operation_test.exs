defmodule OT.JSON.OperationTest do
  use ExUnit.Case, async: true

  doctest OT.JSON.Operation

  alias OT.JSON.Operation

  describe ".invert/1" do
    setup do
      {:ok, op: [%{p: [0], ld: 3}, %{p: [1], li: 2}]}
    end

    test "inverts the op", %{op: op} do
      assert Operation.invert(op) ==
        [%{p: [1], ld: 2}, %{p: [0], li: 3}]
    end

    test "results in proper document state", %{op: op} do
      data = [3, 4, 5, 6, 7]
      {:ok, data_op} = OT.JSON.apply(data, op)
      op_i = Operation.invert(op)
      {:ok, data_op_i} = OT.JSON.apply(data_op, op_i)
      assert data_op_i == data
    end
  end
end
