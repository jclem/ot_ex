new_op = [2, %{i: "vc"}]
conc_op = [1, %{i: "ef"}, 1]

Benchee.run(
  %{
    "simple_op" => fn ->
      OT.Text.Transformation.transform(new_op, conc_op, :left)
    end
  },
  memory_time: 2
)
