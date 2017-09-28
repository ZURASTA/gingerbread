Application.ensure_all_started(:gingerbread_service)
Application.ensure_all_started(:ecto)

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Gingerbread.Service.Repo, :manual)
