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

    ...
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

## Setup

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

And finally add the following to your schemas:

```elixir
use EctoQuerify,
  schema: __MODULE__,
  repo: YourRepo
```

## Usage

After you have added EctoQuerify to your schema, you can use the the following functions:

- get
- get_by
- list
- create
- update
- delete

# get

Get single record by ID.

Basic example:

```elixir
{:ok, person} = Person.get(id)
```

Preload associations:

```elixir
{:ok, %{parent: parent, kids: kids} = person} = Person.get(id, [:parent, :kids])
```

# get_by

Get single record by multiple field values.

Basic example:

```elixir
{:ok, person} = Person.get_by(name: "Tom", surname: "Wiggins")
```

Preload associations:

```elixir
{:ok, %{parent: parent, kids: kids} = person} = Person.get_by([name: "Tom", surname: "Wiggins"], [:parent, :kids])
```

# list

List records by their fields and associations.

Basic example:

```elixir
{:ok, people} = Person.list(name: "Tom", age: 2)
```

List by association fields:

```elixir
{:ok, people} = Person.list(name: "Tom", parent__name: "Bradley")
```
