
//////////////////////////
// Query di riscaldamento:
//////////////////////////

// Get all users in the dataset
MATCH (u:User)
RETURN u

// Get all Meetups in the dataset
MATCH (m:Meetup)
RETURN m

// Show Meetups e Tags
MATCH (m:Meetup)-[r:TAGGED]->(t:Tag)
RETURN m, r, t

// Show relations for a specific User
MATCH (u:User {name:"<insert user name>"})-[r]->(o)
RETURN u, r, o

// Get all users who joined a Meetup after 1 November 2017
MATCH (u:User)-[r:JOINED]->(m:Meetup)
WHERE r.when > apoc.date.parse('01/11/2017', 'ms', 'dd/MM/yyyy')
RETURN u, r, m


//////////////////
// Query avanzate:
//////////////////

// Schema:
CALL db.schema();

// Show top 5 Meetups by popularity
MATCH (m:Meetup)
WITH m, size(()-[:JOINED]->(m)) as degree
ORDER BY degree DESC
RETURN m.name, degree
LIMIT 5

// Show top 10 active users by partecipation
MATCH (u:User)
WITH u, size((u)-[:JOINED]->(:Meetup)) as degree
ORDER BY degree DESC
RETURN u.name, degree
LIMIT 10

// Top 10 users by interests
MATCH (u:User)-[:JOINED]->(:Meetup)-[:TAGGED]->(t:Tag)
WITH u, SIZE(COLLECT(DISTINCT t)) as interests
ORDER BY interests DESC
RETURN u.name, interests
LIMIT 10

// Shortest path Eros -> Piero
MATCH (u1:User {name:"Piero S."}), (u2:User {name:"Eros B."}), p=shortestPath( (u1)-[*]-(u2)  )
RETURN u1, u2, p


/////////////////////////
// Query raccomandazione:
/////////////////////////

// Prendere colleghi di Eros
// Prendere "meetup" frequentati dai colleghi di Eros
// Rimuovere "meetup" già frequentati da Eros
MATCH (eros:User {name: "Eros B."}),
      (eros)-[:JOINED]->(:Meetup)<-[:JOINED]-(colleague:User),
      (colleague)-[:JOINED]->(newMeetup:Meetup)
WHERE NOT (eros)-[:JOINED]->(newMeetup)
RETURN newMeetup.name, collect(distinct colleague.name) AS joiners, count(distinct colleague.name) as occurrences
ORDER BY occurrences DESC;

// Raccomandazioni by topic
MATCH (eros:User {name:"Eros B."}),
	  (eros)-[:JOINED]->(meetup:Meetup),
      (meetup:Meetup)-[:TAGGED]->(tag:Tag)<-[:TAGGED]-(newMeetup:Meetup)
WHERE NOT (eros)-[:JOINED]->(newMeetup)
RETURN eros, meetup, tag, newMeetup


///////////////////////
// Funzioni di supporto
///////////////////////

// Export the graph as Cypher query to a file
CALL apoc.export.cypher.all('/tmp/meetup.cypher', {format: 'cypher-shell'})

// Empty the DB relationships
MATCH ()-[r]-() DELETE r

// Empty the DB nodes
MATCH (n) DELETE n

// Import all Meetup data from our proxy
WITH "https://meetup-proxy-zthscriext.now.sh/membership?meetups=GraphRM,RomaJS,Rust-Roma,Lambda-Roma,Blockchain-Roma,Machine-Learning-Data-Science-Meetup,DotNetCode,RomaWordPress,Agile_Talks" AS url
CALL apoc.load.json(url) YIELD value
UNWIND value.items AS e

MERGE (meetup:Meetup {id:e.meetup.id})
	ON CREATE SET
  		meetup.name = e.meetup.name,
        meetup.link = e.meetup.link

MERGE (user:User {id:e.member.id})
	ON CREATE SET
    	user.name = e.member.name,
        user.status = e.member.status

