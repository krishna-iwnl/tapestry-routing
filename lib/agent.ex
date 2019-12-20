defmodule Storage do
  use Agent
  # state is a PeerData object

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end)
  end

  def get_state(pid) do
    Agent.get(pid, fn x -> x end)
  end

  def get_id(pid) do
    Agent.get(pid, fn x -> x.id end)
  end

  def get_table(pid) do
    Agent.get(pid, fn x -> x.table end)
  end

  def add_neigh(pid, neigh) do
    Agent.update(pid, fn x ->
      new_table = Util.add_neigh(x.id, x.table, neigh)
      %{x | table: new_table}
    end)
  end

  def get_row(pid, row) do
    Agent.get(pid, fn x -> x.table[Integer.to_string(row)] end)
  end
end
