op_a = [
  %{d: "LzUXbWXAoWyE1_J4iGpKw4WWUC6-enZd17T"},
  %{i: "9TUem5mE"},
  %{i: "i1II3ymwQqxuiyLy"},
  0,
  8000,
  %{d: "3B9UVicJSj3r8S2V"},
  %{d: "M1Qd7RPNA3"},
  3
]

op_b = [
  %{d: "9TUem5mEi1II3ymwQqxuiy"},
  %{d: "L"},
  %{i: "IlEF"},
  0,
  8000,
  %{i: "SNO9aAL822C6Z"},
  %{i: "mqO8n06sAdoE5"},
  %{i: "b5t"},
  %{d: "yp"},
  %{d: "0g"}
]

Benchee.run(
  %{
    "elixir" => fn ->
      OT.Text.Composition.compose(op_a, op_b)
    end,
    "rust" => fn ->
      OT.Text.Composition2.compose(op_a, op_b)
    end
  },
  memory_time: 2
)
