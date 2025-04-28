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