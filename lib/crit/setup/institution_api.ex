defmodule Crit.Setup.InstitutionApi do
  alias Crit.Repo
  alias Crit.Setup.Schemas.Institution
  import Crit.Setup.InstitutionServer, only: [server: 1]
  import Ecto.Query
  alias Ecto.Timespan
  alias Pile.TimeHelper

  def species(institution), do: get(:species, institution)
  def procedure_frequencies(institution), do: get(:procedure_frequencies, institution)
  def timeslots(institution), do: get(:timeslots, institution)

  # ----------------------------------------------------------------------------

  def all do
    Repo.all(from Institution)
  end

  def timezone(institution) do
    get(:institution, institution).timezone
  end

  def today!(institution) do
    timezone = timezone(institution)
    TimeHelper.today_date(timezone)
  end

  def timeslot_name(id, institution) do
    timeslot = timeslot_by_id(id, institution)
    timeslot.name
  end

  def timespan(%Date{} = date, timeslot_id, institution) do
    timeslot = timeslot_by_id(timeslot_id, institution)
    Timespan.from_date_time_and_duration(date, timeslot.start, timeslot.duration)
  end

  def species_name(species_id, institution) do
    species(institution)
    |> Enum.find(fn %{id: id} -> id == species_id end)
    |> Map.fetch!(:name)
  end

  # ----------------------------------------------------------------------------
  
  defp get(key, institution),
    do: GenServer.call(server(institution), {:get, key})

  defp timeslot_by_id(id, institution) do
    get(:timeslots, institution)
    |> EnumX.find_by_id(id)
  end
end
