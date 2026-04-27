List<String> sessionNames = new List<String>{
    'IT Service Management (ENG)', 'Insurance', 'Energy & Utility', 'Service', 'Banking'
};

List<Shift__c> toDelete = new List<Shift__c>();

for (String name : sessionNames) {
    List<Shift__c> shifts = [
        SELECT Id FROM Shift__c
        WHERE Session__r.Name = :name
        ORDER BY CreatedDate
    ];
    if (shifts.size() > 5) {
        for (Integer i = 5; i < shifts.size(); i++) {
            toDelete.add(shifts[i]);
        }
    }
}

delete toDelete;
System.debug('Deleted ' + toDelete.size() + ' excess shifts');
