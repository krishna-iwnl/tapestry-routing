import Util

defmodule PeerSupervisor do
  use Supervisor

  def start_link(nodes) do
    Supervisor.start_link(__MODULE__, nodes, name: :PeerSuper)
  end

  def add_all_dynamic(nodes) do
    # div(length(m), 100)
    static_len = length(nodes) - 1
    {m, dynamic_nodes} = Enum.split(nodes, static_len)

    Enum.map(dynamic_nodes, fn n ->
      rand_starting_node = Enum.random(m)
      Peer.add_dynamic(rand_starting_node, n)
    end)
  end

  def init(nodes) do
    # IO.inspect m

    # div(length(m), 100)
    static_len = length(nodes) - 1
    {m, dynamic_nodes} = Enum.split(nodes, static_len)

    chunks = Enum.chunk_every(m, 500)
    tasks = Enum.map(chunks, fn c -> Task.async(fn -> Util.get_chunk_tables(c, m) end) end)
    nodes = Enum.map(tasks, fn t -> Task.await(t, :infinity) end) |> List.flatten()

    dynamic_nodes =
      Enum.map(dynamic_nodes, fn x ->
        {x, Util.get_new_table(x)}
      end)

    nodes = nodes ++ dynamic_nodes

    children =
      Enum.map(nodes, fn p ->
        id = elem(p, 0)
        table = elem(p, 1)
        peerdata = Peer_data.get_peer(id, table)
        worker(Peer, [peerdata], id: peerdata.id)
      end)

    #   IO.inspect m
    # IO.inspect(children)

    supervise(children, strategy: :one_for_one)
  end
end
