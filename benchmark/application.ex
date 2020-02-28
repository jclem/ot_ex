defmodule OTHelpers do
  def ex_to_js_op(%{i: text}), do: text
  def ex_to_js_op(%{d: text}), do: -OT.Text.JSString.length(text)
  def ex_to_js_op(x), do: x

  def ex_to_js_ot(ot) do
    Enum.map(ot, &ex_to_js_op/1)
  end

  def js_to_ex_op(%{"i" => text}), do: %{i: text}
  # Dummy function for elixir, it expects a string of n length,
  # but doesn't use the contents. Just send a dummy
  def js_to_ex_op(%{"d" => num}), do: %{d: num}
  def js_to_ex_op(x), do: x

  def js_to_ex_ot(ot) do
    Enum.map(ot, &js_to_ex_op/1)
  end
end

code = File.read!(Path.join(__DIR__, "big_code.txt"))
big_op = Jason.decode!(File.read!(Path.join(__DIR__, "big_operation.txt")))
big_ex_op = OTHelpers.js_to_ex_ot(big_op)

code2 = File.read!(Path.join(__DIR__, "big_code2.txt"))
big_op2 = Jason.decode!(File.read!(Path.join(__DIR__, "big_operation2.txt")))
big_ex_op2 = OTHelpers.js_to_ex_ot(big_op2)

Benchee.run(
  %{
    "apply" => fn ->
      OT.Text.Application.apply!(code, [28965, %{i: "B"}, %{d: 11}, 30952])
    end,
    "apply_del_string" => fn ->
      OT.Text.Application.apply!(code, [28965, %{i: "B"}, %{d: "CodeSandbox"}, 30952])
    end,
    "big_op" => fn ->
      OT.Text.Application.apply!(code, big_ex_op)
    end,
    "big_op2" => fn ->
      OT.Text.Application.apply!(code2, big_ex_op2)
    end
  },
  memory_time: 2
)
