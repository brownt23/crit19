defmodule CritWeb.Usables.AnimalController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :usables_animal_path
  import CritWeb.Plugs.Authorize

  alias Crit.Usables.AnimalApi
  alias CritWeb.Audit

  plug :must_be_able_to, :manage_animals

  def index(conn, _params) do
    animals = AnimalApi.all(institution(conn))
    render(conn, "index.html", animals: animals)
  end
  

  def bulk_create_form(conn, _params,
    changeset \\ AnimalApi.bulk_animal_creation_changeset()
  ) do 
    render(conn, "bulk_creation.html",
      changeset: changeset,
      path: path(:bulk_create),
      options: AnimalApi.available_species(institution(conn)))
  end

  def bulk_create(conn, %{"bulk_creation" => animal_params}) do
    case AnimalApi.create_animals(animal_params, institution(conn)) do
      {:ok, animals} ->
        conn
        |> bulk_create_audit(animals)
        |> put_flash(:info, "Success!")
        |> render("index.html",
                  animals: animals)
      {:error, %Ecto.Changeset{} = changeset} ->
        bulk_create_form(conn, [], changeset)
    end
  end

  defp bulk_create_audit(conn, [one_animal | _rest] = animals) do
    audit_data = %{ids: EnumX.ids(animals),
                   in_service_date: one_animal.in_service_date,
                   out_of_service_date: one_animal.out_of_service_date
                  }
    Audit.created_animals(conn, audit_data)
  end

  def update(conn, %{"animal_id" => id, "animal" => animal_params}) do
    # IO.inspect animal_params
    case AnimalApi.update(id, animal_params, institution(conn)) do
      {:ok, animal} ->
        render(conn, "show.html", animal: animal)
      {:error, changeset} ->
        render(conn, "edit_animal_form.html",
          changeset: changeset, action: path(:update, id))
    end
  end
end
