defmodule PC2Tests do
  def abort_one() do
    a = spawn(PC2Node, :coordinator, [])
    b = spawn(PC2Node, :slave, [])
    c = spawn(PC2Node, :slave, [])
    d = spawn(PC2Node, :slave, [])
    send(a, {:add_slave, b})
    send(a, {:add_slave, c})
    send(a, {:add_slave, d})
    send(b, {:vote, :yes})
    send(c, {:vote, :yes})
    send(d, {:vote, :no})
    send(a, {:start_2pc})
  end

  def abort_and_kill_coordinator() do
    a = spawn(PC2Node, :coordinator, [])
    b = spawn(PC2Node, :slave, [])
    c = spawn(PC2Node, :slave, [])
    d = spawn(PC2Node, :slave, [])
    send(a, {:add_slave, b})
    send(a, {:add_slave, c})
    send(a, {:add_slave, d})
    send(b, {:vote, :yes})
    send(c, {:vote, :yes})
    send(d, {:vote, :no})
    send(a, {:start_2pc})
  end

  def commit_all() do
    a = spawn(PC2Node, :coordinator, [])
    b = spawn(PC2Node, :slave, [])
    c = spawn(PC2Node, :slave, [])
    d = spawn(PC2Node, :slave, [])
    send(a, {:add_slave, b})
    send(a, {:add_slave, c})
    send(a, {:add_slave, d})
    send(b, {:vote, :yes})
    send(c, {:vote, :yes})
    send(d, {:vote, :yes})
    send(a, {:start_2pc})
  end
end
