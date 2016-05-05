# Query: Developer Materials

**Developer materials** query is designed for the needs of developer materials finder web page
and it is used to search and filter developer related documents.

It is restricted to search on top of the following `sys_type`s:

 - quickstart
 - video
 - demo
 - jbossdeveloper_example
 - jbossdeveloper_archetype
 - jbossdeveloper_bom
 - solution
 - article

In addition to matching documents it also provides two aggregations around "format" which is basically
[terms aggregation] of `sys_type` field. The tricky part is that one specific `sys_type` category
is split into two _arbitrary_ categories depending on `experimental` field value.

[terms aggregation]: http://www.elasticsearch.org/guide/en/elasticsearch/reference/1.4/search-aggregations-bucket-terms-aggregation.html

More specifically documents having `sys_type: quickstart` belong to
either `quickstart` or `quickstart_early_access` category.
If the document has `experimental: true` then it belongs to the `quickstart_early_access`
otherwise it belongs to `quickstart`.

The following text consists of three parts:

- description of URL parameters accepted by this registered query
- explanation of query output
- expert explanation of the query itself

## URL parameters

##### `query`
Optional simple query string free text. Example: `query=java+tutorial`.

- <http://dcp_server:port/v2/rest/search/developer_materials?query=java+tutorial>

##### `from`
Optional number of document that will be the first in the hits section. Default value is `0`. This is useful for pagination.
The query returns up to 9 matching documents only. This means that second page should use `9`, third page `18`.

- <http://dcp_server:port/v2/rest/search/developer_materials?from=9>

##### `size`

Optional parameter determining number of documents returned in response. Giving public clients option to directly
specify `size` can be dangerous (imagine clients asking for very high number of records). Usually, it is enough
to give clients an option to select from a limited set of predefined sizes. In this case client can select from
one of the following options [`10`, `15`, `20`, `25`]. To select one option client passes one of the following
parameters with non-null value:

* `size10` = 10 documents (default)
* `size15` = 15 documents
* `size20` = 20 documents
* `size25` = 25 documents

For example:

- <http://dcp_server:port/v2/rest/search/developer_materials?size10=true>

If multiple options are used then the highest number wins. For example the following request
will return `20` documents (or less if there are not enough matching documents).

- <http://dcp_server:port/v2/rest/search/developer_materials?size10=true&size20=true&size15=true>

##### `level`
Optional filter accepting a string value. URL parameter value MUST be lowercased.
Example values: `beginner`, `intermediate` or `advanced`.

- <http://dcp_server:port/v2/rest/search/developer_materials?level=advanced>

##### `tag`
Optional filter accepting a string value for `sys_tags` value (called "topic" on the UI page).
Can be used multiple times. URL parameter value MUST be lowercased.

- <http://dcp_server:port/v2/rest/search/developer_materials?tag=camel&tag=rest>

##### `publish_date`
Optional filter accepting date in a string format.
If present then only documents having `sys_created >= publish_date` are included.

- <http://dcp_server:port/v2/rest/search/developer_materials?publish_date=2013>
- <http://dcp_server:port/v2/rest/search/developer_materials?publish_date=2013-01>
- <http://dcp_server:port/v2/rest/search/developer_materials?publish_date=2013-02-22>

##### `activity_date_from`
Optional filter accepting date in ISO timestamp format.
Filters out documents that do not have any date in `sys_activity_dates`
 array **greater or equal** to given value, i.e. there hasn't been any
 activity recorded for such document after this date.

- <http://dcp_server:port/v2/rest/search/developer_materials?activity_date_from=2010-12-06T06:34:55.000Z>

##### `activity_date_to`
Optional filter accepting date in ISO timestamp format.
Filters out documents that do not have any date in `sys_activity_dates`
 array **lower or equal** to given value, i.e. there hasn't been any
 activity recorded for such document prior to this date.
 
- <http://dcp_server:port/v2/rest/search/developer_materials?activity_date_to=2010-12-06T06:34:55.000Z>

##### `rating`
Optional filter accepting a number value. URL parameter value MUST be a number.

- <http://dcp_server:port/v2/rest/search/developer_materials?rating=1>

##### `sys_type`
Optional filter used for `sys_type` value (called "format" on the UI page).
In order to distinguish between **quickstarts** and **early access** materials new _virtual_ `sys_type` value
called `quickstart_early_access` has been modelled.

- <http://dcp_server:port/v2/rest/search/developer_materials?sys_type=quickstart_early_access>
- <http://dcp_server:port/v2/rest/search/developer_materials?sys_type=quickstart>
- <http://dcp_server:port/v2/rest/search/developer_materials?sys_type=video&sys_type=book>

Technically speaking, the `sys_type` value in returned documents is `quickstart` all the time.
The new (virtual) category appears **only** in aggregations output and can be used as `sys_type` filter input.
All needed conversions are handled inside the query at execution time.

Pseudo-code of `sys_type` processing is as follows:

    if (sys_type == 'quickstart' && experimental != undefined && experimental != null && experimental === true) {
      'quickstart_early_access'
    } else
    if (sys_type == 'quickstart') {
      'quickstart'
    }
    else { sys_type is used }

