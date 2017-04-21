defmodule PCTests do
  def test_abort() do
    a = spawn(PCNode, :coordinator, [])
    b = spawn(PCNode, :slave, [])
    c = spawn(PCNode, :slave, [])
    d = spawn(PCNode, :slave, [])
    send(a, {:add_slave, b})
    send(a, {:add_slave, c})
    send(a, {:add_slave, d})

    send(b, {:vote, :yes})
    send(c, {:vote, :yes})
    send(d, {:vote, :no})

    send(a, {:start_3pc})
  end

  def test_commit() do
    a = spawn(PCNode, :coordinator, [])
    b = spawn(PCNode, :slave, [])
    c = spawn(PCNode, :slave, [])
    d = spawn(PCNode, :slave, [])
    send(a, {:add_slave, b})
    send(a, {:add_slave, c})
    send(a, {:add_slave, d})
    send(b, {:vote, :yes})
    send(c, {:vote, :yes})
    send(d, {:vote, :yes})
    send(a, {:start_3pc})
  end
end
