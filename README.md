# Searchisko configuration

[Searchisko](https://github.com/searchisko/searchisko) needs to be properly configured before it can be
used. This project contains configuration of Searchisko running behind <http://dcp.jboss.org/>. 

## Installing configuration 

Initialization steps:

1. Get JBoss Developer artifacts from <https://github.com/jboss-developer/www.jboss.org/tree/master/_dcp> and copy them into data structure of configurations
2. Create Elasticsearch index templates - `index_templates/init_templates.sh`
3. Create Elasticsearch indexes  - `indexes/init_indexes.sh`
4. Create Elasticsearch mappings - `mappings/init_mappings.sh`
5. Push all init data in the following order:
   - `data/provider/init_providers.sh` 
   - `data/config/init_config.sh`
   - `data/project/init_projects.sh`
   - `data/contributor/init-contributors.sh`
   - `data/query/init-queries.sh`
6. Initialize Elasticsearch rivers - `rivers/init_rivers.sh` 

Note: each .sh script accepts commandline parameters which allows to configure 
location of Searchisko REST API or Elasticsearch search node http connector used by 
given script. Steps 2 - 5 can be performed by top level `init_all_noriver.sh` script.

### Example - localhost:8080

1. Optional: Clean environment (Searchisko data and embedded DB)

		rm -rf ~/.dcp_data/
		rm -rf $JBOSS_HOME/bin/searchisko.*

2. Start Searchisko in local EAP. Read [Development Docs](https://github.com/searchisko/searchisko/blob/master/documentation/development.md).

3. Push all init data

		cd configuration/
		./init_all_noriver.sh


### Example - OpenShift

1. Push repo to Openshift

2. Connect to Openshift Console
		
		ssh 5163d7b25973ca8ae4001fcf@dcp-jbossorgdev.rhcloud.com

3. Stop EAP and the database and remove all Elasticsearch cluster data

		ctl_app stop
		rm -rf ~/app-root/data/search

4. Delete data in the database

		# Recently, OpenShift does not seem to allow to stop only the app, but it stops the database as well,
		# we have to first start the app to make the database available.

		ctl_app start or do git push to openshift repo

		mysql dcp;
		delete from Config; delete from Contributor; delete from Project;
		delete from Provider; delete from Rating; delete from TaskStatusInfo;
		delete from Query;
		exit;

5. Push all init data

		# Wait till app is up - visit main page of DCP
		cd ~/app-root/repo/configuration
		./init_all_noriver.sh http://${OPENSHIFT_JBOSSEAP_IP}:8080

	* Optionally push other init data. For example if you have list of contributors or passwords for rivers.
	  (Such init data is typically not shared in public repo.)

6. Start Rivers

		cd ~/app-root/repo/configuration/rivers/
		./init_rivers.sh


## Versions management

As Searchisko is evolving and changing so does the configuration as well. It is important to pay attention
to proper versions management.

- **Development:** While new Searchisko version is in development phase, all related configuration updates
  are pushed into the `master` branch.
  
- **Release:** As soon as new Searchisko version is released a new git branch of configuration is created from master.
  The branch name must refer to Searchisko version. For example when Searchisko [`v2.0.1`](https://github.com/searchisko/searchisko/releases/tag/v2.0.1)
  is released then there is created a new branch called `v2.0.1` as well.
  
- **Updates:** Whenever there is made a change in configuration that apply to already released versions of Searchisko
  the update must be back-ported to all other relevant branches too.
  
TODO:

Give example (git CLI sequence) of back-porting configuration changes to older version.