search = ->
  queryString = @request.body.query || ""
  options = @request.body.options || {size: 10}
  result = HTTP.post(
    "http://localhost:9200/item_index/_search", {
      data: queryString
      params: options
    }
  )
  if result?.content
    content = JSON.parse(result.content)
    gridEvents = ({
      score: hit._score
      id: hit._source.eidID
      name: hit._source.eventName
    } for hit in content.hits.hits)
    @response.end(JSON.stringify(
      results: gridEvents
      total: content.hits.total
      aggregations: content.aggregations
    ))
  else
    @response.end(JSON.stringify([]))

Router.route "/search", search,
  where: 'server'
