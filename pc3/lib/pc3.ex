defmodule PCNode do

  require Record

  Record.defrecordp :coordinator_state, :coordinator_state, [votes: []]
  Record.defrecordp :slave_state, :slave_state, [decision: []]

  def coordinator(), do: coordinator([], coordinator_state(votes: []))

  defp coordinator(slaves, coordinator_state(votes: votes) = state) do
    receive() do
      {:add_slave, pid} ->
        log("Coordinator added slave: #{pid |> pid_to_string()}")
        coordinator([pid | slaves], state)
      {:start_3pc} ->
        log("Coordinator, 1st phase trying to commit")
        query_to_commit(slaves)
        coordinator(slaves, state)
      {:vote, vote} ->
        log("Cordinator received a #{vote |> bool_to_string}")
        votes2 = [vote | votes]
        is_voting_done = length(votes2) == length(slaves)
        if is_voting_done do
          completion(slaves, votes2)
        else
          newState = coordinator_state(state, votes: votes2)
          coordinator(slaves, newState)
        end
    end
  end

  defp completion(slaves, votes) do
    log("As coordinator, 2nd phase")
    consensus = Enum.all?(votes, &(&1 == :yes))
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

  def slave(), do: slave([], slave_state(decision: nil))

  defp slave(slaves, state) do
    receive() do
      {:vote, decision} ->
        log("Will propose: #{bool_to_string(decision)}")
        slave(slaves, slave_state(decision: decision))
      {:query, coordinator} ->
        log("Queried by coordinator")
        send(coordinator, {:vote, slave_state(state, :decision)})
        slave(slaves, state)
      {:commit, coordinator} ->
        log(:commit)
        send(coordinator, {:ack})
      {:abort, coordinator} ->
        log(:abort)
        send(coordinator, {:ack})
    end
  end


  defp query_to_commit(nodes), do: broadcast(nodes, {:query, self()})

  defp broadcast(nodes, message), do: for node <- nodes, do: send(node, message)

  defp log(:commit), do: log("Commit!")

  defp log(:abort), do: log("Abort")

  defp log(string), do: IO.puts("#{who_am_i()} - #{string}")

  defp who_am_i(), do: self() |> pid_to_string()

  defp bool_to_string(bool) do
    case bool do
      :yes -> "yes"
      :no -> "no"
      true -> "yes"
      _ -> "no"
    end
  end

  defp pid_to_string(pid), do: :erlang.pid_to_list(pid)
end
