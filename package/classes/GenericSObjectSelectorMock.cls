public class GenericSObjectSelectorMock implements GenericSObjectSelector.API
{
	private Mocks.Method mockSelectById = new Mocks.Method('GenericSObjectSelector', 'selectById');
    private Mocks.Method mockSelectByIds = new Mocks.Method('GenericSObjectSelector', 'selectByIds');
    private Mocks.Method mockSelectWhere = new Mocks.Method('GenericSObjectSelector', 'selectWhere');
    private Mocks.Method mockSelectAll = new Mocks.Method('GenericSObjectSelector', 'selectAll');
    
    public void assertCalls()
    {
        mockSelectById.doAssertsNow();
        mockSelectByIds.doAssertsNow();
        mockSelectWhere.doAssertsNow();
        mockSelectAll.doAssertsNow();
    }
    
    public SObject selectById(Id recordId)
    {
        return (SObject)mockSelectById.call(new List<Object>{recordId});
    }
    
    public Mocks.Method whenSelectById()
    {
        return mockSelectById;
    }
    
    public List<SObject> selectByIds(Set<Id> ids)
    {
        return (List<SObject>)mockSelectByIds.call(new List<Object>{ids});
    }
    
    public Mocks.Method whenSelectByIds()
    {
        return mockSelectByIds;
    }
    
    public List<SObject> selectWhere(String whereClause)
    {
        return (List<SObject>)mockSelectWhere.call(new List<Object>{whereClause});
    }
    
    public Mocks.Method whenSelectWhere()
    {
        return mockSelectWhere;
    }
    
    public List<SObject> selectAll()
    {
        return (List<SObject>)mockSelectAll.call();
    }
    
    public Mocks.Method whenSelectAll()
    {
        return mockSelectAll;
    }
}