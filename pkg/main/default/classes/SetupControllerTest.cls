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
		DocuSignAPIMock.success();
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

			Test.startTest();
			try {
				SetupController.addUsers(userJson, rolesJson);
				throw new AssertException('Expected addUser to fail');
			} catch (AuraHandledException ex) {
				System.assertNotEquals(String.format(Label.QueryError_2, new List<Object> {
					u.Email,
					'[MAX_MEMBERS_EXCEEDED]: The maximum number of members for the account has been exceeded.'}),
					ex.getMessage());
			}
			Test.stopTest();
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
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			List<Product> productsList = SetupController.getProductsOnAccount();
			Test.stopTest();

			System.assertEquals(false, productsList.isEmpty());
			System.assertEquals(4, productsList.size());
		}
	}

	@IsTest
	static void test_getProductsOnAccount_unauthorized() {
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
	static void test_getProductRoles_error() {
		System.runAs(UserMock.createDocuSignUser(true)) {
			Test.startTest();
			try {
				SetupController.getProductRoles();
				throw new AssertException('Expected failure');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
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
			template.TemplateType__c = Gen.TYPE_ONLINE;
			update template;

			Test.setCurrentPage(Page.GenTemplateNavigator);
			ApexPages.currentPage().getParameters().put('id', template.Id);
			PageReference expectedOnlineEditorPage = Page.OnlineEditorGenTemplate ;
			expectedOnlineEditorPage.getParameters().put('id', template.Id);
			expectedOnlineEditorPage.getParameters().put('isEdit', 'false');
			expectedOnlineEditorPage.getParameters().put('isFromSetupWizard', 'true');
			SetupController controller = new SetupController();

			Test.startTest();
			PageReference result = controller.redirectOnNewTemplate();
			Test.stopTest();

			System.assertNotEquals(null, result);
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
			SetupController controller = new SetupController();

			Test.startTest();
			PageReference result = controller.redirectOnNewTemplate();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_queryEnvelopeConfigurationsForDisplay_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			EnvelopeConfiguration__c config1 = TestUtils.createEnvelopeConfiguration('Config 1', 'Account');
			EnvelopeConfiguration__c config2 = TestUtils.createEnvelopeConfiguration('Config 2', 'Account');

			Test.startTest();
			List<EnvelopeConfiguration.Listing> listings = SetupController.getEnvelopeConfigurations();
			Test.stopTest();

			System.assertEquals(2, Collection.size(listings));
			Boolean found1 = false, found2 = false;
			// Cannot depend on implicit ordering. This causes the unit test to fail intermittently.
			for (EnvelopeConfiguration.Listing l : listings) {
				EnvelopeConfiguration__c expected;
				System.assertNotEquals(null, l);
				if (l.id == config1.Id) {
					found1 = true;
					expected = config1;
				} else if (l.id == config2.Id) {
					found2 = true;
					expected = config2;
				} else {
					throw new AssertException('Unexpected listing: ' + l);
				}
				System.assertEquals(expected.Name, l.name);
				System.assertEquals(expected.SourceObject__c, l.sourceObject);
			}
			System.assert(found1);
			System.assert(found2);
		}
	}

	@IsTest
	static void test_queryEnvelopeConfigurationsForDisplay_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			TestUtils.createEnvelopeConfiguration('Config 1', 'Account');
			TestUtils.createEnvelopeConfiguration('Config 2', 'Account');
			Test.startTest();
			try {
				SetupController.getEnvelopeConfigurations();
				throw new AssertException('Expected failure');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_beginDocuSignOAuth_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			TestUtils.generateKey();

			Test.startTest();
			System.assertNotEquals(null, SetupController.beginDocuSignOAuth(TestUtils.getOrigin(), 'PROD', null));
			System.assertNotEquals(null, SetupController.beginDocuSignOAuth(TestUtils.getOrigin(), 'pRODUCTIOn', null));
			System.assertNotEquals(null, SetupController.beginDocuSignOAuth(TestUtils.getOrigin(), 'demo', null));
			System.assertNotEquals(null, SetupController.beginDocuSignOAuth(TestUtils.getOrigin(), 'stage', null));
			System.assertNotEquals(null, SetupController.beginDocuSignOAuth(TestUtils.getOrigin(), 'other', 'https://other.docusign.com'));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_beginSalesforceOAuth_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			String result = SetupController.beginSalesforceOAuth(
				LoginInformation.TYPE_USER,
				TestUtils.getOrigin());
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_redirectToNewConfigUrl() {
		PageReference pg = Page.Setup;
		pg.getParameters().put('id', UserInfo.getUserId());
		Test.setCurrentPage(pg);

		Test.startTest();
		PageReference result = new SetupController().redirectToNewConfigUrl();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.getUrl().startsWithIgnoreCase(Page.EnvelopeConfigurationNavigator.getUrl().substringBefore('?')));
		System.assert(result.getUrl().containsIgnoreCase('id='+UserInfo.getUserId()));
	}

	@IsTest
	static void test_authorizeConnectedApplication_error() {
		System.runAs(UserMock.createDocuSignUser(false)) { // unauthorized
			Test.startTest();
			try {
				SetupController.authorizeConnectedApplication();
				throw new AssertException('Expected failure');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_authorizeConnectedApplication_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			// No way to ensure connected app is installed in target org, so non-null response is acceptable.
			System.assertNotEquals(null, SetupController.authorizeConnectedApplication());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deauthorizeConnectedApplication_error() {
		System.runAs(UserMock.createDocuSignUser(false)) { // unauthorized
			Test.startTest();
			try {
				SetupController.deauthorizeConnectedApplication();
				throw new AssertException('Expected failure');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deauthorizeConnectedApplication_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			// No way to ensure connected app is installed in target org, so non-null response is acceptable.
			System.assertNotEquals(null, SetupController.deauthorizeConnectedApplication());
			Test.stopTest();
		}
	}
}

