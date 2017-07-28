defmodule Gingerbread.Service do
    @moduledoc false

    use Application

    def start(_type, _args) do
        import Supervisor.Spec, warn: false

        children = [
            Gingerbread.Service.Repo,
            Gingerbread.Service.Entity
        ]

        opts = [strategy: :one_for_one, name: Gingerbread.Service.Supervisor]
        Supervisor.start_link(children, opts)
    end
end
