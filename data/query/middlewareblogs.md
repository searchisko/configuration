# Query: middlewareblogs

**middlewareblogs** is a query that can list the most recent middleware blogs. Middleware blogs
are such blogs that does not have tag value equal to `"feed_group_name_nonmiddleware"`.
It is possible to filter returned data (see below for details).

## URL parameters

##### `size`

Optional number of documents returned. If no `size` parameter is provided then value of `10` is used.

**Example:**

- <http://dcp_server:port/v2/rest/search/middlewareblogs?size=20>

##### `from`

Optional position of the first document returned. If no `from` parameter is provided then value of `0` is used.

**Example:**

- <http://dcp_server:port/v2/rest/search/middlewareblogs?from=5>

##### `query`

Optional parameter. Use query applied against the following fields:

- "sys_title^2.5",
- "sys_description",
- "sys_content_plaintext",
- "_all",
- "sys_project_name^0.5",
- "sys_tags^0.5",
- "sys_contributors.fulltext",
- "comment_body"

If no `query` parameter is provided then all middleware blog documents will match.

**Example:**

- <http://dcp_server:port/v2/rest/search/middlewareblogs?query=co>

##### `project`

Optional parameter. Can be used multiple times.
If provided then the query is restricted to documents having field `sys_project` equal to one of provided values.

**Example:**

- <http://dcp_server:port/v2/rest/search/middlewareblogs?project=seam&project=jopr>

##### `tag`

Optional parameter. Can be used multiple times.
If provided then the query is restricted to documents having field `sys_tags` equal to one of provided values.

**Example:**

- <http://dcp_server:port/v2/rest/search/middlewareblogs?tag=fedora&tag=red+hat>

##### `aggs`

Optional parameter. If provided and has not null value then the output includes two terms aggregations on top
of the fields `sys_project` and `sys_tags`.

**Example:**

- <http://dcp_server:port/v2/rest/search/middlewareblogs?aggs=1>

## Query output format

Matching documents are returned in `hits.hits[]`. Every document contains `fields` section with returned data.

## Query implementation details

This chapter discusses implementation details of Elasticsearch query. It should be considered _Expert Only_ chapter.

Unescaped mustache template:

      {
        "fields": [
          "sys_url_view",
          "sys_title",
          "sys_contributors",
          "sys_description",
          "sys_created",
          "author",
          "sys_project",
          "sys_tags",
          "tags",
          "sys_content_id",
          "sys_content",
          "avatar_link"
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
                  "sys_title^2.5",
                  "sys_description",
                  "sys_content_plaintext",
                  "_all",
                  "sys_project_name^0.5",
                  "sys_tags^0.5",
                  "sys_contributors.fulltext",
                  "comment_body"
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
                  "not": {
                    "terms": {
                      "sys_tags": ["feed_group_name_nonmiddleware"]
                    }
                  }
                },{
                  "or": [
                    {{#project}}
                    { "term": { "sys_project": "{{.}}" }},
                    {{/project}}
                    {}
                  ]
                },{
                "or": [
                    {{#tag}}
                    { "term": { "sys_tags": "{{.}}" }},
                    {{/tag}}
                    {}
                  ]
                }
              ]
            }
          }
        },
        "sort": [
          { "sys_created": "desc" },
          "_score"
        ]
        {{#aggs}},
        "aggs": {
          "sys_project": {
            "terms": {
              "field": "sys_project"
            }
          },
          "sys_tags": {
            "terms": {
              "field": "sys_tags"
            }
          }
        }
       {{/aggs}}
      }