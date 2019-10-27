defmodule Crit.Usables.Schemas.BulkAnimal do
  use Ecto.Schema
  import Ecto.Changeset
  import Pile.ChangesetFlow
  alias Crit.Usables.FieldConverters.{ToDate, ToNameList}


  embedded_schema do
    # user-supplied fields
    field :names, :string
    field :species_id, :integer
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :timezone, :string   # strictly, this is filled in by calling code,
                               # not by a user or browser.

    # computed fields
    field :in_service_date, :date
    field :out_of_service_date, :date
    field :computed_names, {:array, :string}
  end

  @form_fields [:names, :species_id, :timezone,
                :in_service_datestring, :out_of_service_datestring]

  def changeset(bulk, attrs) do
    bulk
    |> cast(attrs, @form_fields)
    |> validate_required(@form_fields)
  end

  def creation_changeset(attrs) do
    given_all_form_values_are_present(changeset(%__MODULE__{}, attrs),
      fn changeset ->
        changeset
        |> ToNameList.split_names(from: :names, to: :computed_names)
        |> ToDate.put_service_dates
      end)
  end
end
