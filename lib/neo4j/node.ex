defmodule LightningGraph.Neo4j.Node do
  def update(conn, %{
        pub_key: pub_key,
        alias: node_alias,
        color: color
      }) do
    query = """
    MATCH (n:node {pub_key:"#{pub_key}"})
    SET n += { alias: "#{node_alias}", color: "#{color}" }
    RETURN n;
    """

    Bolt.Sips.query!(conn, query)
  end
end
