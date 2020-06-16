@IsTest
private class OrganizationServiceTest {

	@IsTest
	static void test_getDailyApiLimit() {
		OrgLimit dailyApiLimit = OrgLimits.getMap().get(OrganizationService.KEY_DAILY_API_LIMIT);

		Test.startTest();
		OrganizationService.OrganizationLimit result = OrganizationService.getDailyApiLimit();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(dailyApiLimit.getValue(), result.current);
		System.assertEquals(dailyApiLimit.getLimit(), result.maximum);
	}

	@IsTest
	static void test_getEvents() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			insert new List<Log__c> { // 3 warnings, 1 error
				new Log__c(TransactionId__c = String.valueOf(UUID.randomUUID()), Severity__c = 'WARN'),
				new Log__c(TransactionId__c = String.valueOf(UUID.randomUUID()), Severity__c = 'WARN'),
				new Log__c(TransactionId__c = String.valueOf(UUID.randomUUID()), Severity__c = 'ERROR'),
				new Log__c(TransactionId__c = String.valueOf(UUID.randomUUID()), Severity__c = 'INFO'),
				new Log__c(TransactionId__c = String.valueOf(UUID.randomUUID()), Severity__c = 'DEBUG'),
				new Log__c(TransactionId__c = String.valueOf(UUID.randomUUID()), Severity__c = 'WARN')
			};

			Test.startTest();
			OrganizationService.OrganizationEvents result = OrganizationService.getEvents(7);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(7, result.days);
			System.assertEquals(1, result.errors);
			System.assertEquals(3, result.warnings);
		}
	}

	@IsTest
	static void test_buildOrganizationInfo() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			OrganizationService.OrganizationInfo result = OrganizationService.buildOrganizationInfo(1);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(UserInfo.getOrganizationId(), result.id);
			System.assertEquals(UserInfo.getOrganizationName(), result.name);
			System.assertEquals(Salesforce.edition, result.type);
			System.assertEquals(Salesforce.isSandbox, result.isSandbox);
			System.assertEquals(String.valueOf(Application.version), result.packageVersion);
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(s.AccountId__c, result.accountId);
			System.assertEquals(s.Environment__c, result.environment);
			System.assertNotEquals(null, result.properties);
			System.assertEquals(new Set<String> { 'dailyApiLimit', 'events' }, result.properties.keySet());
			System.assertNotEquals(null, result.properties.get('dailyApiLimit'));
			System.assertNotEquals(null, result.properties.get('events'));
		}
	}

	@IsTest
	static void test_getOrganizationInfo_unauthorized() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				OrganizationService.getOrganizationInfo();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getOrganizationInfo_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			RestContext.request = new RestRequest();
			RestContext.request.httpMethod = 'GET';
			if (String.isNotBlank(Application.namespace)) {
				RestContext.request.requestURI = '/services/apexrest/' + Application.namespace + '/v1/org';
			} else {
				RestContext.request.requestURI = '/services/apexrest/v1/org';
			}
			RestContext.request.addParameter(OrganizationService.KEY_EVENT_PERIOD_DAYS, '3');
			RestContext.response = new RestResponse();

			Test.startTest();
			OrganizationService.getOrganizationInfo();
			Test.stopTest();

			System.assertNotEquals(null, RestContext.response);
			System.assertNotEquals(null, RestContext.response.headers);
			System.assertEquals('application/json', RestContext.response.headers.get('Content-Type'));
			System.assertNotEquals(null, RestContext.response.responseBody);
			Map<String, Object> oi = (Map<String, Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());
			System.assertNotEquals(null, oi);
			System.assertEquals(UserInfo.getOrganizationId(), oi.get('id'));
			System.assertEquals(UserInfo.getOrganizationName(), oi.get('name'));
			System.assertEquals(Salesforce.edition, oi.get('type'));
			System.assertEquals(Salesforce.isSandbox, oi.get('isSandbox'));
			System.assertEquals(String.valueOf(Application.version), oi.get('packageVersion'));
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(s.AccountId__c, oi.get('accountId'));
			System.assertEquals(s.Environment__c, oi.get('environment'));
			System.assertNotEquals(null, oi.get('properties'));
			System.assertEquals(new Set<String> { 'dailyApiLimit', 'events' }, ((Map<String, Object>)oi.get('properties')).keySet());
			System.assertNotEquals(null, ((Map<String, Object>)oi.get('properties')).get('dailyApiLimit'));
			System.assertNotEquals(null, ((Map<String, Object>)oi.get('properties')).get('events'));
		}
	}
}
