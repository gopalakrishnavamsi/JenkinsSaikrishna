@IsTest
private class AccountServiceTest {

	@IsTest
	static void test_getAccount_unauthorized() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountService.getAccount();
				throw new AssertException('Expected getAccount to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private class ExpiredAccountMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			if (request.getEndpoint().endsWith('/billing_plan')) {
				response.setBody('{"billingPlan": {"planId": "' + String.valueOf(Environment.TRIAL_PLAN_ID) + '","planName": "DocuSign for Salesforce 30 Day Expire","paymentCycle": "annually","paymentMethod": "free_trial","perSeatPrice": "$0.00","otherDiscountPercent": "0.00","supportIncidentFee": "$0.00","supportPlanFee": "$0.00","includedSeats": "1","enableSupport": "false","currencyCode": "USD","planClassification": "partner","seatDiscounts": [{"beginSeatCount": "0","endSeatCount": "0","discountPercent": "0.00"}]},"successorPlans": [],"billingAddress": {"phone": "+1 5105555555","firstName": "Unit","lastName": "Test","email": "unit@test.com"},"billingAddressIsCreditCardAddress": "true"}');
			} else { // GET account
				response.setBody('{"currentPlanId":"' + String.valueOf(Environment.TRIAL_PLAN_ID) + '","planName":"TRIAL_30_DAY","planStartDate":"2017-01-05T17:54:37.1800000Z","planEndDate":"2018-01-05T17:54:37.1800000Z","billingPeriodStartDate":"2017-01-05T08:00:00.0000000Z","billingPeriodEndDate":"2017-02-05T08:00:00.0000000Z","billingPeriodEnvelopesSent":"4","billingPeriodEnvelopesAllowed":"unlimited","billingPeriodDaysRemaining":"0","canUpgrade":"false","canCancelRenewal":"false","envelopeSendingBlocked":"false","envelopeUnitPrice":"$0.00","suspensionStatus":"","accountName":"DocuSign","connectPermission":"full","docuSignLandingUrl":"http://www.docusign.com/products/sign_up/buy_now.php","distributorCode":"DEVCENTER_DEMO_APRIL2013","accountIdGuid":"67db8eaa-8e05-486b-a146-8cb2b93d1aa4","currencyCode":"USD","forgottenPasswordQuestionsCount":"1","paymentMethod":"purchase_order","seatsAllowed":"unlimited","seatsInUse":"1","createdDate":"2017-01-05T17:54:36.7770000Z","isDowngrade":"false","billingProfile":"web","allowTransactionRooms":"false"}');
			}
			return response;
		}
	}

	@IsTest
	static void test_getAccount_expired() {
		Test.setMock(HttpCalloutMock.class, new ExpiredAccountMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			try {
				AccountService.getAccount();
				throw new AssertException('Expected getAccount to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.TrialAccountExpired, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private class TrialAccountMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			if (request.getEndpoint().endsWith('/billing_plan')) {
				response.setBody('{"billingPlan": {"planId": "' + String.valueOf(Environment.TRIAL_PLAN_ID) + '","planName": "DocuSign for Salesforce 30 Day Expire","paymentCycle": "annually","paymentMethod": "free_trial","perSeatPrice": "$0.00","otherDiscountPercent": "0.00","supportIncidentFee": "$0.00","supportPlanFee": "$0.00","includedSeats": "1","enableSupport": "false","currencyCode": "USD","planClassification": "partner","seatDiscounts": [{"beginSeatCount": "0","endSeatCount": "0","discountPercent": "0.00"}]},"successorPlans": [],"billingAddress": {"phone": "+1 5105555555","firstName": "Unit","lastName": "Test","email": "unit@test.com"},"billingAddressIsCreditCardAddress": "true"}');
			} else { // GET account
				Datetime billingStart = Datetime.now().addDays(-1);
				Datetime billingEnd = billingStart.addDays(10);
				response.setBody('{"currentPlanId":"' + String.valueOf(Environment.TRIAL_PLAN_ID) + '","planName":"TRIAL_30_DAY","planStartDate":"2017-01-05T17:54:37.1800000Z","planEndDate":"2018-01-05T17:54:37.1800000Z","billingPeriodStartDate":' + JSON.serialize(billingStart) + ',"billingPeriodEndDate":' + JSON.serialize(billingEnd) + ',"billingPeriodEnvelopesSent":"4","billingPeriodEnvelopesAllowed":"unlimited","billingPeriodDaysRemaining":"0","canUpgrade":"false","canCancelRenewal":"false","envelopeSendingBlocked":"false","envelopeUnitPrice":"$0.00","suspensionStatus":"","accountName":"DocuSign","connectPermission":"full","docuSignLandingUrl":"http://www.docusign.com/products/sign_up/buy_now.php","distributorCode":"DEVCENTER_DEMO_APRIL2013","accountIdGuid":"67db8eaa-8e05-486b-a146-8cb2b93d1aa4","currencyCode":"USD","forgottenPasswordQuestionsCount":"1","paymentMethod":"purchase_order","seatsAllowed":"unlimited","seatsInUse":"1","createdDate":"2017-01-05T17:54:36.7770000Z","isDowngrade":"false","billingProfile":"web","allowTransactionRooms":"false"}');
			}
			return response;
		}
	}

	@IsTest
	static void test_getAccount_trial() {
		Test.setMock(HttpCalloutMock.class, new TrialAccountMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			Account result = AccountService.getAccount();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.trialStatus);
		}
	}

	@IsTest
	static void test_getAccount_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			Account result1 = AccountService.getAccount();
			Account result2 = AccountService.getAccount();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
			System.assertEquals(null, result1.trialStatus);
		}
	}

	@IsTest
	static void test_getTrialStatus() {
		Date today = Date.today();

		// Expires today
		Account account1 = new Account(UUID.randomUUID(), 1234L, 'Unit test 1',
			new Account.Plan(Environment.TRIAL_PLAN_ID, 'Plan 1', today, today),
			new Account.Billing(today, today),
			Account.ConnectPermission.Full,
			Environment.production);

		// Expires in 1 day
		Account account2 = new Account(UUID.randomUUID(), 1234L, 'Unit test 2',
			new Account.Plan(Environment.TRIAL_PLAN_ID, 'Plan 2', today, today.addDays(1)),
			new Account.Billing(today, today.addDays(1)),
			Account.ConnectPermission.Full,
			Environment.production);

		// Expires in 2 days
		Account account3 = new Account(UUID.randomUUID(), 1234L, 'Unit test 3',
			new Account.Plan(Environment.TRIAL_PLAN_ID, 'Plan 3', today, today.addDays(2)),
			new Account.Billing(today, today.addDays(2)),
			Account.ConnectPermission.Full,
			Environment.production);

		// Expired yesterday
		Account account4 = new Account(UUID.randomUUID(), 1234L, 'Unit test 4',
			new Account.Plan(Environment.TRIAL_PLAN_ID, 'Plan 4', today, today.addDays(-1)),
			new Account.Billing(today, today.addDays(-1)),
			Account.ConnectPermission.Full,
			Environment.production);

		// Expires in > 7 days
		Account account5 = new Account(UUID.randomUUID(), 1234L, 'Unit test 5',
			new Account.Plan(Environment.TRIAL_PLAN_ID, 'Plan 5', today, today.addDays(10)),
			new Account.Billing(today, today.addDays(10)),
			Account.ConnectPermission.Full,
			Environment.production);

		// Not trial plan
		Account account6 = new Account(UUID.randomUUID(), 1234L, 'Unit test 6',
			new Account.Plan(UUID.randomUUID(), 'Plan 6', today, today.addDays(-1)),
			new Account.Billing(today, today.addDays(-1)),
			Account.ConnectPermission.Full,
			Environment.production);

		Test.startTest();
		Account.TrialStatus result1 = AccountService.getTrialStatus(account1); // today
		Account.TrialStatus result2 = AccountService.getTrialStatus(account2); // 1 day
		Account.TrialStatus result3 = AccountService.getTrialStatus(account3); // 2 days
		Account.TrialStatus result4 = AccountService.getTrialStatus(account4); // expired
		Account.TrialStatus result5 = AccountService.getTrialStatus(account5); // > 7 days
		Account.TrialStatus result6 = AccountService.getTrialStatus(account6); // not trial
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.isExpired);
		System.assertEquals(Label.TrialAccountExpiresToday, result1.message);

		System.assertNotEquals(null, result2);
		System.assert(!result2.isExpired);
		System.assertEquals(Label.TrialAccountExpiresOneDay, result2.message);

		System.assertNotEquals(null, result3);
		System.assert(!result3.isExpired);
		System.assertEquals(String.format(Label.TrialAccountExpiresSoon_1, new List<String> { '2' }), result3.message);

		System.assertNotEquals(null, result4);
		System.assert(result4.isExpired);
		System.assertEquals(Label.TrialAccountExpired, result4.message);

		System.assertNotEquals(null, result5);
		System.assert(!result5.isExpired);
		System.assertEquals(null, result5.message);

		System.assertNotEquals(null, result6);
		System.assert(!result6.isExpired);
		System.assertEquals(null, result6.message);
	}

	@IsTest
	static void test_login_unauthorized() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountService.login('u@unit.test', UUID.randomUUID().toString(), Environment.Target.Production, null, null);
				throw new AssertException('Expected login to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_login_error() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountService.login('u@unit.test', UUID.randomUUID().toString(), Environment.Target.Production, null, null);
				throw new AssertException('Expected login to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.UNAUTHORIZED, ex.error.code);
				System.assertEquals('dunno', ex.error.description);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_login_invalid_environment() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountService.login('u@unit.test', UUID.randomUUID().toString(), null, null, null);
				throw new AssertException('Expected login to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_login_invalid_credentials() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.UnauthorizedMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountService.login('u@unit.test', UUID.randomUUID().toString(), Environment.Target.Demo, null, null);
				throw new AssertException('Expected login to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.InvalidUsernameOrPassword, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	class NoAccountsMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			final HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json; charset=UTF-8');
			final String reqUrl = request.getEndpoint();
			if (reqUrl.contains('/login_information')) {
				response.setStatusCode(200);
				response.setBody('{"apiPassword": "a", "loginAccounts": []}');
			}
			return response;
		}
	}

	@IsTest
	static void test_login_no_accounts() {
		Test.setMock(HttpCalloutMock.class, new NoAccountsMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountService.login('u@unit.test', UUID.randomUUID().toString(), Environment.Target.Production, null,
					null);
				throw new AssertException('Expected login to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.NoValidAccounts, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private class MultipleAccountMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			final String endpoint = request.getEndpoint();
			final HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json; charset=UTF-8');
			response.setStatusCode(200);
			if (endpoint.contains('login_information')) {
				response.setBody('{"apiPassword":"fake-password","loginAccounts":[{"name":"Account1","accountId":"1111","accountIdGuid":"11111111-1111-1111-1111-111111111111","baseUrl":"https://demo.docusign.net/restapi/v2/accounts/1111","isDefault":"false","userName":"Account1 User","userId":"11111111-1111-1111-1111-111111111111","email":"user.1@unit.test","siteDescription":"","loginUserSettings":[{"name":"canManageAccount","value":"true"},{"name":"canSendEnvelope","value":"true"},{"name":"allowSendOnBehalfOf","value":"true"},{"name":"apiAccountWideAccess","value":"true"}]},{"name":"Account2","accountId":"2222","accountIdGuid":"22222222-2222-2222-2222-222222222222","baseUrl":"https://demo.docusign.net/restapi/v2/accounts/2222","isDefault":"true","userName":"Account2 User","userId":"22222222-2222-2222-2222-222222222222","email":"user.2@unit.test","siteDescription":"","loginUserSettings":[{"name":"canManageAccount","value":"true"},{"name":"canSendEnvelope","value":"true"},{"name":"allowSendOnBehalfOf","value":"true"},{"name":"apiAccountWideAccess","value":"true"}]}]}');
			} else { // return user settings
				response.setBody('{"userSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendEnvelope","value": "true"},{"name": "locale","value": "en"},{"name": "canSendAPIRequests","value": "false"},{"name": "apiAccountWideAccess","value": "true"},{"name": "enableVaulting","value": "false"},{"name": "vaultingMode","value": "none"},{"name": "enableTransactionPoint","value": "true"},{"name": "enableSequentialSigningAPI","value": "true"},{"name": "enableSquentialSigningUI","value": "true"},{"name": "enableDSPro","value": "true"},{"name": "powerFormAdmin","value": "true"},{"name": "powerFormUser","value": "true"},{"name": "canEditSharedAddressbook","value": "share"},{"name": "canManageTemplates","value": "share"},{"name": "enableSignOnPaperOverride","value": "true"},{"name": "enableSignerAttachments","value": "true"},{"name": "allowSendOnBehalfOf","value": "true"},{"name": "allowRecipientLanguageSelection","value": "true"},{"name": "canLockEnvelopes","value": "true"},{"name": "canUseScratchpad","value": "true"},{"name": "canCreateWorkspaces","value": "true"},{"name": "allowEmailChange","value": "true"},{"name": "allowPasswordChange","value": "true"},{"name": "useAccountServerForPasswordChange","value": "false"},{"name": "federatedStatus","value": "none"},{"name": "bulksend","value": "true"},{"name": "selfSignedRecipientEmailDocument","value": "include_pdf"},{"name": "isWorkspaceParticipant","value": "false"},{"name": "allowSupplementalDocuments","value": "false"},{"name": "supplementalDocumentIncludeInDownload","value": "false"},{"name": "disableDocumentUpload","value": "false"},{"name": "disableOtherActions","value": "false"}],"signerEmailNotifications": {"envelopeActivation": "true","envelopeComplete": "true","carbonCopyNotification": "true","certifiedDeliveryNotification": "true","envelopeDeclined": "true","envelopeVoided": "true","envelopeCorrected": "true","reassignedSigner": "true","purgeDocuments": "true","faxReceived": "true","documentMarkupActivation": "true","agentNotification": "true","offlineSigningFailed": "true","whenSigningGroupMember": "true"},"senderEmailNotifications": {"envelopeComplete": "true","changedSigner": "true","senderEnvelopeDeclined": "true","withdrawnConsent": "true","recipientViewed": "true","deliveryFailed": "true","offlineSigningFailed": "true"}}');
			}
			return response;
		}
	}

	@IsTest
	static void test_login_multiple_accounts() {
		Test.setMock(HttpCalloutMock.class, new MultipleAccountMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			AccountService.LoginResult result = AccountService.login('u@unit.test', UUID.randomUUID().toString(),
				Environment.Target.Production, null, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(AccountService.LoginStatus.SelectAccount, result.status);
			System.assertNotEquals(null, result.accountOptions);
			System.assertEquals(2, result.accountOptions.size());
		}
	}

	@IsTest
	static void test_login_multiple_accounts_select_one() {
		Test.setMock(HttpCalloutMock.class, new MultipleAccountMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			AccountService.LoginResult result = AccountService.login('u@unit.test', UUID.randomUUID().toString(),
				Environment.Target.Production, null, 2222L);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(AccountService.LoginStatus.Success, result.status);
			System.assertNotEquals(null, result.accountOptions);
			System.assertEquals(1, result.accountOptions.size());
			System.assertEquals(2222L, result.accountOptions[0].accountNumber);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().BaseUrl__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().AccountId__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().Username__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().Password__c);
		}
	}

	@IsTest
	static void test_login_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			AccountService.LoginResult result = AccountService.login('u@unit.test', UUID.randomUUID().toString(),
				Environment.Target.Production, null, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(AccountService.LoginStatus.Success, result.status);
			System.assertEquals(1, result.accountOptions.size());
			System.assertEquals(22222222L, result.accountOptions[0].accountNumber);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().BaseUrl__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().AccountId__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().Username__c);
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().Password__c);
		}
	}

	private class BaseUrlMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('SUCCESS');
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"loginAccounts":[{"name":"Account 2","accountId":"22222222","accountIdGuid":"22222222-2222-2222-2222-222222222222","baseUrl":"https://unit.test.docusign.net/restapi/v2/accounts/22222222","isDefault":"false","userName":"Account 2 User (VALID)","userId":"22222222-2222-2222-2222-222222222222","email":"user@example.com","siteDescription":"","loginAccountSettings":[{"name":"usesAPI","value":"false"}],"loginUserSettings":[{"name":"canManageAccount","value":"true"},{"name":"canSendAPIRequests","value":"false"},{"name":"canSendEnvelope","value":"true"},{"name":"allowSendOnBehalfOf","value":"true"},{"name":"apiAccountWideAccess","value":"true"},{"name":"allowRecipientLanguageSelection","value":"true"}]}],"apiPassword":"fake-password"}');
			return response;
		}
	}

	@IsTest
	static void test_login_base_Url() {
		Test.setMock(HttpCalloutMock.class, new BaseUrlMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			AccountService.LoginResult result = AccountService.login('u@unit.test', UUID.randomUUID().toString(),
				Environment.Target.Other, new Url('https://unit.test.docusign.net'), null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(AccountService.LoginStatus.Success, result.status);
			System.assertEquals('https://unit.test.docusign.net/', AccountSettings__c.getOrgDefaults().BaseUrl__c);
		}
	}

	@IsTest
	static void test_connect_unauthorized() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountService.connect('u@unit.test', UUID.randomUUID().toString());
				throw new AssertException('Expected connect to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_connect() {
		Test.setMock(WebServiceMock.class, new AccountSoapAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			System.assertNotEquals(null, AccountService.connect('u@unit.test', UUID.randomUUID().toString()));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_validate_Account_Trial() {
		Account.Trial a1 = null;
		Account.Trial a2 = new Account.Trial(null, new Account.TrialUser('u@unit.test', 'Unit', 'Test', 'US', true), null);
		Account.Trial a3 = new Account.Trial('Unit Test', null, null);
		Account.Trial a4 = new Account.Trial('Unit Test', new Account.TrialUser('u@unit.test', null, null, 'US', true), null);
		Account.Trial a5 = new Account.Trial('Unit Test', new Account.TrialUser('bad-email', 'Unit', 'Test', 'US', true), null);
		Account.Trial a6 = new Account.Trial('Unit Test', new Account.TrialUser('u@unit.test', 'Unit', 'Test', null, true), null);
		Account.Trial a7 = new Account.Trial('Unit Test', new Account.TrialUser('u@unit.test', 'Unit', 'Test', 'US', true), null);
		Account.Trial a8 = new Account.Trial('Unit Test', new Account.TrialUser(null, 'Unit', 'Test', 'US', true), null);
		Account.Trial a9 = new Account.Trial('Unit Test', new Account.TrialUser('u@unit.test', 'Unit', 'Test', 'US', null), null);

		Test.startTest();
		ValidationResult result1 = AccountService.validate(a1);
		ValidationResult result2 = AccountService.validate(a2);
		ValidationResult result3 = AccountService.validate(a3);
		ValidationResult result4 = AccountService.validate(a4);
		ValidationResult result5 = AccountService.validate(a5);
		ValidationResult result6 = AccountService.validate(a6);
		ValidationResult result7 = AccountService.validate(a7);
		ValidationResult result8 = AccountService.validate(a8);
		ValidationResult result9 = AccountService.validate(a9);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.isValid);
		System.assertNotEquals(null, result1.messages);
		System.assertEquals(1, result1.messages.size());
		System.assertEquals(Label.UndefinedArgument, result1.messages[0]);

		System.assertNotEquals(null, result2);
		System.assert(!result2.isValid);
		System.assertNotEquals(null, result2.messages);
		System.assertEquals(1, result2.messages.size());
		System.assertEquals(Label.CompanyRequired, result2.messages[0]);

		System.assertNotEquals(null, result3);
		System.assert(!result3.isValid);
		System.assertNotEquals(null, result3.messages);
		System.assertEquals(4, result3.messages.size());
		System.assert(result3.messages.contains(Label.EmailRequired));
		System.assert(result3.messages.contains(Label.NameRequired));
		System.assert(result3.messages.contains(Label.UserCountryRequired));
		System.assert(result3.messages.contains(Label.MarketingPreferenceRequired));

		System.assertNotEquals(null, result4);
		System.assert(!result4.isValid);
		System.assertNotEquals(null, result4.messages);
		System.assertEquals(1, result4.messages.size());
		System.assertEquals(Label.NameRequired, result4.messages[0]);

		System.assertNotEquals(null, result5);
		System.assert(!result5.isValid);
		System.assertNotEquals(null, result5.messages);
		System.assertEquals(1, result5.messages.size());
		System.assertEquals(Label.InvalidEmail, result5.messages[0]);

		System.assertNotEquals(null, result6);
		System.assert(!result6.isValid);
		System.assertNotEquals(null, result6.messages);
		System.assertEquals(1, result6.messages.size());
		System.assertEquals(Label.UserCountryRequired, result6.messages[0]);

		System.assertNotEquals(null, result7);
		System.assert(result7.isValid);

		System.assertNotEquals(null, result8);
		System.assert(!result8.isValid);
		System.assertNotEquals(null, result8.messages);
		System.assertEquals(1, result8.messages.size());
		System.assertEquals(Label.EmailRequired, result8.messages[0]);

		System.assertNotEquals(null, result9);
		System.assert(!result9.isValid);
		System.assertNotEquals(null, result9.messages);
		System.assertEquals(1, result9.messages.size());
		System.assertEquals(Label.MarketingPreferenceRequired, result9.messages[0]);
	}

	@IsTest
	static void test_prepareTrial_unauthorized() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountService.prepareTrial('u@unit.test');
				throw new AssertException('Expected prepareTrial to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_prepareTrial_success() {
		User u = TestUtils.createDocuSignAdministrator();
		u.Phone = '5555551111';
		u.MobilePhone = '5555552222';
		u.Street = '123 Fake St';
		u.City = 'Anywhere';
		u.State = 'CA';
		u.PostalCode = '99999';
		u.Country = 'US';
		update u;

		System.runAs(u) {
			String email = UUID.randomUUID().toString() + '@unit.test';

			Test.startTest();
			AccountService.TrialAccount result = AccountService.prepareTrial(email);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!Collection.isEmpty(result.countries));
			System.assert(!Collection.isEmpty(result.marketing));
			System.assertNotEquals(null, result.account);
			System.assertEquals(UserInfo.getOrganizationName(), result.account.company);
			System.assertNotEquals(null, result.account.user);
			System.assertEquals(email, result.account.user.email);
			System.assertEquals(u.FirstName, result.account.user.firstName);
			System.assertEquals(u.LastName, result.account.user.lastName);
			System.assertEquals(StringUtils.mkName(u.FirstName, u.LastName), result.account.user.name);
			System.assertEquals(u.Country, result.account.user.countryCode);
			AccountService.Marketing marketing = result.marketing.get(u.Country);
			System.assertNotEquals(null, marketing);
			System.assertEquals(marketing.defaultOptIn, result.account.user.marketingOptIn);
			System.assertNotEquals(null, result.account.address);
			System.assertEquals(u.Street, result.account.address.address1);
			System.assertEquals(null, result.account.address.address2);
			System.assertEquals(u.City, result.account.address.city);
			System.assertEquals(u.State, result.account.address.region);
			System.assertEquals(u.PostalCode, result.account.address.postalCode);
			System.assertEquals(u.Country, result.account.address.country);
			System.assertEquals(u.Phone, result.account.address.phone);
		}
	}

	@IsTest
	static void test_createTrial_unauthorized() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountService.createTrial(null);
				throw new AssertException('Expected createTrial to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createTrial_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			try {
				Credentials.getInstance();
				throw new AssertException('Expected credentials to be uninitialized');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
			}
			Account.Trial a = new Account.Trial(
				'Unit Test',
				new Account.TrialUser('u@unit.test', 'Unit', 'Test', 'US', true),
				null);

			Test.startTest();
			Account.Membership result = AccountService.createTrial(a);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.accountId);
			System.assertNotEquals(null, result.accountNumber);
			System.assert(String.isNotBlank(result.name));
			System.assertNotEquals(null, result.baseUrl);
			System.assertNotEquals(null, result.settings);
			System.assertEquals(null, result.apiPassword);

			Credentials c = Credentials.getInstance();
			System.assertNotEquals(null, c);
			System.assert(c.isValid);
		}
	}

	@IsTest
	static void test_createTrial_failure() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Account.Trial a = new Account.Trial('Unit Test', new Account.TrialUser('u@unit.test', 'Unit', 'Test', null, false), null);

			Test.startTest();
			try {
				AccountService.createTrial(a);
				throw new AssertException('Expected createTrial to fail');
			} catch (ValidationException ex) {
				System.assertEquals(Label.InvalidTrialAccount + '\n' + Label.UserCountryRequired, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getDocuSignUrl_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			Url result = AccountService.getDocuSignUrl();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getDocuSignUrl_failure() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				AccountService.getDocuSignUrl();
				throw new AssertException('Expected getDocuSignUrl to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.UnauthorizedPageAccess, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_stringToSearchBehavior() {
		Test.startTest();
		System.assertEquals(Recipient.SearchBehavior.DiscreteMatchBeginning, AccountService.stringToSearchBehavior(null));
		System.assertEquals(Recipient.SearchBehavior.DiscreteMatchBeginning, AccountService.stringToSearchBehavior(''));
		System.assertEquals(Recipient.SearchBehavior.DiscreteMatchBeginning, AccountService.stringToSearchBehavior('\t'));
		System.assertEquals(Recipient.SearchBehavior.DiscreteMatchBeginning, AccountService.stringToSearchBehavior(' discretematchbeginning'));
		System.assertEquals(Recipient.SearchBehavior.DiscreteMatchAny, AccountService.stringToSearchBehavior('DISCRETEMATCHANY\n'));
		System.assertEquals(Recipient.SearchBehavior.DiscreteMatchExact, AccountService.stringToSearchBehavior('DiscreteMatchExact'));
		System.assertEquals(Recipient.SearchBehavior.CompoundMatchExact, AccountService.stringToSearchBehavior('CompoundMatchExact'));
		System.assertEquals(Recipient.SearchBehavior.CompoundMatchBeginning, AccountService.stringToSearchBehavior('CompoundMatchBeginning'));
		System.assertEquals(Recipient.SearchBehavior.CompoundMatchAny, AccountService.stringToSearchBehavior('CompoundMatchAny'));
		Test.stopTest();
	}

	@IsTest
	static void test_getSettings_unauthorized() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountService.getSettings();
				throw new AssertException('Expected getSettings to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSettings_success() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			AccountService.Settings result = AccountService.getSettings();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.envelope);
			System.assertNotEquals(null, result.defaultEmailLocalizations);
			System.assertNotEquals(null, result.defaultChatterLocalizations);
			System.assertNotEquals(null, result.calloutTimeout);
			System.assertNotEquals(null, result.entityResolvers);
			System.assertNotEquals(null, result.documentResolvers);
			System.assertNotEquals(null, result.recipientResolvers);
			System.assertNotEquals(null, result.recipientSearchBehavior);
		}
	}

	@IsTest
	static void test_saveSettings_unauthorized() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				AccountService.saveSettings(null);
				throw new AssertException('Expected save to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveSettings_success() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			AccountService.Settings s = new AccountService.Settings(
				EnvelopeSettings.getInstance(),
				null,
				null,
				12345,
				new List<String> { 'er1', 'er2' },
				new List<String> { 'dr1', 'dr2' },
				new List<String> { 'rr1', 'rr2' },
				Recipient.SearchBehavior.CompoundMatchBeginning);

			Test.startTest();
			AccountService.Settings result = AccountService.saveSettings(s);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!(result === s));
			System.assertNotEquals(null, result.defaultEmailLocalizations);
			System.assertNotEquals(null, result.defaultChatterLocalizations);
			System.assertEquals(12345, result.calloutTimeout);
			System.assertEquals(new List<String> { 'er1', 'er2' }, result.entityResolvers);
			System.assertEquals(new List<String> { 'dr1', 'dr2' }, result.documentResolvers);
			System.assertEquals(new List<String> { 'rr1', 'rr2' }, result.recipientResolvers);
			System.assertEquals(Recipient.SearchBehavior.CompoundMatchBeginning, result.recipientSearchBehavior);
		}
	}

	@IsTest
	static void test_getUsers_unauthorized() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountService.getUsers();
				throw new AssertException('Expected getUsers to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getUsers_success() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createDocuSignUser();
			TestUtils.createDocuSignUser();
			TestUtils.createDocuSignAdministrator();

			Test.startTest();
			List<Account.User> result = AccountService.getUsers();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.size() >= 4);
		}
	}

	class UserPartialSuccessMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');

			if (request.getMethod() == 'POST') {
				response.setBody('{"newUsers": [{"userId": "11111111-1111-1111-1111-111111111111","userName": "user1","email": "user1@unit.test","apiPassword":"pw1"},{"userId": "22222222-2222-2222-2222-222222222222","userName": "user2","email": "user2@unit.test","errorDetails": {"errorCode": "SOME_ERROR","message": "Error message"}}]}');
			} else { // DELETE
				response.setBody('{"users": [{"userId": "11111111-1111-1111-1111-111111111111","userName": "user1","email": "user1@unit.test","apiPassword":"pw1"},{"userId": "22222222-2222-2222-2222-222222222222","userName": "user2","email": "user2@unit.test","errorDetails": {"errorCode": "SOME_ERROR","message":"Error message"}}]}');
			}

			return response;
		}
	}

	class UserExistenceMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');

			if (request.getMethod() == 'POST') {
				response.setBody('{"newUsers": [{"userId": "11111111-1111-1111-1111-111111111111","userName": "user1","email": "user1@unit.test","apiPassword":"pw1"},{"userId": "22222222-2222-2222-2222-222222222222","userName": "user2","email": "user2@unit.test","errorDetails": {"errorCode": "USER_ALREADY_EXISTS_IN_ACCOUNT","message": "User already exists"}}]}');
			} else { // DELETE
				response.setBody('{"users": [{"userId": "11111111-1111-1111-1111-111111111111","userName": "user1","email": "user1@unit.test","apiPassword":"pw1"},{"userId": "22222222-2222-2222-2222-222222222222","userName": "user2","email": "user2@unit.test","apiPassword":"pw2","errorDetails": {"errorCode": "USER_DOES_NOT_EXIST_IN_SYSTEM","message": "User not found"}}]}');
			}

			return response;
		}
	}

	@IsTest
	static void test_addUsers_already_exists() {
		Test.setMock(HttpCalloutMock.class, new UserExistenceMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = TestUtils.createUser(UserInfo.getProfileId(), u1Email, null, false);
			User u2 = TestUtils.createUser(UserInfo.getProfileId(), u2Email, null, false);

			Test.startTest();
			List<Account.User> result = AccountService.addUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, u2Email, 'User', 'Two', false)
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(TestUtils.ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(TestUtils.ID1.toString(), UserSettings__c.getInstance(u1.Id).Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertEquals(TestUtils.ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(TestUtils.ID2.toString(), UserSettings__c.getInstance(u2.Id).Username__c);
		}
	}

	@IsTest
	static void test_addUsers_success_partial() {
		Test.setMock(HttpCalloutMock.class, new UserPartialSuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = TestUtils.createUser(UserInfo.getProfileId(), u1Email, null, false);
			User u2 = TestUtils.createUser(UserInfo.getProfileId(), u2Email, null, false);

			Test.startTest();
			List<Account.User> result = AccountService.addUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, u2Email, 'User', 'Two', false)
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(TestUtils.ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(TestUtils.ID1.toString(), UserSettings__c.getInstance(u1.Id).Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(result[1].hasError);
			System.assertNotEquals(null, result[1].error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, result[1].error.code);
			System.assertEquals('[SOME_ERROR] Error message', result[1].error.description);
			System.assertEquals(TestUtils.ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).Username__c);
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
			User u2 = TestUtils.createUser(UserInfo.getProfileId(), u2Email, null, false);

			Test.startTest();
			List<Account.User> result = AccountService.addUsers(new List<Account.User> {
				new Account.User(TestUtils.ID1, 'user1', u1Email, 'User', 'One', 'pw1',
					Account.USER_STATUS_ACTIVE, true, true, u1.Id, null),
				new Account.User(TestUtils.ID2, 'user2', u2Email, 'User', 'Two', 'pw2',
					Account.USER_STATUS_PENDING_ACTIVATION, false, true, u2.Id, null)
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(TestUtils.ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(TestUtils.ID1.toString(), UserSettings__c.getInstance(u1.Id).Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertEquals(TestUtils.ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(TestUtils.ID2.toString(), UserSettings__c.getInstance(u2.Id).Username__c);
		}
	}

	@IsTest
	static void test_removeUsers_self() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			User u1 = TestUtils.createUser();

			Test.startTest();
			try {
				AccountService.removeUsers(new List<Account.User> {
					new Account.User(u1.Id, 'u1', 'u1@unit.test', 'User', 'One', true),
					new Account.User(UserInfo.getUserId(), 'u2', 'u2@unit.test', 'User', 'Two', false)
				}, true);
				throw new AssertException('Expected removeUsers to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.CannotRemoveSelf, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_removeUsers_not_found() {
		Test.setMock(HttpCalloutMock.class, new UserExistenceMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = TestUtils.createUser(UserInfo.getProfileId(), u1Email, UUID.randomUUID().toString(), false);
			User u2 = TestUtils.createUser(UserInfo.getProfileId(), u2Email, UUID.randomUUID().toString(), false);
			UserSettings__c us1 = UserSettings__c.getInstance(u1.Id);
			us1.Username__c = u1.Username__c;
			us1.Password__c = UUID.randomUUID().toString();
			UserSettings__c us2 = UserSettings__c.getInstance(u2.Id);
			us2.Username__c = u2.Username__c;
			us2.Password__c = UUID.randomUUID().toString();
			insert new List<UserSettings__c> { us1, us2 };

			Test.startTest();
			List<Account.User> result = AccountService.removeUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, u2Email, 'User', 'Two', false)
			}, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(TestUtils.ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Password__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u1.Id].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertEquals(TestUtils.ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).Password__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u2.Id].Username__c);
		}
	}

	@IsTest
	static void test_removeUsers_success_partial() {
		Test.setMock(HttpCalloutMock.class, new UserPartialSuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = TestUtils.createUser(UserInfo.getProfileId(), u1Email, UUID.randomUUID().toString(), false);
			User u2 = TestUtils.createUser(UserInfo.getProfileId(), u2Email, UUID.randomUUID().toString(), false);
			UserSettings__c us1 = UserSettings__c.getInstance(u1.Id);
			us1.Username__c = u1.Username__c;
			us1.Password__c = UUID.randomUUID().toString();
			UserSettings__c us2 = UserSettings__c.getInstance(u2.Id);
			us2.Username__c = u2.Username__c;
			us2.Password__c = UUID.randomUUID().toString();
			insert new List<UserSettings__c> { us1, us2 };

			Test.startTest();
			List<Account.User> result = AccountService.removeUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, u2Email, 'User', 'Two', false)
			}, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(TestUtils.ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Password__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u1.Id].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(result[1].hasError);
			System.assertNotEquals(null, result[1].error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, result[1].error.code);
			System.assertEquals('[SOME_ERROR] Error message', result[1].error.description);
			System.assertEquals(TestUtils.ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(u2.Username__c, UserSettings__c.getInstance(u2.Id).Username__c);
			System.assertNotEquals(null, UserSettings__c.getInstance(u2.Id).Password__c);
			System.assertEquals(u2.Username__c, [SELECT Username__c FROM User WHERE Id = :u2.Id].Username__c);
		}
	}

	@IsTest
	static void test_removeUsers_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = TestUtils.createUser(UserInfo.getProfileId(), u1Email, UUID.randomUUID().toString(), false);
			User u2 = TestUtils.createUser(UserInfo.getProfileId(), u2Email, UUID.randomUUID().toString(), false);
			UserSettings__c us1 = UserSettings__c.getInstance(u1.Id);
			us1.Username__c = u1.Username__c;
			us1.Password__c = UUID.randomUUID().toString();
			UserSettings__c us2 = UserSettings__c.getInstance(u2.Id);
			us2.Username__c = u2.Username__c;
			us2.Password__c = UUID.randomUUID().toString();
			insert new List<UserSettings__c> { us1, us2 };

			Test.startTest();
			List<Account.User> result = AccountService.removeUsers(new List<Account.User> {
				new Account.User(TestUtils.ID1, 'user1', u1Email, 'User', 'One', 'pw1',
					Account.USER_STATUS_ACTIVE, true, true, u1.Id, null),
				new Account.User(TestUtils.ID2, 'user2', u2Email, 'User', 'Two', 'pw2',
					Account.USER_STATUS_PENDING_ACTIVATION, false, true, u2.Id, null)
			}, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(TestUtils.ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Password__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u1.Id].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertEquals(TestUtils.ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).Username__c);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).Password__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u2.Id].Username__c);
		}
	}

	@IsTest
	static void test_executePostInstallScripts_unauthorized() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				AccountService.executePostInstallScripts();
				throw new AssertException('Expected executePostInstallScripts to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_executePostInstallScripts_success() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {

			Test.startTest();
			PostInstallResults result = AccountService.executePostInstallScripts();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
		}
	}

	@IsTest
	static void test_resetCredentials_unauthorized() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				AccountService.resetCredentials(true);
				throw new AssertException('Expected resetCredentials to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resetCredentials_success() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			AccountService.resetCredentials(true);
			Test.stopTest();

			AccountSettings__c s1 = AccountSettings__c.getOrgDefaults();
			System.assertEquals(null, s1.Username__c);
			System.assertEquals(null, s1.Password__c);

			UserSettings__c s2 = UserSettings__c.getInstance();
			System.assertEquals(null, s2.Username__c);
			System.assertEquals(null, s2.Password__c);

			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId()].Username__c);
		}
	}
}
