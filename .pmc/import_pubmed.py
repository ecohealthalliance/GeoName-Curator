import pymongo
import os
import datetime

pmc_db = pymongo.MongoClient(os.environ["MONGO_HOST"])["pmc"]
geoname_curator_db = pymongo.MongoClient(os.environ["MONGO_HOST"])['geoname-curator']

geoname_curator_db.curatorSources.remove({"_source": "pubmed_sample"})

for item in pmc_db.articles.find():
    geoname_curator_db.curatorSources.insert({
        "_source": "pubmed_sample",
        "_sourceId": "pubmed_sample_" + str(item["_id"]),
        "title": item["article_title"],
        "addedDate": datetime.datetime.now(),
        "content": item["extracted_text"],
        "reviewed": False,
        "feedId": "pubmed_sample"
    })
