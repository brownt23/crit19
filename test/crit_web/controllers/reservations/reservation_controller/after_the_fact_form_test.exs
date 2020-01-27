defmodule CritWeb.Reservations.ReservationController.AfterTheFactFormTest do
  use Crit.DataCase, async: true
  alias CritWeb.Reservations.AfterTheFactForm
  alias Ecto.Timespan

  describe "form_1_changeset synthesizes some values" do
    test "success" do
      params = %{species_id: to_string(@bovine_id),
                 date: "2019-01-01",
                 date_showable_date: "January 1, 2019",
                 time_slot_id: "1",
                 institution: @institution}

      expected_span =
        Timespan.from_date_time_and_duration(~D[2019-01-01], ~T[08:00:00], 4 * 60)

      AfterTheFactForm.form_1_changeset(params)
      |> assert_changes(
           species_id: @bovine_id,
           species_name: @bovine,
           date: ~D[2019-01-01],
           date_showable_date: "January 1, 2019",
           time_slot_name: @institution_first_time_slot.name,
           span: expected_span
         )
    end
  end
end