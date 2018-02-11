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

All'interno della cartella `import` è presente un file `meetup.cypher` contenente il dataset che verrà utilizzato durante il corso del workshop. Per caricare questo dataset è necessario eseguire i seguenti comandi:

```sh
$ docker-compose exec neo4j bash
# ... entriamo nel container docker (usare al posto di graphrm qui la password impostata sopra)
docker$  ./bin/neo4j-shell -u neo4j -p graphrm < '/import/meetup.cypher' > '/import/output.log'
# ... attendere un paio di minuti
docker$ exit
```

Notare che lo script sopra genererà un file `output.log` dentro la cartella `import`, utile ai fini di debug qualora qualcosa andasse storto durante l'operazione.

A questo punto sarà possibile tornare sul Neo4J browser e provare una query per testare il corretto funzionamento dello script di caricamento dati:

```cypher
MATCH (n1)-[r]->(n2) RETURN r, n1, n2 LIMIT 25
```

Con il seguente risultato:

![Grafo GraphRM](/doc/example-query.png?raw=true "Risultato query Cypher")
