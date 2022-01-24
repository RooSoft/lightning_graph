# LightningGraph

Lightning Network graph analysis tool

## Create the graph

* Converts LND's describegraph output
* Imports this converted graph into Neo4j
* Adds info to nodes based on graph analysis

## Query the graph

* Get common peers
* Get community members
* Get farthest nodes
* Get cheapest routes

## How to use

using `config/config.exs`, returning `roosoft`'s node info

```elixir
LightningGraph.Neo4j.get_connection 
|> LightningGraph.Neo4j.Query.get_node_by_alias("roosoft")
```