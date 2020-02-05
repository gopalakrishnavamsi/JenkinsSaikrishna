@IsTest
private class SetupControllerTest {

	@IsTest
	static void test_constructor() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			SetupController result = new SetupController();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Application.namespace, result.namespace);
		}
	}

	@IsTest
	static void test_getLogin_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			LoginInformation result = SetupController.getLogin();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Success', result.status);
			Credentials c = Credentials.getInstance();
			System.assertEquals(c.user.id, result.id);
			System.assertEquals(c.user.name, result.name);
			System.assertEquals(c.account.email, result.email);
			System.assertEquals(1, Collection.size(result.accounts));
			System.assertEquals(c.account.id, result.accounts[0].id);
			System.assertEquals(c.account.accountNumber, result.accounts[0].accountNumber);
			System.assertEquals(c.account.name, result.accounts[0].name);
			System.assertEquals(c.environment.eSignatureBaseUrl.toExternalForm(), result.accounts[0].eSignatureBaseUrl);
			System.assert(result.accounts[0].isDefault);
		}
	}

	@IsTest
	static void test_getLogin_no_account() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			LoginInformation result = SetupController.getLogin();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('Failure', result.status);
			System.assertEquals(null, result.id);
			System.assertEquals(UserInfo.getName(), result.name);
			System.assertEquals(UserInfo.getUserEmail(), result.email);
			System.assertEquals(0, Collection.size(result.accounts));
		}
	}

	@IsTest
	static void test_getLogin_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.getLogin();
				throw new AssertException('Expected getLogin to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_beginOAuth_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.beginOAuth(TestUtils.getOrigin(), 'prod', null);
				throw new AssertException('Expected beginOAuth to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_beginOAuth_failure() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				SetupController.beginOAuth(null, null, null);
				throw new AssertException('Expected beginOAuth to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(AuthService.DOMAIN_ERROR_PAYLOAD, ex.getMessage());
			}
			try {
				SetupController.beginOAuth(TestUtils.getOrigin(), '', null);
				throw new AssertException('Expected beginOAuth to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				SetupController.beginOAuth(TestUtils.getOrigin(), '  ', null);
				throw new AssertException('Expected beginOAuth to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				SetupController.beginOAuth(TestUtils.getOrigin(), 'other', null);
				throw new AssertException('Expected beginOAuth to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				SetupController.beginOAuth(TestUtils.getOrigin(), 'other', 'https://example.com');
				throw new AssertException('Expected beginOAuth to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_beginOAuth_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			TestUtils.generateKey();

			Test.startTest();
			System.assertNotEquals(null, SetupController.beginOAuth(TestUtils.getOrigin(), 'PROD', null));
			System.assertNotEquals(null, SetupController.beginOAuth(TestUtils.getOrigin(), 'pRODUCTIOn', null));
			System.assertNotEquals(null, SetupController.beginOAuth(TestUtils.getOrigin(), 'demo', null));
			System.assertNotEquals(null, SetupController.beginOAuth(TestUtils.getOrigin(), 'stage', null));
			System.assertNotEquals(null, SetupController.beginOAuth(TestUtils.getOrigin(), 'other', 'https://other.docusign.com'));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_completeOAuth_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.completeOAuth('code', TestUtils.generateState(true), null, null);
				throw new AssertException('Expected completeOAuth to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_completeOAuth_success() {
		DocuSignAPIMock.success();
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String state = TestUtils.generateState(true);

			Test.startTest();
			LoginInformation result = SetupController.completeOAuth('code', state, null, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.STATUS_SUCCESS, result.status);
		}
	}

	@IsTest
	static void test_completeOAuth_error() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String state = TestUtils.generateState(true);

			Test.startTest();
			LoginInformation result = SetupController.completeOAuth(null, state, 'consent_required', 'Consent required.');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.STATUS_FAILURE, result.status);
			System.assertEquals(Label.ConsentRequired, result.message);
		}
	}

	@IsTest
	static void test_setAccount_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.setAccount(null, null, null);
				throw new AssertException('Expected setAccount to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_setAccount_success() {
		DocuSignAPIMock.success();
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Long accountNumber = (Long)AccountSettings__c.getOrgDefaults().AccountNumber__c;

			Test.startTest();
			LoginInformation result = SetupController.setAccount('prod', null, accountNumber);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.STATUS_SUCCESS, result.status);
		}
	}

	@IsTest
	static void test_logout_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			LoginInformation result = SetupController.logout(true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(null, result.id);
			System.assertEquals(UserInfo.getName(), result.name);
			System.assertEquals(UserInfo.getUserEmail(), result.email);
			System.assertEquals(0, Collection.size(result.accounts));

			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(null, s.Environment__c);
			System.assertEquals(null, s.AccountBaseUrl__c);
			System.assertEquals(null, s.ESignatureBaseUrl__c);
			System.assertEquals(null, s.AccountId__c);
			System.assertEquals(null, s.AccountNumber__c);
			System.assertEquals(null, s.AccountName__c);
			System.assertEquals(null, s.Email__c);

			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Username__c);
			UserSettings__c us = UserSettings__c.getInstance();
			System.assertEquals(null, us.AccessToken0__c);
			System.assertEquals(null, us.AccessToken1__c);
			System.assertEquals(null, us.AccessToken2__c);
			System.assertEquals(null, us.AccessToken3__c);
			System.assertEquals(null, us.AccessToken4__c);
			System.assertEquals(null, us.AccessToken5__c);
			System.assertEquals(null, us.AccessTokenExpires__c);
		}
	}

	@IsTest
	static void test_logout_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.logout(false);
				throw new AssertException('Expected logout to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addUsers_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.addUsers('', '');
				throw new AssertException('Expected addUsers to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addUsers_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			User u = UserMock.createUser();
			String userJson = '[{"sourceId":"' + u.Id + '","email":"' + u.Email + '","firstName":"' + u.FirstName + '","lastName":"' + u.LastName + '","canManageAccount":true}]';
			String rolesJson = '{"e_sign":"Administrator"}';
			Test.startTest();
			List<Account.User> result = SetupController.addUsers(userJson, rolesJson);
			Test.stopTest();
			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_addUsers_invalidInputs() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			String userJson = '';
			String rolesJson = '{"e_sign":"User"}';
			try {
				SetupController.addUsers(userJson, rolesJson);
				throw new AssertException('Expected addUsers to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
		}
	}

	class UserFailureMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');

			response.setBody('{"newUsers": [{"userId": "22222222-2222-2222-2222-222222222222","userName": "user2","email": "user2@unit.test","errorDetails":{"errorCode":"MAX_MEMBERS_EXCEEDED","message":"The maximum number of members for the account has been exceeded."}}]}');

			return response;
		}
	}

	@IsTest
	static void test_addUsers_api_failure() {
		Test.setMock(HttpCalloutMock.class, new UserFailureMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			User u = UserMock.createUser();
			String userJson = '[{"sourceId":"' + u.Id + '","email":"' + u.Email + '","firstName":"' + u.FirstName + '","lastName":"' + u.LastName + '","canManageAccount":true}]';
			String rolesJson = '{"e_sign":"User"}';
			try {
				SetupController.addUsers(userJson, rolesJson);
				throw new AssertException('Expected addUser to fail');
			} catch (AuraHandledException ex) {
				System.assertNotEquals(null, ex.getMessage());
			}
		}
	}

	@IsTest
	static void test_removeUsers_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			User u = UserMock.createDocuSignUser(false);

			Test.startTest();
			String userRemovalJson = '[{"id":"' + u.Username__c + '","name":"Test AdminUser","email":"testAdmin@unitTest.com","status":"Active","admin":true,"eSignatureRole":"Administrator","documentGenerationRole":"Generator","negotiationRole":null,"clmRole":null,"provisioned":"2019-09-15","sourceId":"' + u.Id + '"}]';
			List<Account.User> result = SetupController.removeUsers(userRemovalJson);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_removeUsers_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				String userRemovalJson = '[{"id":"' + UUID.randomUUID().toString() + '","name":"Test AdminUser","email":"testAdmin@unitTest.com","status":"Active","admin":true,"eSignatureRole":"Administrator","documentGenerationRole":"Generator","negotiationRole":null,"clmRole":null,"provisioned":"2019-09-15","sourceId":"' + UserInfo.getUserId() + '"}]';
				SetupController.removeUsers(userRemovalJson);
				throw new AssertException('Expected removeUser to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_removeUsers_invalidInputs() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			String userRemovalJson = '';
			try {
				SetupController.removeUsers(userRemovalJson);
				throw new AssertException('Expected addUsers to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
		}
	}

	@IsTest
	static void test_getUsers_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<Account.User> result = SetupController.getUsers();
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_getUsers_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				SetupController.getUsers();
				throw new AssertException('Expected getUsers to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_editUserPermissions_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				String userIdsToEdit = '["' + UserInfo.getUserId() + '"]';
				String roles = '{"e_sign":"Administrator","gen":"Generator","negotiate":"Negotiator"}';
				SetupController.editUserPermissions(userIdsToEdit, roles);
				throw new AssertException('Expected editUserPermissions to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_editUserPermissions_invalidUserIds() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				String userIdsToEdit = '';
				String roles = '{"e_sign":"Administrator","gen":"Generator","negotiate":"Negotiator"}';
				SetupController.editUserPermissions(userIdsToEdit, roles);
				throw new AssertException('Expected editUserPermissions to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_editUserPermissions_success() {
		DocuSignAPIMock.success();
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			User u1 = UserMock.createClmAdministrator(false);
			User u2 = UserMock.createDocuSignNegotiator(false);
			String userIdsToEdit = '["' + u1.Id + '", "' + u2.Id + '"]';
			String roles = '{"e_sign":"Administrator","gen":"Generator","negotiate":"Negotiator"}';
			Test.startTest();
			List<Account.User> result = SetupController.editUserPermissions(userIdsToEdit, roles);
			Test.stopTest();
			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_editUserPermissions_invalidRoles() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				String userIdsToEdit = '["' + UserInfo.getUserId() + '"]';
				String roles = '';
				SetupController.editUserPermissions(userIdsToEdit, roles);
				throw new AssertException('Expected editUserPermissions to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_beginSpringOAuth_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			String result = SetupController.beginSpringOAuth('testState');
			Test.stopTest();
			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_beginSpringOAuth_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.beginSpringOAuth('testState');
				throw new AssertException('Expected beginSpringOAuth to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	class SpringOAuthSuccessMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"success":true,"message":"Successfully stored refresh token."}');
			return response;
		}
	}

	class SpringOAuthFailureMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('Bad Request');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('Bad Request');
			return response;
		}
	}

	@IsTest
	static void test_completeSpringOAuth_success() {
		Test.setMock(HttpCalloutMock.class, new SpringOAuthSuccessMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			SpringOAuthLoginInformation loginInformation = SetupController.completeSpringOAuth('1234556');
			System.assertNotEquals(null, loginInformation);
			System.assert(loginInformation.success);
			System.assertEquals(Label.SuccessDocuSignAuthorization, loginInformation.message);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_completeSpringOAuth_fail() {
		Test.setMock(HttpCalloutMock.class, new SpringOAuthFailureMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			SpringOAuthLoginInformation loginInformation = SetupController.completeSpringOAuth('1234556');
			System.assertNotEquals(null, loginInformation);
			System.assert(!loginInformation.success);
			System.assertEquals(Label.UnableToConnectDocuSignGen, loginInformation.message);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_completeSpringOAuth_missingSettings() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
			accountSettings.ScmWebBaseUrl__c = '';
			update accountSettings;
			Test.startTest();
			SpringOAuthLoginInformation loginInformation = SetupController.completeSpringOAuth('1234556');
			System.assertNotEquals(null, loginInformation);
			System.assert(!loginInformation.success);
			System.assertEquals(Label.MissingDocuSignGenAuthorizationSettings, loginInformation.message);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_completeSpringOAuth_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.completeSpringOAuth('1234556');
				throw new AssertException('Expected completeSpringOAuth to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addTrialGen_unauthorized() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				SetupController.addTrialGen();
				throw new AssertException('Expected addTrialGen to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addTrialGen_success() {
		DocuSignAPIMock.success();
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			System.assert(SetupController.addTrialGen());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addTrialNegotiate_unauthorized() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				SetupController.addTrialNegotiate();
				throw new AssertException('Expected addTrialNegotiate to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addTrialNegotiate_success() {
		DocuSignAPIMock.success();
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			System.assert(SetupController.addTrialNegotiate());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_doPlatformAuthorizationSettingsExist_positive() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			Boolean result = SetupController.doPlatformAuthorizationSettingsExist();
			Test.stopTest();
			System.assertEquals(true, result);
		}
	}

	@IsTest
	static void test_doPlatformAuthorizationSettingsExist_negative() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			Boolean result = SetupController.doPlatformAuthorizationSettingsExist();
			Test.stopTest();
			System.assertEquals(false, result);
		}
	}

	@IsTest
	static void test_getProductsOnAccount_positive() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser(true)) {
			Test.startTest();
			List<Product> productsList = SetupController.getProductsOnAccount();
			Test.stopTest();
			System.assertEquals(false, productsList.isEmpty());
			System.assertEquals(4, productsList.size());
		}
	}

	@IsTest
	static void test_getProductsOnAccount_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				SetupController.getProductsOnAccount();
				throw new AssertException('Expected getProducts to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getProductRoles_positive() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			String productRoles = SetupController.getProductRoles();
			Test.stopTest();
			Map<String, List<String>> productRolesMap = (Map<String, List<String>>)JSON.deserialize(productRoles, Map<String, List<String>>.class);
			System.assertEquals(true, String.isNotBlank(productRoles));
			System.assertEquals(4, productRolesMap.size());
			System.assertEquals(1, productRolesMap.get('gen').size());
			System.assertEquals(1, productRolesMap.get('negotiate').size());
			System.assertEquals(3, productRolesMap.get('clm').size());
			System.assertEquals(3, productRolesMap.get('e_sign').size());
		}
	}

	@IsTest
	static void test_getProductRoles_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				SetupController.getProductsOnAccount();
				throw new AssertException('Expected getProductRoles to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getProfiles_positive() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			List<Profile> profiles = SetupController.getProfiles();
			Test.stopTest();
			System.assertEquals(false, profiles.isEmpty());
		}
	}

	@IsTest
	static void test_getProfiles_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.getProfiles();
				throw new AssertException('Expected getProfiles to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getPermissionSets_positive() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			List<PermissionSet> permissionSets = SetupController.getPermissionSets();
			Test.stopTest();
			System.assertEquals(false, permissionSets.isEmpty());
		}
	}

	@IsTest
	static void test_getPermissionSets_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.getPermissionSets();
				throw new AssertException('Expected getPermissionSets to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_filterSFUsers_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.filterSFUsers('testString');
				throw new AssertException('Expected filterSFUsers to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_filterSFUsers_nullInput() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			try {
				SetupController.filterSFUsers(null);
				throw new AssertException('Expected filterSFUsers to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_filterSFUsers_blankInput() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			try {
				SetupController.filterSFUsers('');
				throw new AssertException('Expected filterSFUsers to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_filterSFUsers_validInput() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			String filterString = '{"filters":[{"type":"User","value":"test"},{"type":"Profile","value":"test"},{"type":"Permission Set","value":"test"}]}';
			Test.startTest();
			List<User> filteredUserList = SetupController.filterSFUsers(filterString);
			Test.stopTest();
			System.assertEquals(0, filteredUserList.size());
		}
	}

	@IsTest
	static void test_getNewGenTemplateUrl_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.getNewGenTemplateUrl();
				throw new AssertException('Expected getNewGenTemplateUrl to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getNewGenTemplateUrl_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			String gentemplateUrl = SetupController.getNewGenTemplateUrl();
			Test.stopTest();
			System.assertNotEquals(null, gentemplateUrl);
			System.assert(gentemplateUrl.startsWith(Site.getBaseUrl()), true);
		}
	}

	@IsTest
	static void test_getGenTemplates_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				SetupController.getGenTemplates();
				throw new AssertException('Expected getNewGenTemplateUrl to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getGenTemplates_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate');
			insert testTemplate;
			List<Gen.GenTemplateDisplay> templatesList = new List<Gen.GenTemplateDisplay>();
			Test.startTest();
			templatesList = SetupController.getGenTemplates();
			Test.stopTest();
			System.assertEquals(1, templatesList.size());
			System.assertEquals('TestTemplate', templatesList[0].name);
		}
	}

	@IsTest
	static void test_redirectOnNewTemplate_OnlineEditor() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Permissions.assignPermissionSets(
				new Set<Id> { UserInfo.getUserId() },
				new Set<String> { Permissions.DOCUSIGN_GENERATOR, Permissions.DOCUSIGN_NEGOTIATOR });

			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateType__c = Gen.ONLINE_EDITOR_TYPE;
			update template;

			Test.setCurrentPage(Page.GenTemplateNavigator);
			ApexPages.currentPage().getParameters().put('id', template.Id);
			PageReference expectedOnlineEditorPage = Page.OnlineEditorGenTemplate ;
			expectedOnlineEditorPage.getParameters().put('id', template.Id);
			expectedOnlineEditorPage.getParameters().put('isEdit', 'false');
			expectedOnlineEditorPage.getParameters().put('isFromSetupWizard', 'true');
			Test.startTest();
			SetupController controller = new SetupController();
			PageReference result = controller.redirectOnNewTemplate();
			System.assertEquals(Salesforce.baseUrl.toExternalForm() + expectedOnlineEditorPage.getUrl(), result.getUrl());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redirectOnNewTemplate_WordBasedGen() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Permissions.assignPermissionSets(
				new Set<Id> { UserInfo.getUserId() },
				new Set<String> { Permissions.DOCUSIGN_GENERATOR, Permissions.DOCUSIGN_NEGOTIATOR });

			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateType__c = 'Microsoft Word';
			update template;

			Test.setCurrentPage(Page.GenTemplateNavigator);
			ApexPages.currentPage().getParameters().put('id', template.Id);
			PageReference expectedWordBasedGenPage = Page.GenTemplate ;
			expectedWordBasedGenPage.getParameters().put('id', template.Id);
			expectedWordBasedGenPage.getParameters().put('isEdit', 'false');
			expectedWordBasedGenPage.getParameters().put('isFromSetupWizard', 'true');
			Test.startTest();
			SetupController controller = new SetupController();
			PageReference result = controller.redirectOnNewTemplate();
			System.assertEquals(Salesforce.baseUrl.toExternalForm() + expectedWordBasedGenPage.getUrl(), result.getUrl());
			Test.stopTest();
		}
	}
}

