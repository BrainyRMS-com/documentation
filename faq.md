# FAQ

### Chi scrive i Market Leader?
La CF [competitors](https://console.cloud.google.com/functions/details/europe-west1/competitors?env=gen2&inv=1&invt=AbnCCA&project=brainy-v2&tab=logs)


### Cosa potrebbe essere la mancata visualizzazione dei market leader (aka senza competitor)?

La CF `competitors` non è andata a buon fine.

Rilanciarla! (vedi esempio su Postman, non condivisibile qui per ragioni di segretezza)


### Non ci sono i prezzi da (mese) in poi

La future season è impostata correttamente? Se è stata messa che termina prima di (mese), allora è un comportamento corretto.


### Disattivare/Eliminare camere che si vedono ancora in frontend

Nel `root_doc`, proprietà `roomtypes`, impostare: 
- `disabled: true`
- `quantity: 0`


### Le metriche Last Year non sono aggiornate

Il problema tipico si manifesta nello storico, che è palesemente sbagliato (ad es. numero camere occupate maggiori del totale disponibile).

Dopo qualsiasi modifica alla tabella `daily_recap` (o a qualche sua query dipendente), va rilanciato il calcolo delle LY metrics tramite un POST a:
`https://importance-fine-tune-3cuixb5lia-ew.a.run.app/generate_last_year_metrics` con JSON `{"property_id": "ABCDEF", "pms_name": "passepartout" }`.
L'aggiornamento dei dati è immediato.


### Segnalazione di mancato caricamento storico

- Va rilanciato lo scarico delle prenotazioni (~10 minuti). Attenzione: se è Octorate, vanno chiamate entrambe le CF `octoratesync/syncHistory` e `octorate_downloadAll/init` (vedere i rispettivi esempi in Postman).
- Far girare la daily recap  (alcune ore!). Per farla andare immediatamente, senza attendere il prossimo avvio schedulato, cliccare su `Schedule backfill`.
- Rilanciare le LY metrics (vedi sezione precedente).


### Come elimino definitivamente le properties BMI dal front end?

- prima fai unsubscribe
- poi si possono cancellare da admin


### Come elimino definitivamente una Property Krossbooking?

- Si elimina la Property tramite la pagina di Admin https://v2.brainyrms.com/pmsdashboard/manageproperties
- Se in Firestore permane il documento è perché ci sono dei documenti nella subcollection `logs` che non sono stati cancellati con successo. 
Eseguire lo script https://github.com/lucamarogna-brainy/aa_debug/blob/main/firestore_deleteOldDocuments.js (aprire il codice per leggere come usarlo).
- Cancellare le Cloud Tasks Queue.
- Cancellare i dati da BigQuery (ATTENZIONE: finora non l'ho mai fatto per precauzione).
- Cancellare i token da Secret Manager.
- Aggiornare il JSON contenente l'elenco delle property, che si trova qui: https://console.cloud.google.com/security/secret-manager/secret/kross-hotels-credentials/versions?inv=1&invt=Ab1lIg&project=brainy-v2
