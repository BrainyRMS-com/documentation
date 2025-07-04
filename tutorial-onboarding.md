## Onboarding SLOPE

1. andare su <https://slope-sync-3cuixb5lia-ew.a.run.app/docs#/default/initiate_data_pull_initiate_data_pull_get>
2. mettere il api token fornito dal slope per la property.
3. Attendere che tutti i task siano completati
4. lancia la query per le stats: <https://console.cloud.google.com/bigquery/scheduled-queries/locations/europe/configs/652d27ef-0000-259a-9787-94eb2c0ea148/runs?hl=it&inv=1&invt=Abm_EQ&project=brainy-v2>
5. poi fai onboading (ricorda di usare la chiave token come propertyID)
6. la cartella è su github - <https://github.com/BrainyRMS-com/PMSIntegrations>
7. initial pull py


## Onboarding doppia property PASSEPARTOUT

È successo (2025-06-24, Country House Il Girasole) che una stessa property volesse essere splittata in due property distinte, 
per meglio separare le tipologie di camere (in questo caso, appartamenti vs camere).
La cosa non è affatto banale e si è proceduto come segue:
1. Impostare il mapping corretto delle camere, come sempre. _(Questo passaggio non ricordo se va fatto prima o dopo l'onboarding oppure se ci pensa direttamente il processo di onboarding stesso)_
2. Onboarding normale della property con i suoi dati reali (es. "COUNTRYHOUSEILGIRASOLE").
3. Al termine, andare su BigQuery, tabella `room_mapping` e sostituire con un UPDATE il campo `propertyId` da "COUNTRYHOUSEILGIRASOLE" a "COUNTRYHOUSEILGIRASOLECAMERE".
4. Ripetere il passaggio precedente anche per l'altra struttura (es. COUNTRYHOUSEILGIRASOLEAPPARTAMENTI).
5. In Firestore, clonare il root_doc originale "COUNTRYHOUSEILGIRASOLE" (si veda lo script apposito https://github.com/lucamarogna-brainy/aa_debug/blob/main/firestore_cloneRootDocument.js), due volte, avendo l'accortezza di nominarlo secondo le convezioni dei punti precedenti.
6. Si può ora cancellare il root_doc originale "COUNTRYHOUSEILGIRASOLE", anche se non sono sicuro che poi la fatturazione, gli utenti ecc, siano ereditati dai due nuovi root_doc.
7. Togliere dai rispettivi root_doc appena creati le camere che non appartengono alla property in questione; i campi interessati sono: `parent_child_mapping`, `roomtypes` e `room_count`.
8. Nei nuovi root_doc, inserire la proprietà `group` valorizzata al reale nome della struttura (es. "COUNTRYHOUSEILGIRASOLE").
9. Scaricare le prenotazioni da apposita API https://passpartout-sync-27810994373.europe-west1.run.app/docs#/default/reservations_task_creator_reservations_task_creator_post, passando qualcosa come questo: ```{
  "client_id": "countryhouseilgirasole",
  "last_modified_at": "2024-01-01 00:00:01",
  "is_initial_pull": false,
  "date_range": ["2024-01-01", "2026-06-24"]
}```


**NB**: tutto questo funziona poiché è stata anche contestualmente aggiornata la tabella `data_view`.
