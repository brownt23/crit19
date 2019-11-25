defmodule Crit.Assertions.Changeset do
  import Crit.Assertions.Defchain
  import ExUnit.Assertions
  alias Ecto.Changeset
  import Crit.DataCase, only: [errors_on: 1]

  defchain assert_valid(%Changeset{} = changeset),
    do: assert changeset.valid?

  defchain assert_invalid(%Changeset{} = changeset),
    do: refute changeset.valid?

  defchain assert_changes(%Changeset{} = changeset, list) do
    Enum.map(list, fn
      {field, expected} ->
        assert changeset.changes[field] == expected
        assert Map.has_key?(changeset.changes, field) 
      field ->
        assert Map.has_key?(changeset.changes, field)
    end)
  end

  defchain assert_change(cs, arg2) when is_list(arg2), do: assert_changes(cs, arg2)

  defchain assert_unchanged(%Changeset{} = changeset),
    do: assert changeset.changes == %{}

  defchain assert_unchanged(%Changeset{} = changeset, field) when is_atom(field) do
    refute Map.has_key?(changeset.changes, field)
  end

  defchain assert_unchanged(%Changeset{} = changeset, fields) when is_list(fields),
    do: Enum.map fields, &(assert_unchanged changeset, &1)

  defchain assert_errors(%Changeset{} = changeset, list) do
    refute changeset.valid?
    errors = errors_on(changeset)
    Enum.map(list, fn
      field when is_atom(field) ->
        assert is_list(errors[field])
      {field, expected} when is_binary(expected) ->
        assert expected in errors[field]
      {field, expecteds} when is_list(expecteds) ->
        Enum.map expecteds, &(assert &1 in errors[field])
    end)
  end

  defchain assert_error(cs, arg2) when is_atom(arg2), do: assert_errors(cs, [arg2])
  defchain assert_error(cs, arg2),                    do: assert_errors(cs,  arg2)
    
  








  
  defchain assert_changed_to(%Changeset{} = changeset, field, expected) do 
    assert changeset.changes[field] == expected
    assert Map.has_key?(changeset.changes, field)
  end

  defchain assert_recorded_changes(%Changeset{} = changeset, data_map, fields)
  when is_list(fields) do
    Enum.map(fields, fn field ->
      assert_changed_to(changeset, field, data_map[field])
    end)
  end

end


