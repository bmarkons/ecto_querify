defmodule EctoQuerify.GetBy do
  @moduledoc """
  This module holds get_by/2 function and macro for using it.
  """

  import Ecto.Query

  alias EctoQuerify.Filters
  alias EctoQuerify.GetBy
  alias EctoQuerify.Preloader

  require Logger

  @doc """
  Gets the unique record matching the specified filters.
  If no record is found or multiple records are found, it returns error tuple.
  """
  def get_by(repo, schema_module, filters, preload \\ [])

  def get_by(repo, schema_module, filters, preload) when is_list(filters) and is_list(preload) do
    with {:ok, query} <- Filters.filter(schema_module, filters) do
      Logger.debug(
        "DB.get_by #{schema_module} by filters #{inspect(filters)} with preload #{inspect(preload)}"
      )

      case query
           |> Preloader.preload_with_join(preload)
           |> repo.all() do
        [record] ->
          {:ok, record}

        [_record | _] ->
          {:error, :multiple_records_found}

        [] ->
          {:error, :not_found}
      end
    end
  end

  defmacro __using__(opts) do
    quote do
      def get_by(filters, preload \\ []),
        do: GetBy.get_by(unquote(opts[:repo]), unquote(opts[:schema]), filters, preload)
    end
  end
end
