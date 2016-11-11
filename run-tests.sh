#!/bin/bash

# example:
#
# ./run-tests.sh --app_uri=http://127.0.0.1 --app_port=13000 --mongo_host=127.0.0.1 --mongo_port=13001 --prod_db=eidr-connect --test_db=eidr-connect-test

for i in "$@"
do
case $i in
    --prod_db=*)
    prod_db="${i#*=}"
    shift
    ;;
    --test_db=*)
    test_db="${i#*=}"
    shift
    ;;
    --mongo_host=*)
    mongo_host="${i#*=}"
    shift
    ;;
    --mongo_port=*)
    mongo_port="${i#*=}"
    shift
    ;;
    --app_uri=*)
    app_uri="${i#*=}"
    shift
    ;;
    --app_port=*)
    app_port="${i#*=}"
    shift
    ;;
    *)
    ;;
esac
shift
done

# use args or default
prod_db=${prod_db:=eidr-connect}
test_db=${test_db:=eidr-connect-tests}
mongo_host=${mongo_host:=127.0.0.1}
mongo_port=${mongo_port:=27017}
app_uri=${app_uri:=http://localhost}
app_port=${app_port:=13000}

chimp=node_modules/chimp/bin/chimp.js
mongo=node_modules/mongodb-prebuilt/binjs/
watch=""
quit=0


if [ "$WATCH" == "true" ]; then
  watch="--watch";
  SECONDS=0
fi

# Clean-up
function finish {
  echo "Cleaning-up..."
  $mongo/mongo.js $mongo_host:$mongo_port/$test_db .scripts/drop-database.js
  echo "Restoring the original '$test_db' db from a dump file..."
  $mongo/mongorestore.js -h $mongo_host --port $mongo_port -d $test_db tests/dump/$prod_db --quiet
  echo "done."
  rm -rf tests/dump/ # cle
}
trap finish EXIT
trap finish INT
trap finish SIGINT  # 2
trap finish SIGQUIT # 3
trap finish SIGKILL # 9
trap finish SIGTERM # 15
# Note: must be bound before starting the actual test


# Back up the current database
rm -rf tests/dump/
echo "Creating a bson dump of our 'eidr-connect' db..."
$mongo/mongodump.js -h $mongo_host --port $mongo_port -d $prod_db -o tests/dump/ --quiet
echo "done."

$chimp $watch --ddp=$app_uri:$app_port \
        --path=tests/ \
        --coffee=true \
        --compiler=coffee:coffee-script/register \

# Output time elapsed
if [ "$WATCH" != "true" ]; then
  echo ''
  echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed"
  echo ''
fi
