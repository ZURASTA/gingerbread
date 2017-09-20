defmodule Gingerbread.Service.Repo do
    @app :gingerbread_service
    Gingerbread.Service.Repo.Config.setup(@app, __MODULE__)
    use Ecto.Repo, otp_app: @app

    def child_spec(_args) do
        %{
            id: __MODULE__,
            start: { __MODULE__, :start_link, [] },
            type: :supervisor
        }
    end

    @on_load :setup_config
    defp setup_config() do
        Gingerbread.Service.Repo.Config.setup(@app, __MODULE__)
        :ok
    end
end
