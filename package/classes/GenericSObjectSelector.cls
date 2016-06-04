/**
 * @class GenericSObjectSelector
 * This is a generic SObject selector that can query the database for any SObject type. The selector
 * uses describe calls to build a list of SObject fields so that any query you do will return all of
 * the fields on the SObject. To use this selector just call the static method new instance passing in
 * the SObjectType of the records you want to select and then you can call the selector methods like
 * normal. For example, to select all accounts that have a hot rating then call like so:
 * 
 * 		List<Account> accounts = GenericSObjectSelector.newInstance(Account.sObjectType).selectWhere(
 * 			'Rating = \'Hot\''
 * 		);
 * 
 * This selector also has a mock class which will allow you to unit test code that needs this selector
 * without hitting the database and also allows you to assert any calls to it. For example to mock
 * the selectByIds method to return the variable records and to assert it is only called once you can
 * do:
 * 
 * 		GenericSObjectSelectorMock selector = new GenericSObjectSelectorMock();
 * 		selector.whenSelectByIds().thenReturn(records)
 * 								  .thenAssertCalled(1);
 * 
 * 		GenericSObjectSelector.setImplementation(selector);
 */
public class GenericSObjectSelector
{
	public interface API
    {
        SObject selectById(Id recordId);
        List<SObject> selectByIds(Set<Id> ids);
        List<SObject> selectWhere(String whereClause);
        List<SObject> selectAll();
    }
    
    private static GenericSObjectSelector.API implementation;
    
    public static GenericSObjectSelector.API newInstance(SObjectType sObjType)
    {
        if (implementation == null)
        	return new ServiceImplementation(sObjType);
        
        return implementation;
    }
    
    public static void setImplementation(GenericSObjectSelector.API impl)
    {
        implementation = impl;
    }
    
    public class ServiceImplementation implements API
    {
        private SObjectType sObjType;
        private DescribeSObjectResult sObjDescribe;
        private String queryBase;
        private String fields;

        public ServiceImplementation(SObjectType sObjType)
        {
            this.sObjType = sObjType;
            this.sObjDescribe = sObjType.getDescribe();
            this.queryBase = String.format(
                'SELECT {0} FROM {1}',
                new List<String>{ getFieldList(), sObjDescribe.getName() }
            );
        }

        public SObject selectById(Id recordId)
        {
            if(recordId == null)
                return null;
            
            return Database.query(queryBase + ' WHERE Id = :recordId');
        }
        
        public List<SObject> selectByIds(Set<Id> ids)
        {
            if(ids == null || ids.isEmpty())
                return new List<SObject>();
            
            return Database.query(queryBase + ' WHERE Id IN :ids');
        }
        
        public List<SObject> selectWhere(String whereClause)
        {
            if(whereClause == null || whereClause == '')
                return new List<SObject>();
            
            return Database.query(queryBase + ' WHERE ' + whereClause);
        }
        
        public List<SObject> selectAll()
        {
            return Database.query(queryBase);
        }
        
        private String getFieldList()
        {
            if(!String.isBlank(fields))
                return fields;

            String fieldList = '';
            
            Map<String, SObjectField> fieldMap = sObjDescribe.fields.getMap();
            for(String field : fieldMap.keySet())
            {
                fieldList += String.format(', {0}', new List<String>{fieldMap.get(field).getDescribe().getName()});
            }
            
            fields = fieldList.removeStart(', ');
            return fields;
        }
    }
}