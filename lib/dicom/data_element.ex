defmodule Dicom.DataElement do
  @moduledoc """
  Implements a DICOM data element.

  References:
    * https://dicom.nema.org/dicom/2013/output/chtml/part05/chapter_7.html
  """

  alias Dicom.DataElement
  defstruct [:group_number, :element_number, :vr, :values]

  @type t :: %__MODULE__{}

  def from(group_number, element_number, value_representation, values) do
    %DataElement{
      :group_number => group_number,
      :element_number => element_number,
      :vr => value_representation,
      :values => values
    }
  end

  def from(keyword, values) when is_atom(keyword) do
    {:ok, {group_no, elem_no}} = Dicom.TagDict.get_tag_parts_by_keyword(keyword)
    {:ok, value_rep} = Dicom.TagDict.get_by_tag_parts(group_no, elem_no, :vr)

    %DataElement{
      :group_number => group_no,
      :element_number => elem_no,
      :vr => value_rep,
      :values => values
    }
  end

  def value(data_element, index \\ 0) do
    data_element.values |> Enum.at(index)
  end

  def tag(group_number, element_number)
      when is_number(group_number) and is_number(element_number) do
    Bitwise.bsl(group_number, 16) + element_number
  end

  def tag(%DataElement{:group_number => group_number, :element_number => element_number}) do
    tag(group_number, element_number)
  end

  defimpl String.Chars, for: DataElement do
    def to_string(%DataElement{
          group_number: group_number,
          element_number: element_number,
          vr: vr,
          values: values
        }) do
      group = Integer.to_string(group_number, 16)
      element = Integer.to_string(element_number, 16)

      name =
        case Dicom.TagDict.get_by_tag_parts(group_number, element_number, :name) do
          {:ok, name} -> name
          :error -> nil
        end

      "(#{group}, #{element}) #{vr} (#{name}): #{values}"
    end
  end
end
