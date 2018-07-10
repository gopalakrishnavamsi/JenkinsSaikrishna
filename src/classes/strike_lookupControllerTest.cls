/* --------------------------------------------------
Strike by Appiphony

Version: 0.9.0
Website: http://www.lightningstrike.io
GitHub: https://github.com/appiphony/Strike-Components
License: BSD 3-Clause License
-------------------------------------------------- */
@isTest
private class strike_lookupControllerTest {
    @isTest static void test_getRecentRecords() {
        Schema.Account a = new Schema.Account(Name='Test Account');
        insert a;
        
        String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'"}';
        String newJsonString = '{"searchField":"Name", "object": "NewObj", "filter": "Name = \'Test Account\'"}';
        String wrongJsonString = 'oops';

        Test.startTest();
        String responseString = strike_lookupController.getRecentRecords(jsonString, false);

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        System.assertEquals(true, response.get('isSuccess'));

        responseString = strike_lookupController.getRecentRecords(wrongJsonString, false);

        response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        results = (Map<String, Object>)response.get('results');
        System.assertEquals(false, response.get('isSuccess'));

        responseString = strike_lookupController.getRecentRecords(newJsonString, false);
        Test.stopTest();

        response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        results = (Map<String, Object>)response.get('results');
        System.assertEquals(true, response.get('isSuccess'));
    }

    @isTest static void test_getData() {
        Schema.Account a = new Schema.Account(Name='Test Account');
        insert a;

        String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'", "order": "Name", "limit": "5", "searchTerm": "Test"}';
        String wrongJsonString = 'oops';

        Test.startTest();
        String responseString = strike_lookupController.getRecords(jsonString, false);

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');

        System.assertEquals(1, data.size());

        Map<String, Object> record = (Map<String, Object>)data.get(0);

        System.assertEquals(a.Id, record.get('value'));

        responseString = strike_lookupController.getRecords(wrongJsonString, false);
        Test.stopTest();

        response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        results = (Map<String, Object>)response.get('results');
        System.assertEquals(false, response.get('isSuccess'));
    }

    @isTest static void test_getData_subtitleField() {
        Schema.Account a = new Schema.Account(Name='Test Account');
        insert a;

        String jsonString = '{"searchField":"Name", "subtitleField": "Name", "object": "Account", "filter": "Name = \'Test Account\'", "searchTerm": "Test"}';

        Test.startTest();
        String responseString = strike_lookupController.getRecords(jsonString, false);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');

        System.assertEquals(1, data.size());

        Map<String, Object> record = (Map<String, Object>)data.get(0);

        System.assertEquals(a.Id, record.get('value'));
    }

    @isTest static void test_getData_addressField() {
        Schema.Account a = new Schema.Account(
            Name='Test Account',
            BillingStreet='Test Street',
            BillingCity='Test City',
            BillingState='Test State',
            BillingCountry='Test Country',
            BillingPostalCode='Test Postal Code');
        insert a;

        String jsonString = '{"searchField":"Name", "subtitleField": "BillingAddress", "object": "Account", "filter": "Name = \'Test Account\'", "searchTerm": "Test"}';

        Test.startTest();
        String responseString = strike_lookupController.getRecords(jsonString, false);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');

        System.assertEquals(1, data.size());

        Map<String, Object> record = (Map<String, Object>)data.get(0);

        System.assertEquals(a.Id, record.get('value'));
    }

    @isTest static void test_getData_reference() {
        Schema.Account a = new Schema.Account(Name='Test Account');
        insert a;

        Contact c = new Contact(
            LastName='Contact',
            FirstName='Test',
            AccountId = a.Id);
        insert c;

        String jsonString = '{"searchField":"FirstName", "subtitleField": "Account.Name", "object": "Contact", "filter": "Name = \'Test Contact\'", "searchTerm": "Test"}';

        Test.startTest();
        String responseString = strike_lookupController.getRecords(jsonString, false);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');

        System.assertEquals(1, data.size());

        Map<String, Object> record = (Map<String, Object>)data.get(0);

        System.assertEquals(c.Id, record.get('value'));
    }

    @isTest static void test_getRecordLabel() {
        String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'"}';
        String wrongJsonString = 'oops';

        Test.startTest();
        String responseString = strike_lookupController.getRecordLabel(jsonString);

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        System.assertEquals(true, response.get('isSuccess'));

        responseString = strike_lookupController.getRecordLabel(wrongJsonString);
        Test.stopTest();

        response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        results = (Map<String, Object>)response.get('results');
        System.assertEquals(false, response.get('isSuccess'));
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