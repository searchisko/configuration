# Query: Contributor Profiles

**Contributor Profiles** is a query that return data from `contributor_profile` type.
Query can return up to 30 profiles.

## URL parameters

##### `query`

Can be used for full-text search across contributor profiles. It is searching on top
of `sys_contributors` and `sys_title` fields.
If no `query` parameter is provided then all contributor profiles will match.

**Example:**

- <http://dcp_server:port/v2/rest/search/contributor_profiles?query=pete>

##### `contributor`

Is used to pull specific profiles only or to narrow the scope the query will be executed against.
It **MUST match `sys_contributors`** value.
Can be used multiple times.

**Example:**

Get Pete's profile:

- <http://dcp_server:port/v2/rest/search/contributor_profiles?contributor=Pete+Muir+<pmuir%40bleepbleep.org.uk>>

##### `total`

Providing any non-empty value for parameter total will cause the query to return only the total number of accounts matching the query. If the query parameter is empty then total number of contributor profiles is returned (note: This number may vary depending on the roles if access to a particular contributor profile data source is constrained to a particular role owner.).

**Example:**

- <http://dcp_server:port/v2/rest/search/contributor_profiles?total=yes>

##### `aggregate`

Optional parameter which if non-empty switches on aggregation of the returned results. By default it'll collect them in form of monthly buckets. You can change the time interval with parameter documented below.

**Example:**

- <http://dcp_server:port/v2/rest/search/contributor_profiles?aggregate=y>

##### `by_company`

Optional parameter which if non-empty switches on sub-aggregation of the returned results by company. It'll work only if `aggregate` parameter is also specified.

**Example:**

- <http://dcp_server:port/v2/rest/search/contributor_profiles?aggregate=y&by_company=y>

##### `by_country`

Optional parameter which if non-empty switches on sub-aggregation of the returned results by country. It'll work only if `aggregate` parameter is also specified.

**Example:**

- <http://dcp_server:port/v2/rest/search/contributor_profiles?aggregate=y&by_country=y>

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

- <http://dcp_server:port/v2/rest/search/contributor_profiles?aggregate=yes&interval=week>

##### `bucket_key_format`

Optional parameter which specifies format of the key of time breakdown bucket.

Default value: `yyyy-MM`

