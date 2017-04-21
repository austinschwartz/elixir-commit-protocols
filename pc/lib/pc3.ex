defmodule PC3Node do

  def coordinator(), do: coordinator([], :q, [])

  defp coordinator(slaves, state, votes) do
    receive() do
      {:add_slave, slave} ->
        log("Coordinator added slave: #{slave |> pid_to_string()}")
        coordinator([slave | slaves], state, votes)
      {:start_3pc} ->
        log("Coordinator, 1st phase, sending xacts")
        broadcast(slaves, {:xact, self()})
        coordinator(slaves, :w, votes)
      {:vote, vote} ->
        log("Cordinator received a #{vote |> bool_to_string}")
        votes2 = [vote | votes]
        is_voting_done = length(votes2) == length(slaves)
        if is_voting_done do
          done(slaves, votes2)
          coordinator(slaves, state, votes2)
        else
          coordinator(slaves, state, votes2)
        end
    end
  end

  def slave(), do: slave([], :q, nil)

  defp slave(slaves, state, vote) do
    receive() do
      {:vote, decision} ->
        case decision do
          :yes -> 
            slave(slaves, :w, decision)
          :no ->
            slave(slaves, :a, decision)
        end
      {:xact, coordinator} ->
        log("xact from coordinator, sending #{bool_to_string(vote)}") # xact
        send(coordinator, {:vote, vote})
        slave(slaves, state, vote)
      {:prepare, coordinator} ->
        log("prepare from coordinator, sending ack") # xact
        send(coordinator, {:ack})
      {:commit, _} ->
        log(:commit)
      {:abort, _} ->
        log(:abort)
    end
  end

  defp done(slaves, votes) do
    consensus = Enum.all?(votes, &(&1 == :yes))
    log("Coordinator received all votes: [#{Enum.map(votes, &(&1 |> bool_to_string)) |> Enum.join(",")}]")
    action = case consensus do
      true ->  
        log("Coordinating sending out prepare msges")
        :prepare
      false -> 
        log("Coordinating sending out abort msges")
        :abort
    end
    broadcast(slaves, {action, self()})
    wait_acks(slaves, length(slaves), :ack)
  end


  defp wait_acks(slaves, 0, final) do 
    case final do
      :ack ->
        log("Coordinator received all acks, sending commit messages")
        broadcast(slaves, {:commit, self()})
      _ ->
        log("how did i get here?")
    end
  end

  defp wait_acks(slaves, remaining, final) do
    receive() do
      {:ack} ->
        wait_acks(slaves, remaining - 1, final)
    end
  end

  def broadcast(nodes, message), do: for node <- nodes, do: send(node, message)

  defp log(:commit), do: log("Commit!")

  defp log(:abort), do: log("Abort")

  defp log(string), do: IO.puts("#{who_am_i()} - #{string}")

  defp who_am_i(), do: self() |> pid_to_string()

  defp bool_to_string(bool) do
    case bool do
      :yes -> "yes"
      :no -> "no"
      true -> "yes"
      false -> "no"
      nil -> "nil?"
      _ -> "???"
    end
  end

  defp pid_to_string(pid), do: :erlang.pid_to_list(pid)
end
