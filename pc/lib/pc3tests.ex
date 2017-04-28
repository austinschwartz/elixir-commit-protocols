defmodule PC3Tests do
  def commit_all(n) do
    a = spawn(PC3Node, :coordinator, [])
    r = Range.new(1, n)
    pids = Enum.map(r, fn i -> spawn(PC3Node, :slave, []) end)
    pids |> Enum.each(fn pid -> send(a, {:add_slave, pid}) end)
    pids |> Enum.each(fn pid -> send(pid, {:vote, :yes}) end)
    send(a, {:start_3pc})
  end

  def abort_all(n) do
    a = spawn(PC3Node, :coordinator, [])
    r = Range.new(1, n)
    pids = Enum.map(r, fn i -> spawn(PC3Node, :slave, []) end)
    pids |> Enum.each(fn pid -> send(a, {:add_slave, pid}) end)
    pids |> Enum.each(fn pid -> send(pid, {:vote, :no}) end)
    send(a, {:start_3pc})
  end

  def abort_one(n) do
    a = spawn(PC3Node, :coordinator, [])
    r = Range.new(1, n)
    pids = Enum.map(r, fn i -> spawn(PC3Node, :slave, []) end)
    pids |> Enum.each(fn pid -> send(a, {:add_slave, pid}) end)
    pids |> Enum.each(fn pid -> send(pid, {:vote, :yes}) end)
    send(Enum.at(pids, :rand.uniform(n) + 1), {:vote, :no})
    send(a, {:start_3pc})
  end
end
