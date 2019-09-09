defmodule Crit.Usables do
  alias Crit.Usables.Animal
  alias Crit.Sql

  
  # @moduledoc """
  # The Usables context.
  # """

  # import Ecto.Query, warn: false
  # alias Crit.Repo

  # alias Crit.Usables.Animal

  # @doc """
  # Returns the list of animals.

  # ## Examples

  #     iex> list_animals()
  #     [%Animal{}, ...]

  # """
  # def list_animals do
  #   Repo.all(Animal)
  # end


  def add_service_gap(%Animal{id: animal_id}, start_date, end_date, reason) do
    add_service_gap(animal_id, start_date, end_date, reason)
  end

  def add_service_gap(_animal_id, _start_date, _end_date, _reason) do
  end

  def get_complete_animal(id, institution) do
    case id |> Animal.Query.complete |> Sql.one(institution) do
      nil ->
        raise KeyError, "No animal id #{id}"
      animal ->
        animal
    end
  end

  def create_animal(attrs, _unavailabilites, institution) do
    case %Animal{} |> Animal.changeset(attrs) |> Sql.insert(institution) do
      {:ok, animal} ->
        {:ok, animal.id}
    end
  end

  # @doc """
  # Updates a animal.

  # ## Examples

  #     iex> update_animal(animal, %{field: new_value})
  #     {:ok, %Animal{}}

  #     iex> update_animal(animal, %{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def update_animal(%Animal{} = animal, attrs) do
  #   animal
  #   |> Animal.changeset(attrs)
  #   |> Repo.update()
  # end

  # @doc """
  # Deletes a Animal.

  # ## Examples

  #     iex> delete_animal(animal)
  #     {:ok, %Animal{}}

  #     iex> delete_animal(animal)
  #     {:error, %Ecto.Changeset{}}

  # """
  # def delete_animal(%Animal{} = animal) do
  #   Repo.delete(animal)
  # end

  def change_animal(%Animal{} = animal) do
    Animal.changeset(animal, %{})
  end

  def repeated_animal_changeset(_params) do
  end
end
