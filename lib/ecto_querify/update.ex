defmodule EctoQuerify.Update do
  @moduledoc """
  This module holds update/2 function and macro for using it.
  """

  # Further improvements:
  #
  # 1. Define behaviour EctoQuerify.UpdateChangeset with following function:
  #     - update_changeset/2
  #
  #    All schemas provided to using macro must use the behaviour.
  #
  # 2. Raise compilation error in case schema provided to using macro doesn't implement
  #    EctoQuerify.UpdateChangeset behaviour.

  require Logger

  alias EctoQuerify.Get
  alias EctoQuerify.Update

  @doc """
  Updates existing record by ID or schema.
  """
  def update(repo, schema_module, schema_or_id, opts) when is_list(opts),
    do: update(repo, schema_module, schema_or_id, Map.new(opts))

  def update(repo, schema_module, %{} = schema, %{} = attrs) do
    with [primary_key | _] <- schema_module.__schema__(:primary_key),
         associations_to_preload <- associations_to_preload(schema_module, attrs),
         {:ok, schema} <-
           schema
           |> repo.preload(associations_to_preload)
           |> schema_module.update_changeset(attrs)
           |> repo.update() do
      Logger.debug(
        "DB.update #{inspect(schema_module)} #{Map.get(schema, primary_key)} with #{inspect(attrs)}"
      )

      {:ok, schema}
    end
  end

  def update(repo, schema_module, id, %{} = attrs) do
    with {:ok, schema} <- Get.get(repo, schema_module, id) do
      update(repo, schema_module, schema, attrs)
    end
  end

  defp associations_to_preload(schema_module, attrs) do
    associations = schema_module.__schema__(:associations)
    fields_and_associations_to_update = Map.keys(attrs)

    Enum.filter(fields_and_associations_to_update, fn field ->
      Enum.member?(associations, field)
    end)
  end

  defmacro __using__(opts) do
    quote do
      def update(schema_or_id, attrs),
        do: Update.update(unquote(opts[:repo]), unquote(opts[:schema]), schema_or_id, attrs)

      defoverridable update: 2
    end
  end
end
