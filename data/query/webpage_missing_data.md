# Query: Webpage Missing Data

**Webpage Missing Data** is a query that returns list of webpage documents
missing important data. Important data is: `sys_title`, `sys_description` or
`sys_content_plaintext`.

It also returns aggregation statistics about total count of missing docs per
individual fields for each content provider.

## URL parameters

##### `from`

Optional position of the first document returned. If no `from` parameter is provided then value of `0` is used.

**Example:**

- <http://dcp_server:port/v2/rest/search/webpage_missing_data?from=5>

##### `contentType`

Optional parameter that allows limiting the results to the particular sys_content_type. If no `contentType` parameter is provided then all sys_content_type's are being returned.

**Example:**

- <http://dcp_server:port/v2/rest/search/webpage_missing_data?contentType=rht_website>


## Query output format

Up to 50 first matching documents are returned in `hits.hits[]`. Every returned document contains
important fields (see above for the list) and `check#` fields with missing flag. This way it is easy
to learn which particular fields were identified as missing for individual documents.

The top aggregation section `aggregations.sys_content_provider.buckets[]` provides statistics per individual content
providers (see the `key` value for content provider code). 

For each content provider the `sys_content_type.buckets[]` contain statistics about missing important data in documents
(see the `key` value for content type code). At this level there are provided `missing#` counts for each missing
important field.

For example:

The following output means there were found `128` documents for content provider `rht` missing important data.
All of those documents belong to `rht_website` content type. In these documents `25` are missing `sys_title` field,
`22` are missing `sys_content_plaintext` and finally `128` are missing `sys_description` field.

````
  "aggregations": {
    "sys_content_provider": {
      "doc_count_error_upper_bound": 0,
      "sum_other_doc_count": 0,
      "buckets": [
        {
          "key": "rht",
          "doc_count": 128,
          "sys_content_type": {
            "doc_count_error_upper_bound": 0,
            "sum_other_doc_count": 0,
            "buckets": [
              {
                "key": "rht_website",
                "doc_count": 128,
                "missing#sys_title": {
                  "doc_count": 25
                },
                "missing#sys_content_plaintext": {
                  "doc_count": 22
                },
                "missing#sys_description": {
                  "doc_count": 128
                }
              }
            ]
          }
        }
      ]
    }
  }
````

## Query implementation details

Source of the query can be found in [`webpage_missing_data.json`](webpage_missing_data.json) file. Here is an unencoded version of the mustache query for easier reference.

  {
    "size": 50,
    "from": {{#from}}{{from}}{{/from}}{{^from}}0{{/from}},
    "fields": [
      "sys_content_id", "sys_content_type",
      "sys_title", "sys_description", "sys_content_plaintext",
      "sys_url_view"
    ],
    "script_fields": {
      "check#sys_title": {
        "script": "_source.sys_title ? 'Field not missing' : 'MISSING'"
      },
      "check#sys_description": {
        "script": "_source.sys_description ? 'Field not missing' : 'MISSING'"
      },
      "check#sys_content_plaintext": {
        "script": "_source.sys_content_plaintext ? 'Field not missing' : 'MISSING'"
      }
    },
    "query": {
      "filtered": {
        "query": {
          "match_all": {}
        },
        "filter": {
          "or": [
            { "missing": { "field": "sys_title" } },
            { "missing": { "field": "sys_description" } },
            { "missing": { "field": "sys_content_plaintext" } }
          ]
        }
      }
    },
    "aggs": {
      "sys_content_provider": {
        "terms": {
          "field": "sys_content_provider"
        },
        "aggs": {
          "sys_content_type": {
            "terms": {
              "field": "sys_content_type"
            },
            "aggs": {
              "missing#sys_title": {
                "missing": {
                  "field": "sys_title"
                }
              },
              "missing#sys_description": {
                "missing": {
                  "field": "sys_description"
                }
              },
              "missing#sys_content_plaintext": {
                "missing": {
                  "field": "sys_content_plaintext"
                }
              }
            }
          }
        }
      }
    }
  }