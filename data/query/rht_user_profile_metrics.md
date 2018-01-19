# Query: RHT User profile metrics

**rht_user_profile_metrics** is a query providing metrics over rht_user_profile data.

## URL parameters

##### `website`

Required parameter which defines for which website metrics should be applied
Possible values:

* rhd (default)
* openShiftOnlineFree
* openShiftOnlinePro
* openShiftIo

**Example:**

- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd>

##### `interval`

Optional parameter in order to change time interval in which the results are aggreagated into buckets. The possible values are:

* second
* minute
* hour
* day
* week
* month (default)
* quarter
* year

**Example:**

- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&interval=week>

##### `bucket_key_format`

Optional parameter which specifies format of the key of time breakdown bucket.

Default value: `yyyy-MM`

See spec for more info. [ElasticSearch reference docs](https://www.elastic.co/guide/en/elasticsearch/reference/1.4/search-aggregations-bucket-daterange-aggregation.html#date-format-pattern)

- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&bucket_key_format=yyyy-MM-dd&interval=day>


##### `date_from`
Optional filter accepting date in a string format. It's also possible to use date intervals with this parameter e.g. 'now-1y' or 'now-7d'.
If present then only contributors having `sys_created >= date_from` are included.

- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&date_from=2013>
- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&date_from=2013-01>
- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&date_from=2013-02-22>
- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&date_from=2013-02-22T01:02:04.009Z>
- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&date_from=now-1y>

##### `date_to`
Optional filter accepting date in a string format. It's also possible to use date intervals with this parameter e.g. 'now-1y' or 'now-7d'.
If present then only contributors having `sys_created < date_to` are included.

- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&date_to=2013>
- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&date_to=2013-01>
- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&date_to=2013-02-22>
- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&date_to=2013-02-22T01:02:04.009Z>
- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&date_to=now-1y>

##### `timezone_offset`

Optional parameter which can be used in order to change timezone used when aggregating results into buckets. The timezone setting defaults to 'America/New_York'. Time zones may either be specified as an ISO 8601 UTC offset (e.g. +01:00 or -08:00) or as a timezone id, an identifier used in the TZ database like America/Los_Angeles.

**Example:**

- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&timezone_offset=America/New_York>



## Query output format

Query returns just aggregations and no data in `hits.hits[]` field

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
                        "match_all" : { } 
                    }
                    {{#date_from}}
                    , {
                        "range": {
                            "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessTimestamp": {
                                "gte": "{{date_from}}",
                                "time_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
                            }
                        }
                    }
                    {{/date_from}}
                    {{#date_to}}
                    , {
                        "range": {
                            "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessTimestamp": {
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
        "user_account_type_agg" : {
            "terms" : { "field" : "userAccountType" }
        },
        "social_links_count_agg" : {
            "terms" : { "field" : "numOfSocialLinks" }
        },
        "social_links_types_agg" : {
            "terms" : { "field" : "accounts.domain" }
        },
        "first_access_agg": {
            "date_histogram": {
                "field": "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessTimestamp",
                "order": { "_key": "asc" },
                "interval" : "{{interval}}{{^interval}}month{{/interval}}",
                "format": "{{bucket_key_format}}{{^bucket_key_format}}yyyy-MM{{/bucket_key_format}}",
                "pre_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
            }
            ,"aggs" : {
              "by_channel" : { 
                "filters" : {
                  "filters" : {
                    "website" : { 
                        "and": [ 
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "website"   } },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : false } }
                        ]
                    },
                    "website_from_rh" : {
                        "and": [
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "website" } },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : true } }
                        ]
                    },
                    "website_from_rhd" : {
                        "and": [
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "website" } },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : true } },
                            { "script" : { "script" : "(_source.regInfo.rhd != null && !_source.regInfo.rhd.firstAccessTimestamp.empty) ? _source.regInfo.rhd.firstAccessTimestamp < _source.regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessTimestamp : 1<0" } }
                        ]
                    },
                    "infoq" :   {
                        "and": [
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "infoq"   } },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : false } }
                        ]
                    },
                    "infoq_from_rh" :   {
                        "and": [
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "infoq"   } },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : true } }
                        ]
                    },
                    "dzone" :   {
                        "and": [
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "dzone" } },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : false } }
                        ]
                    },
                    "dzone_from_rh" :   {
                        "and": [
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "dzone" } },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : true } }
                        ]
                    },
                    "conference" :   {
                        "and": [
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "conference"   } },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : false } }
                        ]
                    },
                    "conference_from_rh" :   {
                        "and": [
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "conference"   } },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : true } }
                        ]
                    }
                  }
                }
              }
            }
        }
    }
}
````
