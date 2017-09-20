defmodule Gingerbread.Service do
    @moduledoc """
      The service application for managing entity relationships.
    """

    use Application

    def start(_type, args) do
        import Supervisor.Spec, warn: false

        setup_mode = args[:setup_mode] || :auto

        if setup_mode == :auto do
            if Mix.env == :test do
                Gingerbread.Service.Repo.DB.drop()
            end
            Gingerbread.Service.Repo.DB.create()
        end

        children = [
            Gingerbread.Service.Repo,
            Gingerbread.Service.Entity
        ]

        opts = [strategy: :one_for_one, name: Gingerbread.Service.Supervisor]
        supervisor = Supervisor.start_link(children, opts)

        if setup_mode == :auto do
            Gingerbread.Service.Repo.DB.migrate()
        end

        supervisor
    end
end
