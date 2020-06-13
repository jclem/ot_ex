new_op = [2, %{i: "vc"}]
conc_op = [1, %{i: "ef"}, 1]

Benchee.run(
  %{
    "elixir" => fn ->
      OT.Text.Transformation.transform(new_op, conc_op, :left)
    end,
    "rust" => fn ->
      OT.RustTest.transform(new_op, conc_op)
    end
  },
  memory_time: 2
)
