@isTest(SeeAllData=false)
private class MocksTest
{
    private static TestMethod void callRecorderShouldRecordTheNumberOfCalls()
    {
        MockClass mock = new MockClass();
        
        System.assertEquals(0, mock.whenAdd().wasCalled().getCount(), 'SANITY -- Should start counting from zero');
        
        mock.add(1,2);
        mock.add(3,4);
        mock.add(5,6);
        
        System.assertEquals(3, mock.whenAdd().wasCalled().getCount(), 'Should have counted three calls');
    }
    
    private static TestMethod void callRecorderShouldRecordArguments()
    {
        MockClass mock = new MockClass();
        
        mock.add(1,2);
        mock.add(3,4);
        mock.add(5,6);
        
        System.assertEquals(new List<Object>{1,2}, mock.whenAdd().wasCalled().getArguments(0), 'Should have recorded the first calls arguments');
        System.assertEquals(new List<Object>{3,4}, mock.whenAdd().wasCalled().getArguments(1), 'Should have recorded the second calls arguments');
        System.assertEquals(new List<Object>{5,6}, mock.whenAdd().wasCalled().getArguments(2), 'Should have recorded the third calls arguments');
    }
    
    private static TestMethod void callRecorderShouldReturnAllArguments()
    {
        MockClass mock = new MockClass();
        
        mock.add(1,2);
        mock.add(3,4);
        mock.add(5,6);
        
        List<List<Object>> expectedArgs = new List<List<Object>>();
        expectedArgs.add(new List<Object>{1, 2});
        expectedArgs.add(new List<Object>{3, 4});
        expectedArgs.add(new List<Object>{5, 6});
        
        System.assertEquals(expectedArgs, mock.whenAdd().wasCalled().getArguments(), 'Should have returned all of the arguments');
    }
    
    private static TestMethod void methodShouldReturnSpecifiedReturnValue()
    {
		MockClass mock = new MockClass();
        
        mock.whenAdd().thenReturn(3);
        
        System.assertEquals(3, mock.add(1,2), 'Should return specified return value');
    }
    
    private static TestMethod void methodShouldThrowSpecifiedException()
    {
        MockClass mock = new MockClass();
        
        mock.whenVoidMethod().thenThrow(new TestException('TestException'));
        
        try
        {
	        mock.voidMethod();
            System.assert(false, 'Should have thrown an exception');
        }
        catch(Exception e)
        {
            System.assertEquals('TestException', e.getMessage(), 'Should have the specified exception');
        }
    }
    
    private static TestMethod void methodShouldCallSpecifiedCallback()
    {
        MockClass mock = new MockClass();
        MethodCallback callback = new MethodCallback();
        
        mock.whenVoidMethod().thenDo(callback);
        
        mock.voidMethod();
        
        System.assertEquals(1, callback.Calls, 'Should have called the specified callback');
    }
    
    private static TestMethod void methodShouldGiveArgumentsToCallback()
    {
		MockClass mock = new MockClass();
        MethodCallback callback = new MethodCallback();
        
        mock.whenAdd().thenDo(callback);
        
        mock.add(1, 2);
        
        System.assertEquals(new List<Object>{1, 2}, callback.Arguments[0], 'Should have given the callback the call arguments');
    }
    
    private static TestMethod void methodShouldReturnTheCallbackReturnValue()
    {
		MockClass mock = new MockClass();
        MethodCallback callback = new MethodCallback();
       
        callback.ReturnValue = 3;        
        mock.whenAdd().thenDo(callback);
        
        System.assertEquals(3, mock.add(3, 4), 'Should have returned the value the callback returned');
    }
    
    private static TestMethod void methodShouldAssertNotCalled()
    {
		MockClass mock = new MockClass();
        
        mock.whenVoidMethod().thenAssertNotCalled();
        
        mock.assertCalls();
        
        System.assertEquals(0, mock.whenVoidMethod().wasCalled().getCount(), 'Should have asserted that the method was not called');
    }
    
    private static TestMethod void methodShouldAssertCalls()
    {
        MockClass mock = new MockClass();
        
        mock.whenVoidMethod().thenAssertCalled(2);
        
        mock.voidMethod();
        mock.voidMethod();
        
        mock.assertCalls();
        
        System.assertEquals(2, mock.whenVoidMethod().wasCalled().getCount(), 'Should have asserted that the method was called twice');
    }
    
    private static TestMethod void methodShouldAssertCalledWithArgument()
    {
        MockClass mock = new MockClass();
        
        mock.whenSingleArg().thenAssertCalledWith(1);
        
        mock.singleArg(1);
        
        mock.assertCalls();
    }
    
    private static TestMethod void methodShouldAssertCalledWithArguments()
    {
		MockClass mock = new MockClass();
        
        mock.whenAdd().thenAssertCalledWith(new List<Object>{1, 2})
            		  .thenAssertCalledWith(new List<Object>{3, 4});
        
        mock.add(1, 2);
        mock.add(3, 4);
        
        mock.assertCalls();
        
        System.assertEquals(new List<Object>{1, 2}, mock.whenAdd().wasCalled().getArguments(0), 'Should have asserted that the method was called with the first set of arguments');
        System.assertEquals(new List<Object>{3, 4}, mock.whenAdd().wasCalled().getArguments(1), 'Should have asserted that the method was called with the second set of arguments');
    }
    
    private class MethodCallback implements Mocks.MethodListener
    {
        public Object ReturnValue {get; set;}
        public Integer Calls {get; set;}
        public List<List<Object>> Arguments {get; set;}
        
        public MethodCallback()
        {
            ReturnValue = null;
            Calls = 0;
            Arguments = new List<List<Object>>();
        }
        
        public Object execute(List<Object> args)
        {
            Calls++;
            Arguments.add(args);
            return ReturnValue;
        }
    }
    
    private class TestException extends Exception {}
    
    private class MockClass
    {
        Mocks.Method mockVoidMethod = new Mocks.Method('Class', 'voidMethod');
        Mocks.Method mockAdd = new Mocks.Method('Class', 'add');
        Mocks.Method mockSingleArg = new Mocks.Method('Class', 'singleArg');
        
        public void assertCalls()
        {
			mockVoidMethod.doAssertsNow();
            mockAdd.doAssertsNow();
        }
        
        public void voidMethod()
        {
            mockVoidMethod.call();
        }
        
        public Mocks.Method whenVoidMethod()
        {
            return mockVoidMethod;
        }
        
        public Integer add(Integer number1, Integer number2)
        {
            return (Integer)mockAdd.call(new List<Integer>{number1, number2});
        }
        
        public Mocks.Method whenAdd()
        {
            return mockAdd;
        }
        
        public void singleArg(Integer number1)
        {
            mockSingleArg.call(new List<Integer>{number1});
        }
        
        public Mocks.Method whenSingleArg()
        {
            return mockSingleArg;
        }
    }
}