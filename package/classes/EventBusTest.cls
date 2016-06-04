@isTest(SeeAllData=false)
private class EventBusTest
{
    private static TestMethod void observable_registersEvents()
    {
        TestObservable test = new TestObservable();
        System.assert(test.getEvents().contains('test1'), 'Should return the first registered event');
        System.assert(test.getEvents().contains('test2'), 'Should return the second registered event');
    }
    
    private static TestMethod void observable_firesEvents()
    {
        TestObservable test = new TestObservable();
        TestCallback fn = new TestCallback();
        
        test.addEventListener('test1', fn);
        
        test.fire('test1', new List<Object>{1,2});
        test.fire('test1', new List<Object>{3,4});
        
        System.assertEquals(2, fn.calls.size(), 'Should have called the event listener twice');
        System.assertEquals(1, fn.calls[0].Arguments.get('x'), 'Should call listener with first x argument');
        System.assertEquals(2, fn.calls[0].Arguments.get('y'), 'Should call listener with first y argument');
        
        System.assertEquals(3, fn.calls[1].Arguments.get('x'), 'Should call listener with second x argument');
        System.assertEquals(4, fn.calls[1].Arguments.get('y'), 'Should call listener with second y argument');
    }
    
    private static TestMethod void observable_canRemoveEvent()
    {
        TestObservable test = new TestObservable();
        TestCallback fn = new TestCallback();
        
        System.assertEquals(2, test.getEvents().size(), 'SANITY -- Should start with 2 registered events.');
        test.remove('test1');
        System.assertEquals(1, test.getEvents().size(), 'Should remove an event.');
        System.assert(test.getEvents().contains('test2'), 'Should remove the specified event.');
    }
    
    private static TestMethod void observable_returnsNull_whenEventDoesNotExist()
    {
        TestObservable test = new TestObservable();
        
        System.assertEquals(null, test.fire('hello'), 'Should return null.');
    }
    
    private static TestMethod void emitter_throwsExceptionWhenWrongNumberOfArgs()
    {
        TestObservable test = new TestObservable();
        TestCallback fn = new TestCallback();
        
        test.addEventListener('test1', fn);
        
        try
        {
            test.fire('test1', new List<Object>{1});
            System.assert(false, 'Expected an exception but none thrown.');
        }
        catch(EventBus.EventException e)
        {
            System.assertEquals('Invalid number of arguments passed. Expected 2 but got 1.', e.getMessage(), 'Unexpected exception message.');
        }
    }
    
    private static TestMethod void event_returnsEventNames()
    {
        TestObservable test = new TestObservable();
        TestCallback fn = new TestCallback();
        
        test.addEventListener('test1', fn);
        
        test.fire('test1', new List<Object>{1,2});
        
        Set<String> argNames = fn.calls.get(0).getArgumentNames();
        System.assertEquals(2, argNames.size(), 'Should return all of the argument names.');
        System.assert(argNames.contains('x'), 'Should return the first argument name.');
        System.assert(argNames.contains('y'), 'Should return the second argument name.');
    }
    
    private static TestMethod void event_recordsExceptions()
    {
        TestObservable test = new TestObservable();
        TestCallback fn = new TestCallback();
        fn.throwException = true;
        
        test.addEventListener('test1', fn);
        
        EventBus.Event event = test.fire('test1', new List<Object>{1,2});
        
        System.assertEquals(true, event.hasErrors(), 'Should have registered the error.');
        System.assertEquals(1, event.Errors.size(), 'Should add one error.');
        System.assertEquals('Test Error', event.Errors.get(0), 'Should save the exception message.');
    }
    
    private static TestMethod void event_canBeTerminated()
    {
        TestObservable test = new TestObservable();
        TestCallback fn = new TestCallback();
        TestCallback fn2 = new TestCallback();
        fn.vetosEvent = true;
        
        test.addEventListener('test1', fn);
        test.addEventListener('test1', fn2);
        
        EventBus.Event event = test.fire('test1', new List<Object>{1,2});
        
        System.assertEquals(true, event.isTerminated(), 'Should have registered the event as terminated.');
        System.assertEquals(0, fn2.calls.size(), 'Should not invoke any more callbacks.');
    }
    
    private static TestMethod void eventBuilder_constructusEvent()
    {
        EventBus.Event event = new EventBus.EventBuilder().withName('test')
            										      .withArgument('x', 1)
            										      .withArgument('y', 2)
            										      .fire();
        
        System.assertEquals('test', event.Name, 'Should set the event name');
        System.assertEquals(2, event.Arguments.keySet().size(), 'Should set two events');
        System.assertEquals(1, event.Arguments.get('x'), 'Should set the first argument' );
        System.assertEquals(2, event.Arguments.get('y'), 'Should set the second argument' );
    }
    
    private static TestMethod void mockCallback_recordsCalls()
    {
		TestObservable test = new TestObservable();
        EventBus.MockCallback fn = new EventBus.MockCallback();
        
        test.addEventListener('test1', fn);
        test.fire('test1', new List<Object>{1,2});
        test.fire('test1', new List<Object>{2,3});
        
        System.assertEquals(2, fn.Calls.size(), 'Should have recorded two calls');
    }
    
    private static TestMethod void mockCallback_vetosEvent()
    {
        TestObservable test = new TestObservable();
        EventBus.MockCallback fn = new EventBus.MockCallback();
        fn.Veto = true;
        
        test.addEventListener('test1', fn);
        test.fire('test1', new List<Object>{1,2});
        
        System.assert(fn.Calls.get(0).isTerminated(), 'Should veto the event');
    }
    
    private static TestMethod void mockCallback_throwsException()
    {
        TestObservable test = new TestObservable();
        EventBus.MockCallback fn = new EventBus.MockCallback();
        fn.ThrowException = true;
        
        test.addEventListener('test1', fn);
        test.fire('test1', new List<Object>{1,2});
        
        System.assert(fn.Calls.get(0).hasErrors(), 'Should throw an exception');
        System.assertEquals('Test Error', fn.Calls.get(0).Errors.get(0), 'Should throw exception with message \'Test Error\'');
    }
    
    private class TestCallback implements EventBus.Callback
    {
        public List<EventBus.Event> calls = new List<EventBus.Event>();
        public Boolean throwException = false;
        public Boolean vetosEvent = false;

        public void call(EventBus.Event event)
        {
            calls.add(event);
            
            if(vetosEvent)
            {
                event.terminate();
            }
            
            if(throwException)
            {
                throw new EventBus.EventException('Test Error');
            }
        }
    }
    
	private class TestObservable extends EventBus.Observable
    {
        public TestObservable()
        {
            registerEvents(new List<EventBus.Emitter>{
                new Test1Emitter(),
                new Test2Emitter()
            });
        }
        
        public EventBus.Event fire(String eventName)
        {
            return fireEvent(eventName);
        }
        
        public EventBus.Event fire(String eventName, List<Object> args)
        {
            return fireEvent(eventName, args);
        }
        
        public void remove(String eventName)
        {
            removeEvent(eventName);
        }
    }
    
    private class Test1Emitter extends EventBus.Emitter
    {
        protected override String getEventName() { return 'test1'; }
        protected override List<String> getArgumentNames() { return new List<String>{'x','y'}; }
    }
    
    private class Test2Emitter extends EventBus.Emitter
    {
        protected override String getEventName() { return 'test2'; }
        protected override List<String> getArgumentNames() { return new List<String>{'a','b'}; }
    }
}