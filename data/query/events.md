# Query: events

**events** is a query used to pull upcoming events broken down by either **start** or **end** date of the event
and grouped by months. It is possible to filter returned data (see below for details).

## URL parameters

##### `region`

Optional parameter.
If provided then the query is restricted to documents having field `region` equal to the region value.

**Example:**

- <http://dcp_server:port/v2/rest/search/events?region=XXX>

##### `product`

Optional parameter.
If provided then the query is restricted to documents having field `target_product` equal to the product value.

**Example:**

- <http://dcp_server:port/v2/rest/search/events?product=XXX>

##### `solution`

Optional parameter.
If provided then the query is restricted to documents having field `solution` equal to the solution value.

**Example:**

- <http://dcp_server:port/v2/rest/search/events?solution=XXX>

##### `format`

Optional parameter.
If provided then the query is restricted to documents having field `format` equal to the format value.

**Example:**

- <http://dcp_server:port/v2/rest/search/events?format=XXX>

## Query output format

Matching documents - **the events** - are returned in two data sets found under
`aggregations.months_by_start_date` and `aggregations.months_by_end_date` (section `hits.hits[]` is always empty
and it is not a bug). Full path to documents is `aggregations.<type>.buckets.events.hits.hits[]` and the month these
documents fall into is found in `aggregations.<type>.buckets.key_as_string` where the `<type>` specify type of events
grouping by month of either `start_date` or `end_date`. Monthly groups are ordered in ascending fashion (i.e. close
events go first).

There are also aggregations for individual filters found under `aggregations`. They can be used to populate
filter drop down boxes in the web UI.

## Query implementation details

This chapter discusses implementation details of Elasticsearch query. It should be considered _Expert Only_ chapter.

Unescaped mustache template:

      {
        "size": 0,
        "query": {
          "filtered": {
            "filter": {
              "and": [
                {
                  "range": {
                    "end_date": {
                      "gte": "now-1000d"
                    }
                  }
                }
                {{#region}}
                ,{
                  "term": {
                    "region": "{{region}}"
                  }
                }
                {{/region}}
                {{#product}}
                ,{
                  "term": {
                    "target_product": "{{product}}"
                  }
                }
                {{/product}}
                {{#solution}}
                ,{
                  "term": {
                    "solution": "{{solution}}"
                  }
                }
                {{/solution}}
                {{#format}}
                ,{
                  "term": {
                    "format": "{{format}}"
                  }
                }
                {{/format}}
              ]
            }
          }
        },
        "aggs": {
          "months_by_start_date": {
            "date_histogram": {
              "field": "start_date",
              "interval": "month",
              "format": "MMMM YYYY",
              "order": {
                "_key": "asc"
              }
            },
            "aggs": {
              "events": {
                "top_hits": {
                  "sort": [
                    "start_date",
                    "end_date"
                  ],
                  "_source": {
                    "include": [
                      "start_date",
                      "end_date",
                      "sys_title",
                      "sys_description",
                      "sys_url_view",
                      "image",
                      "format",
                      "sys_id"
                    ]
                  },
                  "size": 500
                }
              }
            }
          },
          "months_by_end_date": {
            "date_histogram": {
              "field": "end_date",
              "interval": "month",
              "format": "MMMM YYYY",
              "order": {
                "_key": "asc"
              }
            },
            "aggs": {
              "events": {
                "top_hits": {
                  "sort": [
                    "start_date",
                    "end_date"
                  ],
                  "_source": {
                    "include": [
                      "start_date",
                      "end_date",
                      "sys_title",
                      "sys_description",
                      "sys_url_view",
                      "image",
                      "format",
                      "sys_id"
                    ]
                  },
                  "size": 500
                }
              }
            }
          },
          "format_global": {
            "global": {},
            "aggs": {
              "format_filter": {
                "filter": {
                  "range": {
                    "end_date": {
                      "gte": "now-1000d"
                    }
                  }
                },
                "aggs": {
                  "format": {
                    "terms": {
                      "field": "format",
                      "order": {
                        "_term": "asc"
                      }
                    }
                  }
                }
              }
            }
          },
          "region_global": {
            "global": {},
            "aggs": {
              "region_filter": {
                "filter": {
                  "range": {
                    "end_date": {
                      "gte": "now-1000d"
                    }
                  }
                },
                "aggs": {
                  "region": {
                    "terms": {
                      "field": "region",
                      "order": {
                        "_term": "asc"
                      }
                    }
                  }
                }
              }
            }
          },
          "product_global": {
            "global": {},
            "aggs": {
              "product_filter": {
                "filter": {
                  "range": {
                    "end_date": {
                      "gte": "now-1000d"
                    }
                  }
                },
                "aggs": {
                  "product": {
                    "terms": {
                      "field": "target_product",
                      "order": {
                        "_term": "asc"
                      }
                    }
                  }
                }
              }
            }
          },
          "solution_global": {
            "global": {},
            "aggs": {
              "solution_filter": {
                "filter": {
                  "range": {
                    "end_date": {
                      "gte": "now-1000d"
                    }
                  }
                },
                "aggs": {
                  "solution": {
                    "terms": {
                      "field": "solution",
                      "order": {
                        "_term": "asc"
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
