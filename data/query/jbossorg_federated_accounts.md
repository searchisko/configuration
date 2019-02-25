# Query: SSO federation accounts links

**SSO federation accounts links** is a query that return data from `sso_federation` type. It won't return any direct results as its primary purpose is generating reports. Therefore the only data returned are date aggregation counts. The query supports several parameters for filtering and configuring the aggregation.

## URL parameters

##### `provider`

An optional parameter specifying which provider's links should be taken into account. The available list of values here are:
* RedHatExternalProvider
* RedHatInternalProvider
* FacebookProvider
* Google2Provider
* GitHubProvider
* LinkedInProvider
* TwitterProvider

If omitted the query will aggregate all federated links regardless the `provider` value in the data.

##### `active`

An optional parameter which defines whether the federated links that are being aggregated should be active or non-active. The parameter can take only boolean values of `true` and `false`. If not specified the aggregation will take all links into account regardless the `active` status in the data.

##### `with_new_account`

An optional parameter which defines whether the federated links that are being aggregated should be only the ones created while a new internal jboss.org account is created or opposite, only the ones created when no new account is created internally. If not specified all federated links are taken into account regardless the `with_new_account` status in the data.

##### `interval`

An optional parameter which can be used together with `aggregate` parameter in order to change time interval in which the results are aggreagated into buckets. The possible values are:

* second
* minute
* hour
* day
* week
* month (default)
* quarter
* year

**Example:**

- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?interval=week>

##### `bucket_key_format`

An optional parameter which specifies format of the key of time breakdown bucket.

Default value: `yyyy-MM`

See spec for more info. [ElasticSearch reference docs](https://www.elastic.co/guide/en/elasticsearch/reference/1.4/search-aggregations-bucket-daterange-aggregation.html#date-format-pattern)

- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?bucket_key_format=yyyy-MM-dd&interval=day>

##### `date_field`
An optional parameter defining what field to use when filtering on dates e.g. `date_from` resp. `date_to` or doing histogram (buckets). By default it's `sys_created`.

- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?date_field=sys_updated>

##### `date_from`
An optional filter accepting date in a string format. It's also possible to use date intervals with this parameter e.g. 'now-1y' or 'now-7d'.
If present then only federation links having `sys_created >= date_from` resp. `<date_field> >= date_from` are included.

- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?date_from=2013>
- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?date_from=2013-01>
- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?date_from=2013-02-22>
- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?date_from=2013-02-22T01:02:04.009Z>
- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?date_from=now-1y>

##### `date_to`
An optional filter accepting date in a string format. It's also possible to use date intervals with this parameter e.g. 'now-1y' or 'now-7d'.
If present then only federation links having `sys_created < date_to` resp. `<date_field> >= date_to` are included.

- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?date_to=2013>
- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?date_to=2013-01>
- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?date_to=2013-02-22>
- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?date_to=2013-02-22T01:02:04.009Z>
- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?date_to=now-1y>

##### `timezone_offset`

An optional parameter which can be used together with `aggregate` parameter in order to change timezone used when aggregating results into buckets. The timezone setting defaults to 'America/New_York'. Time zones may either be specified as an ISO 8601 UTC offset (e.g. +01:00 or -08:00) or as a timezone id, an identifier used in the TZ database like America/Los_Angeles.

**Example:**

- <http://dcp_server:port/v2/rest/search/jbossorg_federated_accounts?timezone_offset=America/New_York>


## Query output format

Aggregations of data for matching documents are returned in `aggregations.bucketeted.buckets[]`.

## Query implementation details

This chapter discusses implementation details of Elasticsearch query. It should be considered _Expert Only_ chapter.

Unescaped mustache template:

```
{
  "size":0,
  "query" : {
    "filtered": {
      "filter" : {
        "and": {
          "filters": [
            {{#provider}}
            {
              "term" : { "provider" : "{{provider}}" }
            },
            {{/provider}}
            {{#active}}
            {
              "term" : { "active" : {{active}} }
            },
            {{/active}}
            {{#with_new_account}}
            {
              "term" : { "with_new_account" : {{with_new_account}} }
            },
            {{/with_new_account}}
            {{#date_from}}
            {
              "range": {
                "{{date_field}}{{^date_field}}sys_created{{/date_field}}": {
                  "gte": "{{date_from}}",
                  "time_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
                }
              }
            },
            {{/date_from}}
            {{#date_to}}
            {
              "range": {
                "{{date_field}}{{^date_field}}sys_created{{/date_field}}": {
                  "lt": "{{date_to}}",
                  "time_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
                }
              }
            },
            {{/date_to}}
            {}
          ]
        }
      }
    }
  },
  "aggs" : {
    "bucketed" : {
      "date_histogram" : {
        "field" : "{{date_field}}{{^date_field}}sys_created{{/date_field}}",
        "interval" : "{{interval}}{{^interval}}month{{/interval}}",
        "format": "{{bucket_key_format}}{{^bucket_key_format}}yyyy-MM{{/bucket_key_format}}",
        "pre_zone" : "{{timezone_offset}}{{^timezone_offset}}America/New_York{{/timezone_offset}}"
      }
    }
  }
}
```