# Query: forum_threads_by_project

**forum_threads_by_project** is a query that can list the most recent forum threads for a given project. Additionally the results can be scrolled with use of `size` and `from` parameters.

## URL parameters

##### `size`

Optional parameter determining number of documents returned in response with default value of `8`.
For security reasons this parameter is constrained only to predefined list of values which are [`10`, `15`, `20`, `25`].To select one option client passes one of the following parameters with non-null value:

* `size10` = 10 documents
* `size15` = 15 documents
* `size20` = 20 documents
* `size25` = 25 documents

For example:

- <http://dcp_server:port/v2/rest/search/forum_threads_by_project?size10=true>

If multiple options are used then the highest number wins.

##### `from`

Optional position of the first document returned. If no `from` parameter is provided then value of `0` is used.

**Example:**

- <http://dcp_server:port/v2/rest/search/forum_threads_by_project?from=5>

##### `project`

Optional parameter. If provided then the query is restricted to forum threads having field `sys_project` equal to the given project name.

**Example:**

- <http://dcp_server:port/v2/rest/search/forum_threads_by_project?project=seam>

## Query output format

Matching documents are returned in `hits.hits[]`. Every document contains `fields` section with returned data.

## Query implementation details

This chapter discusses implementation details of Elasticsearch query.

Unescaped mustache template:

```
{
   "from": {{#from}}{{from}}{{/from}}{{^from}}0{{/from}},
   "size": 8,
   {{#size10}}"size": 10,{{/size10}}
   {{#size15}}"size": 15,{{/size15}}
   {{#size20}}"size": 20,{{/size20}}
   {{#size25}}"size": 25,{{/size25}}
   "sort": [ { "sys_last_activity_date": "desc" } ],
   "fields": [
      "sys_title", "sys_url_view", "sys_last_activity_date"
   ],
   "script_fields" : {
      "replies_count" : {
         "script" : "_source.sys_comments ? _source.sys_comments.length : 0"
      }
   },
   "query" : {
      "filtered": {
         "filter": {
            "and": [
               {{#project}}
                  {
                     "term": { "sys_project": "{{.}}" }
                  },
               {{/project}}
               {}
            ]
         }
      }
   }
}
```