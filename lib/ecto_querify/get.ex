defmodule EctoQuerify.Get do
  @moduledoc """
  This module holds get/2 function and macro for using it.
  """

  import Ecto.Query

  alias EctoQuerify.Get
  alias EctoQuerify.Preloader

  require Logger

  @doc """
  Get record by id.
  """
  def get(repo, schema_module, id, preload \\ [])

  def get(repo, schema_module, id, preload) when is_bitstring(id) and is_list(preload) do
    Logger.debug("DB.get #{schema_module} by id #{id} with preload #{inspect(preload)}")

    [primary_key | _] = schema_module.__schema__(:primary_key)

    query =
      schema_module
      |> where([x], field(x, ^primary_key) == ^id)
      |> Preloader.preload_with_join(preload)

    case repo.one(query) do
      nil ->
        {:error, :not_found}

      record ->
        {:ok, record}
    end
  end

  defmacro __using__(opts) do
    quote do
      def get(id, preload \\ []),
        do: Get.get(unquote(opts[:repo]), unquote(opts[:schema]), id, preload)
    end
  end
end
