@isTest(SeeAllData=false)
private class GenericSObjectSelectorTest
{
    private static TestMethod void selector_isMockable()
    {
		GenericSObjectSelectorMock mock = new GenericSObjectSelectorMock();
        
        GenericSObjectSelector.setImplementation(mock);
        
        System.assertEquals(mock, GenericSObjectSelector.newInstance(Account.SObjectType), 'Should return mock selector');
        
        mock.whenSelectAll().thenAssertCalled(1);
        mock.whenSelectById().thenAssertCalled(1);
        mock.whenSelectByIds().thenAssertCalled(1);
        mock.whenSelectWhere().thenAssertCalled(1);
        
        mock.selectAll();
        mock.selectById(null);
        mock.selectByIds(null);
        mock.selectWhere(null);
        
        mock.assertCalls();
    }

	private static TestMethod void selectById_IdNull_doesNotQuery()
    {
        Account record = new Account(Name='Test');
        insert record;
        
        Integer queries = Limits.getQueries();
        SObject result = GenericSObjectSelector.newInstance(Account.SObjectType).selectById(null);
        
        System.assertEquals(null, result, 'Should return null when no ID provided');
        System.assertEquals(queries, Limits.getQueries(), 'Should not query the database without an ID');
    }
    
    private static TestMethod void selectById_returnsSObject()
    {
        Account record = new Account(Name='Test');
        insert record;
        
        SObject result = GenericSObjectSelector.newInstance(Account.SObjectType).selectById(record.Id);
        
        System.assertEquals(record.Id, result.Id, 'Should return the correct record');
    }
    
    private static TestMethod void selectByIds_IdsNull_doesNotQuery()
    {
        Account record1 = new Account(Name='Test1');
        Account record2 = new Account(Name='Test2');
        Account record3 = new Account(Name='Test3');
        insert new List<Account>{record1, record2, record3};
        
        Integer queries = Limits.getQueries();
        List<SObject> result = GenericSObjectSelector.newInstance(Account.SObjectType).selectByIds(
            null
        );
        
        System.assertEquals(new List<SObject>(), result, 'Should return an empty list');
        System.assertEquals(queries, Limits.getQueries(), 'Should not query the database without an ID');
    }

    private static TestMethod void selectByIds_IdsEmpty_doesNotQuery()
    {
        Account record1 = new Account(Name='Test1');
        Account record2 = new Account(Name='Test2');
        Account record3 = new Account(Name='Test3');
        insert new List<Account>{record1, record2, record3};
        
        Integer queries = Limits.getQueries();
        List<SObject> result = GenericSObjectSelector.newInstance(Account.SObjectType).selectByIds(
            new Set<Id>()
        );
        
        System.assertEquals(new List<SObject>(), result, 'Should return an empty list');
        System.assertEquals(queries, Limits.getQueries(), 'Should not query the database without an ID');
    }
    
    private static TestMethod void selectByIds_returnsSObjects()
    {
        Account record1 = new Account(Name='Test1');
        Account record2 = new Account(Name='Test2');
        Account record3 = new Account(Name='Test3');
        insert new List<Account>{record1, record2, record3};
        
        List<SObject> result = GenericSObjectSelector.newInstance(Account.SObjectType).selectByIds(
            new Set<Id>{record1.Id, record3.Id}
        );
        
        System.assertEquals(2, result.size(), 'Should return two records');
        
        Set<Id> ids = getRecordIds(result);
        System.assert(ids.contains(record1.Id), 'Should return record 1');
        System.assert(ids.contains(record3.Id), 'Should return record 3');
    }
    
    private static TestMethod void selectWhere_clauseNull_doesNotQuery()
    {
        Account record1 = new Account(Name='Test1', Rating='Hot');
        Account record2 = new Account(Name='Test2');
        Account record3 = new Account(Name='Test3', Rating='Hot');
        insert new List<Account>{record1, record2, record3};
        
        Integer queries = Limits.getQueries();
        List<SObject> result = GenericSObjectSelector.newInstance(Account.SObjectType).selectWhere(
            null
        );
        
        System.assertEquals(new List<SObject>(), result, 'Should return an empty list');
        System.assertEquals(queries, Limits.getQueries(), 'Should not query the database without a where clause');
    }
    
    private static TestMethod void selectWhere_clauseEmpty_doesNotQuery()
    {
        Account record1 = new Account(Name='Test1', Rating='Hot');
        Account record2 = new Account(Name='Test2');
        Account record3 = new Account(Name='Test3', Rating='Hot');
        insert new List<Account>{record1, record2, record3};
        
        Integer queries = Limits.getQueries();
        List<SObject> result = GenericSObjectSelector.newInstance(Account.SObjectType).selectWhere(
            ''
        );
        
        System.assertEquals(new List<SObject>(), result, 'Should return an empty list');
        System.assertEquals(queries, Limits.getQueries(), 'Should not query the database without a where clause');
    }

    private static TestMethod void selectWhere_returnsSObjects()
    {
        Account record1 = new Account(Name='Test1', Rating='Hot');
        Account record2 = new Account(Name='Test2');
        Account record3 = new Account(Name='Test3', Rating='Hot');
        insert new List<Account>{record1, record2, record3};
        
        Integer queries = Limits.getQueries();
        List<SObject> result = GenericSObjectSelector.newInstance(Account.SObjectType).selectWhere(
            'Rating = \'Hot\''
        );
        
        System.assertEquals(2, result.size(), 'Should return two records');
        
        Set<Id> ids = getRecordIds(result);
        System.assert(ids.contains(record1.Id), 'Should return record 1');
        System.assert(ids.contains(record3.Id), 'Should return record 3');
    }
    
    private static TestMethod void selectAll_returnsAllSObjects()
    {
        Account record1 = new Account(Name='Test1');
        Account record2 = new Account(Name='Test2');
        Account record3 = new Account(Name='Test3');
        insert new List<Account>{record1, record2, record3};
        
        List<SObject> result = GenericSObjectSelector.newInstance(Account.SObjectType).selectAll();
        
        System.assertEquals(3, result.size(), 'Should return all three records');
        
        Set<Id> ids = getRecordIds(result);
        System.assert(ids.contains(record1.Id), 'Should return record 1');
        System.assert(ids.contains(record2.Id), 'Should return record 2');
        System.assert(ids.contains(record3.Id), 'Should return record 3');
    }
    
    private static Set<Id> getRecordIds(List<SObject> records)
    {
        return new Map<Id, SObject>(records).keySet();
    }
}