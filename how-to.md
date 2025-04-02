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
