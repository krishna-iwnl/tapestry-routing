defmodule Util do
  def id_to_guid(id) when is_bitstring(id) do
    hash =
      :crypto.hash(:sha, id)
      |> Base.encode16()
      |> String.slice(0, 8)

    hash
  end

  def get_unique_guids(size) do
    l = :rand.uniform(200_000)
    r = l + size - 1

    m =
      Enum.reduce(l..r, MapSet.new(), fn x, acc ->
        MapSet.put(acc, Util.id_to_guid(Integer.to_string(x)))
      end)

    MapSet.to_list(m)
  end

  def get_table(guid, nodes) do
    m = Util.get_new_table(guid)
    res = Enum.reduce(nodes, m, fn n, acc -> acc = add_neigh(guid, acc, n) end)
    # IO.inspect res
    res
  end

  def get_chunk_tables(chunk, nodes) do
    Enum.map(chunk, fn n -> {n, Util.get_table(n, nodes)} end)
  end

  def get_new_table(id) do
    lvl = Enum.map(0..15, fn i -> {Integer.to_string(i, 16), []} end)
    m = Map.new(lvl)

    t =
      Enum.map(0..7, fn i ->
        d = String.at(id, i)
        e = Map.put(m, d, [id])
        {Integer.to_string(i), e}
      end)

    table = Map.new(t)
    table
  end

  def add_neigh(id, table, neigh) when is_map(table) do
    pre = String.length(lcp([id, neigh]))
    next = String.at(neigh, pre)

    pre = pre |> Integer.to_string()
    old = table[pre][next]

    cond do
      pre |> String.to_integer() > 7 -> table
      length(old) > 3 -> table
      true -> put_in(table[pre][next], Enum.uniq(old ++ [neigh]))
    end
  end

  def next(hex_string) do
    {int, _} = Integer.parse(hex_string, 16)
    next = rem(int + 1, 16)
    next = Integer.to_string(next, 16)
  end

  def to_hex(int) do
    Integer.to_string(int, 16)
  end

  def get_next_from_row(row, pos) do
    e = row[pos]
    # IO.inspect "pos?"
    # IO.inspect pos
    len = map_size(row)

    cond do
      length(e) == 0 -> get_next_from_row(row, next(pos))
      true -> e
    end
  end

  def getNextHop(id, table, n, guid) do
    cond do
      n == String.length(guid) |> Integer.to_string() ->
        :self

      true ->
        # IO.puts "lvl"
        # IO.inspect n
        next = String.at(guid, String.to_integer(n))
        e = table[n]
        e = get_next_from_row(e, next)

        cond do
          Enum.any?(e, fn x -> x == id end) ->
            getNextHop(id, table, Integer.to_string(String.to_integer(n) + 1), guid)

          true ->
            e
        end
    end
  end

  def lcp([]), do: ""

  def lcp(strs) do
    min = Enum.min(strs)
    max = Enum.max(strs)

    index =
      Enum.find_index(0..String.length(min), fn i -> String.at(min, i) != String.at(max, i) end)

    if index, do: String.slice(min, 0, index), else: min
  end
end
