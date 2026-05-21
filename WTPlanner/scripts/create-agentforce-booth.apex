Session__c s = new Session__c(
    Name = 'Agentforce',
    Session_Type__c = 'a2tJ9000000H0uYIAS',
    Location__c = 'Booth Area',
    Min_Shifts__c = 1,
    Max_Shifts__c = 2
);
insert s;

List<Shift__c> shifts = new List<Shift__c>{
    new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(8, 30, 0, 0), End_Time__c = Time.newInstance(10, 0, 0, 0)),
    new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(8, 30, 0, 0), End_Time__c = Time.newInstance(10, 0, 0, 0)),
    new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(11, 20, 0, 0), End_Time__c = Time.newInstance(14, 0, 0, 0)),
    new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(11, 20, 0, 0), End_Time__c = Time.newInstance(14, 0, 0, 0)),
    new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(14, 0, 0, 0), End_Time__c = Time.newInstance(17, 0, 0, 0)),
    new Shift__c(Session__c = s.Id, Start_Time__c = Time.newInstance(14, 0, 0, 0), End_Time__c = Time.newInstance(17, 0, 0, 0))
};
insert shifts;

System.debug('✅ Agentforce (Id: ' + s.Id + ') — ' + shifts.size() + ' shift creati');
