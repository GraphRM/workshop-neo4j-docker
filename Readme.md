### Neo4J docker image per GraphRM workshop su community #Aperitech

Questa immagine docker è stata pensata per il workshop GraphRM sulle community #Aperitech a ROMA..

In questo repository potete trovare una configurazione docker per avviare Neo4J e caricare i dati del workshop senza troppi problemi.

La configurazione di questa istanza docker contiene:

* Le APOC più comuni per Neo4J già installate
* L'abilitazione alla lettura file per procedure APOC (utile per importare file)
* Le cartelle `data`, `import` e `plugin` esposte all'interno dell'istanza docker
    * Tutte e 3 le cartelle sono reperibili nella `root` (`/`) del container docker
* L'esposizione delle porte `7474` (Neo4J browser) e `7687` (protocollo Bolt) dal container

### Requisiti

* Docker 1.7 o superiori

## Installazione

Per avviare questa instanza docker Neo4J è sufficiente il seguente comando:

```sh
$ docker-compose up -d
```

Dopo qualche secondo sarà possibile aprire il browser e puntarlo su `localhost:7474`.
Le credenziali per l'istanza sono quelle di default (`neo4j/neo4j`), verrà ad ogni modo richiesto di cambiare la password al primo avvio: si consiglia di impostare `graphrm` ai fini di questo workshop.

## Caricamento dati

# Metodo rapido

All'interno della cartella `import` è presente un file `meetups.dump` contenente il dataset seriale che verrà utilizzato durante il corso del workshop.

### Neo4J Desktop

Aprire Neo4J Desktop e fare il login. Nella pagina principale scegliere un progetto vuoto (solitamente `My Project` sotto `Projects`) e aprire il tab `Terminal` come mostrato:

![Neo4j Desktop Terminale](/doc/neo4j-desktop-terminal.png?raw=true "Terminale Neo4j Desktop")

Controllare che il database sia non attivo (il tasto Play :arrow_forward: dovrebbe essere cliccabile, mentre stop e ricarica dovrebbero essere grigie).
A questo punto eseguire i seguenti comandi dal terminale:

```sh
bash-3.2$ bin/neo4j-admin load --from=/absolutepath/to/import/meetups.dump --database=graph.db --force
... dopo 5 secondi ...
bash-3.2$
```

A questo punto avviare il database (cliccare il tasto Play :arrow_forward: ) e cliccare poi su `Open Browser`: se dovesse apparire un modale `Database Security Alert`, cliccare su `Continue Anyway`*.
A volte il Neo4J browser potrebbe non collegarsi immediatamente al database, in tal caso quando proverete ad inviare una query otterrete il messaggio `Failed to construct 'WebSocket': The URL 'ws://:7687' is invalid.`. Non preoccupatevi, aspettate qualche secondo fino a che non comparirà la seguente schermata:


![Connessione Neo4j avvenuta](/doc/neo4j-connected.png?raw=true "Connessione Neo4j avvenuta")

### Istruzioni Docker

Spengere l'immagine docker e caricare i dati via `neo4j-admin`:

```sh
$ docker-compose stop
...
$ docker-compose run neo4j bash
docker$ ./bin/neo4j-admin load --from=/import/meetups.dump --database=graph.db --force
... dopo 5 secondi ...
docker$ exit
$ docker-compose up -d
```

A questo punto andare su `localhost:7474` con il proprio browser e navigare il nuovo dataset.

### Verifica caricamento dati:

A questo punto sarà possibile tornare sul Neo4J browser e provare una query per testare il corretto funzionamento dello script di caricamento dati:

```cypher
MATCH (n1)-[r]->(n2) RETURN r, n1, n2 LIMIT 25
```

Con il seguente risultato:

![Grafo GraphRM](/doc/example-query.png?raw=true "Risultato query Cypher")

## Problemi e soluzioni

Se ci dovessero essere problemi con i passi per l'installazione sopra, creare una issue Github su questo repository: cercheremo di rispondervi il prima possibile.

Se invece avete trovato dei problemi e avete la soluzione, condividete la vostra soluzione creando una PR su questo repository!
