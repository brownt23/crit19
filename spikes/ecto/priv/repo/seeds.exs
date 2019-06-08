alias Spikes.Repo


alias Spikes.Repo
alias Spikes.{Animal, Procedure, ReservationBundle}

# This lets me repopulate the database without deleting the tables,
# which is a pain because I've always got Postico open to the database.
Repo.delete_all(Animal)
Repo.delete_all(Procedure)
Repo.delete_all(ReservationBundle)


bovine_bundle = Repo.insert!(%ReservationBundle{ name: "horses" })
equine_bundle = Repo.insert!(%ReservationBundle{ name: "equine" })
vm334 = Repo.insert!(%ReservationBundle{ name: "vm334" })

Repo.insert! %Animal{
  name: "bossie",
  species: "bovine",
  reservation_bundles: [bovine_bundle, vm334]
}


Repo.insert! %Animal{
  name: "lassy",
  species: "bovine",
  reservation_bundles: [bovine_bundle]
}

Repo.insert! %Animal{
  name: "jake",
  species: "equine",
  reservation_bundles: [equine_bundle]
}


Repo.insert! %Procedure{
  name: "cow procedure",
  reservation_bundles: [bovine_bundle, vm334]
}

Repo.insert! %Procedure{
  name: "vm334 procedure",
  reservation_bundles: [vm334]
}

Repo.insert! %Procedure{
  name: "horse procedure",
  reservation_bundles: [equine_bundle]
}

