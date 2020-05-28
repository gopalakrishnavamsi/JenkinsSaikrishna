@IsTest
public class LookupControllerTest {

	@IsTest
	static void test_getRecords_default() {

		Contact c = TestUtils.createContact();

		Id [] fixedSearchResults = new Id[1];
		fixedSearchResults[0] = c.Id;
		Test.setFixedSearchResults(fixedSearchResults);

		Test.startTest();
		LookupController.Response response = LookupController.getRecords('unit');
		Test.stopTest();

		System.assert(response.isSuccess);

		Map<String, Object> results = response.results;
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(1, data.size());

		Map<String, Object> record = (Map<String, Object>)data.get(0);

		System.assertEquals(c.Id, record.get('value'));
		System.assertEquals(c.Name, record.get('label'));
		System.assertEquals(c.Email, record.get('sublabel'));
	}

	@IsTest
	static void test_getData_without_subtitled() {

		Contact c = new Contact(
			FirstName = 'Test',
			LastName = 'Contact');
		insert c;

		Id [] fixedSearchResults = new Id[1];
		fixedSearchResults[0] = c.Id;
		Test.setFixedSearchResults(fixedSearchResults);

		Test.startTest();
		LookupController.Response response = LookupController.getRecords('Test');
		Test.stopTest();

		System.assert(response.isSuccess);

		Map<String, Object> results = response.results;
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(1, data.size());

		Map<String, Object> record = (Map<String, Object>)data.get(0);

		System.assertEquals(c.Id, record.get('value'));
		System.assertEquals('Test Contact', record.get('label'));
		System.assertEquals(null, record.get('sublabel'));
	}

	@IsTest
	static void test_getData_noResult() {
		Contact c = new Contact(
			FirstName = 'Test',
			LastName = 'Contact');
		insert c;

		Test.startTest();
		LookupController.Response response = LookupController.getRecords('abcd');
		Test.stopTest();

		System.assert(response.isSuccess);

		Map<String, Object> results = response.results;
		List<Object> data = (List<Object>)results.get('data');
		System.assertEquals(0, data.size());
	}

	@IsTest
	static void test_getData_failure() {
		Contact c = new Contact(
			FirstName = 'Test',
			LastName = 'Contact');
		insert c;

		Test.startTest();
		LookupController.Response response = LookupController.getRecords('');
		Test.stopTest();

		System.assert(!response.isSuccess);
		System.assertEquals(response.errMsg, Label.NoSearchResults);
	}

}