// Describe Shift_Assignment__c fields
Schema.DescribeSObjectResult describe = Shift_Assignment__c.SObjectType.getDescribe();
Map<String, Schema.SObjectField> fields = describe.fields.getMap();

System.debug('=== Shift_Assignment__c Fields ===');
List<String> fieldNames = new List<String>(fields.keySet());
fieldNames.sort();

for (String fieldName : fieldNames) {
    Schema.DescribeFieldResult fieldDescribe = fields.get(fieldName).getDescribe();
    if (fieldName.contains('user') || fieldName.contains('assign') || fieldName.contains('session')) {
        System.debug('Field: ' + fieldName + ' | Label: ' + fieldDescribe.getLabel() + ' | Type: ' + fieldDescribe.getType());
    }
}

// Try to query assignment with all fields
System.debug('\n=== Sample Assignment ===');
List<Shift_Assignment__c> assignments = [SELECT Id, Name FROM Shift_Assignment__c LIMIT 1];
if (!assignments.isEmpty()) {
    System.debug('Assignment Name: ' + assignments[0].Name);
    System.debug('Assignment Id: ' + assignments[0].Id);
}
