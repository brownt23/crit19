defmodule Crit.Usables.Schemas.ServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Datespan
  alias Crit.Sql

  schema "service_gaps" do
    field :gap, Datespan
    field :reason, :string

    field :in_service_date, :date, virtual: true
  end

  @required [:gap, :reason]

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def changeset(fields) when is_list(fields) do
    changeset(%__MODULE__{}, Enum.into(fields, %{}))
  end

  def update_in_service_date(struct, attrs, institution) do
    struct
    |> cast(attrs, [:in_service_date])
    |> put_new_in_service_date
    |> Sql.update(institution)
  end

  defp put_new_in_service_date(changeset) do
    new_date = changeset.changes.in_service_date
    put_change(changeset, :gap, Datespan.strictly_before(new_date))
  end

  def separate_kinds(service_gaps) do
    in_service = Enum.find(service_gaps, &is_for_in_service?/1)
    out_of_service = Enum.find(service_gaps, &is_for_out_of_service?/1)
    others = [] # They cannot be created yet.

    %{in_service: in_service,
      out_of_service: out_of_service,
      others: others
    }
  end

  defp is_for_in_service?(service_gap),
    do: Datespan.infinite_down?(service_gap.gap)
  defp is_for_out_of_service?(service_gap),
    do: Datespan.infinite_up?(service_gap.gap)
end