_See "Query implementation details" for further details._

##### `project`
Optional lowercased code of project. This can be used for **product** material finder.

- <http://dcp_server:port/v2/rest/search/developer_materials?project=eap&project=portal>

##### `randomized`

Passing in `randomized` parameter with non-null value orders resulting documents in random fashion
(i.e. not by Lucene scoring function).

- <http://dcp_server:port/v2/rest/search/developer_materials?randomized=true>

##### `seed`

If `randomized` results are used then `seed` parameter can be passed to get
[consistent random results](https://www.elastic.co/guide/en/elasticsearch/guide/current/random-scoring.html).
If not passed then the `default` value is used by default.

- <http://dcp_server:port/v2/rest/search/developer_materials?randomized=true&seed=cb1702a54386ad4a>

##### `newFirst`

Optional flag to order resulting documents by `sys_created` date (descending).

- <http://dcp_server:port/v2/rest/search/developer_materials?query=java&newFirst=true>

##### `oldFirst`

Optional flag to order resulting documents by `sys_created` date (ascending).

- <http://dcp_server:port/v2/rest/search/developer_materials?query=java&oldFirst=true>

## Query output format

The query has hardcoded list of fields that are returned:

    "fields": [
      "contributors",
      "duration",
      "experimental",
      "github_repo_url",
      "level",
      "sys_author",
      "sys_contributors",
      "sys_created",
      "sys_description",
      "sys_rating_avg",
      "sys_rating_num",
      "sys_title",
      "sys_type",
      "sys_url_view",
      "thumbnail",
      "sys_tags",
      "target_product"
    ]

Additionally returned data contains slice of **matching documents**, **total number** of matching documents
and **two aggregation sections**.

1. `hits.hits[]` contains up to 9 documents (you can paginate through them using `from` URL parameter)

2. `hits.total` contains total number of matching documents

3. `aggregations.format.count_without_filters.format_counts.buckets[]` contains total counts for all **AVAILABLE**
"formats" (note we have separation between `quickstart` and `quickstart_early_access` formats).
Counts do not reflect any selected filters, it is always total count of documents in this category. Technically speaking,
this aggregation can be used to get a list of all available formats in the data.

4. `aggregations.format.count_with_filters.format_counts.buckets[]` contains counts for all **RELEVANT** "formats"
(relevant to query and filters). If there are no matching documents for format then such format is missing here
(so you can use list from above aggregation to produce complete list of formats assigning missing formats a zero count).

## Query implementation details

This chapter discusses implementation details of Elasticsearch query. It should be considered _Expert Only_ chapter.

This query uses a lot of conditional clauses. This means the query itself has to be provided as single encoded string
(see [search template] docs) which makes it hard for reading and editing. Because of this the following part describes structure of query internals.

[search template]: http://www.elasticsearch.org/guide/en/elasticsearch/reference/1.4/search-template.html

The following is the query with all the optional filters applied:

    {
      "from": {{#from}}{{from}}{{/from}}{{^from}}0{{/from}},
      "size": 10,
      {{#size15}}"size": 15,{{/size15}}
      {{#size20}}"size": 20,{{/size20}}
      {{#size25}}"size": 25,{{/size25}}
      "fields": [
        "contributors", "duration", "experimental", "github_repo_url", "level", "sys_author", "sys_contributors",
        "sys_created", "sys_description", "sys_rating_avg", "sys_rating_num", "sys_title", "sys_type",
        "sys_url_view", "thumbnail", "sys_tags", "target_product"
      ],
      {{#randomized}}
      "query": {
        "function_score": {
      {{/randomized}}
          "query": {
            "filtered": {
              {{#query}}
              "query": {
                "simple_query_string": {
                  "query": "{{query}}",
                  "fields": [
                    "sys_description", "sys_tags^1.5", "sys_contributors.fulltext", "sys_project_name^2.0","sys_title^2.5"
                  ]
                }
              },
              {{/query}}
              "filter": {
                "and": {
                  "filters": [
                    {{#level}}
                    {
                      "term": {
                        "level": "{{level}}"
                      }
                    },
                    {{/level}}
                    {{#tag}}
                    {
                      "term": {
                        "sys_tags": ["{{.}}"]
                      }
                    },
                    {{/tag}}
                    {{#publish_date}}
                    {
                      "range": {
                        "sys_created": {
                          "gte": "{{publish_date}}"
                        }
                      }
                    },
                    {{/publish_date}}
                    {{#activity_date_from}}
                    {
                      "range": {
                        "sys_activity_dates": {
                          "gte": "{{activity_date_from}}"
                        }
                      }
                    },
                    {{/activity_date_from}}
                    {{#activity_date_to}}
                    {
                      "range": {
                        "sys_activity_dates": {
                          "lte": "{{activity_date_to}}"
                        }
                      }
                    },
                    {{/activity_date_to}}
                    {{#rating}}
                    {
                      "range": {
                        "sys_rating_avg": {
                          "gte": "{{rating}}"
                        }
                      }
                    },
                    {{/rating}}
                    {
                      "or": [
                        {{#sys_type}}
                        {
                          "script": {
                            "script": "(format_selection == 'quickstart_early_access' && _source.sys_type == 'quickstart' && _source.experimental != undefined && _source.experimental != null && _source.experimental === true) || (format_selection == 'quickstart' && _source.sys_type == format_selection && _source.experimental !== true) || (format_selection != 'quickstart' && format_selection != 'quickstart_early_access' && _source.sys_type == format_selection)",
                            "params": {
                              "format_selection": "{{.}}",
                              "lang": "js"
                            }
                          }
                        },
                        {{/sys_type}}
                        {}
                      ]
                    },
                    {
                      "or": [
                        {{#project}}
                        {
                            "term": { "sys_project": "{{.}}" }
                        },
                        {{/project}}
                        {}
                      ]
                    },
                    {
                      "terms": {
                        "sys_content_provider": [
                          "jboss-developer", "rht"
                        ]
                      }
                    }
                  ]
                }
              }
            }
          }
      {{#randomized}}
          ,"functions": [
            {
              "random_score": { "seed": "{{#seed}}{{seed}}{{/seed}}{{^seed}}default{{/seed}}" }
            }
          ]
        }
      }
      {{/randomized}}
      {{^randomized}}
      ,"sort": [
        {{#newFirst}} { "sys_created": "desc" }, {{/newFirst}}
        {{#oldFirst}} { "sys_created": "asc" }, {{/oldFirst}}
        "_score"
      ]
      {{/randomized}}
      ,
      "aggregations": {
        "format": {
          "global": {},
          "aggregations": {
            "count_with_filters": {
              "filter": {
                "and": {
                  "filters": [
                    {{#query}}
                    {
                      "query": {
                        "simple_query_string": {
                          "query": "{{query}}",
                          "fields": [
                            "sys_description", "sys_tags^1.5", "sys_contributors.fulltext", "sys_project_name^2.0", "sys_title^2.5"
                          ]
                        }
                      }
                    },
                    {{/query}}
                    {{#level}}
                    {
                      "term": { "level": "{{level}}" }
                    },
                    {{/level}}
                    {{#tag}}
                    {
                      "term": { "sys_tags": ["{{.}}"] }
                    },
                    {{/tag}}
                    {{#publish_date}}
                    {
                      "range": {
                        "sys_created": { "gte": "{{publish_date}}" }
                      }
                    },
                    {{/publish_date}}
                    {{#activity_date_from}}
                    {
                      "range": {
                        "sys_activity_dates": {
                          "gte": "{{activity_date_from}}"
                        }
                      }
                    },
                    {{/activity_date_from}}
                    {{#activity_date_to}}
                    {
                      "range": {
                        "sys_activity_dates": {
                          "lte": "{{activity_date_to}}"
                        }
                      }
                    },
                    {{/activity_date_to}}
                    {{#rating}}
                    {
                      "range": {
                        "sys_rating_avg": { "gte": "{{rating}}"}
                      }
                    },
                    {{/rating}}
                    {
                      "or": [
                        {{#sys_type}}
                        {
                          "script": {
                            "script": "(format_selection == 'quickstart_early_access' && _source.sys_type == 'quickstart' && _source.experimental != undefined && _source.experimental != null && _source.experimental === true) || (format_selection == 'quickstart' && _source.sys_type == format_selection && _source.experimental !== true) || (format_selection != 'quickstart' && format_selection != 'quickstart_early_access' && _source.sys_type == format_selection)",
                            "params": {
                              "format_selection": "{{.}}",
                              "lang": "js"
                            }
                          }
                        },
                        {{/sys_type}}
                        {}
                      ]
                    },
                    {
                      "or": [
                        {{#project}}
                        {
                          "term": { "sys_project": "{{.}}" }
                        },
                        {{/project}}
                        {}
                      ]
                    },
                    {
                      "terms": {
                        "sys_content_provider": [
                          "jboss-developer", "rht"
                        ]
                      }
                    }
                  ]
                }
              },
              "aggregations": {
                "format_counts": {
                  "terms": {
                    "script": "_source.sys_type == 'quickstart' ? ( _source.experimental != undefined && _source.experimental != null && _source.experimental === true ? _source.sys_type + '_early_access' : _source.sys_type ) : _source.sys_type",
                    "lang": "js",
                    "size": 100
                  }
                }
              }
            },
            "count_without_filters": {
              "filter": {
                "and": {
                  "filters": [
                    {
                      "terms": {
                        "sys_content_provider": [
                          "jboss-developer", "rht"
                        ]
                      }
                    }
                  ]
                }
              },
              "aggregations": {
                "format_counts": {
                  "terms": {
                    "script": "_source.sys_type == 'quickstart' ? ( _source.experimental != undefined && _source.experimental != null && _source.experimental === true ? _source.sys_type + '_early_access' : _source.sys_type ) : _source.sys_type",
                    "lang": "js",
                    "size": 100
                  }
                }
              }
            }
          }
        }
      }
    }