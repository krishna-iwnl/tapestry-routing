# State of each peer
defmodule Peer_data do
  defstruct id: nil,
            table: nil

  def get_peer(guid) do
    tab = Util.get_new_table(guid)
    %Peer_data{id: guid, table: tab}
  end

  def get_peer(guid, tab) do
    %Peer_data{id: guid, table: tab}
  end
end
