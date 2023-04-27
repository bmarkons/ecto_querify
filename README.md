# EctoQuerify

This library allows you to add the most common query functions to your Ecto Schemas.

For example, let's say you have CatSchema in your app:

```elixir
defmodule CatSchema do
    use Ecto.Schema
    
    # Use query functions from EctoQuerify
    use EctoQuerify,
      schema: __MODULE__,
      repo: YourRepo

    @primary_key {:id, Ecto.UUID, autogenerate: true}
    schema "cats" do
      belongs_to(:owner, Owner, type: Ecto.UUID)
      field(:name, :string)
      field(:breed, :string)
    end
  end
end
```

After adding EctoQuerify functions to your schema, you can use the following functions:

```elixir
CatSchema.get(id)
CatSchema.get_by(name: "tom")
CatSchema.create(name: "tom")
CatSchema.update(cat, name: "tom")
CatSchema.list(name: "tom")
CatSchema.delete(cat)
```

## Installation

Add to your `mix.exs` file:

```elixir
def deps do
  [
    {:ecto_querify, "~> 0.1.0"}
  ]
end
```

Then run:

```zsh
mix deps.get
```
