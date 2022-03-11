defmodule LightningGraph.Neo4j.Lnd.Mutations.Node do
  def update(conn, node_update) do
    query =
      """
      MATCH (n:node {pub_key:"#{node_update.identity_key}"})
      SET n += { alias: "#{node_update.alias}", color: "#{node_update.color}" }
      RETURN n;
      """
      |> IO.inspect()

    Bolt.Sips.query!(conn, query)
  end
end
