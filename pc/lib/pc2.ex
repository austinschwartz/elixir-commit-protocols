defmodule PC2Node do

  def coordinator(), do: coordinator([], [])

  defp coordinator(slaves, votes) do
    receive() do
      {:add_slave, slave} ->
        log("Coordinator added slave: #{slave |> pid_to_string()}")
        coordinator([slave | slaves], votes)
      {:start_2pc} ->
        log("Coordinator, 1st phase, sending xacts")
        broadcast(slaves, {:xact, self()})
        coordinator(slaves, votes)
      {:vote, vote} ->
        log("Cordinator received a #{vote |> bool_to_string}")
        votes2 = [vote | votes]
        is_voting_done = length(votes2) == length(slaves)
        if is_voting_done do
          done(slaves, votes2)
        else
          coordinator(slaves, votes2)
        end
    end
  end

  def slave(), do: slave([], nil)

  defp slave(slaves, state) do
    receive() do
      {:vote, decision} ->
        log("Will propose: #{bool_to_string(decision)}")
        slave(slaves, decision)
      {:xact, coordinator} ->
        log("xact from coordinator") # xact
        send(coordinator, {:vote, state})
        slave(slaves, state)
      {:commit, coordinator} ->
        log(:commit)
      {:abort, coordinator} ->
        log(:abort)
    end
  end

  defp done(slaves, votes) do
    consensus = Enum.all?(votes, &(&1 == :yes))
    log("Coordinator received all votes: [#{Enum.map(votes, &(&1 |> bool_to_string)) |> Enum.join(",")}]")
    action = case consensus do
      true ->  :commit
      false -> :abort
    end
    broadcast(slaves, {action, self()})
    wait_acks(length(slaves), action)
  end


  defp wait_acks(0, final), do: log(final)

  defp wait_acks(remaining, final) do
    case final do
      0 -> log(final)
      _ -> 
      receive() do
        {:ack} ->
          wait_acks(remaining - 1, final)
      end
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
