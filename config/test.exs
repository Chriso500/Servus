use Mix.Config

config :logger,
  level: :info
  #level: :debug

config :servus,
database: %{
  rootpath: "./db",
  testmode: "?mode=memory"
}

#config :junit_formatter,
#  print_report_file: true