class Graph::WasInvalidatedBy
  include Neo4j::ActiveRel

  from_class 'Graph::FileVersion'
  to_class 'Graph::Activity'
  type 'WasInvalidatedBy'
end