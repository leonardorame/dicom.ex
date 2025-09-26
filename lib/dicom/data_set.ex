defmodule Dicom.DataSet do
  alias Dicom.DataElement

  @type t :: %{integer() => DataElement.t()}

  @spec from_elements(Enumerable.t({atom(), any()})) :: t()
  def from_elements(elements) do
    elements
    |> Enum.map(&{DataElement.tag(&1), &1})
    |> Enum.into(%{})
  end

  @spec from_keyword_list([{atom(), any()}]) :: t()
  def from_keyword_list(value_list) do
    value_list
    |> Enum.map(fn {keyword, value} ->
      Dicom.DataElement.from(keyword, normalize_values(value))
    end)
    |> from_elements()
  end

  defp normalize_values(nil), do: []
  defp normalize_values(value) when is_list(value), do: value
  defp normalize_values(value), do: [value]

  @spec fetch(t(), atom()) :: {:ok, DataElement.t()} | {:error, atom()}
  def fetch(ds, keyword) when is_atom(keyword) do
    with {:ok, {group_no, elem_no}} <- Dicom.TagDict.get_tag_parts_by_keyword(keyword),
         {:ok, de} <- Map.fetch(ds, Dicom.DataElement.tag(group_no, elem_no)) do
      {:ok, de}
    else
      _ -> {:error, :no_such_element}
    end
  end

  @spec fetch!(t(), atom()) :: DataElement.t()
  def fetch!(ds, keyword) when is_atom(keyword) do
    case fetch(ds, keyword) do
      {:ok, de} -> de
      {:error, :no_such_element} -> raise KeyError, "Element #{keyword} not found in data set."
    end
  end

  @spec value_for!(t(), atom(), integer()) :: any()
  def value_for!(ds, keyword, index \\ 0) when is_atom(keyword) and is_integer(index) do
    ds
    |> fetch!(keyword)
    |> DataElement.value(index)
  end

  def to_string(ds) do
    ds
    |> Map.values()
    |> Enum.map(&String.Chars.to_string/1)
    |> Enum.join("\n")
  end
end
