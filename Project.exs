defmodule Proj3 do
  require Logger

  def main() do
    args = System.argv
    nodes = Enum.at(args, 0) |> String.to_integer
    num_requests = Enum.at(args, 1) |> String.to_integer

    Registry.start_link(keys: :unique, name: :peer_process_registry)
    Hops_counter.start_link(nodes * num_requests)

    m = Util.get_unique_guids(nodes)
    PeerSupervisor.start_link(m)
    PeerSupervisor.add_all_dynamic(m)

    Process.sleep(3000)

    Enum.map(m, fn id ->
      Proj3.random_connect(id, num_requests, m)
    end)

    Process.sleep(20000)
  end

  def random_connect(id, num_reqs, nodes) do
    Enum.map(1..num_reqs, fn _ ->
      dest_id = Enum.random(nodes)
      Peer.connect(id, dest_id)
    end)

    # IO.inspect "done"
  end
end
Proj3.main()
