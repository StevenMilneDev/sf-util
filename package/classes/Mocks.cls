/**
 * Utilities for mocking classes during unit testing.  Requires that mockable classes implements an API interface, also
 * requires a mock class to be coded.  Below is an example of a mockable class and it's mock.
 * 
 * global class ContainerClass
 * {
 * 		global interface API
 * 		{
 *  		SObject__c myMethod(Integer myArg);
 * 		}
 * 
 * 		private static ContainerClass.API impl;
 * 
 * 		global static ContainerClass.API newInstance()
 * 		{
 *			if(impl == null)
 * 			{
 *				return new Implementation();
 *			}
 * 			else
 * 			{
 *				return impl;
 *			}
 *		}
 *
 *		global static void setImplementation(ContainerClass.API newImpl)
 * 		{
 *			impl = newImpl;
 *		}
 * 
 * 		public class Implementation implements ContainerClass.API
 * 		{
 *			SObject__c myMethod(Integer myArg)
 *			{
 *				//Do something
 *				return null;
 * 			}
 *		}
 *
 *		public class MockImplementation implements ContainerClass.API
 * 		{
 * 			Mocks.Method mockMyMethod = new Mocks.Method('ContainerClass', 'myMethod');
 * 
 * 			void assertCalls()
 * 			{
 *				mockMyMethod.doAssertsNow();
 *			}
 * 
 *			SObject__c myMethod(Integer myArg)
 *			{
 *				return (SObject__c)mockMyMethod.call(new List<Integer>{myArg});
 * 			}
 *
 *			Mocks.Method whenMyMethod()
 *			{
 *				return mockMyMethod;
 * 			}
 *		}
 * }
 * 
 * The above class can now be mocked in unit tests with the following code:
 * 
 * ContainerClass.MockImplementation mock = new ContainerClass.MockImplementation();
 * ContainerClass.setImpl(mock);
 * mock.whenMyMethod().thenReturn(new SObject__c())	//Set the value that the mock method will return
 * 					  .thenAssertCalled(2)			//Assert that this method was called twice
 *                    .thenAssertCalledWith(7)		//Assert that this method was called with 7 as an argument
 *  				  .thenAssertCalledWith(28);	//Assert that this method was called with 28 as an argument as well
 * 					  .thenDo(new MethodListener()) //Call the passed in method listener at the time the mock was called
 * 
 * //Call code that you are testing
 * 
 * mock.assertCalls();	//Now tell the mock to do it's service method asserts
 */
public class Mocks
{
    /**
     * Records calls to a mocked method.  The number of calls and also the arguments that each call was passed are
     * stored.
     */
	public class MethodCallRecorder
    {
        private Integer calls = 0;
        private List<List<Object>> arguments = new List<List<Object>>();
        
        /**
         * Returns the number of times the method has been called so far.
         * @return The number of times the method has been called so far.
         */
        public Integer getCount()
        {
            return calls;
        }
        
        /**
         * Returns the parameters that were passed to the method on the specified call, where 0 was the first call.
         * @param callIndex The number of the method call.
         * @return The parameters that were passed to the method on the specified call.
         */
        public List<Object> getArguments(Integer callIndex)
        {
            return arguments.get(callIndex);
        }
        
        /**
         * Returns a list of all the parameters that have been passed to the method so far.
         * @return A list of all the parameters that have been passed to the method so far.
         */
        public List<List<Object>> getArguments()
        {
			return arguments;
        }
        
        /**
         * Records a method call event, takes a list of the parameters that were passed to the method.
         * @param args The parameters to record.
         */
        public void recordCall(List<Object> args)
        {
            calls++;
            arguments.add(args);
        }
    }
    
    /**
     * Classes that implement this interface can be passed to the mock to be executed when the mocked method was called
     * allowing asserts as the method has been called.
     */
    public interface MethodListener
    {
        Object execute(List<Object> callArguments);
    }
    
    /**
     * A mock method to be used in class mocks. This mock method can record all calls that it recieves and can also
     * perform assertions on those calls for you.  The constructor of this class requires the name of the class that
     * it lives in side and the method name, these are used to print the qualified name of the method when an assert
     * fails.
     */
    public class Method
    {
        private String serviceName;
        private String methodName;
        private Object returnValue;
        private Exception exceptionToThrow;
        private MethodCallRecorder calls;
        private MethodListener listener;
        
        private Integer assertCalls;
        private List<List<Object>> assertArgs;
        
        public Method(String serviceName, String methodName)
        {
            this.serviceName = serviceName;
            this.methodName = methodName;
            calls = new MethodCallRecorder();
            assertCalls = -1;
            assertArgs = new List<List<Object>>();
        }
        
        /**
         * Returns the methods call recorder so the caller can get access to the number of invokations and the
         * argumets of each
         */
        public MethodCallRecorder wasCalled()
        {
            return calls;
        }
        
