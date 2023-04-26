defmodule EctoQuerify.Filters do
  @moduledoc """
  This module provides filter/2 function for flexible filtering by schema or its associations fields.
  """

  import Ecto.Query

  alias EctoQuerify.Preloader

  @supported_filters [
    :exact,
    :in,
    :iexact,
    :contains,
    :icontains,
    :gt,
    :gte,
    :lt,
    :lte,
    :startswith,
    :istartswith,
    :endswith,
    :iendswith,
    :range,
    :regex,
    :iregex
  ]

  @default_filter :exact

  def filter(query, filters) when is_list(filters) do
    case do_filter(query, filters) do
      {:error, _} = error ->
        error

      query ->
        {:ok, query}
    end
  end

  defp do_filter(query, filters) when is_list(filters) do
    Enum.reduce_while(filters, query, fn {filter, value}, query ->
      parsed_filter_parts =
        filter
        |> Atom.to_string()
        |> String.split("__")
        |> Enum.map(&String.to_atom/1)
        |> append_default_filter()

      case preload_associations(parsed_filter_parts, query) do
        {:ok, query} ->
          query = apply_filter(query, parsed_filter_parts, value)
          {:cont, query}

        {:error, _} = error ->
          {:halt, error}
      end
    end)
  end

  defp append_default_filter(filter_parts) when is_list(filter_parts) do
    filter_or_something_else = List.last(filter_parts)

    if Enum.member?(@supported_filters, filter_or_something_else) do
      filter_parts
    else
      filter_parts ++ [@default_filter]
    end
  end

  defp preload_associations([_field | [_filter | []]], query), do: {:ok, query}

  defp preload_associations([association | [_field | [_filter | []]]], query),
    do: {:ok, Preloader.preload_with_join(query, [association])}

  defp preload_associations(
         [association | [nested_association | [_field | [_filter | []]]]],
         query
       ),
       do: {:ok, Preloader.preload_with_join(query, [{association, nested_association}])}

  defp preload_associations([_a | [_b | [_c | [_d | [_e | _]]]]], _query),
    do: {:error, :unsupported_filtering_by_deeply_nested_associations}

  defp apply_filter(query, [field | [filter | []]], value),
    do: filter_by(query, filter, field, value)

  defp apply_filter(query, [association | [field | [filter | []]]], value),
    do: filter_by(query, filter, field, value, association)

  defp apply_filter(
         query,
         [_association | [nested_association | [field | [filter | []]]]],
         value
       ),
       do: filter_by(query, filter, field, value, nested_association)

  defp filter_by(query, filter, field, value, association \\ nil)

  # exact
  defp filter_by(query, :exact, field, nil, nil), do: where(query, [x], is_nil(field(x, ^field)))

  defp filter_by(query, :exact, field, value, nil),
    do: where(query, [x], field(x, ^field) == ^value)

  defp filter_by(query, :exact, field, nil, association),
    do: where(query, [{^association, x}], is_nil(field(x, ^field)))

  defp filter_by(query, :exact, field, value, association),
    do: where(query, [{^association, x}], field(x, ^field) == ^value)

  # iexact
  defp filter_by(query, :iexact, field, value, nil),
    do: where(query, [x], fragment("lower(?) = lower(?)", field(x, ^field), ^value))

  defp filter_by(query, :iexact, field, value, association),
    do:
      where(query, [{^association, x}], fragment("lower(?) = lower(?)", field(x, ^field), ^value))

  # in
  defp filter_by(query, :in, field, values, nil) when is_list(values),
    do: where(query, [x], field(x, ^field) in ^values)

  defp filter_by(query, :in, field, values, association) when is_list(values),
    do: where(query, [{^association, x}], field(x, ^field) in ^values)
end
