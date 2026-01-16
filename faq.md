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


### Come elimino definitivamente una Property (anche BI/BMI)?

1. Sarebbe meglio fare unsubscribe lato cliente (se abbiamo l'account).
2. Entrare come utente `v2admin` —> Manage Properties —> All Properties.
3. Cercare la combinazione giusta di PMS e Property.
4. Cliccare sul tasto `DELETE` della Property corretta.


### Come elimino definitivamente una Property Krossbooking?

- Si elimina la Property tramite la pagina di Admin https://v2.brainyrms.com/pmsdashboard/manageproperties
- Se in Firestore permane il documento è perché ci sono dei documenti nella subcollection `logs` che non sono stati cancellati con successo. 
Eseguire lo script https://github.com/lucamarogna-brainy/aa_debug/blob/main/firestore_deleteOldDocuments.js (aprire il codice per leggere come usarlo).
- Cancellare le Cloud Tasks Queue.
- Cancellare i dati da BigQuery (ATTENZIONE: finora non l'ho mai fatto per precauzione).
- Cancellare i token da Secret Manager.
- Aggiornare il JSON contenente l'elenco delle property, che si trova qui: https://console.cloud.google.com/security/secret-manager/secret/kross-hotels-credentials/versions?inv=1&invt=Ab1lIg&project=brainy-v2


### Cambiare la past season (aka `seasonSystem`)
- Siccome vengono cambiati tutti i `base price`, è necessario inviare poi cliccare su `Settings -> Refresh Calculation`.


### Come impostare automaticamente la proporzione tra le camere?

Inviare un messaggio sul topic `roomTypesChanged` con un payload simile a questo:
```json5
{
  attributes: {
    pmsId: 13,
    propertyId: 'OLY',
	origin: 'calc-proportion',	// con questo calcolo solo la proporzione tra le camere!
  }
}
```

NB: c'è già uno script pronto per questo, che si trova qui: https://github.com/lucamarogna-brainy/aa_debug/blob/main/pubsub_roomTypesChanged.js.


### Come visualizzare i dati "monthly" del passato?

Ad esempio, se mi posiziono su gennaio 2025, voglio vedere il confronto con gennaio 2024.

Se la property ha una reference/past season impostata, però, la funzione delle LY metrics potrebbe saltare volutamente quel periodo.

La cosa strana è che, invece, nella BI i dati si vedono tutti poiché l'interrogazione viene fatta su tutto il periodo tramite la daily_recap.

Per fare in modo che anche su front-end Brainy si vedano i dati del passato è necessario:
- aggiornare la `seasonUser` in modo da coprire tutto il periodo (es. gennaio—dicembre 2024);
- dopodiché va rilanciata la `LY metrics`.


### Come inviare i prezzi anche alle camere virtuali (con quantity=0)?

Sono state fatte delle eccezioni ad hoc per alcuni PMS e alcune property (ad esempio "Grand Hotel President" di Passepartout).

Guarda nei file `core.js` (linea 778) e `occupancy.js` (linea 401) della repository `brainy-v2` per capire come aggiungerne un'altra.

Inoltre, in base al PMS, potrebbe essere necessario una modifica anche al download delle camere e la creazione del relativo parent_child_mapping.
Ad esempio, per **Passepartout**, sono state fatte delle eccezioni nei file `passepartout.py` (linea 166) e `processing.py` (linea 155) della repository `roomtype-change`.

Infine, sempre in base alle istruzioni ricevute dal cliente, potrebbe essere necessario impostare delle proporzioni fisse su queste camere virtuali (o comunque con quantity=0).

### Come inviare i prezzi di una sola tipologia di camera? Come disabilitare invio prezzi per certe camere?

Per le strutture per le quali si desidera abilitare l'invio dei prezzi, 
ma limitatamente ad un sottoinsieme di camere e non a tutte quelle disponibili,
bisogna impostare `roomtypes` aggiungendo la proprietà `allowPushPrices: false` 
per tutte le camere di cui **NON** si desidera inviare i prezzi.

Questa modifica è attiva dal 2026-01-16, per mezzo della commit
https://github.com/lucamarogna-brainy/brainy-v2/commit/9332dc527b6953e4bc84eca013b999442c9d628e.

Ma poi va fatto il filtro anche sulla repository del PMS specifico, nella funzione di invio prezzi.
Esempio: https://github.com/BrainyRMS-com/ericsoft/commit/af3c9635f512e6aa7ce7e964832314f8bf7171c4#diff-9bd8ce8b1e7d5ec5cad8a8f899cbc6b60d09a741aee53f629784d6a0eb0845c6R268-R272.

Esempio tratto da un caso reale (Ericsoft, Salice Resort, richiesta del 2026-01-15):
> Inviamo solo la GIRAS.

```json5
[
  {
    "id": 'COMFORT T',
    "disabled": false,
    "allowPushPrices": false, // <--- non inviamo i prezzi di questa camera
  },
  {
    "id": 'Gir Up',
    "disabled": false,
    "allowPushPrices": false, // <--- non inviamo i prezzi di questa camera
  },
  {
    "id": 'GIRAS',
    "disabled": false,
    // <--- allowPushPrices non specificato (cioè `undefined`)
  }
]
```
