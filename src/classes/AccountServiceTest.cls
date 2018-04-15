@IsTest
private class AccountServiceTest {

	static testMethod void test_getAccount_unauthorized() {
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

	static testMethod void test_getAccount_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			Account result1 = AccountService.getAccount();
			Account result2 = AccountService.getAccount();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
		}
	}

	static testMethod void test_getTrialStatus() {
		Date today = Date.today();

		// Expires today
		Account account1 = new Account(UUID.randomUUID(), 'Unit test 1',
			new Account.Plan(Environment.trial30DayPlanId, 'Plan 1', today, today),
			new Account.Billing(today, today),
			Account.ConnectPermission.Full,
			Environment.production);

		// Expires in 1 day
		Account account2 = new Account(UUID.randomUUID(), 'Unit test 2',
			new Account.Plan(Environment.trial30DayPlanId, 'Plan 2', today, today.addDays(1)),
			new Account.Billing(today, today.addDays(1)),
			Account.ConnectPermission.Full,
			Environment.production);

		// Expires in 2 days
		Account account3 = new Account(UUID.randomUUID(), 'Unit test 3',
			new Account.Plan(Environment.trial30DayPlanId, 'Plan 3', today, today.addDays(2)),
			new Account.Billing(today, today.addDays(2)),
			Account.ConnectPermission.Full,
			Environment.production);

		// Expired yesterday
		Account account4 = new Account(UUID.randomUUID(), 'Unit test 4',
			new Account.Plan(Environment.trial30DayPlanId, 'Plan 4', today, today.addDays(-1)),
			new Account.Billing(today, today.addDays(-1)),
			Account.ConnectPermission.Full,
			Environment.production);

		// Expires in > 7 days
		Account account5 = new Account(UUID.randomUUID(), 'Unit test 5',
			new Account.Plan(Environment.trial30DayPlanId, 'Plan 5', today, today.addDays(10)),
			new Account.Billing(today, today.addDays(10)),
			Account.ConnectPermission.Full,
			Environment.production);

		// Not trial plan
		Account account6 = new Account(UUID.randomUUID(), 'Unit test 6',
			new Account.Plan(UUID.randomUUID(), 'Plan 6', today, today.addDays(-1)),
			new Account.Billing(today, today.addDays(-1)),
			Account.ConnectPermission.Full,
			Environment.production);

		Test.startTest();
		AccountService.TrialStatus result1 = AccountService.getTrialStatus(account1); // today
		AccountService.TrialStatus result2 = AccountService.getTrialStatus(account2); // 1 day
		AccountService.TrialStatus result3 = AccountService.getTrialStatus(account3); // 2 days
		AccountService.TrialStatus result4 = AccountService.getTrialStatus(account4); // expired
		AccountService.TrialStatus result5 = AccountService.getTrialStatus(account5); // > 7 days
		AccountService.TrialStatus result6 = AccountService.getTrialStatus(account6); // not trial
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

	static testMethod void test_parseEnvironment() {
		Test.startTest();
		System.assertEquals(Environment.production, AccountService.parseEnvironment('production', 'whatever'));
		System.assertEquals(Environment.production, AccountService.parseEnvironment('prod', 'whatever'));
		System.assertEquals(Environment.production, AccountService.parseEnvironment('eu', null));
		System.assertEquals(Environment.production, AccountService.parseEnvironment('au', null));
		System.assertEquals(Environment.production, AccountService.parseEnvironment('ca', null));
		System.assertEquals(Environment.demo, AccountService.parseEnvironment('demo', null));
		System.assertEquals(Environment.invalid, AccountService.parseEnvironment('whatever', null));
		System.assertEquals(Environment.invalid, AccountService.parseEnvironment(' ', null));
		System.assertEquals(Environment.invalid, AccountService.parseEnvironment(null, null));
		System.assertEquals(Environment.invalid, AccountService.parseEnvironment('other', 'not-a-url'));
		Test.stopTest();
	}

	static testMethod void test_login_unauthorized() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountService.login('u@unit.test', UUID.randomUUID().toString(), 'prod', null, null);
				throw new AssertException('Expected login to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	static testMethod void test_login_error() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountService.login('u@unit.test', UUID.randomUUID().toString(), 'prod', null, null);
				throw new AssertException('Expected login to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.UNAUTHORIZED, ex.error.code);
				System.assertEquals('dunno', ex.error.description);
			}
			Test.stopTest();
		}
	}

	static testMethod void test_login_invalid_environment() {
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

	static testMethod void test_login_invalid_credentials() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.UnauthorizedMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountService.login('u@unit.test', UUID.randomUUID().toString(), 'demo', null, null);
				throw new AssertException('Expected login to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.InvalidUsernameOrPassword, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	class NoAccountsMock implements HttpCalloutMock {
		public HTTPResponse respond(final HTTPRequest request) {
			final HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json; charset=UTF-8');
			final String reqURL = request.getEndpoint();
			if (reqURL.contains('/login_information')) {
				response.setStatusCode(200);
				response.setBody('{"apiPassword": "a", "loginAccounts": []}');
			}
			return response;
		}
	}

	static testMethod void test_login_no_accounts() {
		Test.setMock(HttpCalloutMock.class, new NoAccountsMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountService.login('u@unit.test', UUID.randomUUID().toString(), 'prod', null, null);
				throw new AssertException('Expected login to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.NoValidAccounts, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private class MultipleAccountMock implements HttpCalloutMock {
		public HTTPResponse respond(final HTTPRequest request) {
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

	static testMethod void test_login_multiple_accounts() {
		Test.setMock(HttpCalloutMock.class, new MultipleAccountMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			AccountService.LoginResult result = AccountService.login('u@unit.test', UUID.randomUUID().toString(), 'prod', null, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(AccountService.LoginStatus.SelectAccount, result.status);
			System.assertNotEquals(null, result.accountOptions);
			System.assertEquals(2, result.accountOptions.size());
		}
	}

	static testMethod void test_login_multiple_accounts_select_one() {
		Test.setMock(HttpCalloutMock.class, new MultipleAccountMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			AccountService.LoginResult result = AccountService.login('u@unit.test', UUID.randomUUID().toString(), 'prod', null, 2222L);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(AccountService.LoginStatus.Success, result.status);
			System.assertNotEquals(null, result.accountOptions);
			System.assertEquals(1, result.accountOptions.size());
			System.assertEquals(2222L, result.accountOptions[0].id);
		}
	}

	static testMethod void test_login_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			AccountService.LoginResult result = AccountService.login('u@unit.test', UUID.randomUUID().toString(), 'prod', null, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(AccountService.LoginStatus.Success, result.status);
			System.assertEquals(1, result.accountOptions.size());
			System.assertEquals(22222222L, result.accountOptions[0].id);
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

	static testMethod void test_login_base_URL() {
		Test.setMock(HttpCalloutMock.class, new BaseUrlMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			AccountService.LoginResult result = AccountService.login('u@unit.test', UUID.randomUUID().toString(), 'other', 'https://unit.test.docusign.net', null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(AccountService.LoginStatus.Success, result.status);
			System.assertEquals('https://unit.test.docusign.net/', AccountSettings__c.getOrgDefaults().BaseUrl__c);
		}
	}

	static testMethod void test_connect_unauthorized() {
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

	static testMethod void test_connect() {
		Test.setMock(WebServiceMock.class, new AccountSoapAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			System.assertNotEquals(null, AccountService.connect('u@unit.test', UUID.randomUUID().toString()));
			Test.stopTest();
		}
	}

	static testMethod void test_validate_Account_Trial() {
		Account.Trial a1 = null;
		Account.Trial a2 = new Account.Trial(null, new Account.TrialUser('u@unit.test', 'Unit', 'Test'), null, true);
		Account.Trial a3 = new Account.Trial('Unit Test', null, null, true);
		Account.Trial a4 = new Account.Trial('Unit Test', new Account.TrialUser('u@unit.test', null, null), null, true);
		Account.Trial a5 = new Account.Trial('Unit Test', new Account.TrialUser('bad-email', 'Unit', 'Test'), null, true);
		Account.Trial a6 = new Account.Trial('Unit Test', new Account.TrialUser('u@unit.test', 'Unit', 'Test'), null, false);
		Account.Trial a7 = new Account.Trial('Unit Test', new Account.TrialUser('u@unit.test', 'Unit', 'Test'), null, true);

		Test.startTest();
		ValidationResult result1 = AccountService.validate(a1);
		ValidationResult result2 = AccountService.validate(a2);
		ValidationResult result3 = AccountService.validate(a3);
		ValidationResult result4 = AccountService.validate(a4);
		ValidationResult result5 = AccountService.validate(a5);
		ValidationResult result6 = AccountService.validate(a6);
		ValidationResult result7 = AccountService.validate(a7);
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
		System.assertEquals(2, result3.messages.size());
		System.assert(result3.messages.contains(Label.EmailRequired));
		System.assert(result3.messages.contains(Label.NameRequired));

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
		System.assertEquals(Label.MustAgreeToTCs, result6.messages[0]);

		System.assertNotEquals(null, result7);
		System.assert(result7.isValid);
	}

	static testMethod void test_prepareTrial_unauthorized() {
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

	static testMethod void test_prepareTrial() {
		User u = TestUtils.createDocuSignAdministrator();
		u.Phone = '5555551111';
		u.MobilePhone = '5555552222';
		u.Street = '123 Fake St';
		u.City = 'Anywhere';
		u.State = 'CA';
		u.PostalCode = '99999';
		u.Country = 'United States';
		update u;

		System.runAs(u) {
			String email = UUID.randomUUID().toString() + '@unit.test';

			Test.startTest();
			Account.Trial result = AccountService.prepareTrial(email);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(UserInfo.getOrganizationName(), result.company);
			System.assertNotEquals(null, result.user);
			System.assertEquals(email, result.user.email);
			System.assertEquals(u.FirstName, result.user.firstName);
			System.assertEquals(u.LastName, result.user.lastName);
			System.assertEquals(StringUtils.mkName(u.FirstName, u.LastName), result.user.name);
			System.assertNotEquals(null, result.address);
			System.assertEquals(u.Street, result.address.address1);
			System.assertEquals(null, result.address.address2);
			System.assertEquals(u.City, result.address.city);
			System.assertEquals(u.State, result.address.region);
			System.assertEquals(u.PostalCode, result.address.postalCode);
			System.assertEquals(u.Country, result.address.country);
			System.assertEquals(u.Phone, result.address.phone);
			System.assert(!result.termsAccepted);
		}
	}

	static testMethod void test_createTrial_unauthorized() {
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

	static testMethod void test_createTrial_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			try {
				Credentials.getInstance();
				throw new AssertException('Expected credentials to be uninitialized');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
			}
			Account.Trial a = new Account.Trial('Unit Test', new Account.TrialUser('u@unit.test', 'Unit', 'Test'), null, true);

			Test.startTest();
			Account.Membership result = AccountService.createTrial(a);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.accountId);
			System.assertNotEquals(null, result.accountUUID);
			System.assert(String.isNotBlank(result.name));
			System.assertNotEquals(null, result.baseUrl);
			System.assertNotEquals(null, result.settings);
			System.assertEquals(null, result.apiPassword);

			Credentials c = Credentials.getInstance();
			System.assertNotEquals(null, c);
			System.assert(c.isValid);
		}
	}

	static testMethod void test_createTrial_failure() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Account.Trial a = new Account.Trial('Unit Test', new Account.TrialUser('u@unit.test', 'Unit', 'Test'), null, false);

			Test.startTest();
			try {
				AccountService.createTrial(a);
				throw new AssertException('Expected createTrial to fail');
			} catch (ValidationException ex) {
				System.assertEquals(Label.InvalidTrialAccount + '\n' + Label.MustAgreeToTCs, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	static testMethod void test_getDocuSignUrl_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			Url result = AccountService.getDocuSignUrl();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	static testMethod void test_getDocuSignUrl_failure() {
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

	static testMethod void test_getSettings_unauthorized() {
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

	static testMethod void test_getSettings_success() {
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
		}
	}

	static testMethod void test_saveSettings_unauthorized() {
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

	static testMethod void test_saveSettings_success() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			AccountService.Settings s = new AccountService.Settings(
				EnvelopeSettings.getInstance(),
				null,
				null,
				12345,
				new List<String> { 'er1', 'er2' },
				new List<String> { 'dr1', 'dr2' },
				new List<String> { 'rr1', 'rr2' });

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
		}
	}
}
