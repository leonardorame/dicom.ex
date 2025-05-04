defmodule Dicom.DataElement do
  @moduledoc """
  A [DICOM data element](https://dicom.nema.org/dicom/2013/output/chtml/part05/chapter_7.html) is one value 
  or a list of values with a defined data type and uniquely
  identified by a tag within a `Dicom.DataSet`.
  """

  @vrs_binary [:OB, :OD, :OF, :OL, :OV, :OW]

  alias Dicom.DataElement
  defstruct [:group_number, :element_number, :vr, :values]

  @type t :: %__MODULE__{}

  def binary?(%DataElement{vr: vr}) do
    vr in @vrs_binary
  end

  def sequence?(%DataElement{vr: vr}) do
    vr == :SQ
  end

  @spec new(integer(), atom(), [any()]) :: t()
  def new(tag, value_representation, values) do
    group_number = Bitwise.bsr(tag, 16)
    element_number = Bitwise.band(tag, 0xFFFF)

    %DataElement{
      group_number: group_number,
      element_number: element_number,
      vr: value_representation,
      values: values
    }
  end

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
end

defimpl String.Chars, for: Dicom.DataElement do
  alias Dicom.DataElement

  defp indent(str, prefix) do
    str
    |> String.split("\n")
    |> Enum.map(fn s -> prefix <> s end)
    |> Enum.join("\n")
  end

  defp append_to_first_line(str, appendix) do
    lines = String.split(str, "\n")

    tail =
      case lines do
        [_ | tail] -> tail
        [] -> []
      end

    [hd(lines) <> appendix | tail] |> Enum.join("\n")
  end

  defp trim_string_to_length(str, length, trim_marker \\ "...") do
    if String.length(str) > length do
      String.slice(str, 0, length - String.length(trim_marker)) <> trim_marker
    else
      str
    end
  end

  def to_string(
        %Dicom.DataElement{
          group_number: group_number,
          element_number: element_number,
          vr: vr,
          values: values
        } = el
      ) do
    group = :io_lib.format("~4.16.0B", [group_number])
    element = :io_lib.format("~4.16.0B", [element_number])

    name =
      case Dicom.TagDict.get_by_tag_parts(group_number, element_number, :name) do
        {:ok, name} -> name
        :error -> nil
      end

    name_str =
      if is_nil(name) do
        ""
      else
        " # #{name}"
      end

    values_str =
      cond do
        DataElement.sequence?(el) ->
          "\n" <>
            (values
             |> Enum.map(&String.Chars.to_string/1)
             |> Enum.join("\n")
             |> indent("  ")) <> "\n"

        DataElement.binary?(el) ->
          Base.encode16(Enum.at(values, 0))
          |> trim_string_to_length(32)

        true ->
          values |> Enum.map(&String.Chars.to_string/1) |> Enum.join(", ")
      end

    str = "(#{group}, #{element}) #{vr}: [#{values_str}]" |> append_to_first_line(name_str)

    str
  end
end
