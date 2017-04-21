defmodule PC3Tests do
  def abort_one() do
    a = spawn(PC3Node, :coordinator, [])
    b = spawn(PC3Node, :slave, [])
    c = spawn(PC3Node, :slave, [])
    d = spawn(PC3Node, :slave, [])
    send(a, {:add_slave, b})
    send(a, {:add_slave, c})
    send(a, {:add_slave, d})
    send(b, {:vote, :yes})
    send(c, {:vote, :yes})
    send(d, {:vote, :no})
    send(a, {:start_3pc})
  end

  def commit_all() do
    a = spawn(PC3Node, :coordinator, [])
    b = spawn(PC3Node, :slave, [])
    c = spawn(PC3Node, :slave, [])
    d = spawn(PC3Node, :slave, [])
    send(a, {:add_slave, b})
    send(a, {:add_slave, c})
    send(a, {:add_slave, d})
    send(b, {:vote, :yes})
    send(c, {:vote, :yes})
    send(d, {:vote, :yes})
    send(a, {:start_3pc})
  end
end
