defmodule Hops_counter do
  use GenServer

  def start_link(count) do
    GenServer.start_link(__MODULE__, count, name: :Hops_counter)
  end

  def update_hop(hops) do
    GenServer.call(:Hops_counter, {:update, hops})
  end

  def handle_call({:update, hops}, _from, {count, max_hops}) do
    max_hops = Enum.max([max_hops, hops])
    # IO.inspect "got #{max_hops}"
    if(count == 1) do
      IO.inspect(max_hops)
      System.stop(0)
    end

    {:reply, max_hops, {count - 1, max_hops}}
  end

  def init(count) do
    {:ok, {count, 0}}
  end
end
