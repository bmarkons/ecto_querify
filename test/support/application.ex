defmodule EctoQuerify.TestApplication do
  @moduledoc """
  Application for test environment.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [TestRepo]

    opts = [strategy: :one_for_one, name: Supervisor]
    Supervisor.start_link(children, opts)
  end
end
