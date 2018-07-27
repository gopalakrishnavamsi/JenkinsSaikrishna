@IsTest
private class SetupControllerTest {

	@IsTest
	static void test_constructor() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			SetupController result = new SetupController();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Application.lightningNamespace, result.namespace);
			System.assertEquals(Salesforce.getLightningHost(), result.lightningHost);
			System.assertEquals(Salesforce.getVisualforceHost(), result.visualforceHost);
		}
	}

	@IsTest
	static void test_getTarget() {
		System.assertEquals(Environment.Target.Invalid, SetupController.getTarget(null));
		System.assertEquals(Environment.Target.Invalid, SetupController.getTarget(''));
		System.assertEquals(Environment.Target.Invalid, SetupController.getTarget('  '));
		System.assertEquals(Environment.Target.Production, SetupController.getTarget('PROD'));
		System.assertEquals(Environment.Target.Production, SetupController.getTarget('production'));
		System.assertEquals(Environment.Target.Demo, SetupController.getTarget('demo'));
		System.assertEquals(Environment.Target.Stage, SetupController.getTarget('stage'));
		System.assertEquals(Environment.Target.Other, SetupController.getTarget('whatever'));
	}

	@IsTest
	static void test_login_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			AccountService.LoginResult result = SetupController.login('u', 'p', 'demo', null, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(AccountService.LoginStatus.Success, result.status);
		}
	}

	@IsTest
	static void test_login_failure() {
		System.runAs(TestUtils.createDocuSignUser()) { // Unauthorized
			Test.startTest();
			try {
				SetupController.login('u', 'p', 'demo', null, null);
				throw new AssertException('Expected login to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAccount_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			Account result = SetupController.getAccount();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getAccount_failure() {
		System.runAs(TestUtils.createDocuSignUser()) { // Unauthorized
			Test.startTest();
			try {
				SetupController.getAccount();
				throw new AssertException('Expected getAccount to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_logout_success() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			SetupController.logout(true);
			Test.stopTest();

			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(null, s.Username__c);
			System.assertEquals(null, s.Password__c);
			UserSettings__c us = UserSettings__c.getInstance();
			System.assertEquals(null, us.Username__c);
			System.assertEquals(null, us.Password__c);
		}
	}

	@IsTest
	static void test_logout_failure() {
		System.runAs(TestUtils.createDocuSignUser()) { // Unauthorized
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
	static void test_startTrial_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			Account.Membership result = SetupController.startTrial('u@unit.test');
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_startTrial_failure() {
		System.runAs(TestUtils.createDocuSignUser()) { // Unauthorized
			Test.startTest();
			try {
				SetupController.startTrial(null);
				throw new AssertException('Expected startTrial to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_addUser_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			List<Account.User> result = SetupController.addUser(UserInfo.getUserId(), 'u@unit.test', 'Unit', 'Test', false);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_addUser_failure() {
		System.runAs(TestUtils.createDocuSignUser()) { // Unauthorized
			Test.startTest();
			try {
				SetupController.addUser(null, null, null, null, false);
				throw new AssertException('Expected addUser to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_removeUser_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			User u = TestUtils.createDocuSignUser();
			TestUtils.createAccountConfiguration();

			Test.startTest();
			List<Account.User> result = SetupController.removeUser(u.Id, u.Username__c);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_removeUser_failure() {
		System.runAs(TestUtils.createDocuSignUser()) { // Unauthorized
			Test.startTest();
			try {
				SetupController.removeUser(null, null);
				throw new AssertException('Expected removeUser to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getUsers_success() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			List<Account.User> result = SetupController.getUsers();
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_getUsers_failure() {
		System.runAs(TestUtils.createDocuSignUser()) { // Unauthorized
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
	static void test_getUser_success() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			User result = SetupController.getUser(UserInfo.getUserId());
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getUser_failure() {
		System.runAs(TestUtils.createRestrictedUser()) { // Unauthorized
			Test.startTest();
			try {
				SetupController.getUser(null);
				throw new AssertException('Expected getUser to fail');
			} catch (AuraHandledException ex) {
				System.assert(String.isNotBlank(ex.getMessage()));
			}
			Test.stopTest();
		}
	}

//	@IsTest
//	static void test_saveState() {
//		// No way to test actual deployment, nor trigger an error here
//		System.runAs(TestUtils.createDocuSignAdministrator()) {
//			TestUtils.createAccountConfiguration();
//
//			Test.startTest();
//			Id result = SetupController.saveState('UNIT TEST');
//			Test.stopTest();
//
//			System.assertEquals(null, result);
//		}
//	}
}
