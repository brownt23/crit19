defmodule Crit.Usables.ServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset
  alias Ecto.Datespan
  alias Pile.TimeHelper

  @today "today"

  schema "service_gaps" do
    field :gap, Datespan
    field :reason, :string

    field :start_date, :string, virtual: true
    field :end_date, :string, virtual: true
    field :timezone, :string, virtual: true
  end

  def initial_changesets(attrs, today_getter \\ &TimeHelper.today_date/1) do
    pre_service = pre_service_changeset(attrs, today_getter) 
    case attrs["end_date"] do
      "never" ->
        [pre_service]
      _ ->
        post_service = 
          post_service_changeset(attrs, today_getter)
          |> reject_overlap(pre_service)
        [pre_service, post_service]
    end
  end

  def pre_service_changeset(attrs, today_getter \\ &TimeHelper.today_date/1) do
    :start_date
    |> changeset_for_date_field(attrs, today_getter)
    |> put_gap(:infinite_down, :start_date, :exclusive)
    |> put_reason("before animal was put in service")
  end

  def post_service_changeset(attrs, today_getter \\ &TimeHelper.today_date/1) do
    :end_date
    |> changeset_for_date_field(attrs, today_getter)
    |> put_gap(:infinite_up, :end_date, :inclusive)
    |> put_reason("animal taken out of service")
  end

  # Util

  defp changeset_for_date_field(field, attrs, today_getter) do 
    %__MODULE__{}
    |> cast(attrs,[field, :timezone])
    |> validate_required([field])
    |> convert_string_to_date_using(field, today_getter)
  end

  def convert_string_to_date_using(changeset, field, today_getter) do
    date_string = changeset.changes[field]
    case date_string == @today || Date.from_iso8601(date_string) do
      true ->
        timezone = changeset.changes.timezone
        today = today_getter.(timezone)
        put_change(changeset, field, today)
      {:ok, date} -> 
        put_change(changeset, field, date)
      {:error, _} ->
        add_error(changeset, field, parse_message())
    end
  end
  
  defp reject_overlap(
    %Changeset{valid?: true, changes: %{end_date: to_be_later}} = changeset,
    %Changeset{valid?: true, changes: %{start_date: to_be_earlier}}
  ) do

    case Date.compare(to_be_earlier, to_be_later) do
      :lt ->
        changeset
      _ ->
        Changeset.add_error(changeset, :end_date, misorder_message())
    end
  end
  defp reject_overlap(changeset, _), do: changeset

  def put_reason(%{valid?: false} = changeset, _), do: changeset
  def put_reason(changeset, reason),
    do: put_change(changeset, :reason, reason)

  def put_gap(%{valid?: false} = changeset, _, _, _), do: changeset
  def put_gap(changeset, span_type, endpoint, exclusivity) do
    date = changeset.changes[endpoint]
    put_change(changeset, :gap, apply(Datespan, span_type, [date, exclusivity]))
  end

  def parse_message,
    do: "isn't a correct date. This should be impossible. Please report the problem."
  
  def misorder_message, do: "should not be before the start date"


  ### Transaction support

  defmodule Multi do
    alias Crit.Usables.ServiceGap
    use Ecto.Schema
    alias Ecto.Multi
    alias Crit.Sql


    defp gap_key(index), do: {:gap, index}
    defp is_gap_key?({:gap, _count}), do: true
    defp is_gap_key?(_), do: false

    defp gap_ids(_repo, map_with_gaps) do
      reducer = fn {key, value}, acc ->
        case is_gap_key?(key) do
          true ->
            [value.id | acc]
          false ->
            acc
        end
      end

      result = 
        map_with_gaps
        |> Enum.reduce([], reducer)
        |> Enum.reverse

      {:ok, result}
    end

    def initial_service_gaps(params, institution) do
      add_insertion = fn {changeset, index}, acc ->
        Multi.insert(acc, gap_key(index), changeset, Sql.multi_opts(institution))
      end

      params
      |> ServiceGap.initial_changesets
      |> Enum.with_index
      |> Enum.reduce(Multi.new, add_insertion)
      |> Multi.run(:gap_ids, &gap_ids/2)
    end
  end
end
