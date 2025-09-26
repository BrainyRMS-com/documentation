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

Fare riferimento alla nuova (2025-09-26) procedura, che fa (quasi) tutto in automatico.

https://github.com/BrainyRMS-com/pms-integrations/blob/main/create-new-pms.sh


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