See spec for more info. [ElasticSearch reference docs](https://www.elastic.co/guide/en/elasticsearch/reference/1.4/search-aggregations-bucket-daterange-aggregation.html#date-format-pattern)

- <http://dcp_server:port/v2/rest/search/contributor_profiles?bucket_key_format=yyyy-MM-dd&interval=day>


##### `date_from`
Optional filter accepting date in a string format. It's also possible to use date intervals with this parameter e.g. 'now-1y' or 'now-7d'.
If present then only contributors having `sys_created >= date_from` are included.

- <http://dcp_server:port/v2/rest/search/contributor_profiles?date_from=2013>
- <http://dcp_server:port/v2/rest/search/contributor_profiles?date_from=2013-01>
- <http://dcp_server:port/v2/rest/search/contributor_profiles?date_from=2013-02-22>
- <http://dcp_server:port/v2/rest/search/contributor_profiles?date_from=2013-02-22T01:02:04.009Z>
- <http://dcp_server:port/v2/rest/search/contributor_profiles?date_from=now-1y>

##### `date_to`
Optional filter accepting date in a string format. It's also possible to use date intervals with this parameter e.g. 'now-1y' or 'now-7d'.
If present then only contributors having `sys_created < date_to` are included.

- <http://dcp_server:port/v2/rest/search/contributor_profiles?date_to=2013>
- <http://dcp_server:port/v2/rest/search/contributor_profiles?date_to=2013-01>
- <http://dcp_server:port/v2/rest/search/contributor_profiles?date_to=2013-02-22>
- <http://dcp_server:port/v2/rest/search/contributor_profiles?date_to=2013-02-22T01:02:04.009Z>
- <http://dcp_server:port/v2/rest/search/contributor_profiles?date_to=now-1y>

##### `timezone_offset`

Optional parameter which can be used together with `aggregate` parameter in order to change timezone used when aggregating results into buckets. The timezone setting defaults to 'America/New_York'. Time zones may either be specified as an ISO 8601 UTC offset (e.g. +01:00 or -08:00) or as a timezone id, an identifier used in the TZ database like America/Los_Angeles.

**Example:**

- <http://dcp_server:port/v2/rest/search/contributor_profiles?aggregate=yes&timezone_offset=America/New_York>

##### `source`

Optional parameter which can be used to limit the results to a particular content type(s).

**Example:**

- <http://dcp_server:port/v2/rest/search/contributor_profiles?source=rht_user_profile>

## Query output format

Matching documents are returned in `hits.hits[]`. Every document contains `fields` section.

## Query implementation details

This chapter discusses implementation details of Elasticsearch query. It should be considered _Expert Only_ chapter.

Unescaped mustache template:

````
{
    {{#total}} "size":  0, {{/total}}
    {{^total}} "size": 30, {{/total}}
    "fields": [ "sys_contributors", "sys_title", "sys_url_view" ],
    "script_fields": {
      "accounts": {
        "script": "(_source.accounts && _source.accounts.length > 0 ) ? _source.accounts[0] : ''"
      }
    },
    "query": {
      "filtered": {
        "filter" : {
          "and": {
            "filters": [
              {{#contributor}}
              {
                "terms": {
                  "sys_contributors": [
                    {{#contributor}}
                    "{{.}}",
                    {{/contributor}}
                    {}
                  ]
                }
              },
              {{/contributor}}
              {{#date_from}}
              {
                "range": {
                  "sys_created": {
                    "gte": "{{date_from}}",
                    "time_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
                  }
                }
              },
              {{/date_from}}
              {{#date_to}}
              {
                "range": {
                  "sys_created": {
                    "lt": "{{date_to}}",
                    "time_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
                  }
                }
              },
              {{/date_to}}
              {}
            ]
          }
        },
        "query": {
          {{#query}}
          "simple_query_string": {
            "fields": ["sys_contributors.fulltext", "sys_title"],
            "query": "{{query}}",
            "default_operator": "and"
          }
          {{/query}}
          {{^query}}
          "match_all": {}
          {{/query}}
        }
      }
    }
    {{#aggregate}}
    ,
    "aggs" : {
      "bucketed" : {
        "date_histogram" : {
          "field" : "{{date_field}}{{^date_field}}sys_created{{/date_field}}",
          "interval" : "{{interval}}{{^interval}}month{{/interval}}",
          "format": "{{bucket_key_format}}{{^bucket_key_format}}yyyy-MM{{/bucket_key_format}}",
          "pre_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
        },
        "aggs" : {
          "by_kpi" : { 
            "filters" : {
              "filters" : {
                "website" :   { "term" : { "regInfo.kpi" : "website"   }},
                "website_from_rh" : { "term" : { "regInfo.kpi" : "website_from_rh" }},
                "infoq" :   { "term" : { "regInfo.kpi" : "infoq"   }},
                "infoq_from_rh" :   { "term" : { "regInfo.kpi" : "infoq_from_rh"   }},
                "dzone" :   { "term" : { "regInfo.kpi" : "dzone"   }},
                "dzone_from_rh" :   { "term" : { "regInfo.kpi" : "dzone_from_rh"   }},
                "conference" :   { "term" : { "regInfo.kpi" : "conference"   }}
              }
            }
          }
          {{#by_country}}
          ,"by_country" : {
              "terms" : { 
                "field" : "country",
                "size" : "0"
              }
          }
          {{/by_country}}
          {{#by_company}}
          ,"by_company" : { 
            "terms" : {
              "field" : "company",
              "size" : "0"
            }
          }
          {{/by_company}}
        }
      }
    }
    {{/aggregate}}
}
````

There are some hacks used to workaround Mustache and ES restrictions.

- To get `accounts` data we are using `script_fields` (see [#232](https://github.com/searchisko/searchisko/issues/232)).

- Since `contributors` param is an array there is no easy way how to conditionally include the
  filter for it and populate the array at the same time. Current mustache template repeat complete
  whole filter as many times as there are items in the `contributor` array. Fortunately it seems
  it is not harming ES (but this can be sensitive to changes in ES query parser in the future).
  
- Items in the `contributor` array are delimited by comma. To eliminate parser error we include
  empty object after the last item in the array. This trick seems to work fine for ES parser now.