        /**
         * Records a mock method call that takes arguments. Will return a value if the return value has been set, or
         * throws an exception if an exception has been set on the mock method. These arguments should be passed in
         * as a list.  If a listener has been registered for this method then the listener is called.
         * @param args a list of arguments that the method was called with, with the left-most paramater first.
         */
        public Object call(List<Object> args)
        {
            calls.recordCall(args);
            
            if(listener != null)
            {
                Object retValue = listener.execute(args);
                if(retValue != null)
                    return retValue;
            }
            
            if(exceptionToThrow != null)
                throw exceptionToThrow;
            
            return returnValue;
        }
        
        /**
         * Records a mock method call that takes no arguments. Will return a value if the return value has been set, or
         * throws an exception if an exception has been set on the mock method. If a listener has been registered on the
         * method then this calls it.
         */
        public Object call()
        {
            calls.recordCall(null);
            
            if(listener != null)
            {
                Object retValue = listener.execute(null);
            	if(retValue != null)
                    return retValue;
            }
            
            if(exceptionToThrow != null)
                throw exceptionToThrow;
            
            return returnValue;
        }
        
        /**
         * Sets the return value for when this method has been called.
         * @param value The value to be returned to the caller on invokation.
         */
        public Method thenReturn(Object value)
        {
            returnValue = value;
            return this;
        }
        
        /**
         * Sets the exception to throw when this method is called.
         * @param ex The exception to throw at the caller on invokation.
         */
        public Method thenThrow(Exception ex)
        {
            exceptionToThrow = ex;
            return this;
        }
        
        /**
         * Sets a callback on the method, a class that implements MethodListener can be executed at the time the
         * method is called.  A callback is provided with all of the arguments that were passed to the method and
         * any value it returns will be returned to the caller.
         * @param eventListener The class to invoke when the mock method.
         */
        public Method thenDo(MethodListener eventListener)
        {
            listener = eventListener;
            return this;
        }
        
        /**
         * Sets the method to assert that it was not called at all.  This requires that doAssertsNow() is called by
         * the end of the test to actually do the assertions.
         */
        public Method thenAssertNotCalled()
        {
            assertCalls = 0;
            return this;
        }
        
        /**
         * Sets the method to assert that it was called exactly the specified number of times, this requires that
         * doAssertsNow() is called by the end of the test to actually do the assertions.
         * @param callTimes The number of times that this method should assert that it was called.
         */
        public Method thenAssertCalled(Integer callTimes)
        {
            assertCalls = callTimes;
            return this;
        }
        
        /**
         * Instructs the method to assert that it was called with the specified parameter, this method is for one
         * parameter methods only, if the mocked method takes more than one parameter then use the list version of
         * this method.  This method requires doAssertsNow() to be called by the end of the test to actually do the
         * assertions.
         * @param arg The parameter to expect this method to be called with.
         */
        public Method thenAssertCalledWith(Object arg)
        {
            return thenAssertCalledWith(new List<Object>{arg});
        }
        
        /**
         * Instructs the method to assert that it was called with the specified parameters, the assertion will pass
         * if the method was called with exactly the same arguments as were passed in at least once.
         * @param args The list of parameters to expect this method to be called with.
         */
        public Method thenAssertCalledWith(List<Object> args)
        {
            assertArgs.add(args);
            return this;
        }
        
        /**
         * Performs any assertions that were requested for this mock method.
         */
        public void doAssertsNow()
        {
            if(assertCalls != -1)
                System.assertEquals(assertCalls, wasCalled().getCount(), getQualifiedMethodName() + ' should have been called ' + assertCalls + ' times.');
            
            if(!assertArgs.isEmpty() && assertCalls != 0)
            {
                for(List<Object> assertArgList : assertArgs)
                {
                    Boolean found = false;
                    for(List<Object> callArgs : wasCalled().getArguments())
                    {
						if(areListsEqual(assertArgList, callArgs))
                        {
                            found = true;
                            break;
                        }
                    }
                    
                    if(!found)
                        System.assert(false, getQualifiedMethodName() + ' should have been called with ' + listToString(assertArgList));
                }
            }
        }
        
        private String getQualifiedMethodName()
        {
			return serviceName + '.' + methodName;
        }
        
        private String listToString(List<Object> source)
        {
			String result = '[';
            for(Integer index = 0; index < source.size(); index++)
            {
                result = result + ' ' + index + ': ' + source[index];
            }
            result += ' ]';
            return result;
        }
        
        private Boolean areListsEqual(List<Object> listA, List<Object> listB)
        {
            if(listA.size() != listB.size())
                return false;
                
            for(Integer index = 0; index < listA.size(); index++)
            {
                if(listA[index] != listB[index])
                    return false;
            }
            
            return true;
        }
    }
}