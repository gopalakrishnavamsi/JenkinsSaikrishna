@IsTest
private class TroubleShootingControllerTest {

	@IsTest
	static void test_getLoginInformation_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			TroubleShootingController.LoginInformation result = TroubleShootingController.getLoginInformation();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('connected', result.status);
			System.assert(String.isNotEmpty(result.accountEmail));
			System.assert(String.isNotEmpty(result.environment));
		}
	}

	@IsTest
	static void test_getLoginInformation_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				TroubleShootingController.getLoginInformation();
				throw new AssertException('Expected getLoginInformation to fail');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_triggerLogout_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				TroubleShootingController.triggerLogout(false);
				throw new AssertException('Expected triggerLogout to fail');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_triggerLogout_success_resetUsers() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			User u1 = UserMock.createDocuSignUser(false);
			User u2 = UserMock.createDocuSignSender(false);

			Boolean result = false;
			Test.startTest();
			result = TroubleShootingController.triggerLogout(true);
			Test.stopTest();

			System.assertEquals(true, result);

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

			//Current user didn't lose admin permissions
			System.assertEquals(1, Collection.size([
				SELECT Id
				FROM PermissionSetAssignment
				WHERE AssigneeId = :UserInfo.getUserId()
				AND PermissionSet.NamespacePrefix = :Application.packageNamespace
				AND PermissionSet.Name = :Permissions.DOCUSIGN_ADMINISTRATOR
			]));

			//DocuSign User permission set is removed from other users
			System.assertEquals(0, Collection.size([
				SELECT Id
				FROM PermissionSetAssignment
				WHERE PermissionSet.NamespacePrefix = :Application.packageNamespace
				AND PermissionSet.Name = :Permissions.DOCUSIGN_USER
			]));
		}
	}

	@IsTest
	static void test_triggerLogout_success_doNotResetUsers() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			User u1 = UserMock.createDocuSignUser(false);
			User u2 = UserMock.createDocuSignSender(false);

			Boolean result = false;
			Test.startTest();
			result = TroubleShootingController.triggerLogout(false);
			Test.stopTest();

			System.assertEquals(true, result);

			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(null, s.Environment__c);
			System.assertEquals(null, s.AccountBaseUrl__c);
			System.assertEquals(null, s.ESignatureBaseUrl__c);
			System.assertEquals(null, s.AccountId__c);
			System.assertEquals(null, s.AccountNumber__c);
			System.assertEquals(null, s.AccountName__c);
			System.assertEquals(null, s.Email__c);

			//Current user didn't lose admin permissions
			System.assertEquals(1, Collection.size([
				SELECT Id
				FROM PermissionSetAssignment
				WHERE AssigneeId = :UserInfo.getUserId()
				AND PermissionSet.NamespacePrefix = :Application.packageNamespace
				AND PermissionSet.Name = :Permissions.DOCUSIGN_ADMINISTRATOR
			]));

		}
	}

	@IsTest
	static void test_triggerChangeSecurityTask_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				TroubleShootingController.triggerChangeSecurityTask();
				throw new AssertException('Expected triggerChangeSecurityTask to fail');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_triggerChangeSecurityTask_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			System.assert(TroubleShootingController.triggerChangeSecurityTask());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_triggerAuthorizeConnectedApp_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				TroubleShootingController.triggerAuthorizeConnectedApp();
				throw new AssertException('Expected triggerAuthorizeConnectedApp to fail');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_triggerDeAuthorizeConnectedApp_unAuthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) { // Unauthorized
			Test.startTest();
			try {
				TroubleShootingController.triggerDeAuthorizeConnectedApp();
				throw new AssertException('Expected triggerDeAuthorizeConnectedApp to fail');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	//Not adding successful unit tests for PlatformAuthorizationService based on the comments in the existing test class.
	//This fails with an ISE when run with all tests. When run by itself it succeeds.
}