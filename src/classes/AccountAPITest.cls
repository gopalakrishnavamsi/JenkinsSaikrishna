@IsTest
private class AccountAPITest {

	@IsTest
	static void test_getError() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			HttpResponse r1 = new HttpResponse();
			r1.setStatusCode(200);
			r1.setStatus('OK');
			r1.setHeader('Content-Type', 'application/json');
			r1.setBody('{"some":"value"}');
			HttpResponse r2 = new HttpResponse();
			r2.setStatusCode(400);
			r2.setStatus('BAD_REQUEST');
			r2.setHeader('Content-Type', 'application/json');
			r2.setBody('{"errorCode":"SOME_ERROR","message":"Some error"}');
			HttpResponse r3 = new HttpResponse();
			r3.setStatusCode(400);
			r3.setStatus('BAD_REQUEST');
			r3.setHeader('Content-Type', 'application/json');
			r3.setBody('{"errorCode":"USER_ALREADY_EXISTS_IN_ACCOUNT","message":"User already exists in account"}');
			HttpResponse r4 = new HttpResponse();
			r4.setStatusCode(400);
			r4.setStatus('BAD_REQUEST');
			r4.setHeader('Content-Type', 'application/json');
			r4.setBody('{"errorCode":"USER_DOES_NOT_EXIST_IN_SYSTEM","message":"User does not exist"}');
			HttpResponse r5 = new HttpResponse();
			r5.setStatusCode(400);
			r5.setStatus('BAD_REQUEST');
			r5.setHeader('Content-Type', 'application/json');
			r5.setBody('{"errorCode":"INVALID_USERID","message":"Invalid user ID"}');

			Test.startTest();
			APIError e1 = client.getError(r1);
			APIError e2 = client.getError(r2);
			APIError e3 = client.getError(r3);
			APIError e4 = client.getError(r4);
			APIError e5 = client.getError(r5);
			Test.stopTest();

			System.assertEquals(APIError.none, e1);

			System.assertNotEquals(null, e2);
			System.assert(e2 instanceof DocuSignAPI.Error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, e2.code);
			System.assertEquals('Some error', e2.description);
			System.assertEquals('SOME_ERROR', ((DocuSignAPI.Error)e2).docuSignCode);

			System.assertNotEquals(null, e3);
			System.assert(!(e3 instanceof DocuSignAPI.Error));
			System.assertEquals(APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT, e3.code);
			System.assertEquals('User already exists in account', e3.description);

			System.assertNotEquals(null, e4);
			System.assert(!(e4 instanceof DocuSignAPI.Error));
			System.assertEquals(APIErrorCode.UNKNOWN_USER, e4.code);
			System.assertEquals('User does not exist', e4.description);

