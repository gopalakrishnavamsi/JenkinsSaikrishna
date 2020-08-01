@IsTest
private class AccountAPITest {

	@IsTest
	static void test_getConsoleViewUrl_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Url result = AccountAPI.getInstance().getConsoleViewUrl();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getConsoleViewUrl_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountAPI.getInstance().getConsoleViewUrl();
				throw new AssertException('Expected getConsoleView call to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);

			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getCustomFields_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<CustomField> cfs = AccountAPI.getInstance().getCustomFields();
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
			System.assertEquals('listField2Item2', cfs[2].value);
			System.assertEquals(new List<String> { 'listField2Item1', 'listField2Item2', 'listField2Item3' }, cfs[2].items);
			System.assert(cfs[2].required);
			System.assert(cfs[2].show);
		}
	}

	@IsTest
	static void test_getCustomFields_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountAPI.getInstance().getCustomFields();
				throw new AssertException('Expected getCustomFields to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSigningGroups_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			List<SigningGroup> signingGroups1 = AccountAPI.getInstance().getSigningGroups();
			// Call again to get cached version
			List<SigningGroup> signingGroups2 = AccountAPI.getInstance().getSigningGroups();
			Test.stopTest();

			System.assertNotEquals(null, signingGroups1);
			System.assertEquals(3, signingGroups1.size());
			System.assert(signingGroups1 === signingGroups2); // Check reference equality

			System.assertNotEquals(null, signingGroups1[0].id);
			System.assertEquals('SG1', signingGroups1[0].name);
			System.assert(signingGroups1[0].isValid);
			System.assertNotEquals(null, signingGroups1[0].members);
			System.assertEquals(2, signingGroups1[0].members.size());
			System.assertNotEquals(null, signingGroups1[0].members[0].username);
			System.assertNotEquals(null, signingGroups1[0].members[0].email);
			System.assertNotEquals(null, signingGroups1[0].members[1].username);
			System.assertNotEquals(null, signingGroups1[0].members[1].email);

			System.assertNotEquals(null, signingGroups1[1].id);
			System.assertEquals('SG2', signingGroups1[1].name);
			System.assert(!signingGroups1[1].isValid);
			System.assertNotEquals(null, signingGroups1[1].members);
			System.assertEquals(0, signingGroups1[1].members.size());

			System.assertNotEquals(null, signingGroups1[2].id);
			System.assertEquals('SG3', signingGroups1[2].name);
			System.assert(signingGroups1[2].isValid);
			System.assertNotEquals(null, signingGroups1[2].members);
			System.assertEquals(1, signingGroups1[2].members.size());
			System.assertNotEquals(null, signingGroups1[2].members[0].username);
			System.assertNotEquals(null, signingGroups1[2].members[0].email);
		}
	}

	private class SigningGroupsUnauthorizedMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"ACCOUNT_LACKS_PERMISSIONS","message":"Signing groups are unauthorized for this account"}');
			return response;
		}
	}

	@IsTest
	static void test_getSigningGroups_unauthorized() {
		Test.setMock(HttpCalloutMock.class, new SigningGroupsUnauthorizedMock());
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountAPI.getInstance().getSigningGroups();
				throw new AssertException('Expected getSigningGroups to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.ACCOUNT_LACKS_PERMISSIONS, ex.error.code);
				System.assertEquals(Label.SigningGroupsProhibited, ex.getMessage());
			}
			// Empty result is cached as the answer from DS will never change
			List<SigningGroup> result = AccountAPI.getInstance().getSigningGroups();
			Test.stopTest();

			System.assert(Collection.isEmpty(result));
		}
	}

	@IsTest
	static void test_getSigningGroups_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountAPI.getInstance().getSigningGroups();
				throw new AssertException('Expected getSigningGroups to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			// Result is not cached for non-auth-related errors
			try {
				AccountAPI.getInstance().getSigningGroups();
				throw new AssertException('Expected getSigningGroups to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTabs_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<Tab> customTabs = AccountAPI.getInstance().getTabs();
			Test.stopTest();

			System.assertNotEquals(null, customTabs);
			System.assertEquals(3, customTabs.size());

			System.assertNotEquals(null, customTabs[0]);
			System.assertNotEquals(null, customTabs[0].id);
			System.assertEquals('text', customTabs[0].type);
			System.assertEquals('Field 1 name', customTabs[0].name);
			System.assertEquals(null, customTabs[0].path);
			System.assertEquals(null, customTabs[0].writeBack);
			System.assertEquals(null, customTabs[0].allowSenderToEdit);
			System.assertEquals('Field 1 anchor', customTabs[0].autoPlaceText);

			System.assertNotEquals(null, customTabs[1]);
			System.assertNotEquals(null, customTabs[1].id);
			System.assertEquals('email', customTabs[1].type);
			System.assertEquals('Field 2 name', customTabs[1].name);
			System.assertEquals('Opportunity.Id', customTabs[1].path);
			System.assert(!customTabs[1].writeBack);
			System.assert(!customTabs[1].allowSenderToEdit);
			System.assertEquals(null, customTabs[1].autoPlaceText);

			System.assertNotEquals(null, customTabs[2]);
			System.assertNotEquals(null, customTabs[2].id);
			System.assertEquals('something', customTabs[2].type);
			System.assertEquals('Field 3 name', customTabs[2].name);
			System.assertEquals('Account.Name', customTabs[2].path);
			System.assert(customTabs[2].writeBack);
			System.assert(customTabs[2].allowSenderToEdit);
			System.assertEquals(null, customTabs[2].autoPlaceText);
		}
	}

	@IsTest
	static void test_getTabs_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountAPI.getInstance().getTabs();
				throw new AssertException('Expected getTabs to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveTab_success_create() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Tab t = new Tab(
				null,
				'text',
				'tab1',
				Tab.KEY_PREFIX + UUID.randomUUID().toString(),
				'Account.Name',
				false,
				true,
				'anchorText');

			Test.startTest();
			Tab result = AccountAPI.getInstance().saveTab(t);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(t.type, result.type);
			System.assertEquals(t.name, result.name);
			System.assertEquals(t.key, result.key);
			System.assertEquals(t.path, result.path);
			System.assertEquals(t.writeBack, result.writeBack);
			System.assertEquals(t.allowSenderToEdit, result.allowSenderToEdit);
		}
	}

	@IsTest
	static void test_saveTab_success_update() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Tab t = new Tab(
				UUID.randomUUID(),
				'text',
				'tab1',
				Tab.KEY_PREFIX + UUID.randomUUID().toString(),
				'Account.Name',
				false,
				true,
				'anchorText');

			Test.startTest();
			Tab result = AccountAPI.getInstance().saveTab(t);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(t.id, result.id);
			System.assertEquals(t.type, result.type);
			System.assertEquals(t.name, result.name);
			System.assertEquals(t.key, result.key);
			System.assertEquals(t.path, result.path);
			System.assertEquals(t.writeBack, result.writeBack);
			System.assertEquals(t.allowSenderToEdit, result.allowSenderToEdit);
		}
	}

	@IsTest
	static void test_saveTab_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Tab t = new Tab(
				UUID.randomUUID(),
				'text',
				'tab1',
				Tab.KEY_PREFIX + UUID.randomUUID().toString(),
				'Account.Name',
				false,
				true,
				'anchorText');

			Test.startTest();
			try {
				AccountAPI.getInstance().saveTab(t);
				throw new AssertException('Expected saveTab to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteTab_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			System.assert(AccountAPI.getInstance().deleteTab(UUID.randomUUID()));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteTab_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountAPI.getInstance().deleteTab(UUID.randomUUID());
				throw new AssertException('Expected deleteTab to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEveryoneGroupId_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			try {
				client.getEveryoneGroupId();
				throw new AssertException('Expected getEveryoneGroupId to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEveryoneGroupId_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			System.assertNotEquals(null, client.getEveryoneGroupId());
			Test.stopTest();
		}
	}
}
