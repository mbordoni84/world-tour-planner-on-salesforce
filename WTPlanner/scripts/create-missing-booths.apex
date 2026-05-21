Id boothTypeId = 'a2tJ9000000H0uYIAS';

List<String> boothNames = new List<String>{'Demo occhiali', 'Tableau', 'Sales', 'Apromore'};

List<Session__c> sessions = new List<Session__c>();
for (String name : boothNames) {
    sessions.add(new Session__c(
        Name = name,
        Session_Type__c = boothTypeId,
        Location__c = 'Booth Area',
        Min_Shifts__c = 1,
        Max_Shifts__c = 2
    ));
}
insert sessions;

List<Shift__c> shifts = new List<Shift__c>();
for (Session__c s : sessions) {
    // Fascia 1: 08:30 - 10:00 (x2)
    shifts.add(new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(8, 30, 0, 0), End_Time__c = Time.newInstance(10, 0, 0, 0)));
    shifts.add(new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(8, 30, 0, 0), End_Time__c = Time.newInstance(10, 0, 0, 0)));
    // Fascia 2: 11:20 - 14:00 (x2)
    shifts.add(new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(11, 20, 0, 0), End_Time__c = Time.newInstance(14, 0, 0, 0)));
    shifts.add(new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(11, 20, 0, 0), End_Time__c = Time.newInstance(14, 0, 0, 0)));
    // Fascia 3: 14:00 - 17:00 (x2)
    shifts.add(new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(14, 0, 0, 0), End_Time__c = Time.newInstance(17, 0, 0, 0)));
    shifts.add(new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(14, 0, 0, 0), End_Time__c = Time.newInstance(17, 0, 0, 0)));
}
insert shifts;

System.debug('Creati ' + sessions.size() + ' booth e ' + shifts.size() + ' shift');
for (Session__c s : sessions) {
    System.debug('  ✅ ' + s.Name + ' (Id: ' + s.Id + ')');
}
