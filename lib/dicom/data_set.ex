defmodule Dicom.DataSet do
  alias Dicom.DataElement

  def from_elements(elements) do
    elements
    |> Enum.map(&{DataElement.tag(&1), &1})
    |> Enum.into(%{})
  end

  def from_keyword_list(value_list) do
    value_list
    |> Enum.map(fn {keyword, value} -> Dicom.DataElement.from(keyword, [value]) end)
    |> from_elements()
  end

  def fetch(ds, keyword) when is_atom(keyword) do
    with {:ok, {group_no, elem_no}} <- Dicom.TagDict.get_tag_parts_by_keyword(keyword),
         {:ok, de} <- Map.fetch(ds, Dicom.DataElement.tag(group_no, elem_no)) do
      {:ok, de}
    else
      _ -> :error
    end
  end

  def fetch!(ds, keyword) when is_atom(keyword) do
    case fetch(ds, keyword) do
      {:ok, de} -> de
      :error -> raise KeyError, "Element #{keyword} not found in data set."
    end
  end
end
