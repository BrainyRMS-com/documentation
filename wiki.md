## How does "importance of the day" calculation work


### 1. Workflow
- Every (other) day at 01:00 AM, the Workflow `daily-run-market-leaders` runs.
(It lasts over 7 hours!)
- The Workflow branch `runImportancesAndCompetitors` executes the Cloud Functions `runImportancesAndCompetitors`.
- The Workflow branch `runImportanceHistoryAndFineTuneImportance` executes the Cloud Run at 
<https://importance-history-3cuixb5lia-uw.a.run.app/create_importance_history_tasks> 
and <https://importance-fine-tune-3cuixb5lia-ew.a.run.app/month_fine_tune>


### 2. runImportancesAndCompetitors

Creates GCP Tasks for CF `importance` and `competitors`.


### 3. importance

It does the calculation and then:
- saves the result to `systemImportance` field of the `days` document;
- publishes a message to the `calculatePrices` topic.


### 4. Listeners of "calculatePrices" topic

- irev1


## Query per...

### Query per vedere le differenze tra due tabelle con la stessa struttura e (quasi) gli stessi dati
```bigquery
SELECT
  COALESCE(t1.reservationId, t2.reservationId) AS reservationId,

  -- Indica se la riga è mancante in una delle due tabelle
  CASE
    WHEN t1.reservationId IS NULL THEN 'MISSING IN VISTA1'
    WHEN t2.reservationId IS NULL THEN 'MISSING IN VISTA2'
    ELSE 'MATCH'
  END AS row_status,

  -- Mostra la differenza di "status" solo se i valori non corrispondono
  IF(t1.status IS DISTINCT FROM t2.status, CONCAT(t1.status, ' -> ', t2.status), NULL) AS status_diff,

  -- Mostra la differenza di "is_outliers" solo se i valori non corrispondono
  IF(t1.is_outliers IS DISTINCT FROM t2.is_outliers, CONCAT(CAST(t1.is_outliers AS STRING), ' -> ', CAST(t2.is_outliers AS STRING)), NULL) AS is_outliers_diff,

  -- Mostra la differenza di "price" solo se i valori non corrispondono
  IF(t1.price IS DISTINCT FROM t2.price, CONCAT(CAST(t1.price AS STRING), ' -> ', CAST(t2.price AS STRING)), NULL) AS price_diff
FROM
  (
    SELECT
      reservationId,
      ANY_VALUE(status) AS status,
      ANY_VALUE(is_outliers) AS is_outliers,
      ANY_VALUE(price) AS price
    FROM `brainy-v2.zzzDEBUG.negresco_luglio_vista1`
    GROUP BY reservationId
  ) AS t1
FULL OUTER JOIN
  (
    SELECT
      reservationId,
      ANY_VALUE(status) AS status,
      ANY_VALUE(is_outliers) AS is_outliers,
      ANY_VALUE(price) AS price
    FROM `brainy-v2.zzzDEBUG.negresco_luglio_vista2`
    GROUP BY reservationId
  ) AS t2
  ON t1.reservationId = t2.reservationId
WHERE
  t1.reservationId IS NULL OR t2.reservationId IS NULL
  OR t1.status IS DISTINCT FROM t2.status
  OR t1.is_outliers IS DISTINCT FROM t2.is_outliers
  OR t1.price IS DISTINCT FROM t2.price
ORDER BY
  reservationId
```
