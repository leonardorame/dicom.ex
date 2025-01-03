defmodule Dicom.TagDict do
  @by_tag Dicom.TagDict.Dict.by_tag()

  @by_keyword (for {group_no, group} <- @by_tag, {elem_no, %{:keyword => keyword}} <- group do
                 {keyword, {group_no, elem_no}}
               end)
              |> Enum.into(%{})

  def get_by_tag_parts(group_number, element_number, attribute) do
    with {:ok, group} <- Map.fetch(@by_tag, group_number),
         {:ok, element} <- Map.fetch(group, element_number),
         {:ok, attribute} <- Map.fetch(element, attribute) do
      {:ok, attribute}
    else
      _ -> :error
    end
  end

  def get_tag_parts_by_keyword(keyword) do
    case Map.fetch(@by_keyword, keyword) do
      {:ok, {group_no, elem_no}} ->
        {:ok, {group_no, elem_no}}

      :error ->
        :error
    end
  end
end
