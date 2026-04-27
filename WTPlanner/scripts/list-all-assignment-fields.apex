// List ALL fields on Shift_Assignment__c
Schema.DescribeSObjectResult describe = Shift_Assignment__c.SObjectType.getDescribe();
Map<String, Schema.SObjectField> fields = describe.fields.getMap();

System.debug('=== ALL Shift_Assignment__c Fields ===');
List<String> fieldNames = new List<String>(fields.keySet());
fieldNames.sort();

for (String fieldName : fieldNames) {
    Schema.DescribeFieldResult fieldDescribe = fields.get(fieldName).getDescribe();
    System.debug(fieldName + ' | ' + fieldDescribe.getLabel() + ' | ' + fieldDescribe.getType());
}

System.debug('\n Total fields: ' + fields.size());