MERGE (user)-[:JOINED {as: e.meetup.who, when: e.member.joined}]->(meetup)

MERGE (organizer:User {id: e.meetup.organizer.id})
MERGE (organizer)-[:CREATED {when: e.meetup.created}]->(meetup)

FOREACH (tagName IN e.meetup.topics |
	MERGE (tag:Tag {id: tagName.id, name: tagName.name})
    MERGE (meetup)-[:TAGGED]->(tag)
)


// Import all Meetup event from our proxy
WITH "https://meetup-proxy-zthscriext.now.sh/attendance?meetups=GraphRM,RomaJS,Rust-Roma,Lambda-Roma,Blockchain-Roma,Machine-Learning-Data-Science-Meetup,DotNetCode,RomaWordPress,Agile_Talks" AS url
CALL apoc.load.json(url) YIELD value
UNWIND value.items AS e

MERGE (event:Event {id:e.event.id})
	ON CREATE SET
  		event.name = e.event.name,
        event.local_date = e.event.local_date,
        event.local_time = e.event.local_time,
        event.time = e.event.time,
        event.description = e.event.description ,
        event.link = e.event.link

MERGE (user:User {id:e.member.id})
	ON CREATE SET
    	user.name = e.member.name

MERGE (meetup:Meetup {id:e.meetupId})

MERGE (meetup)-[:HAS_EVENT]->(event)
MERGE (user)-[:PARTICIPATED]->(event)

// Test for duplicates
MATCH (n1:Meetup) WHERE NOT (n1)-[:HAS_EVENT]->() RETURN n1

// More queries with single events and partecipation

// Show top 5 Meetups Events by popularity
MATCH (m:Meetup)-[:HAS_EVENT]->(e:Event)
WITH m,e, size(()-[:PARTICIPATED]->(e)) as degree
ORDER BY degree DESC
RETURN m.name,e.name, degree
LIMIT 5


// Show top 10 active users by partecipation to events

MATCH (u:User)
WITH u, size((u)-[:PARTICIPATED]->(:Event)) as degree
ORDER BY degree DESC
RETURN u.name, degree
LIMIT 10


// Show users with no events

MATCH (n:User)
WITH n,size((n)-[:PARTICIPATED]->(:Event)) as rel_count
WHERE rel_count = 0
RETURN n.name
limit 5


// Show missing event for Enrico R.

MATCH (n:User)-[:JOINED]->(m:Meetup),
		(m)-[:HAS_EVENT]->(e:Event)
WHERE NOT (n)-[:PARTICIPATED]->(e) AND n.name = "Enrico R."
RETURN n.name,m.name,e.name
limit 40


// Show GraphRM meetup trends

MATCH (m:Meetup)-[:HAS_EVENT]->(e:Event)
WITH m,e,SIZE(()-[:PARTICIPATED]->(e)) as participants
WHERE m.name ="GraphRM"
RETURN m.name,participants,e.local_date
ORDER BY m.name ASC,e.time


// Show Users that joined a meetup 7 days before the next event but didn't go

MATCH(u:User)-[j:JOINED]->(m:Meetup),
	 (m)-[:HAS_EVENT]->(e:Event)
WHERE NOT (u)-[:PARTICIPATED]-(e) and (e.time - j.when) > 0 AND (e.time - j.when)/ (1000*60*60*24) < 7
RETURN u.name,m.name,(e.time - j.when)/ (1000* 60*60*24) as days
ORDER BY m.name,u.name, days

// Show Users that joined a meetup but never partecipated to an event

MATCH (u:User)-[j:JOINED]->(m:Meetup),
	 (m)-[:HAS_EVENT]->(e:Event)
WITH u, m, COLLECT(e) AS events
WHERE ALL(e IN events WHERE NOT (u)-[:PARTICIPATED]-(e))
RETURN u, m

// Show Users who changed their interest during the years

