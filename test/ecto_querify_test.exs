defmodule EctoQuerifyTest do
  @moduledoc false

  use ExUnit.Case

  import Ecto.Changeset

  defmodule TestMigration do
    use Ecto.Migration

    def change do
      create table(:cats, primary_key: false) do
        add(:id, :binary_id, null: false, primary_key: true)
        add(:name, :string, size: 256, null: false)
        add(:breed, :string)
        add(:human_id, :binary_id)
      end

      create table(:humans, primary_key: false) do
        add(:id, :binary_id, null: false, primary_key: true)
        add(:name, :string, size: 256, null: false)
        add(:spouse_id, :binary_id)
        add(:father_id, :binary_id)
      end

      create table(:cousins, primary_key: false) do
        add(:human_one_id, :binary_id)
        add(:human_two_id, :binary_id)
      end
    end
  end

  defmodule Human do
    use Ecto.Schema

    @primary_key {:id, Ecto.UUID, autogenerate: true}
    schema "humans" do
      # some may argue and thats okay
      belongs_to(:spouse, Human, foreign_key: :spouse_id, type: Ecto.UUID)
      # same here
      belongs_to(:father, Human, foreign_key: :father_id, type: Ecto.UUID)

      many_to_many(:cousins, Human,
        join_through: "person_to_person",
        join_keys: [human_one_id: :id, human_two_id: :id],
        on_replace: :delete
      )

      field(:name, :string)
    end
  end

  defmodule CatSchema do
    use Ecto.Schema

    @primary_key {:id, Ecto.UUID, autogenerate: true}
    schema "cats" do
      belongs_to(:human, Human, type: Ecto.UUID)
      field(:name, :string)
      field(:breed, :string)
    end

    def create_changeset(schema, attrs) do
      schema
      |> cast(attrs, [:name, :breed])
      |> validate_required([:name])
    end

    def update_changeset(schema, attrs) do
      schema
      |> cast(attrs, [:name, :breed])
      |> validate_required([:name])
    end
  end

  use EctoQuerify,
    schema: CatSchema,
    repo: TestRepo

  setup do
    Ecto.Migrator.with_repo(TestRepo, fn repo ->
      Ecto.Migrator.run(repo, [{0, TestMigration}], :up, all: true)
    end)

    on_exit(fn ->
      Ecto.Migrator.run(TestRepo, [{0, TestMigration}], :down, all: true)

      :ok
    end)

    :ok
  end

  describe "generate" do
    test "fails when repo or schema are not provided" do
      assert_raise RuntimeError, fn ->
        EctoQuerify.generate(schema: CatSchema)
      end

      assert_raise RuntimeError, fn ->
        EctoQuerify.generate(repo: TestRepo)
      end
    end

    test "fails when :only option contains unsupported function" do
      assert_raise RuntimeError, fn ->
        EctoQuerify.generate(schema: CatSchema, repo: TestRepo, only: [:random])
      end
    end
  end

  describe "create" do
    @tag capture_log: true
    test "creates record" do
      assert {:ok, %CatSchema{name: "kitty"}} = create(name: "kitty")
    end

    @tag capture_log: true
    test "when required attrs are not provided - returns error" do
      assert {:error, %Ecto.Changeset{}} = create(breed: "ashera")
    end
  end

  describe "update" do
    @tag capture_log: true
    test "updates record by ID" do
      {:ok, schema} = TestRepo.insert(%CatSchema{name: "kitty", breed: "ashera"})

      assert {:ok, %CatSchema{name: "tom", breed: "free-roaming"}} =
               update(schema.id, name: "tom", breed: "free-roaming")
    end

    @tag capture_log: true
    test "updates record by schema" do
      {:ok, schema} = TestRepo.insert(%CatSchema{name: "kitty", breed: "ashera"})

      assert {:ok, %CatSchema{name: "tom", breed: "free-roaming"}} =
               update(schema, name: "tom", breed: "free-roaming")
    end
  end

  describe "get" do
    @tag capture_log: true
    test "when record is found by primary key - returns record" do
      {:ok, schema} = TestRepo.insert(%CatSchema{name: "kitty"})

      assert {:ok, schema} == get(schema.id)
    end

    @tag capture_log: true
    test "when record is not found by primary key - returns error" do
      {:ok, _schema} = TestRepo.insert(%CatSchema{name: "kitty"})

      assert {:error, :not_found} == get(Ecto.UUID.generate())
    end

    @tag capture_log: true
    test "when preload list is provided - returns record with preloaded associations" do
      {:ok, _schema} = TestRepo.insert(%CatSchema{name: "kitty"})

      assert {:error, :not_found} == get(Ecto.UUID.generate())
    end

    @tag capture_log: true
    test "when preload is provided - preloads associations" do
      {:ok, %{id: human_id}} = TestRepo.insert(%Human{name: "john"})
      {:ok, %{id: cat_id}} = TestRepo.insert(%CatSchema{name: "kitty", human_id: human_id})

      assert {:ok, %CatSchema{id: ^cat_id, human: %Human{id: ^human_id}}} = get(cat_id, [:human])
    end
  end

  describe "get_by" do
    @tag capture_log: true
    test "when unique record is found - returns record" do
      {:ok, _schema} = TestRepo.insert(%CatSchema{name: "kitty"})

      assert {:ok, %CatSchema{name: "kitty", human: nil}} = get_by([name: "kitty"], [:human])
    end

    @tag capture_log: true
    test "when multiple records are found - returns error" do
      TestRepo.insert(%CatSchema{name: "kitty"})
      TestRepo.insert(%CatSchema{name: "kitty"})

      assert {:error, :multiple_records_found} == get_by(name: "kitty")
    end

    @tag capture_log: true
    test "when no record is found - returns error" do
      assert {:error, :not_found} == get_by(name: "kitty")
    end

    @tag capture_log: true
    test "when preload is provided - preloads associations" do
      {:ok, %{id: human_id}} = TestRepo.insert(%Human{name: "john"})
      {:ok, %{id: cat_id}} = TestRepo.insert(%CatSchema{name: "kitty", human_id: human_id})

      assert {:ok, %CatSchema{id: ^cat_id, human: %Human{id: ^human_id}}} =
               get_by([name: "kitty"], [:human])
    end

    test "iexact" do
      {:ok, %{id: human_id}} = TestRepo.insert(%Human{name: "john"})
      {:ok, %{id: cat_id}} = TestRepo.insert(%CatSchema{name: "kitty", human_id: human_id})

      assert {:ok, %CatSchema{id: ^cat_id, human: %Human{id: ^human_id}}} =
               get_by(human__name__iexact: "JoHn")
    end
  end

  describe "list" do
    @tag capture_log: true
    test "when no operator is provided for field filter => returns filtered exact matching" do
      {:ok, %{id: sam_id}} = TestRepo.insert(%Human{name: "sam"})
      {:ok, %{id: john_id}} = TestRepo.insert(%Human{name: "john"})

      TestRepo.insert(%CatSchema{name: "simba", human_id: sam_id})
      TestRepo.insert(%CatSchema{name: "kitty", human_id: john_id})
      TestRepo.insert(%CatSchema{name: "tom", human_id: john_id})

      assert {:ok, [%CatSchema{name: "simba"}]} = list(human_id: sam_id)

      assert {:ok, [%CatSchema{name: "kitty"}, %CatSchema{name: "tom"}]} =
               list(human_id__exact: john_id)
    end

    @tag capture_log: true
    test "when filtering by first nested association => returns result" do
      {:ok, %{id: angela_id}} = TestRepo.insert(%Human{name: "angela"})
      {:ok, %{id: sam_id}} = TestRepo.insert(%Human{name: "sam", spouse_id: angela_id})

      {:ok, %{id: tom_id}} = TestRepo.insert(%CatSchema{name: "tom", human_id: sam_id})
      {:ok, %{id: _kitty_id}} = TestRepo.insert(%CatSchema{name: "kitty", human_id: angela_id})

      assert {:ok, [%CatSchema{id: ^tom_id}]} = list(human__spouse__name__exact: "angela")
    end

    @tag capture_log: true
    test "when filtering by second nested association => returns error" do
      assert {:error, :unsupported_filtering_by_deeply_nested_associations} =
               list(human__spouse__father__name: "john")
    end
  end

  @tag capture_log: true
  test "operator exact" do
    {:ok, %{id: sam_id}} = TestRepo.insert(%Human{name: "sam"})
    {:ok, %{id: john_id}} = TestRepo.insert(%Human{name: "john"})

    TestRepo.insert(%CatSchema{name: "simba", human_id: sam_id})
    TestRepo.insert(%CatSchema{name: "kitty", human_id: john_id})
    TestRepo.insert(%CatSchema{name: "tom", human_id: john_id})

    assert {:ok, [%CatSchema{name: "simba"}]} = list(human_id__exact: sam_id)
  end

  @tag capture_log: true
  test "operator exact when value is nil" do
    {:ok, %{id: john_id}} = TestRepo.insert(%Human{name: "john"})
    TestRepo.insert(%CatSchema{name: "simba", human_id: john_id})
    TestRepo.insert(%CatSchema{name: "kitty", breed: "ashera", human_id: john_id})
    TestRepo.insert(%CatSchema{name: "tom", breed: "free-roaming", human_id: john_id})

    assert {:ok, [%CatSchema{name: "simba"}, %CatSchema{name: "kitty"}, %CatSchema{name: "tom"}]} =
             list(human__spouse_id: nil)

    assert {:ok, [%CatSchema{name: "simba"}]} = list(breed: nil)
  end

  @tag capture_log: true
  test "operator in" do
    {:ok, %{id: john_id}} = TestRepo.insert(%Human{name: "john"})
    TestRepo.insert(%CatSchema{name: "simba", human_id: john_id})
    TestRepo.insert(%CatSchema{name: "kitty", human_id: john_id})
    TestRepo.insert(%CatSchema{name: "tom", human_id: john_id})

    assert {:ok, [%CatSchema{name: "simba"}, %CatSchema{name: "kitty"}, %CatSchema{name: "tom"}]} =
             list(human__id__in: [john_id])

    assert {:ok, [%CatSchema{name: "simba"}]} = list(name__in: ["simba"])
  end

  @tag capture_log: true
  test "operator iexact" do
    TestRepo.insert(%CatSchema{name: "simba"})
    TestRepo.insert(%CatSchema{name: "kitty"})
    TestRepo.insert(%CatSchema{name: "tom"})

    assert {:ok, [%CatSchema{name: "simba"}]} = list(name__iexact: "SiMbA")
    assert {:ok, [%CatSchema{name: "simba"}]} = list(name__iexact: "SIMBA")
    assert {:ok, [%CatSchema{name: "simba"}]} = list(name__iexact: "simba")
  end

  @tag capture_log: true
  test "limit" do
    TestRepo.insert(%CatSchema{name: "simba"})
    TestRepo.insert(%CatSchema{name: "kitty"})
    TestRepo.insert(%CatSchema{name: "tom"})

    {:ok, cats} = list()
    assert length(cats) == 3
    {:ok, cats} = list(limit: 2)
    assert length(cats) == 2
  end

  @tag capture_log: true
  test "order_by" do
    TestRepo.insert(%CatSchema{name: "a"})
    TestRepo.insert(%CatSchema{name: "c"})
    TestRepo.insert(%CatSchema{name: "b"})

    {:ok, [%CatSchema{name: "a"}, %CatSchema{name: "b"}, %CatSchema{name: "c"}]} =
      list(order_by: :name)

    {:ok, [%CatSchema{name: "c"}, %CatSchema{name: "b"}, %CatSchema{name: "a"}]} =
      list(order_by: {:name, :desc})
  end

  @tag capture_log: true
  test "preload" do
    {:ok, %{id: john_id}} = TestRepo.insert(%Human{name: "john"})

    TestRepo.insert(%CatSchema{name: "simba", human_id: john_id})
    TestRepo.insert(%CatSchema{name: "kitty", human_id: john_id})
    TestRepo.insert(%CatSchema{name: "tom", human_id: john_id})

    assert {:ok,
            [
              %CatSchema{human: %Human{}},
              %CatSchema{human: %Human{}},
              %CatSchema{human: %Human{}}
            ]} = list(preload: :human)
  end

  describe "delete" do
    @tag capture_log: true
    test "deletes record by ID" do
      {:ok, %CatSchema{id: schema_id}} =
        TestRepo.insert(%CatSchema{name: "kitty", breed: "ashera"})

      assert {:ok, %CatSchema{id: ^schema_id}} = delete(schema_id)
    end

    @tag capture_log: true
    test "deletes record by schema" do
      {:ok, %CatSchema{id: schema_id} = schema} =
        TestRepo.insert(%CatSchema{name: "kitty", breed: "ashera"})

      assert {:ok, %CatSchema{id: ^schema_id}} = delete(schema)
    end

    @tag capture_log: true
    test "when record doesn't exist - returns error" do
      schema = %CatSchema{id: Ecto.UUID.generate(), name: "kitty", breed: "ashera"}

      assert {:error, :not_found} = delete(schema)
    end
  end

  describe "delete_all" do
    @tag capture_log: true
    test "delete all records" do
      {:ok, %CatSchema{id: _schema_id}} =
        TestRepo.insert(%CatSchema{name: "kitty", breed: "ashera"})

      {:ok, %CatSchema{id: _schema_id}} =
        TestRepo.insert(%CatSchema{name: "boban", breed: "siamese"})

      assert {:ok, 2, nil} = delete_all()
    end

    @tag capture_log: true
    test "delete all records with returning" do
      {:ok, %CatSchema{id: _schema_id}} =
        TestRepo.insert(%CatSchema{name: "kitty", breed: "ashera"})

      {:ok, %CatSchema{id: _schema_id}} =
        TestRepo.insert(%CatSchema{name: "boban", breed: "siamese"})

      assert {:ok, 2,
              [
                %CatSchema{name: "kitty", breed: "ashera"},
                %CatSchema{name: "boban", breed: "siamese"}
              ]} = delete_all(return_deleted: true)
    end

    @tag capture_log: true
    test "delete records with returning and filter" do
      {:ok, %CatSchema{id: _schema_id}} =
        TestRepo.insert(%CatSchema{name: "kitty", breed: "ashera"})

      {:ok, %CatSchema{id: _schema_id}} =
        TestRepo.insert(%CatSchema{name: "boban", breed: "siamese"})

      assert {:ok, 1, [%CatSchema{name: "boban", breed: "siamese"}]} =
               delete_all(name: "boban", return_deleted: true)
    end

    @tag capture_log: true
    test "delete records with filter" do
      {:ok, %CatSchema{id: _schema_id}} =
        TestRepo.insert(%CatSchema{name: "kitty", breed: "ashera"})

      {:ok, %CatSchema{id: _schema_id}} =
        TestRepo.insert(%CatSchema{name: "boban", breed: "siamese"})

      assert {:ok, 1, nil} = delete_all(name: "boban")
    end

    @tag capture_log: true
    test "delete records no match filter" do
      {:ok, %CatSchema{id: _schema_id}} =
        TestRepo.insert(%CatSchema{name: "kitty", breed: "ashera"})

      {:ok, %CatSchema{id: _schema_id}} =
        TestRepo.insert(%CatSchema{name: "boban", breed: "siamese"})

      assert {:ok, 0, []} = delete_all(name: "pera", return_deleted: true)
    end
  end
end
