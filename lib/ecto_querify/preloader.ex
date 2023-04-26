defmodule EctoQuerify.Preloader do
  @moduledoc """
  This module provides functions for custom preloading of associations in Ecto.
  """

  import Ecto.Query

  def preload_with_join(query, associations) do
    {query, _} = do_preload_with_join({query, []}, associations)
    query
  end

  defp do_preload_with_join({query, parent_associations}, []), do: {query, parent_associations}

  defp do_preload_with_join({query, parent_associations}, [association | associations]) do
    {query, parent_associations}
    |> do_preload_with_join(association)
    |> do_preload_with_join(associations)
  end

  defp do_preload_with_join({query, []}, association) when is_atom(association) do
    query =
      query
      |> join(:left, [p], a in assoc(p, ^association), as: ^association)
      |> preload([p, {^association, a}], [{^association, a}])

    {query, []}
  end

  defp do_preload_with_join({query, parent_associations}, association)
       when is_atom(association) do
    query =
      parent_associations
      |> Enum.reduce([association], fn assoc, acc -> [{assoc, acc}] end)
      |> preload_with_join_up_to_second_association(query)

    {query, parent_associations}
  end

  defp do_preload_with_join({query, parent_associations}, {association, nested_associations}) do
    {query, _} =
      {query, [association | parent_associations]}
      |> do_preload_with_join(nested_associations)

    {query, parent_associations}
  end

  defp preload_with_join_up_to_second_association(
         [{first_assoc, [{second_assoc, nested_associations}]}],
         query
       ) do
    Ecto.Queryable.to_query(query)
    |> with_named_binding(first_assoc, fn query, first_assoc ->
      join(query, :left, [p], a in assoc(p, ^first_assoc), as: ^first_assoc)
    end)
    |> with_named_binding(second_assoc, fn query, second_assoc ->
      join(query, :left, [p, {^first_assoc, first}], a in assoc(first, ^second_assoc),
        as: ^second_assoc
      )
    end)
    |> preload([p, {^first_assoc, first}, {^second_assoc, second}], [
      {^first_assoc, {first, [{^second_assoc, {second, ^nested_associations}}]}}
    ])
  end

  defp preload_with_join_up_to_second_association([{first_assoc, [second_assoc]}], query) do
    Ecto.Queryable.to_query(query)
    |> with_named_binding(first_assoc, fn query, first_assoc ->
      join(query, :left, [p], a in assoc(p, ^first_assoc), as: ^first_assoc)
    end)
    |> with_named_binding(second_assoc, fn query, second_assoc ->
      join(query, :left, [p, {^first_assoc, first}], a in assoc(first, ^second_assoc),
        as: ^second_assoc
      )
    end)
    |> preload(
      [p, {^first_assoc, first}, {^second_assoc, second}],
      [{^first_assoc, {first, [{^second_assoc, second}]}}]
    )
  end
end
