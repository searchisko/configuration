# Query: stackoverflow metrics

**stackoverflow_metrics** is a query providing metrics over stackoverflow data.

## URL parameters

##### `tag`

Optional parameter. Can be used multiple times.
If provided then the query is restricted to documents having field `sys_tags` equal to one of provided values.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?tag=java>

##### `interval`

Optional parameter which can be used together with `aggregate` parameter in order to change time interval in which the results are aggreagated into buckets. The possible values are:

* second
* minute
* hour
* day
* week
* month (default)
* quarter
* year

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?interval=week>

##### `bucket_key_format`

Optional parameter which specifies format of the key of time breakdown bucket.

Default value: `yyyy-MM`

See spec for more info. [ElasticSearch reference docs](https://www.elastic.co/guide/en/elasticsearch/reference/1.4/search-aggregations-bucket-daterange-aggregation.html#date-format-pattern)

- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?bucket_key_format=yyyy-MM-dd&interval=day>


##### `date_from`
Optional filter accepting date in a string format. It's also possible to use date intervals with this parameter e.g. 'now-1y' or 'now-7d'.
If present then only contributors having `sys_created >= date_from` are included.

- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?date_from=2013>
- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?date_from=2013-01>
- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?date_from=2013-02-22>
- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?date_from=2013-02-22T01:02:04.009Z>
- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?date_from=now-1y>

##### `date_to`
Optional filter accepting date in a string format. It's also possible to use date intervals with this parameter e.g. 'now-1y' or 'now-7d'.
If present then only contributors having `sys_created < date_to` are included.

- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?date_to=2013>
- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?date_to=2013-01>
- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?date_to=2013-02-22>
- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?date_to=2013-02-22T01:02:04.009Z>
- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?date_to=now-1y>

##### `timezone_offset`

Optional parameter which can be used in order to change timezone used when aggregating results into buckets. The timezone setting defaults to 'America/New_York'. Time zones may either be specified as an ISO 8601 UTC offset (e.g. +01:00 or -08:00) or as a timezone id, an identifier used in the TZ database like America/Los_Angeles.

**Example:**

- <http://dcp_server:port/v2/rest/search/stackoverflow_metrics?timezone_offset=America/New_York>




## Query output format

Matching documents are returned in `hits.hits[]`. Every document contains `fields` section with returned data.

## Query implementation details

This chapter discusses implementation details of Elasticsearch query. It should be considered _Expert Only_ chapter.

Unescaped mustache template:

````
{
    "size":  0,
    "query": {
        "filtered": {
            "filter": {
                "and": [
                    {
                        "or": [
                            {{#tag}}
                            { "term": { "sys_tags": "{{.}}" }},
                            {{/tag}}
                            {}
                        ]
                    }
                    {{#date_from}}
                    ,{
                        "range": {
                            "sys_created": {
                                "gte": "{{date_from}}",
                                "time_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
                            }
                        }
                    }
                    {{/date_from}}
                    {{#date_to}}
                    ,{
                        "range": {
                            "sys_created": {
                                "lt": "{{date_to}}",
                                "time_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
                            }
                        }
                    }
                    {{/date_to}}
                ]
            }
        }
    },
    "aggs": {
        "time_agg": {
            "date_histogram": {
                "field": "sys_created",
                "order": { "_key": "asc" },
                "interval" : "{{interval}}{{^interval}}month{{/interval}}",
                "format": "{{bucket_key_format}}{{^bucket_key_format}}yyyy-MM{{/bucket_key_format}}",
                "pre_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
            },
            "aggs": {
                "answered": {
                    "filter" : { "range" : { "answer_count" : { "gt" : 0 } } }
                },
                "correct_answer": {
                    "filter" : { "term" : { "is_answered" : "true"} }
                }, 
                "view_count": {
                    "stats" : { "field" : "view_count" }
                }
            }
        }
    }
}
````
