defmodule Dicom.DataSet do
  @moduledoc """
  A [DICOM data set](https://dicom.nema.org/dicom/2013/output/chtml/part05/chapter_7.html) is a collection of `Dicom.DataElement`s uniquely identified by their numeric tags.
  """
  alias Dicom.DataElement

  defstruct [:elements, :file_meta]

  @type t :: %__MODULE__{}

  @doc """
  Create a data set from a enumerable of `Dicom.DataElement`s.

  ## Examples

      iex> (for i <- 1..3, do: Dicom.DataElement.from(0x0021, i, :US, i))
      ...> |> Dicom.DataSet.from_elements()
  """
  @spec from_elements(Enumerable.t(DataElement.t())) :: t()
  def from_elements(elements) do
    elem_map =
      elements
      |> Enum.map(&{DataElement.tag(&1), &1})
      |> Enum.into(%{})

    %__MODULE__{elements: elem_map}
  end

  @doc """
  Create a data set from a keyword-value mapping.

  All keywords must be contained in the data dictionary.

  ## Examples

      iex> Dicom.DataSet.from_keyword_list(PatientID: "JDOE123", PatientName: "Doe^John")
  """
  @spec from_keyword_list([{atom(), any()}]) :: t()
  def from_keyword_list(value_list) do
    value_list
    |> Enum.map(fn {keyword, value} ->
      Dicom.DataElement.from(keyword, if(is_list(value), do: value, else: [value]))
    end)
    |> from_elements()
  end

  @typedoc """
  Index value to access an element inside a data set.

  It can be either:

  1. an atom representing a known element keyword from the data dictionary,
  2. a 32-bit integer representing the tag or
  3. a tuple of 2 16-bit integers representing group and element of the tag respectively.
  """
  @type key_type() :: atom() | integer() | {integer(), integer()}

  defp resolve_key(key) do
    case key do
      kw when is_atom(kw) ->
        case Dicom.TagDict.get_tag_parts_by_keyword(kw) do
          {:ok, {group_no, elem_no}} -> {:ok, Bitwise.bsl(group_no, 16) + elem_no}
          :error -> :error
        end

      {group_no, elem_no} ->
        {:ok, Bitwise.bsl(group_no, 16) + elem_no}

      tag when is_integer(tag) ->
        {:ok, tag}

      _ ->
        :error
    end
  end

  @doc """
  Fetches the `Dicom.DataElement` identified by `key` from the `ds`.

  If `ds` contains the element, it is returned in the shape of `{:ok, element}`. If not,
  the atom `:error` is returned instead.

  ## Examples

      iex> ds = DataSet.from_keyword_list(PatientID: "JDOE123")
      iex> {:ok, _element} = DataSet.fetch(ds, :PatientID)
      iex> {:ok, _element} = DataSet.fetch(ds, {0x0010, 0x0020})
      iex> {:ok, _element} = DataSet.fetch(ds, 0x00100020)
      iex> :error = DataSet.fetch(ds, :StudyID)
  """
  @spec fetch(t(), key_type()) :: {:ok, DataElement.t()} | {:error, atom()}
  def fetch(ds, key) do
    with {:ok, tag} <- resolve_key(key),
         {:ok, de} <- Map.fetch(ds.elements, tag) do
      {:ok, de}
    else
      _ -> :error
    end
  end

  @doc """
  Fetches the `Dicom.DataElement` for `key` from `ds`, erroring out if it does not exist.

  If `ds` contains `key`, the `Dicom.DataElement` is returned. If not,
  a `KeyError` exception is raised.

  ## Examples

      iex> ds = DataSet.from_keyword_list(PatientID: "JDOE123")
      iex> _element = DataSet.fetch!(ds, :PatientID)
  """
  @spec fetch!(t(), key_type()) :: DataElement.t()
  def fetch!(ds, key) do
    case fetch(ds, key) do
      {:ok, de} -> de
      :error -> raise KeyError, "Element #{key} not found in data set."
    end
  end

  @doc """
  Fetches the value of the data element identified by `key`.

  This is a shortcut to directly access a specific value. If the
  data element has a value multiplicity > 1, a specific index can
  be accessed with the `index` parameter.

  ## Examples

      iex> ds = DataSet.from_keyword_list(OtherPatientNames: ["Max", "Tom"])
      iex> DataSet.value_for!(ds, :OtherPatientNames, 1)
      "Tom"
  """
  @spec value_for!(t(), key_type(), integer()) :: any()
  def value_for!(ds, key, index \\ 0) when is_integer(index) do
    ds
    |> fetch!(key)
    |> DataElement.value(index)
  end
end

defimpl Enumerable, for: Dicom.DataSet do
  def member?(ds, element) do
    Enumerable.Map.member?(ds.elements, element)
  end

  def reduce(ds, acc, fun) do
    Enumerable.Map.reduce(ds.elements, acc, fun)
  end

  def slice(ds) do
    Enumerable.Map.slice(ds.elements)
  end

  def count(ds) do
    Enumerable.Map.count(ds.elements)
  end
end

defimpl String.Chars, for: Dicom.DataSet do
  def to_string(ds) do
    type_str =
      if Enum.all?(ds.elements, fn {tag, _el} -> tag < 0x00030000 end) do
        "# File Meta"
      else
        "# Data Set"
      end

    ds_str =
      ds.elements
      |> Enum.sort(fn {tag1, _el1}, {tag2, _el2} -> tag1 <= tag2 end)
      |> Enum.map(fn {_tag, el} -> String.Chars.to_string(el) end)
      |> Enum.join("\n")

    parts = [type_str, ds_str]

    parts =
      if is_nil(ds.file_meta) do
        parts
      else
        [String.Chars.to_string(ds.file_meta) | parts]
      end

    Enum.join(parts, "\n")
  end
end
