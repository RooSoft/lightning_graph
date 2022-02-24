defmodule LightningGraph.Neo4j do
  def get_connection do
    config = Application.get_env(:bolt_sips, Bolt)

    # Will create a GenServer if none exist, otherwise will return the existing one
    {:ok, _neo} = Bolt.Sips.start_link(config)

    Bolt.Sips.conn()
  end
end
