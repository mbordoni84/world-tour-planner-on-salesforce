Map<String, String> boothToUserId = new Map<String, String>{
    'a2uJ9000000Pej1IAC' => '005J9000001yytXIAQ', // Agentforce - Superdemo → Piero Ponteggia
    'a2uJ9000000PejyIAC' => '005J9000001yyonIAA', // Slackbot               → Luisa Asta
    'a2uJ9000000PejzIAC' => '005J9000001yyoOIAQ', // Informatica            → Ferruccio Irione
    'a2uJ9000000PpbnIAC' => '005J9000001yytYIAQ', // Tableau                → Raffaele Corti
    'a2uJ9000000Pek0IAC' => '005J9000001yyoVIAQ', // Commerce Cloud         → Francesco Barzano
    'a2uJ9000000Pek1IAC' => '005J9000001yytsIAA', // Field Service          → Timoteo Rinesi
    'a2uJ9000000PpboIAC' => '005J9000001yytNIAQ', // Sales                  → Nicola Diluccia
    'a2uJ9000000PpMUIA0' => '005J9000001yyoEIAQ'  // Revenue                → Dario Finotti
};

List<Session__c> toUpdate = new List<Session__c>();
for (String sessionId : boothToUserId.keySet()) {
    toUpdate.add(new Session__c(
        Id = sessionId,
        session_owner__c = boothToUserId.get(sessionId)
    ));
}
update toUpdate;

System.debug('Aggiornati ' + toUpdate.size() + ' booth');
