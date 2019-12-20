defmodule Peer do
  use GenServer
  # State is a map of id and agent id, %{:id,:aid}

  def start_link(state) do
    name = via_tuple(state.id)
    GenServer.start_link(__MODULE__, [state], name: name)
  end

  def add_neigh(id, neigh) do
    GenServer.call(via_tuple(id), {:add_neigh, neigh})
  end

  def connect(id, dest_id) do
    # IO.inspect("starting from #{id} to #{dest_id}")
    GenServer.cast(via_tuple(id), {:connect, dest_id, id, 0})
  end

  def add_dynamic(curr_id, id) do
    # IO.inspect(id)
    GenServer.cast(via_tuple(curr_id), {:findroot, id, curr_id, 0})
  end

  def pp(id) do
    GenServer.call(via_tuple(id), :pp)
  end

  defp via_tuple(peer_id) do
    {:via, Registry, {:peer_process_registry, peer_id}}
  end

  def init([state]) do
    {:ok, agent_id} = Storage.start_link(state)
    state = %{id: state.id, aid: agent_id}
    {:ok, state}
  end

  def handle_call({:add_neigh, neigh}, _from, state) do
    Storage.add_neigh(state.aid, neigh)
    {:reply, state, state}
  end

  def handle_call(:pp, _from, state) do
    IO.inspect(Storage.get_state(state.aid))
    {:reply, state, state}
  end

  def handle_cast({:connect, dest_id, src_id, hops}, state) do
    # IO.inspect("reached #{state.id} with #{hops}")
    id = Storage.get_id(state.aid)
    table = Storage.get_table(state.aid)
    n = String.length(Util.lcp([state.id, dest_id]))
    next = Util.getNextHop(id, table, Integer.to_string(n), dest_id)

    # IO.inspect(table)
    # IO.inspect(dest_id)
    # IO.inspect(src_id)
    # IO.inspect(next)

    cond do
      next == :self -> GenServer.cast(via_tuple(src_id), {:reached, state.id, hops})
      true -> GenServer.cast(via_tuple(Enum.at(next, 0)), {:connect, dest_id, src_id, hops + 1})
    end

    {:noreply, state}
  end

  def handle_cast({:findroot, dest_id, src_id, n}, state) do
    id = Storage.get_id(state.aid)
    table = Storage.get_table(state.aid)
    next = Util.getNextHop(id, table, Integer.to_string(n), dest_id)

    # IO.inspect(table)
    # IO.inspect(dest_id)
    # IO.inspect(src_id)
    # IO.inspect(next)

    cond do
      next == :self -> GenServer.cast(via_tuple(src_id), {:root, state.id, dest_id})
      true -> GenServer.cast(via_tuple(Enum.at(next, 0)), {:findroot, dest_id, src_id, n + 1})
    end

    {:noreply, state}
  end

  def handle_cast({:root, root, new_node}, state) do
    # IO.inspect("root is #{root}")
    prelen = Util.lcp([root, new_node]) |> String.length()
    GenServer.cast(via_tuple(root), {:add_node_multicast, new_node, prelen})
    {:noreply, state}
  end

  def handle_cast({:add_node_multicast, new_node, n}, state) do
    cond do
      n < 8 ->
        targets = Storage.get_row(state.aid, n)
        Storage.add_neigh(state.aid, new_node)
        add_neigh(new_node, state.id)

        Enum.map(targets, fn row ->
          Enum.map(elem(row, 1), fn y ->
            GenServer.cast(via_tuple(y), {:add_node_multicast, new_node, n + 1})
          end)
        end)

        {:noreply, state}

      true ->
        {:noreply, state}
    end
  end

  def handle_cast({:reached, _dest_id, hops}, state) do
    # IO.inspect("#{state.id} --#{hops}--> #{dest_id}")
    Hops_counter.update_hop(hops)
    {:noreply, state}
  end
end
