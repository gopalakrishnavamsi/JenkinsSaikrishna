/* --------------------------------------------------
Strike by Appiphony

Version: 0.9.0
Website: http://www.lightningstrike.io
GitHub: https://github.com/appiphony/Strike-Components
License: BSD 3-Clause License
-------------------------------------------------- */
@IsTest
private class strike_lookupControllerTest {

	@IsTest
	static void test_getInvalidObject() {
		String jsonString = '{"searchField":"Name", "object": "OtherObject", "filter": "Name = \'Test Lead\'"}';

		Test.startTest();
		String result1 = strike_lookupController.getRecentRecords(jsonString, false);
		String result2 = strike_lookupController.getRecords(jsonString, false);
		String result3 = strike_lookupController.getRecordLabel(jsonString);
		Test.stopTest();

		System.assertEquals(false, ((Map<String, Object>)JSON.deserializeUntyped(result1)).get('isSuccess'));
		System.assertEquals(false, ((Map<String, Object>)JSON.deserializeUntyped(result2)).get('isSuccess'));
		System.assertEquals(false, ((Map<String, Object>)JSON.deserializeUntyped(result3)).get('isSuccess'));
	}

	@IsTest
	static void test_getRecentRecords() {
		Lead l = new Lead(
			FirstName = 'Test',
			LastName = 'Lead',
			Company = 'Test Company');
		insert l;

		String jsonString = '{"searchField":"Name", "object": "Lead", "filter": "Name = \'Test Lead\'"}';
		String newJsonString = '{"searchField":"Name", "object": "NewObj", "filter": "Name = \'Test Lead\'"}';
		String wrongJsonString = 'oops';

		Test.startTest();
		String responseString = strike_lookupController.getRecentRecords(jsonString, false);

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<String, Object> results = (Map<String, Object>)response.get('results');
		System.assertEquals(true, response.get('isSuccess'));

		responseString = strike_lookupController.getRecentRecords(wrongJsonString, false);

		response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		results = (Map<String, Object>)response.get('results');
		System.assertEquals(false, response.get('isSuccess'));

		responseString = strike_lookupController.getRecentRecords(newJsonString, false);
		Test.stopTest();

		response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		System.assertEquals(false, response.get('isSuccess'));
	}

	@IsTest
	static void test_getData() {
		Lead l = new Lead(
			FirstName = 'Test',
			LastName = 'Lead',
			Company = 'Test Company');
		insert l;

		String jsonString = '{"searchField":"Name", "object": "Lead", "filter": "Name = \'Test Lead\'", "order": "Name", "limit": "5", "searchTerm": "Test"}';
		String wrongJsonString = 'oops';

		Test.startTest();
		String responseString = strike_lookupController.getRecords(jsonString, false);

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<String, Object> results = (Map<String, Object>)response.get('results');
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(1, data.size());

		Map<String, Object> record = (Map<String, Object>)data.get(0);

		System.assertEquals(l.Id, record.get('value'));

		responseString = strike_lookupController.getRecords(wrongJsonString, false);
		Test.stopTest();

		response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		results = (Map<String, Object>)response.get('results');
		System.assertEquals(false, response.get('isSuccess'));
	}

	@IsTest
	static void test_getData_subtitleField() {
		Lead l = new Lead(
			FirstName = 'Test',
			LastName = 'Lead',
			Company = 'Test Company');
		insert l;

		String jsonString = '{"searchField":"Name", "subtitleField": "Name", "object": "Lead", "filter": "Name = \'Test Lead\'", "searchTerm": "Test"}';

		Test.startTest();
		String responseString = strike_lookupController.getRecords(jsonString, false);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<String, Object> results = (Map<String, Object>)response.get('results');
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(1, data.size());

		Map<String, Object> record = (Map<String, Object>)data.get(0);

		System.assertEquals(l.Id, record.get('value'));
	}

	@IsTest
	static void test_getData_addressField() {
		Lead l = new Lead(
			FirstName = 'Test',
			LastName = 'Lead',
			Company = 'Test Company',
			Street = 'Test Street',
			City = 'Test City',
			State = 'Test State',
			Country = 'Test Country',
			PostalCode = 'Test Postal Code');
		insert l;

		String jsonString = '{"searchField":"Name", "subtitleField": "Address", "object": "Lead", "filter": "Name = \'Test Lead\'", "searchTerm": "Test"}';

		Test.startTest();
		String responseString = strike_lookupController.getRecords(jsonString, false);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<String, Object> results = (Map<String, Object>)response.get('results');
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(1, data.size());

		Map<String, Object> record = (Map<String, Object>)data.get(0);

		System.assertEquals(l.Id, record.get('value'));
	}

