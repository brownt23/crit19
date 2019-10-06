defmodule Crit.Usables.Write.BulkAnimalWorkflow do
  alias Crit.Sql
  alias Crit.Usables.Write
  alias Crit.Ecto.BulkInsert
  alias Crit.Global
  alias Ecto.Changeset

  def run(supplied_attrs, institution) do
    attrs = Map.put(supplied_attrs, "timezone", Global.timezone(institution))
    steps = [
      &validation_step/1,
      &split_changeset_step/1,
      &bulk_insert_step/1,
    ]

    Write.Workflow.run(attrs, institution, steps)
  end

  # The essential steps in the workflow

  defp validation_step(state) do
    Write.Workflow.validation_step(
      state,
      &Write.BulkAnimal.compute_insertables/1,
      :original_changeset)
  end

  defp split_changeset_step(%{original_changeset: changeset} = state) do
    changesets = Write.BulkAnimal.changeset_to_changesets(changeset)

    {:ok, Map.put(state, :changesets, changesets)}
  end

  defp bulk_insert_step(%{
        original_changeset: changeset,
        changesets: changesets,
        institution: institution}) do

    %{animal_changesets: animal_changesets,
      service_gap_changesets: service_gap_changesets} = changesets

    institution
    |> BulkInsert.three_schema_insertion(
           insert: animal_changesets, yielding: :animal_ids,
           insert: service_gap_changesets, yielding: :service_gap_ids,
           many_to_many: Write.AnimalServiceGap)
    |> Sql.transaction(institution)
    |> Write.Workflow.on_ok(extract: :animal_ids)
    |> Write.Workflow.on_failed_step(fn _, failing_changeset ->
        duplicate = failing_changeset.changes.name
        message = ~s|An animal named "#{duplicate}" is already in service|
        changeset
        |> Changeset.add_error(:names, message)
        |> Changeset.apply_action(:insert)
        # Note that `apply_action` will return {:error, changeset} in this case.
       end)
  end
end
