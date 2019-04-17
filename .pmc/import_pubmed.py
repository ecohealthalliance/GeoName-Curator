import pymongo
import os
import datetime

dump_db = pymongo.MongoClient(os.environ["MONGO_HOST"])["pmc"]
geonaem_curator_db = pymongo.MongoClient(os.environ["MONGO_HOST"])['geoname-curator']

geonaem_curator_db.curatorSources.remove({"_source": "pubmed_sample"})

for item in dump_db.articles.find():
    geonaem_curator_db.curatorSources.insert({
        "_source": "pubmed_sample",
        "_sourceId": "pubmed_sample_" + str(item["_id"]),
        "title": item["article_title"],
        "addedDate": datetime.datetime.now(),
        "content": item["extracted_text"],
        "reviewed": False,
        "feedId": "pubmed_sample"
    })
