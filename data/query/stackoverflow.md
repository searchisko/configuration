# Query: stackoverflow

**stackoverflow** is a query that can list stackoverflow information. 

## URL parameters

##### `size`

Optional number of documents returned. If no `size` parameter is provided then value of `10` is used.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow?size=20>

##### `from`

Optional position of the first document returned. If no `from` parameter is provided then value of `0` is used.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow?from=5>

##### `query`

Optional parameter. Use query applied against the following fields:

- "sys_type",
- "sys_created",

If no `query` parameter is provided then all middleware blog documents will match.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow?query=co>

##### `content`

Optional parameter. Can be used multiple times.
If provided then the query is restricted to documents having field `sys_content_type` equal to one of provided values.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow?sys_content_type=stackoverflow_question>

##### `tag`

Optional parameter. Can be used multiple times.
If provided then the query is restricted to documents having field `sys_tags` equal to one of provided values.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow?tag=docker>

##### `questionid`

Optional parameter. Can be used multiple times.
If provided then the query is restricted to documents having field `sys_id` equal to one of provided values.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow?questionid=12345>

##### `userid`

Optional parameter. Can be used multiple times.
If provided then the query is restricted to documents having field `user_id` equal to one of provided values.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow?userid=12345>

##### `accepted`

Optional parameter. Can be used multiple times.
If provided then the query is restricted to documents having field `is_answered` equal to one of provided values.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow?accepted=true>

##### `accepted_answer`

Optional parameter. Can be used multiple times.
If provided then the query is restricted to documents having field `accepted_answer` equal to one of provided values.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow?accepted_answer=12345>

##### `aggs`

Optional parameter. If provided and has not null value then the output includes two terms aggregations on top
of the fields `sys_project` and `sys_tags`.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow?aggs=1>

## Query output format

Matching documents are returned in `hits.hits[]`. Every document contains `fields` section with returned data.

## Query implementation details

This chapter discusses implementation details of Elasticsearch query. It should be considered _Expert Only_ chapter.

Unescaped mustache template:

{
    "fields": [
      "_source"
    ],
    "from": {{#from}}{{from}}{{/from}}{{^from}}0{{/from}},
    "size": {{#size}}{{size}}{{/size}}{{^size}}10{{/size}},
    "query": {
      "filtered": {
        "query": {
          {{#query}}
          "multi_match": {
            "query": "{{query}}",
            "fields": [
              "sys_type",
              "sys_created"

            ]
          }
          {{/query}}
          {{^query}}
          "match_all": {}
          {{/query}}
        },
        "filter": {
          "and": [
            {
              "or": [
                {{#content}}
                { "term": { "sys_content_type": "{{.}}" }},
                {{/content}}
                {}
              ]
            },{
            "or": [
                {{#tag}}
                { "term": { "sys_tags": "{{.}}" }},
                {{/tag}}
                {}
              ]
            },{
            "or": [
{{#questionid}}
{ "term": { "sys_id": "{{.}}" }},
{{/questionid}}
{}
]
},{
            "or": [
{{#userid}}
{ "term": { "user_id": "{{.}}" }},
{{/userid}}
{}
]
},{
            "or": [
{{#accepted}}
{ "term": { "is_answered": "{{.}}" }},
{{/accepted}}
{}
]
},{
            "or": [
{{#accepted_answer}}
{ "term": { "accepted_answer": "{{.}}" }},
{{/accepted_answer}}
{}
]
}
          ]
        }
      }
    },
    "sort": [
      { "sys_created": "desc" },
      {{#viewcount}} { "_source.viewcount": "desc" }, {{/viewcount}}
      {{#lastactivity}} { "last_activity": "desc" }, {{/lastactivity}}

      "_score"
    ]
    {{#aggs}},
    "aggs": {
      "sys_content_type": {
        "terms": {
          "field": "sys_content_type"
        }
      },
      "sys_tags": {
        "terms": {
          "field": "sys_tags"
        }
      },
"accepted_answer": {
"terms": {
"field": "accepted_answer"
}
}
    }
   {{/aggs}}


}
