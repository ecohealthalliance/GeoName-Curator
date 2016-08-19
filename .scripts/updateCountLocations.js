var counts = db.counts.find();

counts.forEach(function(current) {
	if (current.location) {
		db.counts.update(
			{_id: current._id},
			{
				$set: {locations: [current.location]}
			}
		);
	}
});

db.counts.update({}, {$unset: {location: ""}}, {multi: true});