# OT

This Elixir library contains an implementation of
[operational transformation][ot] for strings. It is the same general algorithm
as [ottypes/text][ot_text], but made invertible.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ot` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ot, "~> 0.1.0"}]
end
```

Documentation can be generated with
[ExDoc](https://github.com/elixir-lang/ex_doc) and published on
[HexDocs](https://hexdocs.pm). Once published, the docs can be found at
[https://hexdocs.pm/ot](https://hexdocs.pm/ot).

## Testing

To run the basic tests, run `mix test`. There are also some longer fuzz tests
available that are quite slow. These can be included in the suite by running
`mix test --include slow_fuzz`.

This repo also has [Credo][credo] and [Dialyzer][dialyxir] checks that can be
run with `mix lint`.

[credo]: https://github.com/rrrene/credo
[dialyxir]: https://github.com/jeremyjh/dialyxir
[ot]: https://en.wikipedia.org/wiki/Operational_transformation
[ot_text]: https://github.com/ottypes/text
