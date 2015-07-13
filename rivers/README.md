This folder contains configuration of rivers running inside Elasticsearch to pull
information from external sources into search indices,
see <https://www.elastic.co/guide/en/elasticsearch/rivers/1.4/index.html>

How to delete river:

- run: `curl -XDELETE http://localhost:15000/_river/jbossorg_jira/_meta`
- restart Elasticsearch node