			System.assertNotEquals(null, e5);
			System.assert(!(e5 instanceof DocuSignAPI.Error));
			System.assertEquals(APIErrorCode.UNKNOWN_USER, e5.code);
			System.assertEquals('Invalid user ID', e5.description);
		}
	}

	@IsTest
	static void test_stringToConnectPermission() {
		Test.startTest();
		System.assertEquals(Account.ConnectPermission.None, AccountAPI.stringToConnectPermission(null));
		System.assertEquals(Account.ConnectPermission.None, AccountAPI.stringToConnectPermission(''));
		System.assertEquals(Account.ConnectPermission.None, AccountAPI.stringToConnectPermission('  '));
		System.assertEquals(Account.ConnectPermission.None, AccountAPI.stringToConnectPermission('NONE'));
		System.assertEquals(Account.ConnectPermission.None, AccountAPI.stringToConnectPermission('none'));
		System.assertEquals(Account.ConnectPermission.None, AccountAPI.stringToConnectPermission('whatever'));
		System.assertEquals(Account.ConnectPermission.Full, AccountAPI.stringToConnectPermission('Full'));
		System.assertEquals(Account.ConnectPermission.SendOnly, AccountAPI.stringToConnectPermission('SendOnly'));
		Test.stopTest();
	}

	@IsTest
	static void test_getAccount_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			Account a = client.getAccount();
			// Second call should be cached
			Account a2 = client.getAccount();
			Test.stopTest();

			System.assert(a === a2);
			System.assertNotEquals(null, a);
			System.assertNotEquals(null, a.plan);
			System.assertNotEquals(null, a.billing);
			System.assertEquals(UUID.fromString('67db8eaa-8e05-486b-a146-8cb2b93d1aa4'), a.id);
			System.assertEquals('DocuSign', a.name);
			System.assertNotEquals(null, a.plan.id);
			System.assertEquals('DEVCENTER_DEMO_APRIL2013', a.plan.name);
			System.assertEquals(Date.newInstance(2017, 1, 5), a.plan.startDate);
			System.assertEquals(Date.newInstance(2018, 1, 5), a.plan.endDate);
			System.assertEquals(Date.newInstance(2017, 1, 5), a.billing.startDate);
			System.assertEquals(Date.newInstance(2017, 2, 5), a.billing.endDate);
			System.assertEquals(Account.ConnectPermission.Full, a.connect);
		}
	}

	@IsTest
	static void test_getAccount_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getAccount();
				throw new AssertException('Expected getAccount to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(400, ex.error.code);
			System.assertEquals('don\'t do that', ex.error.description);
		}
	}

	private class TrialExpiredMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			if (request.getEndpoint().endsWith('/billing_plan')) {
				response.setBody('{"billingPlan": {"planId": "' + String.valueOf(Environment.TRIAL_PLAN_ID) + '","planName": "DocuSign for Salesforce 30 Day Expire","paymentCycle": "annually","paymentMethod": "free_trial","perSeatPrice": "$0.00","otherDiscountPercent": "0.00","supportIncidentFee": "$0.00","supportPlanFee": "$0.00","includedSeats": "1","enableSupport": "false","currencyCode": "USD","planClassification": "partner","seatDiscounts": [{"beginSeatCount": "0","endSeatCount": "0","discountPercent": "0.00"}]},"successorPlans": [],"billingAddress": {"phone": "+1 5105555555","firstName": "Unit","lastName": "Test","email": "unit@test.com"},"billingAddressIsCreditCardAddress": "true"}');
			} else { // GET account
				response.setBody('{"currentPlanId":"' + String.valueOf(Environment.TRIAL_PLAN_ID) + '","planName":"TRIAL_30_DAY","planStartDate":"2017-01-05T17:54:37.1800000Z","planEndDate":"2018-01-05T17:54:37.1800000Z","billingPeriodStartDate":"2030-01-05T08:00:00.0000000Z","billingPeriodEndDate":"2030-02-05T08:00:00.0000000Z","billingPeriodEnvelopesSent":"4","billingPeriodEnvelopesAllowed":"unlimited","billingPeriodDaysRemaining":"0","canUpgrade":"false","canCancelRenewal":"false","envelopeSendingBlocked":"false","envelopeUnitPrice":"$0.00","suspensionStatus":"freetrialexpired","suspensionDate":"2017-02-05T17:54:37.1800000Z","accountName":"DocuSign","connectPermission":"full","docuSignLandingUrl":"http://www.docusign.com/products/sign_up/buy_now.php","distributorCode":"DEVCENTER_DEMO_APRIL2013","accountIdGuid":"67db8eaa-8e05-486b-a146-8cb2b93d1aa4","currencyCode":"USD","forgottenPasswordQuestionsCount":"1","paymentMethod":"purchase_order","seatsAllowed":"unlimited","seatsInUse":"1","createdDate":"2017-01-05T17:54:36.7770000Z","isDowngrade":"false","billingProfile":"web","allowTransactionRooms":"false"}');
			}
			return response;
		}
	}

	@IsTest
	static void test_getAccount_trial_expired() {
		Test.setMock(HttpCalloutMock.class, new TrialExpiredMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			Account result = AccountAPI.getInstance().getAccount();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isTrial);
			System.assertNotEquals(null, result.billing);
			System.assertEquals(Date.newInstance(2017, 1, 5), result.billing.startDate);
			System.assertEquals(Date.newInstance(2017, 2, 5), result.billing.endDate);
		}
	}

	@IsTest
	static void test_addPlanId_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			Account a1 = new Account(
				UUID.randomUUID(),
				1234L,
				'UNIT TEST',
				new Account.Plan(
					UUID.randomUUID(),
					'UNIT TEST PLAN',
					Date.newInstance(1, 1, 2017),
					Date.newInstance(1, 1, 2018)),
				new Account.Billing(
					Date.newInstance(7, 1, 2017),
					Date.newInstance(8, 1, 2017)),
				Account.ConnectPermission.Full,
				Environment.production);

			Test.startTest();
			Account a2 = client.addPlanId(a1, 30000);
			Test.stopTest();

			System.assertNotEquals(null, a2);
			System.assertNotEquals(null, a2.plan);
			System.assertNotEquals(null, a2.plan.id);
		}
	}

	@IsTest
	static void test_addPlanId_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			Account a1 = new Account(
				UUID.randomUUID(),
				1234L,
				'UNIT TEST',
				new Account.Plan(
					UUID.randomUUID(),
					'UNIT TEST PLAN',
					Date.newInstance(1, 1, 2017),
					Date.newInstance(1, 1, 2018)),
				new Account.Billing(
					Date.newInstance(7, 1, 2017),
					Date.newInstance(8, 1, 2017)),
				Account.ConnectPermission.Full,
				Environment.production);
			APIException ex;

			Test.startTest();
			try {
				client.addPlanId(a1, 30000);
			} catch (APIException ex1) {
				ex = ex1;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(400, ex.error.code);
		}
	}

	class AddPlanIdErrorMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"billingPlan":{"planId":""}}');
			return response;
		}
	}

	@IsTest
	static void test_addPlanId_error() {
		Test.setMock(HttpCalloutMock.class, new AddPlanIdErrorMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			UUID initialPlanId = UUID.randomUUID();
			Account a1 = new Account(
				UUID.randomUUID(),
				1234L,
				'UNIT TEST',
				new Account.Plan(
					initialPlanId,
					'UNIT TEST PLAN',
					Date.newInstance(1, 1, 2017),
					Date.newInstance(1, 1, 2018)),
				new Account.Billing(
					Date.newInstance(7, 1, 2017),
					Date.newInstance(8, 1, 2017)),
				Account.ConnectPermission.Full,
				Environment.production);

			Test.startTest();
			Account a2 = client.addPlanId(a1, 30000);
			Test.stopTest();

			System.assertNotEquals(null, a2);
			System.assert(a1 === a2); // Same reference
			System.assertNotEquals(null, a2.plan);
			System.assertEquals(initialPlanId, a2.plan.id);
		}
	}

	@IsTest
	static void test_getUserSettings_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			Url baseUrl = new Url('https://unit.test/');
			Account.Membership ua1 = new Account.Membership(1L, UUID.randomUUID(), 'Account 1', TestUtils.ID1, baseUrl, new Map<String, String>());
			Account.Membership ua2 = new Account.Membership(2L, UUID.randomUUID(), 'Account 2', TestUtils.ID2, baseUrl, new Map<String, String>());
			Account.Membership ua3 = new Account.Membership(3L, UUID.randomUUID(), 'Account 3', TestUtils.ID3, baseUrl, new Map<String, String>());

			Test.startTest();
			ua1 = ua1.withSettings(client.getUserSettings(baseUrl, 1111L, TestUtils.ID1, 30000));
			ua2 = ua2.withSettings(client.getUserSettings(baseUrl, 2222L, TestUtils.ID2, 30000));
			ua3 = ua3.withSettings(client.getUserSettings(baseUrl, 3333L, TestUtils.ID3, 30000));
			Test.stopTest();

			System.assertNotEquals(null, ua1);
			System.assertNotEquals(null, ua1.settings);
			System.assertEquals(4, ua1.settings.size());
			System.assert(ua1.getFlag('canManageAccount'));
			System.assert(ua1.getFlag('canSendEnvelope'));
			System.assert(!ua1.getFlag('apiAccountWideAccess'));
			System.assert(!ua1.getFlag('allowSendOnBehalfOf'));
			System.assert(!client.isValidAccount(ua1));

			System.assertNotEquals(null, ua2);
			System.assertNotEquals(null, ua2.settings);
			System.assertEquals(4, ua2.settings.size());
			System.assert(ua2.getFlag('canManageAccount'));
			System.assert(ua2.getFlag('canSendEnvelope'));
			System.assert(ua2.getFlag('apiAccountWideAccess'));
			System.assert(ua2.getFlag('allowSendOnBehalfOf'));
			System.assert(client.isValidAccount(ua2));

			System.assertNotEquals(null, ua3);
			System.assertNotEquals(null, ua3.settings);
			System.assertEquals(0, ua3.settings.size());
			System.assert(!ua3.getFlag('canManageAccount'));
			System.assert(!ua3.getFlag('canSendEnvelope'));
			System.assert(!ua3.getFlag('apiAccountWideAccess'));
			System.assert(!ua3.getFlag('allowSendOnBehalfOf'));
			System.assert(!client.isValidAccount(ua3));
		}
	}

	@IsTest
	static void test_getUserSettings_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getUserSettings(new Url('https://unit.test/'), 1111L, TestUtils.ID1, 30000);
				throw new AssertException('Expected getUserSettings to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(400, ex.error.code);
		}
	}

	@IsTest
	static void test_getAccountCredentials_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			Account.Credentials a = client.getAccountCredentials(TestUtils.ID2);
			Test.stopTest();

			System.assertNotEquals(null, a);
			System.assertEquals(22222222L, a.accountNumber);
			System.assertEquals('fake-password', a.apiPassword);
		}
	}

	@IsTest
	static void test_getAccountCredentials_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex;

			Test.startTest();
			try {
				client.getAccountCredentials(UUID.randomUUID());
				throw new AssertException('Expected getAccountCredentials to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals('dunno', ex.getMessage());
		}
	}

	class LoginInformationNoAccountsMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"apiPassword":"fake-password","loginAccounts":null}');
			return response;
		}
	}

	@IsTest
	static void test_getAccountCredentials_no_accounts() {
		Test.setMock(HttpCalloutMock.class, new LoginInformationNoAccountsMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			UUID accountId = UUID.randomUUID();
			TestUtils.createAccountConfiguration(accountId, accountId.toString() + '@unit.test');
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			Account.Credentials a = client.getAccountCredentials(accountId);
			Test.stopTest();

			System.assertNotEquals(null, a);
			System.assertEquals(null, a.accountNumber);
			System.assertEquals(accountId, a.accountId);
			System.assertEquals(null, a.apiPassword);
		}
	}

	@IsTest
	static void test_getValidAccounts_no_credentials() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				new AccountAPI(new Credentials(Environment.production, UUID.randomUUID(), 1234L, null, null, null,
					false, null, false))
					.getValidAccounts();
				throw new AssertException('Expected getValidAccounts to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getValidAccounts_none() {
		Test.setMock(HttpCalloutMock.class, new LoginInformationNoAccountsMock());
		TestUtils.createAccountConfiguration();
		AccountAPI client = AccountAPI.getInstance(Environment.demo, UUID.randomUUID().toString(), UUID.randomUUID().toString());

		Test.startTest();
		List<Account.Membership> result = client.getValidAccounts();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.isEmpty());
	}

	class LoginInformationSingleValidAccountMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"loginAccounts": [{"name": "Account 2 (VALID)","accountId": "22222222","accountIdGuid": "22222222-2222-2222-2222-222222222222","baseUrl": "https://www.docusign.net/restapi/v2/accounts/22222222","isDefault": "false","userName": "Account 2 User (VALID)","userId": "22222222-2222-2222-2222-222222222222","email": "user@example.com","siteDescription": "","loginAccountSettings": [{"name": "usesAPI","value": "false"}],"loginUserSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendAPIRequests","value": "false"},{"name": "canSendEnvelope","value": "true"},{"name": "allowSendOnBehalfOf","value": "true"},{"name": "apiAccountWideAccess","value": "true"},{"name": "allowRecipientLanguageSelection","value": "true"}]}],"apiPassword": "fake-password"}');
			return response;
		}
	}

	@IsTest
	static void test_getValidAccounts_single_valid() {
		Test.setMock(HttpCalloutMock.class, new LoginInformationSingleValidAccountMock());
		TestUtils.createAccountConfiguration();
		AccountAPI client = AccountAPI.getInstance(Environment.demo, UUID.randomUUID().toString(), UUID.randomUUID().toString());

		Test.startTest();
		List<Account.Membership> result = client.getValidAccounts();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(1, result.size());
		System.assertEquals(22222222L, result[0].accountNumber);
		System.assertEquals(UUID.fromString('22222222-2222-2222-2222-222222222222'), result[0].accountId);
		System.assertEquals('Account 2 (VALID)', result[0].name);
		System.assertEquals(UUID.fromString('22222222-2222-2222-2222-222222222222'), result[0].userId);
		System.assertEquals('fake-password', result[0].apiPassword);
		System.assertNotEquals(null, result[0].baseUrl);
		System.assertEquals('https://www.docusign.net/', result[0].baseUrl.toExternalForm());
		System.assertNotEquals(null, result[0].settings);
		System.assertEquals(6, result[0].settings.size());
	}

	class LoginInformationSingleInvalidAccountMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"loginAccounts": [{"name": "Account 1 (INVALID)","accountId": "11111111","accountIdGuid": "11111111-1111-1111-1111-111111111111","baseUrl": "https://www.docusign.net/restapi/v2/accounts/11111111","isDefault": "true","userName": "Account 1 User (INVALID)","userId": "11111111-1111-1111-1111-111111111111","email": "user@example.com","siteDescription": "","loginAccountSettings": [{"name": "usesAPI","value": "true"}],"loginUserSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendAPIRequests","value": "false"},{"name": "canSendEnvelope","value": "true"},{"name": "allowSendOnBehalfOf","value": "false"},{"name": "apiAccountWideAccess","value": "false"},{"name": "allowRecipientLanguageSelection","value": "true"}]}],"apiPassword": "fake-password"}');
			return response;
		}
	}

	@IsTest
	static void test_getValidAccounts_single_invalid() {
		Test.setMock(HttpCalloutMock.class, new LoginInformationSingleInvalidAccountMock());
		TestUtils.createAccountConfiguration();
		AccountAPI client = AccountAPI.getInstance(Environment.demo, UUID.randomUUID().toString(), UUID.randomUUID().toString());

		Test.startTest();
		List<Account.Membership> result = client.getValidAccounts();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.isEmpty());
	}

	class LoginInformationMultipleValidAccountMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			String endpoint = request.getEndpoint();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json');

			if (endpoint.contains('/login_information')) {
				response.setBody('{"loginAccounts": [{"name": "Account 1 (INVALID)","accountId": "11111111","accountIdGuid": "11111111-1111-1111-1111-111111111111","baseUrl": "https://www.docusign.net/restapi/v2/accounts/11111111","isDefault": "true","userName": "Account 1 User (INVALID)","userId": "11111111-1111-1111-1111-111111111111","email": "user@example.com","siteDescription": "","loginAccountSettings": [{"name": "usesAPI","value": "true"}],"loginUserSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendAPIRequests","value": "false"},{"name": "canSendEnvelope","value": "true"},{"name": "allowSendOnBehalfOf","value": "false"},{"name": "apiAccountWideAccess","value": "false"},{"name": "allowRecipientLanguageSelection","value": "true"}]},{"name": "Account 2 (VALID)","accountId": "22222222","accountIdGuid": "22222222-2222-2222-2222-222222222222","baseUrl": "https://www.docusign.net/restapi/v2/accounts/22222222","isDefault": "false","userName": "Account 2 User (VALID)","userId": "22222222-2222-2222-2222-222222222222","email": "user@example.com","siteDescription": "","loginAccountSettings": [{"name": "usesAPI","value": "false"}],"loginUserSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendAPIRequests","value": "false"},{"name": "canSendEnvelope","value": "true"},{"name": "allowSendOnBehalfOf","value": "true"},{"name": "apiAccountWideAccess","value": "true"},{"name": "allowRecipientLanguageSelection","value": "true"}]},{"name": "Account 3 (VALID)","accountId": "33333333","accountIdGuid": "33333333-3333-3333-3333-333333333333","baseUrl": "https://www.docusign.net/restapi/v2/accounts/33333333","isDefault": "false","userName": "Account 3 User (VALID)","userId": "33333333-3333-3333-3333-333333333333","email": "user@example.com","siteDescription": "","loginAccountSettings": [{"name": "usesAPI","value": "false"}],"loginUserSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendAPIRequests","value": "false"},{"name": "canSendEnvelope","value": "true"},{"name": "allowSendOnBehalfOf","value": "true"},{"name": "apiAccountWideAccess","value": "true"},{"name": "allowRecipientLanguageSelection","value": "true"}]}],"apiPassword": "fake-password"}');
			} else if (endpoint.contains(TestUtils.ID1.toString())) {
				// TestUtils.ID1 = invalid
				response.setBody('{"userSettings": [{"name": "canManageAccount","value": "false"},{"name": "canSendEnvelope","value": "true"},{"name": "apiAccountWideAccess","value": "true"},{"name": "allowSendOnBehalfOf","value": "true"}]}');
			} else if (endpoint.contains(TestUtils.ID2.toString())) {
				// TestUtils.ID2 = invalid
				response.setBody('{"userSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendEnvelope","value": "true"},{"name": "apiAccountWideAccess","value": "true"},{"name": "allowSendOnBehalfOf","value": "true"}]}');
			} else {
				// TestUtils.ID3 = valid
				response.setBody('{"userSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendEnvelope","value": "true"},{"name": "apiAccountWideAccess","value": "true"},{"name": "allowSendOnBehalfOf","value": "true"}]}');
			}

			return response;
		}
	}

	@IsTest
	static void test_getValidAccounts_multiple() {
		Test.setMock(HttpCalloutMock.class, new LoginInformationMultipleValidAccountMock());
		TestUtils.createAccountConfiguration();
		AccountAPI client = AccountAPI.getInstance(Environment.demo, UUID.randomUUID().toString(), UUID.randomUUID().toString());

		Test.startTest();
		List<Account.Membership> result = client.getValidAccounts();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(2, result.size());
	}

	@IsTest
	static void test_stringToUserStatus() {
		System.assertEquals(Account.USER_STATUS_UNKNOWN, AccountAPI.stringToUserStatus(null));
		System.assertEquals(Account.USER_STATUS_UNKNOWN, AccountAPI.stringToUserStatus(''));
		System.assertEquals(Account.USER_STATUS_UNKNOWN, AccountAPI.stringToUserStatus('\t'));
		System.assertEquals(Account.USER_STATUS_UNKNOWN, AccountAPI.stringToUserStatus('blah'));
		System.assertEquals(Account.USER_STATUS_ACTIVE, AccountAPI.stringToUserStatus('active'));
		System.assertEquals(Account.USER_STATUS_CLOSED, AccountAPI.stringToUserStatus('Closed'));
		System.assertEquals(Account.USER_STATUS_PENDING_ACTIVATION, AccountAPI.stringToUserStatus('activationSENT'));
		System.assertEquals(Account.USER_STATUS_PENDING_ACTIVATION, AccountAPI.stringToUserStatus('activationRequired'));
		System.assertEquals(Account.USER_STATUS_DISABLED, AccountAPI.stringToUserStatus('DISABLED'));
	}

	@IsTest
	static void test_userStatusToString() {
		System.assertEquals(null, AccountAPI.userStatusToString(null));
		System.assertEquals(null, AccountAPI.userStatusToString(Account.USER_STATUS_UNKNOWN));
		System.assertEquals('active', AccountAPI.userStatusToString(Account.USER_STATUS_ACTIVE));
		System.assertEquals('closed', AccountAPI.userStatusToString(Account.USER_STATUS_CLOSED));
		System.assertEquals('activationSent', AccountAPI.userStatusToString(Account.USER_STATUS_PENDING_ACTIVATION));
		System.assertEquals('disabled', AccountAPI.userStatusToString(Account.USER_STATUS_DISABLED));
	}

	@IsTest
	static void test_getConsoleViewUrl_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			Url u = client.getConsoleViewUrl();
			Test.stopTest();

			System.assertNotEquals(null, u);
			System.assertEquals('https://unit.test/view/console', u.toExternalForm());
		}
	}

	@IsTest
	static void test_getConsoleViewUrl_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getConsoleViewUrl();
				throw new AssertException('Expected getConsoleView call to fail');
			} catch (APIException ex2) {
				ex = ex2;

			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(new APIError(422, 'FAILURE'), ex.error);
		}
	}

	@IsTest
	static void test_addUsers_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = TestUtils.createUser(UserInfo.getProfileId(), u1Email, null, false);
			User u2 = TestUtils.createUser(UserInfo.getProfileId(), u2Email, null, true);
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			List<Account.User> users = client.addUsers(new List<Account.User> {
				new Account.User(TestUtils.ID1, 'user1', u1Email, 'User', 'One', 'pw1',
					Account.USER_STATUS_ACTIVE, u1.CanManageAccount__c, true, u1.Id, null),
				new Account.User(TestUtils.ID2, 'user2', u2Email, 'User', 'Two', 'pw2',
					Account.USER_STATUS_PENDING_ACTIVATION, u2.CanManageAccount__c, true, u2.Id, null)
			});
			Test.stopTest();

			System.assertNotEquals(null, users);
			System.assertEquals(2, users.size());

			System.assertNotEquals(null, users[0]);
			System.assert(!users[0].hasError);
			System.assertEquals(TestUtils.ID1, users[0].id);
			System.assertEquals('user1', users[0].username);
			System.assertEquals(u1Email, users[0].email);
			System.assertEquals('User', users[0].firstName);
			System.assertEquals('One', users[0].lastName);
			System.assertEquals('pw1', users[0].apiPassword);
			System.assertEquals(u1.Id, users[0].sourceId);
			System.assertEquals(Account.USER_STATUS_ACTIVE, users[0].status);
			System.assert(!users[0].canManageAccount);
			System.assert(users[0].canSendEnvelope);

			System.assertNotEquals(null, users[1]);
			System.assert(!users[1].hasError);
			System.assertEquals(TestUtils.ID2, users[1].id);
			System.assertEquals('user2', users[1].username);
			System.assertEquals(u2Email, users[1].email);
			System.assertEquals('User', users[1].firstName);
			System.assertEquals('Two', users[1].lastName);
			System.assertEquals('pw2', users[1].apiPassword);
			System.assertEquals(u2.Id, users[1].sourceId);
			System.assertEquals(Account.USER_STATUS_PENDING_ACTIVATION, users[1].status);
			System.assert(users[1].canManageAccount);
			System.assert(users[1].canSendEnvelope);
		}
	}

	private class UserAlreadyExistsMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"newUsers": [{"errorDetails": {"errorCode": "USER_ALREADY_EXISTS_IN_ACCOUNT","message": "User already exists"}}]}');
			return response;
		}
	}

	@IsTest
	static void test_addUsers_user_already_exists() {
		Test.setMock(HttpCalloutMock.class, new UserAlreadyExistsMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			List<Account.User> newUsers = client.addUsers(new List<Account.User> {
				new Account.User(TestUtils.ID1, 'user1', 'user1@test.com', 'User', 'One', 'fake-password',
					Account.USER_STATUS_ACTIVE, true, true, null, null)
			});
			Test.stopTest();

			System.assertNotEquals(null, newUsers);
			System.assertEquals(1, newUsers.size());
			System.assertNotEquals(null, newUsers[0]);
			System.assertNotEquals(null, newUsers[0].error);
			System.assert(newUsers[0].hasError);
			System.assertEquals(APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT, newUsers[0].error.code);
			System.assertEquals('User already exists', newUsers[0].error.description);
		}
	}

	private class UserOtherErrorMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"newUsers": [{"errorDetails": {"errorCode": "SOME_ERROR","message": "Some error"}}]}');
			return response;
		}
	}

	@IsTest
	static void test_addUsers_other_error() {
		Test.setMock(HttpCalloutMock.class, new UserOtherErrorMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			List<Account.User> newUsers = client.addUsers(new List<Account.User> {
				new Account.User(TestUtils.ID1, 'user1', 'user1@test.com', 'User', 'One', 'fake-password',
					Account.USER_STATUS_ACTIVE, true, true, null, null)
			});
			Test.stopTest();

			System.assertNotEquals(null, newUsers);
			System.assertEquals(1, newUsers.size());
			System.assertNotEquals(null, newUsers[0]);
			System.assertNotEquals(null, newUsers[0].error);
			System.assert(newUsers[0].hasError);
			System.assertEquals(APIErrorCode.BAD_REQUEST, newUsers[0].error.code);
			System.assertEquals('[SOME_ERROR] Some error', newUsers[0].error.description);
		}
	}

	@IsTest
	static void test_addUsers_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.addUsers(new List<Account.User> {
					new Account.User(UUID.randomUUID(), '', '', '', '', '',
						Account.USER_STATUS_UNKNOWN, true, true, null, null)
				});
				throw new AssertException('Expected addUsers to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(400, ex.error.code);
		}
	}

	@IsTest
	static void test_removeUsers_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			List<Account.User> users = client.removeUsers(new List<Account.User> {
				new Account.User(TestUtils.ID1, 'user1', 'user1@test.com', 'User', 'One', 'fake-password',
					Account.USER_STATUS_ACTIVE, true, true, UserInfo.getUserId(), null),
				new Account.User(TestUtils.ID2, 'user2', 'user2@test.com', 'User', 'Two', 'fake-password',
					Account.USER_STATUS_PENDING_ACTIVATION, false, true, null, null)
			});
			Test.stopTest();

			System.assertNotEquals(null, users);
			System.assertEquals(2, users.size());

			System.assertNotEquals(null, users[0]);
			System.assertEquals(TestUtils.ID1, users[0].id);
			System.assert(!users[0].hasError);

			System.assertNotEquals(null, users[1]);
			System.assertEquals(TestUtils.ID2, users[1].id);
			System.assert(!users[1].hasError);
		}
	}

	@IsTest
	static void test_removeUsers_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.removeUsers(new List<Account.User> {
					new Account.User(UUID.randomUUID(), '', '', '', '', '',
						Account.USER_STATUS_UNKNOWN, true, true, null, null)
				});
				throw new AssertException('Expected removeUsers to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(400, ex.error.code);
		}
	}

	private class UnknownUserMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"users": [{"userId":"11111111-1111-1111-1111-111111111111","errorDetails": {"errorCode": "INVALID_USERID","message": "Invalid UserId."}}]}');
			return response;
		}
	}

	@IsTest
	static void test_removeUsers_not_found() {
		Test.setMock(HttpCalloutMock.class, new UnknownUserMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			List<Account.User> users = client.removeUsers(new List<Account.User> {
				new Account.User(TestUtils.ID1, 'user1', 'user1@test.com', 'User', 'One', 'fake-password',
					Account.USER_STATUS_ACTIVE, true, true, null, null)
			});
			Test.stopTest();

			System.assertNotEquals(null, users);
			System.assertEquals(1, users.size());
			System.assertNotEquals(null, users[0]);
			System.assertNotEquals(null, users[0].error);
			System.assert(users[0].hasError);
			System.assertEquals(APIErrorCode.UNKNOWN_USER, users[0].error.code);
			System.assertEquals('Invalid UserId.', users[0].error.description);
		}
	}

	@IsTest
	static void test_createTrialAccount_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		Test.startTest();
		Account.Membership result = AccountAPI.getInstance(Environment.production)
			.createTrialAccount(new Account.Trial(
				'UNIT TEST',
				new Account.TrialUser(UUID.randomUUID().toString() + '@unit.test', 'Unit', 'Test'),
				new Account.Address(null, null, null, null, null, null, null),
				true));
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(111111L, result.accountNumber);
		System.assertEquals(TestUtils.ID1, result.accountId);
		System.assertEquals('UNIT TEST', result.name);
		System.assertEquals(TestUtils.ID2, result.userId);
		System.assertEquals('fake-password', result.apiPassword);
		System.assertNotEquals(null, result.baseUrl);
		System.assertEquals('https://unit.test.docusign.net/', result.baseUrl.toExternalForm());
	}

	@IsTest
	static void test_createTrialAccount_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.createTrialAccount(new Account.Trial(
					'UNIT TEST',
					new Account.TrialUser(UUID.randomUUID().toString() + '@unit.test', 'Unit', 'Test'),
					new Account.Address(null, null, null, null, null, null, null),
					true));
				throw new AssertException('Expected createTrialAccount to fail');
			} catch (APIException ex1) {
				ex = ex1;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals('don\'t do that', ex.getMessage());
		}
	}

	class CreateAccountErrorMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			String reqBody = request.getBody();
			response.setHeader('Content-Type', 'application/json; charset=utf-8');

			if (reqBody.contains('no_results')) {
				response.setStatusCode(200);
				response.setStatus('OK');
				response.setBody('{"newAccounts":[]}');
			} else {
				response.setStatusCode(400);
				response.setStatus('BAD_REQUEST');

				String errorMessage = 'FAIL';

				if (reqBody.contains('no_message')) {
					errorMessage = '';
				} else if (reqBody.contains('member_email_not_allowed')) {
					errorMessage = 'Member Email Not Allowed';
				} else if (reqBody.contains('member_already_exists')) {
					errorMessage = 'Member Email And User Name Already Exists';
				} else if (reqBody.contains('member_awaiting_activation')) {
					errorMessage = 'Member Email And User Name Awaiting Activation';
				}

				response.setBody('{"errorCode":"BAD_REQUEST","message":"' + errorMessage + '"}');

			}
			return response;
		}
	}

	@IsTest
	static void test_createTrialAccount_errors() {
		Test.setMock(HttpCalloutMock.class, new CreateAccountErrorMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex1, ex2, ex3, ex4, ex5;

			Test.startTest();
			Account.Membership a = client.createTrialAccount(new Account.Trial(
				'no_results',
				new Account.TrialUser(UUID.randomUUID().toString() + '@unit.test', 'Unit', 'Test'),
				new Account.Address(null, null, null, null, null, null, null),
				true));
			try {
				client.createTrialAccount(new Account.Trial(
					'UNIT TEST',
					new Account.TrialUser(UUID.randomUUID().toString() + '@unit.test', 'Unit', 'Test'),
					new Account.Address(null, null, null, null, null, null, null),
					true));
				throw new AssertException('Expected createTrialAccount to fail');
			} catch (APIException ex) {
				ex1 = ex;
			}
			try {
				client.createTrialAccount(new Account.Trial(
					'no_message',
					new Account.TrialUser(UUID.randomUUID().toString() + '@unit.test', 'Unit', 'Test'),
					new Account.Address(null, null, null, null, null, null, null),
					true));
				throw new AssertException('Expected createTrialAccount to fail');
			} catch (APIException ex) {
				ex2 = ex;
			}
			try {
				client.createTrialAccount(new Account.Trial(
					'member_email_not_allowed',
					new Account.TrialUser(UUID.randomUUID().toString() + '@unit.test', 'Unit', 'Test'),
					new Account.Address(null, null, null, null, null, null, null),
					true));
				throw new AssertException('Expected createTrialAccount to fail');
			} catch (APIException ex) {
				ex3 = ex;
			}
			try {
				client.createTrialAccount(new Account.Trial(
					'member_already_exists',
					new Account.TrialUser(UUID.randomUUID().toString() + '@unit.test', 'Unit', 'Test'),
					new Account.Address(null, null, null, null, null, null, null),
					true));
				throw new AssertException('Expected createTrialAccount to fail');
			} catch (APIException ex) {
				ex4 = ex;
			}
			try {
				client.createTrialAccount(new Account.Trial(
					'member_awaiting_activation',
					new Account.TrialUser(UUID.randomUUID().toString() + '@unit.test', 'Unit', 'Test'),
					new Account.Address(null, null, null, null, null, null, null),
					true));
				throw new AssertException('Expected createTrialAccount to fail');
			} catch (APIException ex) {
				ex5 = ex;
			}
			Test.stopTest();

			System.assertEquals(null, a);

			System.assertNotEquals(null, ex1);
			System.assertEquals('FAIL', ex1.getMessage());

			System.assertNotEquals(null, ex2);
			System.assertEquals(Label.AccountProvisioningFailed, ex2.getMessage());

			System.assertNotEquals(null, ex3);
			System.assertEquals(Label.UsernameNotAllowed, ex3.getMessage());

			System.assertNotEquals(null, ex4);
			System.assertEquals(Label.AccountAlreadyExists, ex4.getMessage());

			System.assertNotEquals(null, ex5);
			System.assertEquals(Label.ActivationRequired, ex5.getMessage());
		}
	}

	@IsTest
	static void test_getCustomFields_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			List<CustomField> cfs = client.getCustomFields();
			Test.stopTest();

			System.assertNotEquals(null, cfs);
			System.assertEquals(3, cfs.size());
			System.assertEquals('text', cfs[0].type);
			System.assert(cfs[0].isText);
			System.assert(!cfs[0].isList);
			System.assertEquals('textField1', cfs[0].name);
			System.assertEquals('textValue1', cfs[0].value);
			System.assert(!cfs[0].required);
			System.assert(cfs[0].show);
			System.assertEquals('list', cfs[2].type);
			System.assert(!cfs[2].isText);
			System.assert(cfs[2].isList);
			System.assertEquals('listField2', cfs[2].name);
			System.assertEquals('listValue2', cfs[2].value);
			System.assertEquals(new List<String> { 'listField2Item1', 'listField2Item2', 'listField2Item3' }, cfs[2].items);
			System.assert(cfs[2].required);
			System.assert(cfs[2].show);
		}
	}

	@IsTest
	static void test_getCustomFields_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex;

			Test.startTest();
			try {
				client.getCustomFields();
				throw new AssertException('Expected getCustomFields to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(422, ex.error.code);
		}
	}

	@IsTest
	static void test_getDocumentCustomFields_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			List<DocumentCustomField> customTabs = client.getDocumentCustomFields();
			Test.stopTest();

			System.assertNotEquals(null, customTabs);
			System.assertEquals(3, customTabs.size());

			System.assertNotEquals(null, customTabs[0]);
			System.assertEquals(TestUtils.ID1, customTabs[0].id);
			System.assertEquals('Field 1', customTabs[0].label);
			System.assertEquals('text', customTabs[0].type);
			System.assertEquals(null, customTabs[0].mergeField);
			System.assertEquals(new List<String> {
				'one', 'two'
			}, customTabs[0].items);
			System.assertEquals('', customTabs[0].initialValue);
			System.assertNotEquals(null, customTabs[0].options);
			System.assert(!customTabs[0].options.required);
			System.assert(!customTabs[0].options.readOnly);
			System.assert(!customTabs[0].options.shared);
			System.assert(customTabs[0].options.editable);
			System.assert(!customTabs[0].options.includeInEmail);
			System.assertNotEquals(null, customTabs[0].formatting);
			System.assertNotEquals(null, customTabs[0].formatting.font);
			System.assertEquals('default', customTabs[0].formatting.font.family);
			System.assertEquals('default', customTabs[0].formatting.font.color);
			System.assertEquals('default', customTabs[0].formatting.font.size);
			System.assert(!customTabs[0].formatting.font.bold);
			System.assert(!customTabs[0].formatting.font.italic);
			System.assert(!customTabs[0].formatting.font.underline);
			System.assert(!customTabs[0].formatting.masked);
			System.assert(!customTabs[0].formatting.fixedSize);
			System.assertNotEquals(null, customTabs[0].validation);
			System.assertEquals(null, customTabs[0].validation.maximumCharacters);
			System.assertEquals('', customTabs[0].validation.regularExpression);
			System.assertEquals('', customTabs[0].validation.errorMessage);
			System.assertEquals('Field 1 name', customTabs[0].tooltip);
			System.assertEquals('Field 1 anchor', customTabs[0].autoPlaceText);
			System.assertEquals(Datetime.newInstanceGmt(2017, 3, 13, 11, 43, 33), customTabs[0].lastModified);

			System.assertNotEquals(null, customTabs[1]);
			System.assertEquals(TestUtils.ID2, customTabs[1].id);
			System.assertEquals('Field 2', customTabs[1].label);
			System.assertEquals('email', customTabs[1].type);
			System.assertNotEquals(null, customTabs[1].mergeField);
			System.assertEquals('Opportunity.Id', customTabs[1].mergeField.path);
			System.assert(!customTabs[1].mergeField.writeback);
			System.assert(!customTabs[1].mergeField.editable);
			System.assertEquals(new List<String>(), customTabs[1].items);
			System.assertEquals('Field 2 value', customTabs[1].initialValue);
			System.assertNotEquals(null, customTabs[1].options);
			System.assert(customTabs[1].options.required);
			System.assert(customTabs[1].options.readOnly);
			System.assert(customTabs[1].options.shared);
			System.assert(customTabs[1].options.editable);
			System.assert(!customTabs[1].options.includeInEmail);
			System.assertNotEquals(null, customTabs[1].formatting);
			System.assertNotEquals(null, customTabs[1].formatting.font);
			System.assertEquals('tahoma', customTabs[1].formatting.font.family);
			System.assertEquals('brightBlue', customTabs[1].formatting.font.color);
			System.assertEquals('size24', customTabs[1].formatting.font.size);
			System.assert(customTabs[1].formatting.font.bold);
			System.assert(customTabs[1].formatting.font.italic);
			System.assert(customTabs[1].formatting.font.underline);
			System.assert(customTabs[1].formatting.masked);
			System.assert(customTabs[1].formatting.fixedSize);
			System.assertNotEquals(null, customTabs[1].validation);
			System.assertEquals(50, customTabs[1].validation.maximumCharacters);
			System.assertEquals('w+', customTabs[1].validation.regularExpression);
			System.assertEquals('You fail', customTabs[1].validation.errorMessage);
			System.assertEquals('Field 2 name', customTabs[1].tooltip);
			System.assertEquals('', customTabs[1].autoPlaceText);
			System.assertEquals(null, customTabs[1].lastModified);

			System.assertNotEquals(null, customTabs[2]);
			System.assertEquals(TestUtils.ID3, customTabs[2].id);
			System.assertEquals('Field 3', customTabs[2].label);
			System.assertEquals('something', customTabs[2].type);
			System.assertNotEquals(null, customTabs[2].mergeField);
			System.assertEquals('Account.Name', customTabs[2].mergeField.path);
			System.assert(customTabs[2].mergeField.writeback);
			System.assert(customTabs[2].mergeField.editable);
			System.assertEquals(new List<String>(), customTabs[2].items);
			System.assertEquals('', customTabs[2].initialValue);
			System.assertNotEquals(null, customTabs[2].options);
			System.assert(!customTabs[2].options.required);
			System.assert(!customTabs[2].options.readOnly);
			System.assert(!customTabs[2].options.shared);
			System.assert(customTabs[2].options.editable);
			System.assert(!customTabs[2].options.includeInEmail);
			System.assertNotEquals(null, customTabs[2].formatting);
			System.assertNotEquals(null, customTabs[2].formatting.font);
			System.assertEquals('helvetica', customTabs[2].formatting.font.family);
			System.assertEquals('gold', customTabs[2].formatting.font.color);
			System.assertEquals('size11', customTabs[2].formatting.font.size);
			System.assert(customTabs[2].formatting.font.bold);
			System.assert(!customTabs[2].formatting.font.italic);
			System.assert(!customTabs[2].formatting.font.underline);
			System.assert(!customTabs[2].formatting.masked);
			System.assert(!customTabs[2].formatting.fixedSize);
			System.assertNotEquals(null, customTabs[2].validation);
			System.assertEquals(null, customTabs[2].validation.maximumCharacters);
			System.assertEquals('', customTabs[2].validation.regularExpression);
			System.assertEquals('', customTabs[2].validation.errorMessage);
			System.assertEquals('Field 3 name', customTabs[2].tooltip);
			System.assertEquals(null, customTabs[2].lastModified);
		}
	}

	@IsTest
	static void test_getDocumentCustomFields_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getDocumentCustomFields();
				throw new AssertException('Expected getDocumentCustomFields to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(400, ex.error.code);
		}
	}

	@IsTest
	static void test_saveDocumentCustomField_success_create() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			UUID u = client.saveDocumentCustomField(new DocumentCustomField(
				null,
				'',
				'text',
				null,
				null,
				'',
				new DocumentCustomField.Options(),
				new DocumentCustomField.Formatting(),
				new DocumentCustomField.Validation(),
				'',
				'',
				null));
			Test.stopTest();

			System.assertEquals(TestUtils.ID1, u);
		}
	}

	@IsTest
	static void test_saveDocumentCustomField_success_update() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			UUID u = client.saveDocumentCustomField(new DocumentCustomField(
				TestUtils.ID2,
				'',
				'text',
				new DocumentCustomField.MergeField(
					'Account.Id',
					false,
					false),
				null,
				'',
				new DocumentCustomField.Options(),
				new DocumentCustomField.Formatting(),
				new DocumentCustomField.Validation(),
				'',
				'',
				null));
			Test.stopTest();

			System.assertEquals(TestUtils.ID2, u);
		}
	}

	@IsTest
	static void test_saveDocumentCustomField_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.saveDocumentCustomField(new DocumentCustomField(
					UUID.randomUUID(),
					'',
					'text',
					null,
					null,
					'',
					new DocumentCustomField.Options(),
					new DocumentCustomField.Formatting(),
					new DocumentCustomField.Validation(),
					'',
					'',
					null));
				throw new AssertException('Expected saveDocumentCustomField to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(400, ex.error.code);
		}
	}

	@IsTest
	static void test_deleteDocumentCustomField_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			Boolean result = client.deleteDocumentCustomField(UUID.randomUUID());
			Test.stopTest();

			System.assert(result);
		}
	}

	@IsTest
	static void test_deleteDocumentCustomField_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.deleteDocumentCustomField(UUID.randomUUID());
				throw new AssertException('Expected deleteDocumentCustomField to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(400, ex.error.code);
		}
	}
}
