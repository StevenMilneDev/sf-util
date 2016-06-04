# sf-util
A package containing some Apex utility classes for Salesforce. Included utilities are:

* Mocking Framework
* Observable Framework
* Generic SObject Selector

## Installation
This is an unmanaged package and will count towards your org limits. The package can be installed by clicking the installation link.

| Version | Installation URL |
| --- | --- |
| 1.00 | https://login.salesforce.com/packaging/installPackage.apexp?p0=04t580000001iIn |

## Mocking Framework
The mocking framework provides classes that can help abstract other classes and services out of Unit Tests and allow you to test what parameters are passed in method invocations and how many times a method is called. Any class can be mocked so long as it implements an interface. The following class will be mocked as an example.
```
public interface API
{
	Integer add(Integer x, Integer y);
}

public class Adder implements API
{
	public Integer add(Integer x, Integer y)
	{
		return x + y;
	}
}
```
To support mocking we must add a few static methods which will abstract access to the class, the following pattern is useful:
```
private static API impl;

public static API newInstance()
{
	if(this.impl == null)
	{
		return new Adder();
	}
	else
	{
		return this.impl;
	}
}

public static void setImplementation(API impl)
{
	this.impl = impl;
}
```
Using the above methods production code can access the class like so `newInstance().add(1,2);`. Unit tests can now mock this class by using the setImplementation() method. Now we can write a mock class for this Adder like so:
```
public class MockAdder implements API
{
	private Mocks.Method mockAdd = new Mock.Method('Adder', 'add');
	
	public Integer add(Integer x, Integer y)
	{
		return (Integer)mockAdd.call(new List<Object>{x,y});
	}
	
	public Mocks.Method whenAdd()
	{
		return mockAdd;
	}
}
```
With this mock we can now record all interactions with the Adder class by using `setImplementation(new MockAdder());`. The mock method records interactions and holds many methods that can help with testing, all of the methods are chainable. The mock method has the following methods:
```
mockAdder.whenAdd().thenReturn(3)			//Sets the mock method return value
				   .thenThrow(e)			//Throws the provided exception when the method is called
				   .thenDo(callback)		//Will excecute the provided callback each time the method is called
				   .thenAssertNotCalled()	//Asserts that the method was not called
				   .thenAssertCalled(2)		//Asserts that the method was called the specified number of times
				   .thenAssertCalledWith(1)	//Asserts that the method was called with the provided arguments
```
Using this we can create a unit test for a class to ensure it calls the adder with the correct arguments like so:
```
private static TestMethod void adderIsCalled()
{
	MockAdder adder = new MockAdder();
	
	adder.whenAdd().thenReturn(3)
				   .thenAssertCalled(1)
				   .thenAssertCalledWith(new List<Object>{1,2});
	
	Adder.setImplementation(adder);
	
	MyClass.call();
	
	adder.assertCalls();	//Must invoke this at the end of the test so the mock asserts correctly
}
```

## Observable Framework
Allows Apex classes to become observable and fire events, this allows many classes to listen to each other.

## Generic SObject Selector
A selector that can query for any SObject type and return all fields.
