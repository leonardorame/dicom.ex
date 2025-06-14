defmodule Dicom.Image.JPEGLossless do
  use Bitwise
  @moduledoc """
  Minimal decoder for JPEG Lossless baseline (process 14).

  The implementation parses SOF, DHT and SOS segments and performs
  Huffman decoding followed by the inverse DPCM prediction.  Only a
  single component scan without restart markers is supported.  Sample
  precision of 8, 12 and 16 bit images is handled.
  """

  def decode(data) when is_binary(data) do
    {segments, scan} = parse_segments(data)

    sof = Map.fetch!(segments, :sof)
    dht = Map.fetch!(segments, :dht) |> List.first()
    sos = Map.fetch!(segments, :sos)

    {width, height, precision} = parse_sof(sof)
    tables = parse_dht(dht)
    {table_id, predictor} = parse_sos(sos)
    htable = Map.fetch!(tables, table_id)

    decode_scan(scan, width, height, precision, htable, predictor)
  end

  defp parse_segments(<<0xFF, 0xD8, rest::binary>>), do: parse_segments(rest, %{}, nil)
  defp parse_segments(data), do: raise("Invalid JPEG data: missing SOI")

  defp parse_segments(<<0xFF, 0xD9, _::binary>>, segments, scan), do: {segments, scan}

  defp parse_segments(
         <<0xFF, 0xDA, len::16-big, payload::binary-size(len - 2), rest::binary>>,
         segments,
         _scan
       ) do
    {scan, rest} = take_until_eoi(rest, <<>>)
    segments = Map.put(segments, :sos, payload)
    parse_segments(rest, segments, scan)
  end

  defp parse_segments(
         <<0xFF, marker, len::16-big, payload::binary-size(len - 2), rest::binary>>,
         segments,
         scan
       ) do
    key =
      case marker do
        0xC3 -> :sof
        0xC4 -> :dht
        0xDD -> :dri
        _ -> nil
      end

    segments =
      if key do
        Map.update(segments, key, [payload], fn list -> [payload | list] end)
      else
        segments
      end

    parse_segments(rest, segments, scan)
  end

  defp parse_segments(<<>>, segments, scan), do: {segments, scan}

  defp take_until_eoi(<<0xFF, 0xD9, rest::binary>>, acc), do: {acc, rest}

  defp take_until_eoi(<<byte, rest::binary>>, acc), do: take_until_eoi(rest, acc <> <<byte>>)

  defp parse_sof(<<precision, h::16-big, w::16-big, 1, _id, _sampling, _qt>>),
    do: {w, h, precision}

  defp parse_sof(_), do: raise("Only single component SOF3 supported")

  defp parse_dht(<<ht_info, counts::binary-size(16), rest::binary>>) do
    lengths = for <<c <- counts>>, do: c
    total = Enum.sum(lengths)
    <<values::binary-size(total), _::binary>> = rest
    table = build_table(lengths, :binary.bin_to_list(values))
    class = ht_info >>> 4
    id = Bitwise.band(ht_info, 0x0F)
    %{id => table}
  end

  defp build_table(lengths, values) do
    {map, _code, _vals} =
      Enum.reduce(1..16, {%{}, 0, values}, fn len, {acc, code, vals} ->
        count = Enum.at(lengths, len - 1)

        {acc, code, vals} =
          Enum.reduce(1..count, {acc, code, vals}, fn _, {acc2, code2, [v | rest]} ->
            acc2 = Map.put(acc2, {len, code2}, v)
            {acc2, code2 + 1, rest}
          end)

        {acc, code <<< 1, vals}
      end)

    map
  end

  defp parse_sos(<<1, _cid, sel, predictor, _se, _al>>), do: {sel >>> 4, predictor}
  defp parse_sos(_), do: raise("Unsupported SOS")

  defp unstuff(<<>>), do: <<>>
  defp unstuff(<<0xFF, 0x00, rest::binary>>), do: <<0xFF>> <> unstuff(rest)
  defp unstuff(<<byte, rest::binary>>), do: <<byte>> <> unstuff(rest)

  defp decode_scan(data, w, h, prec, table, predictor) do
    bits = unstuff(data)
    {rows, _bits} = decode_rows(0, h, w, prec, table, predictor, bits, [], [])
    values = rows |> Enum.reverse() |> List.flatten()
    encode_pixels(values, prec)
  end

  defp decode_rows(y, h, _w, _p, _t, _pred, bits, rows, _prev) when y == h do
    {rows, bits}
  end

  defp decode_rows(y, h, w, p, t, pred, bits, rows, prev) do
    {row, bits} = decode_row(y, 0, w, p, t, pred, bits, prev, [])
    decode_rows(y + 1, h, w, p, t, pred, bits, [row | rows], row)
  end

  defp decode_row(_y, x, w, _p, _t, _pred, bits, _prev, row) when x == w do
    {Enum.reverse(row), bits}
  end

  defp decode_row(y, x, w, p, t, pred, bits, prev, row) do
    {cat, bits} = decode_symbol(bits, t)
    {diff, bits} = decode_diff(bits, cat)

    pred_val =
      cond do
        x == 0 and y == 0 -> 1 <<< (p - 1)
        x == 0 -> Enum.at(prev, 0)
        true -> hd(row)
      end

    max = (1 <<< p) - 1
    value = Bitwise.band(pred_val + diff, max)

    decode_row(y, x + 1, w, p, t, pred, bits, prev, [value | row])
  end

  defp decode_symbol(bits, table), do: decode_symbol(bits, table, 1, 0)

  defp decode_symbol(<<bit::1, rest::bitstring>>, table, len, code) do
    code = (code <<< 1) + bit

    case Map.get(table, {len, code}) do
      nil -> decode_symbol(rest, table, len + 1, code)
      val -> {val, rest}
    end
  end

  defp decode_diff(bits, 0), do: {0, bits}

  defp decode_diff(bits, size) do
    <<val::unsigned-integer-size(size), rest::bitstring>> = bits
    sign_bit = 1 <<< (size - 1)

    diff =
      if val < sign_bit do
        val - (1 <<< size) + 1
      else
        val
      end

    {diff, rest}
  end

  defp encode_pixels(values, p) when p <= 8 do
    for v <- values, into: <<>>, do: <<v::unsigned-integer-8>>
  end

  defp encode_pixels(values, _p) do
    for v <- values, into: <<>>, do: <<v::unsigned-integer-big-16>>
  end
end
