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
