public class EventBus 
{
	public class EventException extends Exception {}
	
	/**
	 * Constructs a new event to invoke a callback function.
	 * @param {EventBus.Callback} fn The callback to invoke
	 * @param {List<Object>} args The arguments to be given to the 
	 */
	public static EventBus.CallbackInvoker invoke(EventBus.Callback fn)
	{
		return new EventBus.CallbackInvoker(fn);
	}
	
	/**
	 * @class CallbackInvoker
	 * This class is used to build an argument map and event to invoke an event callback.
	 */
	public class CallbackInvoker
	{
		private EventBus.Callback fn;
		private Map<String, Object> args;
		
		public CallbackInvoker(EventBus.Callback func)
		{
			fn = func;
			args = new Map<String, Object>();
		}
		
		/**
		 * Adds an argument to the argument map to be provided to the callback function.
		 * @param {String} argName The name of the argument
		 * @param {Object} argValue The value of the argument
		 * @return {EventBus.CallbackInvoker} This method is chainable
		 */
		public EventBus.CallbackInvoker withArgument(String argName, Object argValue)
		{
			args.put(argName, argValue);
			return this;
		}
		
		/**
		 * Invokes the method with all of the arguments provided so far and returns the event
		 * used to invoke the method with.
		 * @return {EventBus.Event} The event used to invoke the callback with
		 */
		public EventBus.Event now()
		{
			EventBus.event event = new EventBus.Event('invoke', args);
			
			try
			{
				fn.call(event);
			}
			catch(Exception e)
			{
				event.registerError(e.getMessage());
			}
			
			return event;
		}
	}
	
	public interface Callback
	{
		void call(EventBus.Event event);
	}

	/**
	 * @class Event
	 * Represents a fired event.
	 * @property {String} Name The name of the event invoked
	 * @property {Map<String, Object>} Arguments The arguments passed with this invocation
	 * @property {List<String>} Errors A list of error messages caused by the listeners of this event
	 * @property {Boolean} Veto True if this event has been terminated
	 */
	public class Event
	{
		public String Name {get; private set;}
		public Map<String, Object> Arguments {get; private set;}
		public List<String> Errors {get; set;}
		public Boolean Veto {get; set;}
		
		public Event(String eventName, Map<String, Object> args)
		{
			Name = eventName;
			Arguments = args;
			Errors = new List<String>();
			Veto = false;
		}
		
		public Set<String> getArgumentNames()
		{
			return Arguments.keySet();
		}
		
		public void terminate()
		{
			Veto = true;
		}
		
		public Boolean hasErrors()
		{
			return Errors.size() >= 1;
		}
		
		public void registerError(String errorMessage)
		{
			Errors.add(errorMessage);
		}
		
		public Boolean isTerminated()
		{
			return Veto;
		}
	}
	
	public abstract class Emitter
	{   
		private List<Callback> listeners = new List<Callback>();

		public EventBus.Event fire(List<Object> args)
		{
			List<String> argNames = getArgumentNames();
			Map<String, Object> arguments = new Map<String, Object>();
			
			if(args.size() != argNames.size())
			{
				throw new EventException('Invalid number of arguments passed. Expected ' + argNames.size() + ' but got ' + args.size() + '.');
			}

			for(Integer i = 0; i < argNames.size(); i++)
			{
				arguments.put(argNames[i], args[i]);
			}

			EventBus.Event event = new EventBus.Event(getEventName(), arguments);

			for(Callback listener : listeners)
			{
				try
				{
					listener.call(event);
					if(event.isTerminated())
						break;
				}
				catch(Exception e)
				{
					event.registerError(e.getMessage());
				}
			}
			
			return event;
		}
		
		public void addListener(EventBus.Callback listener)
		{
			listeners.add(listener);
		}
		
		protected abstract List<String> getArgumentNames();
		protected abstract String getEventName();
	}

	public virtual class Observable
	{
		private Map<String, EventBus.Emitter> eventEmitters = new Map<String, EventBus.Emitter>();
		
		protected void registerEvent(EventBus.Emitter event)
		{
			eventEmitters.put(event.getEventName(), event);
		}
		
		protected void registerEvents(List<EventBus.Emitter> events)
		{
			for(EventBus.Emitter event : events)
			{
				registerEvent(event);
			}
		}
		
		public void addEventListener(String eventName, Callback fn)
		{
			EventBus.Emitter event = eventEmitters.get(eventName);
			if(event != null)
				event.addListener(fn);
		}
		
		protected EventBus.Event fireEvent(String eventName)
		{
			return fireEvent(eventName, new List<Object>());
		}
		
		protected EventBus.Event fireEvent(String eventName, List<Object> args)
		{
			EventBus.Emitter event = eventEmitters.get(eventName);
			if(event != null)
				return event.fire(args);
			
			return null;
		}
		
		public Set<String> getEvents()
		{
			return eventEmitters.keySet();
		}
		
		protected void removeEvent(String eventName)
		{
			eventEmitters.remove(eventName);
		}
	}
	
	/**
	 * @class EventBuilder
	 * Helper class to construct events for unit tests.
	 */
	public class EventBuilder
	{
		private String eventName;
		private Map<String, Object> eventArgs = new Map<String, Object>();
		
		public EventBus.EventBuilder withName(String name)
		{
			eventName = name;
			return this;
		}
		
		public EventBus.EventBuilder withArgument(String argName, Object argValue)
		{
			eventArgs.put(argName, argValue);
			return this;
		}
		
		public EventBus.Event fire()
		{
			return new EventBus.Event(eventName, eventArgs);
		}
	}
	
	/**
	 * @class MockCallback
	 * Utility class that can be used in place of a real callback on an observable event which can
	 * be used in unit tests to test an observable.
	 * @property {List<EventBus.Event>} Calls Stores every event object that this callback was called with
	 * @property {Boolean} Veto When true this callback will veto each event it is invoked with
	 * @property {Boolean} ThrowException When true this callback will throw an exception each time it is
	 *                                    invoked, the exception message is 'Test Error'.
	 */
	public class MockCallback implements EventBus.Callback
	{
		public List<EventBus.Event> Calls = new List<EventBus.Event>();
		public Boolean Veto = false;
		public Boolean ThrowException = false;

		public void call(EventBus.Event event)
		{
			Calls.add(event);
			
			if(Veto)
				event.terminate();
			
			if(ThrowException)
				throw new EventBus.EventException('Test Error');
		}
	}
}