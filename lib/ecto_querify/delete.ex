defmodule EctoQuerify.Delete do
  @moduledoc """
  This module holds delete/1 function and macro for using it.
  """

  import Ecto.Query
  require Logger
  alias EctoQuerify.Delete

  @doc """
  Deletes record by ID or schema.
  """
  def delete(repo, schema_module, %{} = schema) do
    with [primary_key | _] <- schema_module.__schema__(:primary_key) do
      delete(repo, schema_module, Map.get(schema, primary_key))
    end
  end

  def delete(repo, schema_module, id) do
    [primary_key | _] = schema_module.__schema__(:primary_key)

    result =
      schema_module
      |> where([x], field(x, ^primary_key) == ^id)
      |> repo.delete_all()

    Logger.debug("DB.delete #{inspect(schema_module)} #{id}")

    case result do
      {0, nil} -> {:error, :not_found}
      {1, nil} -> {:ok, struct(schema_module, [{primary_key, id}])}
    end
  end

  defmacro __using__(opts) do
    quote do
      def delete(schema_or_id),
        do: Delete.delete(unquote(opts[:repo]), unquote(opts[:schema]), schema_or_id)
    end
  end
end
