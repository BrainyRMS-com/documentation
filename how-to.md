## Come copiare i dati da un progetto Firestore ad un altro

1. Da terminale, assicurarsi di essere nel progetto `SOURCE`: `gcloud config set project brainy-v2`

2. Eventualmente creare il bucket su Google Cloud Storage di `SOURCE`.

3. Dare i permessi al service account di `DEST` per accedere al bucket di `SOURCE`:
   1. Andare su GCP di `DEST` (es: https://console.cloud.google.com/firestore/databases/-default-/import-export?authuser=0&hl=it&invt=Abtryw&project=brainy-v3) e leggere qual è il service account (es: "I job di importazione/esportazione vengono eseguiti come:").
   2. Andare su GCP di `SOURCE` e selezionare il bucket creato in precedenza.
   3. Click su Permissions —> Grant access.
   4. Come "New principals" inserire il service account del punto `i`.
   5. Come "Role" scegliere `Storage Admin`.

4. Esportare tutto il database oppure una singola Collection:
   - `gcloud firestore export gs://luca_temp3 --async`
   - `gcloud firestore export gs://luca_temp3 --collection-ids=octorate --async`

5. Spostarsi nel progetto `DEST`: `gcloud config set project brainy-v3`

6. Elencare tutti gli oggetti dentro il bucket: `gsutil ls gs://luca_temp3/`

7. Importare i dati: `gcloud firestore import gs://luca_temp3/2025-04-02T13:52:39_25825 --async`

8. Ricordarsi di ritornare al progetto `SOURCE`: `gcloud config set project brainy-v2`


## Aggiunta di un PMS

Quando viene aggiunto un PMS al sistema, vanno eseguite diverse procedure:

### Tabelle base BigQuery
Dataset col nome del PMS tutto in minuscolo (come abbiamo sempre fatto).

Tabella chiamata `data_[nome_struttura]`, dove ovviamente il nome va sanificato (no spazi, no simboli strani, limite al numero di caratteri, ecc.).
Lo schema della tabella:

| field_name     | mode     | type      | description                                                   |
|----------------|----------|-----------|---------------------------------------------------------------|
| property_id    | REQUIRED | STRING    | The PMS internal property ID                                  |
| reservation_id | REQUIRED | STRING    | The PMS internal reservation ID                               |
| insert_time    | REQUIRED | TIMESTAMP | The timestamp of when the row was inserted in the table       |
| raw_data_json  | NULLABLE | JSON      | The payload received from the PMS with all the data (in JSON) |

| **Table Type**           | Partitioned              |
|--------------------------|--------------------------|
| **Partitioned by**       | DAY                      |
| **Partitioned on field** | insert_time              |
| **Partition expiration** | Partitions do not expire |
| **Partition filter**     | Not required             |
| **Clustered by**        | reservation_id           |

Visto che abbiamo problemi con i dati sensibili, nel campo `raw_data_json` vanno già eliminati quei dati; quindi non sarà un vero e proprio "raw" ma un filino di elaborazione dobbiamo farla.

Tabella chiamata `data` generica, in cui verranno memorizzate le prenotazioni di tutte le property appartenenti a questo PMS. Viene usata sicuramente dalla `daily_recap` ma probabilmente anche da altri servizi.
Un giorno andrà rimossa perché NON è assolutamente efficiente e costa molto usarla.

La CR apposita, dovrà quindi effettuare un doppio inserimento: nella tabella `data` e nella `data_[nome_struttura]`.

### Tabella data_view

Va creata la `data_view`, prendendo spunto dalle ultime create; servirà solo come base e test rapidi (es. debug) e non dovrà essere utilizzata realmente durante le normali operazioni, in quanto si utilizzeranno le varie tabelle `data_[nome_struttura]`.
(NB: per il momento anche la `daily_recap` ne farà uso, ma è già in cantiere la soluzione più efficiente)

### properties-stats
Vanno create le tabelle BigQuery `properties-stats-data` e poi la sua view, cioè `properties-stats`.

### Scheduler
Creare quello per aggiornare le statistiche delle property (vedi https://console.cloud.google.com/bigquery/scheduled-queries?inv=1&invt=Ab1EAw&project=brainy-v2).

A seconda del tipo di integrazione, è possibile che si renda necessario scaricare le prenotazioni ogni tot minuti; in questo caso andrà creato l'apposito Scheduled Job.

### Nei file JS del progetto
- config.js
- bigquery.js

### Deploying delle CF
```shell
firebase deploy --only functions:getPropertiesInfo,functions:updatebaseprices,functions:competitors,functions:importance,functions:irev1,functions:onresnotif
```

### Creazione delle collection di Firestore
Se non è già stato fatto, ci pensano poi in automatico gli script.
Ciò non toglie che almeno un "root document" dev'essere stato caricato con tutti i crismi (camere, mapping, ...).

### Creazione dell'estenzione di Firestore per fare l'export su BigQuery
Ne vanno create due, una per il "root document" e una per la collection "days"; da copiare pari pari da quelle esistenti per altri PMS.

Attenzione alla tabella `*_days_raw_changelog`: va fatta a manina perché vanno aggiunti i campi `propertyId` e `date`; quest'ultimo poi va anche partizionato.
```bigquery
-- Creo la tabella PARTIZIONATA temporanea
CREATE TABLE `brainy-v2.firestore_export_eu._temp`
PARTITION BY DATE_TRUNC(date, MONTH)
CLUSTER BY propertyId, operation
AS
SELECT 
  *,
  JSON_VALUE(path_params, "$.propertyId") AS propertyId,
  DATE(SAFE_CAST(SUBSTR(document_name, -10) AS DATE)) AS date,
FROM `brainy-v2.firestore_export_eu.bookingdesigner_days_raw_changelog`
;

-- Rimuovo la vecchia tabella non partizionata
DROP TABLE `brainy-v2.firestore_export_eu.bookingdesigner_days_raw_changelog`;

-- Rinomino la nuova tabella partizionata
ALTER TABLE `brainy-v2.firestore_export_eu._temp`
RENAME TO `bookingdesigner_days_raw_changelog`;
```

### Aggiornamento della query schedulata per la tabella daily_recap
ATTENZIONE: tutte le tabelle di origine devono essere nel medesimo dataset (attualmente è `EU`).

### Modifica della CR roomtype-change
Va aggiunta la query necessaria, copiandola dalle precedenti.

Va creato il file .py per la gestione delle camere e della loro mappatura.

### Modifica della CR smart-budget
Va aggiunta la query necessaria, copiandola dalle precedenti.

### Modifica del Secret "brainy-pms-mapping"
Aggiungere al JSON contenuto la nuova mappatura:
https://console.cloud.google.com/security/secret-manager/secret/brainy-pms-mapping/versions?inv=1&invt=Ab2TPw&project=brainy-v2


## Come trasformare una tabella BigQuery non-partizionata in partizionata (mantenedo i dati)

Puoi creare una nuova tabella partizionata e clusterizzata sovrascrivendo quella esistente, utilizzando una tabella intermedia o eseguendo un'unica istruzione CREATE TABLE AS SELECT (CTAS) che è l'approccio più diretto ed efficiente.

Ecco come puoi farlo in un unico passaggio, sovrascrivendo la tabella attuale con una nuova versione partizionata e clusterizzata.

Puoi usare l'istruzione CREATE OR REPLACE TABLE ... AS SELECT per leggere i dati dalla tabella di origine e scriverli nella nuova tabella con la configurazione di partizionamento e clustering desiderata. Questo comando atomico sostituisce la vecchia tabella con la nuova in un'unica operazione.

```sql
# Passaggio 1: Creare una nuova tabella di appoggio
CREATE OR REPLACE TABLE your_dataset.your_table_NEW
PARTITION BY
  DATE_TRUNC(date, MONTH)
CLUSTER BY
  city, receiveTime
AS (
  SELECT *
  FROM your_dataset.your_table
);

# Passaggio 2: Cancellare la tabella originale
DROP TABLE your_dataset.your_table;

# Passaggio 3: Rinominare la nuova tabella
ALTER TABLE your_dataset.your_table_new
  RENAME TO your_table;
```

### Spiegazione della Query

- `CREATE OR REPLACE TABLE your_dataset.your_table`: Questo comando crea una nuova tabella o ne sostituisce una esistente con lo stesso nome. L'intera operazione è atomica.
- `PARTITION BY DATE_TRUNC(date, MONTH)`:
  - `PARTITION BY` definisce la colonna e la granularità per il partizionamento. 
  - `DATE_TRUNC(date, MONTH)` è una funzione che tronca il valore `TIMESTAMP` del campo `date` all'inizio del mese. Questo crea una partizione per ogni mese, che è esattamente ciò che hai richiesto. BigQuery gestirà automaticamente le partizioni mensili. 
- `CLUSTER BY city, receiveTime`:
  - `CLUSTER BY` specifica le colonne su cui basare il clustering. I dati all'interno di ogni partizione verranno ordinati fisicamente in base ai valori delle colonne `city` e `receiveTime`. 
  - L'ordine delle colonne nel clustering è importante. Le query che filtrano prima per `city` e poi eventualmente per `receiveTime` otterranno i maggiori benefici in termini di performance e costi.
- `AS (SELECT * FROM your_dataset.your_table)`: Questa sottoquery seleziona tutti i dati dalla tua tabella di origine. Questi dati verranno quindi inseriti nella nuova tabella con la struttura di partizionamento e clustering appena definita.

### Vantaggi di Questo Approccio
- Efficienza: È il modo più diretto per raggiungere il tuo obiettivo, senza passaggi manuali intermedi come la creazione e la successiva cancellazione di una tabella temporanea.
- Atomicità: La sostituzione della tabella avviene in un'unica transazione. Non c'è un momento in cui la tabella non esiste o è vuota.
- Semplicità: La sintassi è chiara e compatta.

Dopo aver eseguito questa query, la tua tabella `your_dataset.your_table` sarà partizionata per mese sul campo `date` e clusterizzata per `city` e `receiveTime`, **mantenendo tutti i dati originali**.
