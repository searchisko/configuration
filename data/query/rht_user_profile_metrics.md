# Query: RHT User profile metrics

**rht_user_profile_metrics** is a query providing metrics over rht_user_profile data.

## URL parameters

##### `website`

Required parameter which defines for which website metric `first_access_agg` should be applied
Possible values:

* rhd (default)
* openShiftOnlineFree
* openShiftOnlinePro
* openShiftIo
* jbossorg

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

##### `country_agg`

Optional parameter. If present with any value then aggregations "by country" are added into output of the query (they slow down the query a bit).

**Example:**

- <http://dcp_server:port/v2/rest/search/rht_user_profile_metrics?website=rhd&date_to=2018&country_agg=true>

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
        {{#country_agg}}  
        "country_agg" : {
            "terms" : { "field" : "country", "size": 0 }
        },
        {{/country_agg}}  
        "social_links_types_agg" : {
            "terms" : { 
                "field" : "accounts.domain",
                "exclude" : "redhat.com"
            }
        },
        "subscription_agg" : {
            "filters" : {
              "filters" : {
                "no_subscription" : {
                  "term" : { "subscription.valid" : false   }
                },
                "subscription_valid" : {
                    "and": [
                        { "term" : { "subscription.valid" : true   } },
                        { "range" : { "subscription.signDate" : { "lt": "now" } } },
                        { "range" : { "subscription.expirationDate" : { "gt": "now" } } }
                    ]
                },
                "subscription_expired" : {
                    "and": [
                        { "term" : { "subscription.valid" : true   } },
                        { "range" : { "subscription.signDate" : { "lt": "now" } } },
                        { "range" : { "subscription.expirationDate" : { "lt": "now" } } }
                    ]
                }
              }
            }
        },
        "rhd_members" : {
            "filter" : { "exists" : { "field" : "regInfo.rhd" } }
            ,"aggs" : {
                "rhdmin": {
                    "filter" : {
                        "and": [ 
                            { "term" : { "ppLevels.rhdmin" : true } },
                            { "missing" : { "field" : "ppLevels.rhdfull" } }
                        ]
                    }
                },
                "rhdfull": {
                    "filter" : { "term" : { "ppLevels.rhdfull" : true } }
                },
                "no_valid_level": {
                    "filter" : {
                        "and": [ 
                            { "missing" : { "field" : "ppLevels.rhdmin" } }
                        ]
                    }
                }
            }
        },
        "first_access_agg": {
            "date_histogram": {
                "field": "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessTimestamp",
                "order": { "_key": "asc" },
                "interval" : "{{interval}}{{^interval}}month{{/interval}}",
                "format": "{{bucket_key_format}}{{^bucket_key_format}}yyyy-MM{{/bucket_key_format}}",
                "pre_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
            },
            "aggs" : {
              {{#country_agg}}
              "by_country" : {
                    "terms" : { "field" : "country", "size": 0 }
              },
              {{/country_agg}}
              "by_email_verified" : {
                "filters" : {
                  "filters" : {
                    "verified" : {
                      "term" : { "emailVerified" : true }
                    },
                    "not_verified" : {
                      "or": [
                        { "term" : { "emailVerified" : false }},
                        { "missing" : { "field" : "emailVerified" }}
                      ]
                    }
                  }
                }
              },
              "by_channel" : { 
                "filters" : {
                  "filters" : {
                    "website" : { 
                        "and": [
                            { "or": [
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "website"   } },
                                { "missing" : { "field" : "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal" } },
                                { "not": { "terms": { "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal": ["7016000000122iAAAQ", "7016000000122iKAAQ", "701f2000000tjnwAAA", "701f2000000RieJAAS"] }}}
                            ] },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : false } }
                        ]
                    },
                    "website_from_rh" : {
                        "and": [
                            { "or": [
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "website" } },
                                { "missing" : { "field" : "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal" } },
                                { "not": { "terms": { "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal": ["7016000000122iAAAQ", "7016000000122iKAAQ", "701f2000000tjnwAAA", "701f2000000RieJAAS"] }}}
                            ] },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : true } }
                        ]
                    },
                    "website_from_rhd" : {
                        "and": [
                            { "or": [
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "website" } },
                                { "missing" : { "field" : "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal" } },
                                { "not": { "terms": { "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal": ["7016000000122iAAAQ", "7016000000122iKAAQ", "701f2000000tjnwAAA", "701f2000000RieJAAS"] }}}
                            ] },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : true } },
                            { "script" : { "script" : "(_source.regInfo.rhd != null && !_source.regInfo.rhd.firstAccessTimestamp.empty) ? _source.regInfo.rhd.firstAccessTimestamp < _source.regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessTimestamp : 1<0" } }
                        ]
                    },
                    "infoq" :   {
                        "and": [
                            { "or": [
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "infoq"   } },
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal" : "7016000000122iAAAQ"   } }
                            ] },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : false } }
                        ]
                    },
                    "infoq_from_rh" :   {
                        "and": [
                            { "or": [
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "infoq"   } },
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal" : "7016000000122iAAAQ" } }
                            ] },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : true } }
                        ]
                    },
                    "dzone" :   {
                        "and": [
                            { "or": [
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "dzone"   } },
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal" : "7016000000122iKAAQ" } }
                            ] },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "dzone" } },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : false } }
                        ]
                    },
                    "dzone_from_rh" :   {
                        "and": [
                            { "or": [
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "dzone"   } },
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal" : "7016000000122iKAAQ" } }
                            ] },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : true } }
                        ]
                    },
                    "conference" :   {
                        "and": [
                            { "or": [
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "conference"   } },
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal" : "701f2000000tjnwAAA" } }
                            ] },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : false } }
                        ]
                    },
                    "conference_from_rh" :   {
                        "and": [
                            { "or": [
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "conference"   } },
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal" : "701f2000000tjnwAAA" } }
                            ] },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : true } }
                        ]
                    },
                    "bulkinvite" :   {
                        "and": [
                            { "or": [
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "bulkinvite"   } },
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal" : "701f2000000RieJAAS" } }
                            ] },
                            { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.firstAccessByExistingAccount" : false } }
                        ]
                    },
                    "bulkinvite_from_rh" :   {
                        "and": [
                            { "or": [
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.channel" : "bulkinvite"   } },
                                { "term" : { "regInfo.{{website}}{{^website}}rhd{{/website}}.aTacticIDExternal" : "701f2000000RieJAAS" } }
                            ] },
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
