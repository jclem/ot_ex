ExUnit.start()
ExUnit.configure(exclude: [:slow_fuzz])

"./test/support"
|> File.ls!()
|> Enum.each(&Code.require_file("support/#{&1}", __DIR__))
