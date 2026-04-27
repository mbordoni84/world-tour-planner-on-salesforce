Id breakoutTypeId = [SELECT Id FROM Session_Type__c WHERE Name = 'Breakout' LIMIT 1].Id;

Map<String, List<Integer>> sessionTimes = new Map<String, List<Integer>>{
    'Mulesoft + Informatica' => new List<Integer>{12, 30, 13, 0},
    'Retail & Fashion' => new List<Integer>{13, 20, 13, 50},
    'Telco & Media' => new List<Integer>{14, 10, 14, 40},
    'Consumer Goods' => new List<Integer>{15, 0, 15, 30},
    'TTH' => new List<Integer>{15, 45, 16, 15}
};

List<Session__c> sessions = new List<Session__c>();
for (String name : sessionTimes.keySet()) {
    sessions.add(new Session__c(
        Name = name,
        Session_Type__c = breakoutTypeId,
        Location__c = 'B2',
        Min_Shifts__c = 2,
        Max_Shifts__c = 5,
        Description__c = 'This is the breakout session for ' + name
    ));
}
insert sessions;

List<Shift__c> shifts = new List<Shift__c>();
for (Session__c s : sessions) {
    List<Integer> times = sessionTimes.get(s.Name);
    Time startTime = Time.newInstance(times[0], times[1], 0, 0);
    Time endTime = Time.newInstance(times[2], times[3], 0, 0);
    for (Integer i = 0; i < 5; i++) {
        shifts.add(new Shift__c(
            Session__c = s.Id,
            Start_Time__c = startTime,
            End_Time__c = endTime
        ));
    }
}
insert shifts;

System.debug('Created ' + sessions.size() + ' sessions and ' + shifts.size() + ' shifts');
