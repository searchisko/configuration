# Query: Stale resources

**Stale resources** query is designed to provide a list of 100 documents that have the oldest update information.

 It is restricted to search on top of the following `sys_type`s:

- jbossdeveloper_bom
- quickstart
- jbossdeveloper_archetype
- video
- article
- solution
- jbossdeveloper_example 

Additionally the query is also constrained to return results only from `rht` and `jboss-developer` providers.

## URL parameters

##### `last_updated_before`
Optional filter accepting date in a string format. It's also possible to use date intervals with this parameter e.g. 'now-1y' or 'now-7d'.
If present then only documents having `sys_updated < last_updated_before` are included.

- <http://dcp_server:port/v2/rest/search/stale_resources?last_updated_before=now-1y>
- <http://dcp_server:port/v2/rest/search/stale_resources?last_updated_before=2013>
- <http://dcp_server:port/v2/rest/search/stale_resources?last_updated_before=2013-02-22>
- <http://dcp_server:port/v2/rest/search/stale_resources?last_updated_before=2013-02-22T01:01:01.000Z>

## Query output format

The query has hardcoded list of fields that are returned:

	"fields": [ 
		"sys_updated",
		"sys_created",
		"sys_description",
		"sys_title",
		"sys_url_view",
		"sys_type",
		"sys_content_type",
		"sys_content_id"
    ]

## Query implementation details

Unescaped version of the query:

    {
        "fields" : [ "sys_updated","sys_created","sys_description","sys_title","sys_url_view","sys_type","sys_content_type","sys_content_id" ],
        "size" : 100,
        "sort" : [
            { "sys_updated" : "asc" },
            "_score"
        ],
        "query" : {
            "filtered": {
                "filter": {
                    "and": {
                        "filters": [
                            {{#last_updated_before}}
                            {
                                "range" : {
                                    "sys_updated" : {
                                        "lt": "{{last_updated_before}}"
                                    }
                                }
                            },
                            {{/last_updated_before}}
                            {
                                "terms": {
                                    "sys_content_provider": [ "jboss-developer", "rht" ]
                                }
                            }
                        ]
                    }
                }
            }
        }
    }