defmodule CritWeb.Reservations.AfterTheFactController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :after_the_fact_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.{InstitutionApi,AnimalApi, ProcedureApi}
  # alias Ecto.Changeset
  alias Ecto.ChangesetX
  alias Crit.State.UserTask
  alias CritWeb.Reservations.AfterTheFactStructs, as: Scratch
  alias CritWeb.Reservations.AfterTheFactView, as: View
  alias Crit.Reservations.Schemas.Reservation

  plug :must_be_able_to, :make_reservations

  def start(conn, _params) do
    render(conn, "species_and_time_form.html",
      changeset: Scratch.SpeciesAndTime.empty,
      path: path(:put_species_and_time),
      species_options: InstitutionApi.available_species(institution(conn)),
      time_slot_options: InstitutionApi.time_slot_tuples(institution(conn)))
  end

  def put_species_and_time(conn, %{"species_and_time" => delivered_params}) do
    params = Map.put(delivered_params, "institution", institution(conn))

    case ChangesetX.realize_struct(params, Scratch.SpeciesAndTime) do
      {:ok, new_data} ->
        header =
          View.species_and_time_header(
            new_data.date_showable_date,
            InstitutionApi.time_slot_name(new_data.time_slot_id, institution(conn)))

        {key, _state} =
          %Scratch.State{species_and_time_header: header}
          |> Map.merge(new_data)
          |> UserTask.cast_first
        
        animals =
          AnimalApi.available_after_the_fact(new_data, @institution)

        render(conn, "animals_form.html",
          task_id: key,
          path: path(:put_animals),
          header: header,
          animals: animals)
    end
  end

  def put_animals(conn, %{"animals" => delivered_params}) do
    params = Map.put(delivered_params, "institution", institution(conn))

    case ChangesetX.realize_struct(params, Scratch.Animals) do
      {:ok, new_data} ->
        header =
          new_data.chosen_animal_ids
          |> AnimalApi.ids_to_animals(new_data.institution)
          |> View.animals_header

        workflow_state = 
          new_data
          |> Map.merge(%{animals_header: header})
          |> UserTask.cast_more(new_data.task_id)

        procedures =
          ProcedureApi.all_by_species(workflow_state.species_id, new_data.institution)
        
        render(conn, "procedures_form.html",
          procedures: procedures,
          task_id: new_data.task_id,
          path: path(:put_procedures),
          header: [workflow_state.species_and_time_header, header]
        )
   end
  end
  
  def put_procedures(conn, %{"procedures" => delivered_params}) do
    params = Map.put(delivered_params, "institution", institution(conn))
    case ChangesetX.realize_struct(params, Scratch.Procedures) do
      {:ok, new_data} ->

        workflow_state =
          new_data
          |> Map.merge(%{chosen_procedure_ids: new_data.chosen_procedure_ids})
          |> UserTask.cast_more(new_data.task_id)


        {:ok, reservation} = Reservation.create(workflow_state, institution(conn))

        render(conn, "done.html", show: inspect(reservation))
    end
  end
  
end
