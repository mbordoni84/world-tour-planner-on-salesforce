Map<String, List<Integer>> sessionTimes = new Map<String, List<Integer>>{
    'IT Service Management (ENG)' => new List<Integer>{12, 30, 13, 0},
    'Insurance' => new List<Integer>{13, 20, 13, 50},
    'Energy & Utility' => new List<Integer>{14, 10, 14, 40},
    'Service' => new List<Integer>{15, 0, 15, 30},
    'Banking' => new List<Integer>{15, 45, 16, 15}
};

List<Shift__c> shifts = new List<Shift__c>();

for (String sessionName : sessionTimes.keySet()) {
    Session__c session = [SELECT Id FROM Session__c WHERE Name = :sessionName LIMIT 1];
    Integer existingCount = [SELECT COUNT() FROM Shift__c WHERE Session__c = :session.Id];

    List<Integer> times = sessionTimes.get(sessionName);
    Time startTime = Time.newInstance(times[0], times[1], 0, 0);
    Time endTime = Time.newInstance(times[2], times[3], 0, 0);

    for (Integer i = 0; i < (30 - existingCount); i++) {
        shifts.add(new Shift__c(
            Session__c = session.Id,
            Start_Time__c = startTime,
            End_Time__c = endTime
        ));
    }
}

insert shifts;
System.debug('Created ' + shifts.size() + ' shifts');
