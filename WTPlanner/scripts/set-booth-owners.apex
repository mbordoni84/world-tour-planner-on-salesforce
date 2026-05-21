Map<String, String> boothToUserId = new Map<String, String>{
    'a2uJ9000000PpbrIAC' => '005J9000001yyo2IAA', // Agentforce       → Cristina Ballarati
    'a2uJ9000000PejkIAC' => '005J9000001yytdIAA', // Slack             → Roberto Perfetti
    'a2uJ9000000PejlIAC' => '005J9000001yytlIAA', // Data 360          → Simone Salma
    'a2uJ9000000PejmIAC' => '005J9000001yyoiIAA', // Mulesoft          → Guido Campani
    'a2uJ9000000PejnIAC' => '005J9000001yyobIAA', // Marketing (Booth) → Giorgio Cantoni
    'a2uJ9000000PejoIAC' => '005J9000001yythIAA', // Service (Booth)   → Sara Gregori
    'a2uJ9000000PejpIAC' => '005J9000001yyuCIAQ', // Security & Privacy→ Antonio Sapienza
    'a2uJ9000000PejqIAC' => '005J9000001yynkIAA', // ITSM              → Achille Franzetti
    'a2uJ9000000PejrIAC' => '005J9000001yyohIAA', // SMB               → Giuseppina Nicolosi
    'a2uJ9000000PejsIAC' => '005J9000001yyu7IAA', // Professional Svc  → Paolo Sena
    'a2uJ9000000PpbmIAC' => '005J9000001yytmIAA'  // Demo occhiali     → Simone Salsi
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
