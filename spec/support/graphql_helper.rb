module GraphqlHelper
  def graphql_query(query:, variables: {}, context: {})
    TddSchema.execute(query, variables: variables, context: context)
  end
end
