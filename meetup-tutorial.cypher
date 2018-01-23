// Query di riscaldamento:

// Get all users in the dataset
MATCH (u:User)
RETURN u
	   
// Get all Meetups in the dataset
MATCH (m:Meetup)
RETURN m

// Show Meetups e Tags (da ricontrollare)
MATCH (m:Meetup)-[r:TAGGED]->(t:Tag)
return m, r, t;

// Get all users who joined a Meetup after 1 November 2017
MATCH (u:User)-[r:JOINED]->(m:Meetup)
WHERE r.timestamp > apoc.date.parse('01/11/2017', 'ms', 'dd/MM/yyyy')
RETURN u, r, m

// Query avanzate:

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
// TODO

// Query raccomandazione:

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
// TODO
				   
//				   
// Funzioni di supporto
//
// Export the graph as Cypher query to a file
CALL apoc.export.cypher.all('/tmp/meetup.cypher', {format: 'cypher-shell'})

// Empty the DB relationships
MATCH ()-[r]-() DELETE r

// Empty the DB nodes
MATCH (n) DELETE n

// Import all Meetup data from our proxy
WITH "https://meetup-proxy-dhzneqhyzi.now.sh/membership?meetups=GraphRM,RomaJS,Rust-Roma,Lambda-Roma,Blockchain-Roma,Machine-Learning-Data-Science-Meetup,DotNetCode,RomaWordPress,Agile_Talks" AS url
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
