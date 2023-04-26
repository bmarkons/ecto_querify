defmodule EctoQuerify.DeleteAll do
  @moduledoc """
  This module holds delete_all/1 function and macro for using it.
  """

  import Ecto.Query

  require Logger

  alias EctoQuerify.DeleteAll
  alias EctoQuerify.Filters

  @doc """
  Deletes all records by the given filters.

  Examples:
  To delete all objects within schema:
  delete_all(repo, schema)

  To delete all objects with status being :invalid and error_count greater than 5:
  delete_all(repo, schema, status: :invalid, error_count__gte: 5)

  To delete all objects with status being :invalid and error_count greater than 5 and fetch them in return data:
  delete_all(repo, schema, status: :invalid, error_count__gte: 5, return_deleted: true)
  """

  def delete_all(repo, schema_module, filters) when is_list(filters) do
    with {return_deleted, filters} <- Keyword.pop(filters, :return_deleted, false),
         {:ok, query} <- Filters.filter(schema_module, filters) do
      query
      |> add_select_clause(return_deleted)
      |> repo.delete_all()
      |> Tuple.insert_at(0, :ok)
    end
  end

  defp add_select_clause(query, true = _return_deleted), do: select(query, [object], object)

  defp add_select_clause(query, _return_deleted), do: query

  defmacro __using__(opts) do
    quote do
      def delete_all(filters \\ []),
        do: DeleteAll.delete_all(unquote(opts[:repo]), unquote(opts[:schema]), filters)
    end
  end
end
