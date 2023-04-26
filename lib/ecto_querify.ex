defmodule EctoQuerify do
  @moduledoc """
  Usage example:

  defmodule DogSchema do
    use EctoQuerify,
      repo: Repo,
      schema: __MODULE__
      only: [:get, :get_by]

    ...
  end
  """

  @functions [:create, :update, :get, :get_by, :list, :delete, :delete_all]

  defmacro __using__(opts), do: generate(opts)

  def generate(opts) do
    with schema <- fetch!(opts, :schema),
         repo <- fetch!(opts, :repo),
         function_names <- fetch(opts, :only, @functions) do
      Enum.map(function_names, fn function_name ->
        use_function(function_name, repo, schema)
      end)
    end
  end

  defp use_function(:create, repo, schema) do
    quote do
      use EctoQuerify.Create, repo: unquote(repo), schema: unquote(schema)
    end
  end

  defp use_function(:update, repo, schema) do
    quote do
      use EctoQuerify.Update, repo: unquote(repo), schema: unquote(schema)
    end
  end

  defp use_function(:get, repo, schema) do
    quote do
      use EctoQuerify.Get, repo: unquote(repo), schema: unquote(schema)
    end
  end

  defp use_function(:get_by, repo, schema) do
    quote do
      use EctoQuerify.GetBy, repo: unquote(repo), schema: unquote(schema)
    end
  end

  defp use_function(:list, repo, schema) do
    quote do
      use EctoQuerify.List, repo: unquote(repo), schema: unquote(schema)
    end
  end

  defp use_function(:delete, repo, schema) do
    quote do
      use EctoQuerify.Delete, repo: unquote(repo), schema: unquote(schema)
    end
  end

  defp use_function(:delete_all, repo, schema) do
    quote do
      use EctoQuerify.DeleteAll, repo: unquote(repo), schema: unquote(schema)
    end
  end

  defp use_function(unknown, _repo, _schema) do
    raise """
    EctoQuerify failed to use #{inspect(unknown)} function because it isn't defined.

    Valid functions: #{inspect(@functions)}
    """
  end

  defp fetch!(opts, key) do
    case Keyword.get(opts, key) do
      nil -> raise_invalid_usage_error(key)
      value -> value
    end
  end

  defp fetch(opts, key, default), do: Keyword.get(opts, key, default)

  defp raise_invalid_usage_error(key) do
    raise """
    You must provide #{inspect(key)} option when using Core.Ecto.Facade. Example:

    use EctoQuerify,
      repo: SomeApp.Repo,
      schema: SomeApp.Schema
      only: [:get, :get_by]
    """
  end
end
