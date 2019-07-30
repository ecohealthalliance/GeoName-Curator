This web-app provides an interface for highlighting spans of text and associating
them with geonames.

### Running the application

Install npm dependencies:

```
meteor npm install
```

```
GRITS_API_KEY=ENTER_API_KEY_HERE meteor
```

The [grits-api](https://github.com/ecohealthalliance/grits-api) is used to automatically preannotate location mentions.
The machine annotations can be corrected by human curators when they review
the articles. If you are running your own deployment of the grits API, set the 
domain name in the GRITS_URL environment variable.

### Importing a corpus of articles

By default this will load the OANC corpus portion in `.anc` if the database is empty.
That behavior is defined in `server/startup.coffee`

This repository also contains a script for importing PubMED open access articles
from an external mongo database. A dump of the database for EHA
internal use is available at s3://geoname-data/ai4e_articles-2019-07-10.gzip

```
MONGO_HOST=EXTERNAL_DATABASE_URL python .pmc/import_pubmed.py
```

## Deployment

We have created a script for deploying to Ubuntu AWS instances
[here](https://github.com/ecohealthalliance/infrastructure/tree/master/ansible/main).

You will need to edit inventory.ini if you are not deploying to our server.
Furthermore, if you are not an EHA employee, you will need replace the my_secure.yml
file with one of your own that defines eidr_connect_sensitive_envvars like so:

```
MAIL_URL=smtps service used to handle password resets
GRITS_URL=url for your grits api instance
GRITS_API_KEY=api key for your grits api instances
```

Use the following command to start the deployment:

```
ansible-playbook build-deploy-geoname-curator.yml
```

## Training geoannotator

This application is intended to create training data for the machine learning
components of our geoname annotator. The training script is located
[here](https://github.com/ecohealthalliance/geoname-annotator-training).

To download the data use the following command:
```
GEONAME_CURATOR_URL=url of geoname curator instance here python download_annotations.py
```
To train and evaluate the geoname annotator use the following commands:
```
python train.py
python score.py
```

## Developer notes

This project was created by modifying EIDR-Connect. As a result, some of variable
names are unintuitive, mainly where geoname annotations are referred to as
"incidents." Also, there may be some dead code remaining that is
not relevant to this project.
