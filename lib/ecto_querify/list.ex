defmodule EctoQuerify.List do
  @moduledoc """
  This module holds list/2 function and macro for using it.
  """

  import Ecto.Query

  require Logger

  alias EctoQuerify.Filters
  alias EctoQuerify.List, as: EctoQuerifyList
  alias EctoQuerify.Preloader

  @doc """
  List records by their fields.

  Example:

  list(repo, schema, cloud_account_id__exact: "01GEEFE9CS94VW2SW6NXH6J0FY", inserted_at__gt: ~N[2000-01-01 23:00:07])

  Or with options and explicit operators (exact):

  list(repo, schema, cloud_account_id__exact: "01GEEFE9CS94VW2SW6NXH6J0FY", limit: 10, order_by: :inserted_at)
  """
  def list(repo, schema_module, filters)

  def list(repo, schema_module, filters) when is_list(filters) do
    with limit <- Keyword.get(filters, :limit),
         preload <- Keyword.get(filters, :preload, []),
         order <- Keyword.get(filters, :order_by),
         filters <- Keyword.drop(filters, [:limit, :preload, :order_by]),
         {:ok, query} <- Filters.filter(schema_module, filters) do
      Logger.debug(
        "DB.list #{schema_module} by id #{inspect(filters)} with preload #{inspect(preload)}"
      )

      query
      |> set_limit(limit)
      |> set_order(order)
      |> Preloader.preload_with_join(preload)
      |> repo.all()
      |> then(fn result -> {:ok, result} end)
    end
  end

  defp set_limit(query, limit) do
    case limit do
      nil ->
        query

      limit when is_integer(limit) ->
        limit(query, ^limit)
    end
  end

  defp set_order(query, order) do
    case order do
      nil ->
        query

      {field, direction} ->
        order_by(query, [{^direction, ^field}])

      field ->
        order_by(query, ^field)
    end
  end

  defmacro __using__(opts) do
    quote do
      def list(filters \\ []),
        do: EctoQuerifyList.list(unquote(opts[:repo]), unquote(opts[:schema]), filters)
    end
  end
end