	@IsTest
	static void test_getData_reference() {
		Contact c1 = new Contact(FirstName = 'Test', LastName = 'Lead');
		insert c1;

		Contact c = new Contact(
			FirstName = 'Test',
			LastName = 'Contact',
			ReportsTo = c1);
		insert c;

		String jsonString = '{"searchField":"FirstName", "subtitleField": "ReportsTo.Name", "object": "Contact", "filter": "Name = \'Test Contact\'", "searchTerm": "Test"}';

		Test.startTest();
		String responseString = strike_lookupController.getRecords(jsonString, false);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<String, Object> results = (Map<String, Object>)response.get('results');
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(1, data.size());

		Map<String, Object> record = (Map<String, Object>)data.get(0);

		System.assertEquals(c.Id, record.get('value'));
	}

	@IsTest
	static void test_getRecordLabel() {
		String jsonString = '{"searchField":"Name", "object": "Lead", "filter": "Name = \'Test Lead\'"}';
		String wrongJsonString = 'oops';

		Test.startTest();
		String responseString = strike_lookupController.getRecordLabel(jsonString);

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<String, Object> results = (Map<String, Object>)response.get('results');
		System.assertEquals(true, response.get('isSuccess'));

		responseString = strike_lookupController.getRecordLabel(wrongJsonString);
		Test.stopTest();

		response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		results = (Map<String, Object>)response.get('results');
		System.assertEquals(false, response.get('isSuccess'));
	}

	@IsTest
	static void test_getRecordsGenPreview_positive_searchByRecordId() {
		Opportunity testOpportunity = new Opportunity(Name = 'TestOpportunity', CloseDate = date.today(), StageName = 'Prospecting');
		insert testOpportunity;
		System.assertNotEquals(null, testOpportunity);
		List<Opportunity> testOpportunityList = [SELECT ID, Name FROM Opportunity LIMIT 1];
		System.assertEquals(1, testOpportunityList.size());
		System.assertEquals('TestOpportunity', testOpportunityList[0].Name);
		System.assertNotEquals(null, testOpportunityList[0].Id);
		String jsonString = '{"limit":"5","object":"Opportunity","order":"Name","searchField":"Name","recordId":"' + testOpportunityList[0].Id + '"}';

		Test.startTest();
		String responseString = strike_lookupController.getRecordsGenPreview(jsonString);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<String, Object> results = (Map<String, Object>)response.get('results');
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(1, data.size());

		Map<String, Object> record = (Map<String, Object>)data.get(0);

		System.assertEquals(testOpportunityList[0].Id, record.get('value'));
		System.assertEquals(testOpportunityList[0].Name, record.get('label'));
		System.assertEquals(true, response.get('isSuccess'));

	}

	@IsTest
	static void test_getRecordsGenPreview_positive_searchBySearchTerm() {
		Opportunity testOpportunity = new Opportunity(Name = 'TestOpportunity', CloseDate = date.today(), StageName = 'Prospecting');
		insert testOpportunity;
		System.assertNotEquals(null, testOpportunity);
		List<Opportunity> testOpportunityList = [SELECT ID, Name FROM Opportunity LIMIT 1];
		System.assertEquals(1, testOpportunityList.size());
		System.assertEquals('TestOpportunity', testOpportunityList[0].Name);
		System.assertNotEquals(null, testOpportunityList[0].Id);
		String jsonString = '{"limit":"5","object":"Opportunity","order":"Name","searchField":"Name","searchTerm":"Test"}';

		Test.startTest();
		String responseString = strike_lookupController.getRecordsGenPreview(jsonString);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		Map<String, Object> results = (Map<String, Object>)response.get('results');
		List<Object> data = (List<Object>)results.get('data');

		System.assertEquals(1, data.size());

		Map<String, Object> record = (Map<String, Object>)data.get(0);

		System.assertEquals(testOpportunityList[0].Id, record.get('value'));
		System.assertEquals(testOpportunityList[0].Name, record.get('label'));
		System.assertEquals(true, response.get('isSuccess'));
	}

	@IsTest
	static void test_getRecordsGenPreview_negative() {
		String wrongJsonString = 'oops';

		Test.startTest();
		String responseString = strike_lookupController.getRecordsGenPreview(wrongJsonString);
		Test.stopTest();

		Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
		System.assertEquals(false, response.get('isSuccess'));
		System.assertNotEquals(null, response.get('errMsg'));

	}
}
/* --------------------------------------------------
Copyright 2017 Appiphony, LLC

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the 
following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following 
disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following 
disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote 
products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------- */
