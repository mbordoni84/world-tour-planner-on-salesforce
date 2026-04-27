// Check Event Session configuration
System.debug('=== Event Session Record Types ===');
List<RecordType> recordTypes = [
    SELECT Id, Name, DeveloperName, IsActive
    FROM RecordType
    WHERE SobjectType = 'Event_Session__c'
    ORDER BY Name
];

for (RecordType rt : recordTypes) {
    System.debug('✓ ' + rt.Name + ' (' + rt.DeveloperName + ') | Active: ' + rt.IsActive);
}

System.debug('\n=== Existing Event Sessions ===');
List<Event_Session__c> sessions = [
    SELECT Id, Name, Title__c, RecordType.Name, Session_Type__c, Location__c
    FROM Event_Session__c
    ORDER BY Session_Type__c
    LIMIT 10
];

for (Event_Session__c session : sessions) {
    System.debug('Session: ' + session.Name + ' | Title: ' + session.Title__c + ' | Type: ' + session.Session_Type__c + ' | RT: ' + session.RecordType.Name);
}

System.debug('\n=== Session Type Picklist Values ===');
Schema.DescribeFieldResult fieldResult = Event_Session__c.Session_Type__c.getDescribe();
List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

for (Schema.PicklistEntry entry : picklistValues) {
    System.debug('- ' + entry.getLabel() + ' (Value: ' + entry.getValue() + ')');
}

System.debug('\n=== Summary ===');
System.debug('Record Types: ' + recordTypes.size());
System.debug('Existing Sessions: ' + sessions.size());
System.debug('Picklist Values: ' + picklistValues.size());
