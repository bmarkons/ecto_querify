defmodule EctoQuerify.Create do
  @moduledoc """
  This module holds create/1 function and macro for using it.
  """

  # Further improvements:
  #
  # 1. Define behaviour EctoQuerify.CreateChangeset with following function:
  #     - create_changeset/2
  #
  #    All schemas provided to using macro must use the behaviour.
  #
  # 2. Raise compilation error in case schema provided to using macro doesn't implement
  #    EctoQuerify.CreateChangeset behaviour.

  require Logger
  alias EctoQuerify.Create

  @doc """
  Create new record.
  """
  def create(repo, schema_module, attrs)

  def create(repo, schema_module, %{} = attrs) do
    with [primary_key | _] <- schema_module.__schema__(:primary_key),
         {:ok, schema} <-
           struct(schema_module)
           |> schema_module.create_changeset(attrs)
           |> repo.insert() do
      Logger.debug(
        "DB.insert new #{inspect(schema_module)} with #{primary_key} #{Map.get(schema, primary_key)}."
      )

      {:ok, schema}
    end
  end

  def create(repo, schema_module, attrs) when is_list(attrs),
    do: create(repo, schema_module, Map.new(attrs))

  defmacro __using__(opts) do
    quote do
      def create(attrs), do: Create.create(unquote(opts[:repo]), unquote(opts[:schema]), attrs)
    end
  end
end
