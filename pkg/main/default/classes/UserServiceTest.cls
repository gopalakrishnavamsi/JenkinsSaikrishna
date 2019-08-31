@IsTest
private class UserServiceTest {

	private static final UUID ID1 = UUID.parse('11111111-1111-1111-1111-111111111111');
	private static final UUID ID2 = UUID.parse('22222222-2222-2222-2222-222222222222');

	@IsTest
	static void test_Database_queryUserConfiguration() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			UserService.Configuration result = UserService.DB.queryUserConfiguration();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(Collection.isNotEmpty(result.profiles));
			System.assert(Collection.isNotEmpty(result.permissionSets));
		}
	}

	@IsTest
	static void test_Database_queryCurrentUsers() {
		User admin = UserMock.createDocuSignAdministrator();
		System.runAs(admin) {
			UserMock.createDocuSignUser(false);
			UserMock.createDocuSignUser(false);
			UserMock.createDocuSignUser(false);

			Test.startTest();
			Map<Id, Account.User> result = UserService.DB.queryCurrentUsers(2);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());
			for (Account.User u : result.values()) {
				System.assertNotEquals(null, u);
				System.assertNotEquals(null, u.sourceId);
				System.assert(u.id != null);
			}
		}
	}

	@IsTest
	static void test_Database_queryAvailableUsers() {
		User u1 = UserMock.createUser();
		User u2 = UserMock.createUser();
		User a1 = UserMock.createAdministrator();
		User a2 = UserMock.createAdministrator();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Map<Id, Profile> ps = new Map<Id, Profile>([
				SELECT Id
				FROM Profile
				WHERE Name IN :(NEW Set<String> { u1.Profile.Name, a1.Profile.Name })
				LIMIT 10
			]);
			System.assertEquals(2, ps.size());
			Map<Id, PermissionSet> pss = new Map<Id, PermissionSet>([
				SELECT Id
				FROM PermissionSet
				WHERE Id IN (
					SELECT PermissionSetId
					FROM PermissionSetAssignment
					WHERE AssigneeId IN :(NEW Set<Id> { u2.Id, a2.Id })
				)
				LIMIT 10
			]);
			System.assertEquals(2, pss.size());

			Test.startTest();
			List<Account.User> result1 = UserService.DB.queryAvailableUsers(
				null,
				null,
				ps.keySet(),
				pss.keySet(),
				1000);
			List<Account.User> result2 = UserService.DB.queryAvailableUsers(
				'UNIT TEST',
				null,
				new Set<Id> { Collection.head(ps.keySet()) },
				null,
				1000);
			List<Account.User> result3 = UserService.DB.queryAvailableUsers(
				'',
				u1.Email,
				null,
				null,
				1000);
			Test.stopTest();

			System.assert(Collection.size(result1) >= 4); // This is either 4 or 5 depending on org. *sigh*
			System.assertEquals(2, Collection.size(result2));
			System.assertEquals(1, Collection.size(result3));
		}
	}

	@IsTest
	static void test_getConfiguration_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				UserService.getConfiguration();
				throw new AssertException('Expected getConfiguration to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getConfiguration_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			UserService.Configuration result = UserService.getConfiguration();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getAvailableUsers_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				UserService.getAvailableUsers(null, null, null, null, null);
				throw new AssertException('Expected getAvailableUsers to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAvailableUsers_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			UserMock.createUser();
			UserMock.createUser();

			Test.startTest();
			List<Account.User> result = UserService.getAvailableUsers(null, null, null, null, 10);
			Test.stopTest();

			System.assert(Collection.size(result) >= 2); // Cannot account for users created outside of this test.
		}
	}

	@IsTest
	static void test_getUsers_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				UserService.getUsers(10);
				throw new AssertException('Expected getUsers to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getUsers_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			UserMock.createDocuSignUser(false);
			UserMock.createDocuSignUser(false);
			UserMock.createDocuSignAdministrator(false);

			Test.startTest();
			List<Account.User> result = UserService.getUsers(10);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.size() >= 4);
			for (Account.User u : result) {
				System.assert(Collection.isNotEmpty(u.roles));
			}
		}
	}

	class UserPartialSuccessMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
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

	class UserExistenceMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
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

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, null, false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, null, false);

			Test.startTest();
			List<Account.User> result = UserService.addUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, 'User', 'Two', false)
			}, new Map<String, List<String>>());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(ID1.toString(), [SELECT Username__c FROM User WHERE Id = :u1.Id LIMIT 1].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertEquals(ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(ID2.toString(), [SELECT Username__c FROM User WHERE Id = :u2.Id LIMIT 1].Username__c);
		}
	}

	@IsTest
	static void test_addUsers_success_partial() {
		Test.setMock(HttpCalloutMock.class, new UserPartialSuccessMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, null, false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, null, false);

			Test.startTest();
			List<Account.User> result = UserService.addUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, 'User', 'Two', false)
			}, new Map<String, List<String>>());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(ID1.toString(), [SELECT Username__c FROM User WHERE Id = :u1.Id LIMIT 1].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(result[1].hasError);
			System.assertNotEquals(null, result[1].error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, result[1].error.code);
			System.assertEquals('[SOME_ERROR] Error message', result[1].error.description);
			System.assertEquals(ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u2.Id LIMIT 1].Username__c);
		}
	}

	@IsTest
	static void test_addUsers_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, null, false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, null, false);

			Test.startTest();
			List<Account.User> result = UserService.addUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, 'User', 'Two', false)
			}, new Map<String, List<String>> {
				Product.ESIGNATURE => new List<String> {
					ESignatureProduct.ROLE_ADMINISTRATOR,
					ESignatureProduct.ROLE_SENDER
				}
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertNotEquals(null, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertNotEquals(null, [SELECT Username__c FROM User WHERE Id = :u1.Id LIMIT 1].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertNotEquals(null, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertNotEquals(null, [SELECT Username__c FROM User WHERE Id = :u2.Id LIMIT 1].Username__c);
		}
	}

	@IsTest
	static void test_removeUsers_self() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			User u1 = UserMock.createUser();

			Test.startTest();
			try {
				UserService.removeUsers(new List<Account.User> {
					new Account.User(u1.Id, 'u1@unit.test', 'User', 'One', true),
					new Account.User(UserInfo.getUserId(), 'u2@unit.test', 'User', 'Two', false)
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

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, UUID.randomUUID(), false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, UUID.randomUUID(), false);
			UserSettings__c us1 = UserSettings__c.getInstance(u1.Id);
			us1.AccessToken0__c = UUID.randomUUID().toString();
			us1.Nonce__c = UUID.randomUUID().toString();
			UserSettings__c us2 = UserSettings__c.getInstance(u2.Id);
			us2.AccessToken0__c = UUID.randomUUID().toString();
			us2.Nonce__c = UUID.randomUUID().toString();
			upsert new List<UserSettings__c> { us1, us2 };

			Test.startTest();
			List<Account.User> result = UserService.removeUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, 'User', 'Two', false)
			}, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).AccessToken0__c);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Nonce__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u1.Id LIMIT 1].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertEquals(ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).AccessToken0__c);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).Nonce__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u2.Id LIMIT 1].Username__c);
		}
	}

	@IsTest
	static void test_removeUsers_success_partial() {
		Test.setMock(HttpCalloutMock.class, new UserPartialSuccessMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, UUID.randomUUID(), false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, UUID.randomUUID(), false);
			UserSettings__c us1 = UserSettings__c.getInstance(u1.Id);
			us1.AccessToken0__c = UUID.randomUUID().toString();
			us1.Nonce__c = UUID.randomUUID().toString();
			UserSettings__c us2 = UserSettings__c.getInstance(u2.Id);
			us2.AccessToken0__c = UUID.randomUUID().toString();
			us2.Nonce__c = UUID.randomUUID().toString();
			upsert new List<UserSettings__c> { us1, us2 };

			Test.startTest();
			List<Account.User> result = UserService.removeUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, 'User', 'Two', false)
			}, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Nonce__c);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).AccessToken0__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u1.Id].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(result[1].hasError);
			System.assertNotEquals(null, result[1].error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, result[1].error.code);
			System.assertEquals('[SOME_ERROR] Error message', result[1].error.description);
			System.assertEquals(ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertNotEquals(null, UserSettings__c.getInstance(u2.Id).Nonce__c);
			System.assertNotEquals(null, UserSettings__c.getInstance(u2.Id).AccessToken0__c);
			System.assertEquals(u2.Username__c, [SELECT Username__c FROM User WHERE Id = :u2.Id].Username__c);
		}
	}

	@IsTest
	static void test_removeUsers_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, UUID.randomUUID(), false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, UUID.randomUUID(), false);
			UserSettings__c us1 = UserSettings__c.getInstance(u1.Id);
			us1.Nonce__c = UUID.randomUUID().toString();
			us1.AccessToken0__c = UUID.randomUUID().toString();
			UserSettings__c us2 = UserSettings__c.getInstance(u2.Id);
			us2.Nonce__c = UUID.randomUUID().toString();
			us2.AccessToken0__c = UUID.randomUUID().toString();
			upsert new List<UserSettings__c> { us1, us2 };

			Test.startTest();
			List<Account.User> result = UserService.removeUsers(new List<Account.User> {
				new Account.User(
					ID1,
					u1.Id,
					u1Email,
					'User',
					'One',
					Account.USER_STATUS_ACTIVE,
					Date.today(),
					true,
					null,
					null,
					null),
				new Account.User(
					ID2,
					u2.Id,
					u2Email,
					'User',
					'Two',
					Account.USER_STATUS_PENDING,
					Date.today(),
					false,
					null,
					null,
					null)
			}, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Nonce__c);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).AccessToken0__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u1.Id].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertEquals(ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).Nonce__c);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).AccessToken0__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u2.Id].Username__c);
		}
	}

	@IsTest
	static void test_updateUserRoles_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				UserService.updateUserRoles(null, null);
				throw new AssertException('Expected updateUserRoles to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateUserRoles_undefined_argument() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				UserService.updateUserRoles(null, null);
				throw new AssertException('Expected updateUserRoles to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateUserRoles_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			User u1 = UserMock.createClmAdministrator(false);
			User u2 = UserMock.createDocuSignNegotiator(false);
			User u3 = UserMock.createDocuSignSender(false);

			Test.startTest();
			System.assert(UserService.updateUserRoles(new Set<Id> { UserInfo.getUserId(), u1.Id, u2.Id, u3.Id },
				new Map<String, List<String>> {
					Product.ESIGNATURE => new List<String> { ESignatureProduct.ROLE_ADMINISTRATOR },
					Product.GEN => new List<String> { GenProduct.ROLE_GENERATOR },
					Product.CLM => new List<String> { ClmProduct.ROLE_VIEWER }
				}));
			Test.stopTest();

			Set<String> psas = new Set<String>();
			for (PermissionSetAssignment psa : [
				SELECT AssigneeId, PermissionSetId
				FROM PermissionSetAssignment
				WHERE AssigneeId IN :(NEW Set<Id> { UserInfo.getUserId(), u1.Id, u2.Id, u3.Id })
				AND PermissionSetId IN :Permissions.getPermissionSetMap().values()
			]) {
				psas.add(psa.AssigneeId + ':' + psa.PermissionSetId);
			}
			System.assertEquals(10, psas.size());
			System.assert(psas.contains(UserInfo.getUserId() + ':' + Permissions.getDocuSignAdministratorPermissionSetId()));
			System.assert(psas.contains(u1.Id + ':' + Permissions.getDocuSignAdministratorPermissionSetId()));
			System.assert(psas.contains(u1.Id + ':' + Permissions.getDocuSignGeneratorPermissionSetId()));
			System.assert(psas.contains(u1.Id + ':' + Permissions.getClmViewerPermissionSetId()));
			System.assert(psas.contains(u2.Id + ':' + Permissions.getDocuSignAdministratorPermissionSetId()));
			System.assert(psas.contains(u2.Id + ':' + Permissions.getDocuSignGeneratorPermissionSetId()));
			System.assert(psas.contains(u2.Id + ':' + Permissions.getClmViewerPermissionSetId()));
			System.assert(psas.contains(u3.Id + ':' + Permissions.getDocuSignAdministratorPermissionSetId()));
			System.assert(psas.contains(u3.Id + ':' + Permissions.getDocuSignGeneratorPermissionSetId()));
			System.assert(psas.contains(u3.Id + ':' + Permissions.getClmViewerPermissionSetId()));
		}
	}

	@IsTest
	static void test_getAvailableSystemSenders_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				UserService.getAvailableSystemSenders();
				throw new AssertException('Expected getAvailableSystemSenders to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAvailableSystemSenders_success() {
		User dsa1 = UserMock.createDocuSignAdministrator(false);
		User dsa2 = UserMock.createDocuSignAdministrator(false);
		User dsa3 = UserMock.createDocuSignAdministrator(false);
		User dsu1 = UserMock.createDocuSignUser(false);
		User dsu2 = UserMock.createDocuSignUser(false);
		System.runAs(dsa1) {
			dsa2.IsActive = false;
			update dsa2;
			// dsa1, dsa3 are the only eligible system senders outside of any DS admins configured outside of this unit
			// test. dsa2 is not active and should not be returned, and dsu1 and dsu2 are not admins and therefore
			// ineligible system senders.
			Set<String> invalidUsernames = new Set<String> { dsa2.Username__c, dsu1.Username__c, dsu2.Username__c };

			Test.startTest();
			List<UserService.SystemSender> result = UserService.getAvailableSystemSenders();
			Test.stopTest();

			System.assert(Collection.size(result) >= 2);
			Boolean foundDSA1 = false, foundDSA3 = false;
			for (UserService.SystemSender ss : result) {
				String username = String.valueOf(ss.id);
				if (username == dsa1.Username__c) {
					foundDSA1 = true;
					System.assertEquals(dsa1.Name, ss.name);
					System.assertEquals(dsa1.Email, ss.email);
				} else if (username == dsa3.Username__c) {
					foundDSA3 = true;
					System.assertEquals(dsa3.Name, ss.name);
					System.assertEquals(dsa3.Email, ss.email);
				} else if (invalidUsernames.contains(username)) {
					throw new AssertException('Unexpected system sender: ' + ss);
				}
			}
			System.assert(foundDSA1);
			System.assert(foundDSA3);
		}
	}

	@IsTest
	static void test_verifyBatchSize_user() {
		System.runAs(UserMock.getAdministrator()) {
			List<Account.User> users = new List<Account.User> {
				new Account.User(UUID.randomUUID(), UserInfo.getUserId()),
				new Account.User(UUID.randomUUID(), UserInfo.getUserId()),
				new Account.User(UUID.randomUUID(), UserInfo.getUserId())
			};

			Test.startTest();
			System.assertEquals(new List<Account.User>(), UserService.verifyBatchSize((List<Account.User>)null, -1));
			System.assertEquals(new List<Account.User>(), UserService.verifyBatchSize(new List<Account.User>(), -1));
			System.assertEquals(users, UserService.verifyBatchSize(users, null));
			System.assertEquals(users, UserService.verifyBatchSize(users, -1));
			System.assertEquals(users, UserService.verifyBatchSize(users, 0));
			System.assertEquals(users, UserService.verifyBatchSize(users, 3));
			try {
				UserService.verifyBatchSize(users, 2);
				throw new AssertException('Expected verifyBatchSize to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.MaximumBatchSizeExceeded_2, new List<Object> { 3, 2 }),
					ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_verifyBatchSize_id() {
		System.runAs(UserMock.getAdministrator()) {
			Set<Id> users = new Set<Id> {
				UserMock.createUser().Id,
				UserMock.createUser().Id,
				UserMock.createUser().Id
			};

			Test.startTest();
			System.assertEquals(new Set<Id>(), UserService.verifyBatchSize((Set<Id>)null, -1));
			System.assertEquals(new Set<Id>(), UserService.verifyBatchSize(new Set<Id>(), -1));
			System.assertEquals(users, UserService.verifyBatchSize(users, null));
			System.assertEquals(users, UserService.verifyBatchSize(users, -1));
			System.assertEquals(users, UserService.verifyBatchSize(users, 0));
			System.assertEquals(users, UserService.verifyBatchSize(users, 3));
			try {
				UserService.verifyBatchSize(users, 2);
				throw new AssertException('Expected verifyBatchSize to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.MaximumBatchSizeExceeded_2, new List<Object> { 3, 2 }),
					ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRoles_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				UserService.getRoles(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRoles_undefined_argument() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				UserService.getRoles(null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				UserService.getRoles(new Set<String>());
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRoles_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Set<String> products = new Set<String> { Product.GEN, Product.NEGOTIATE };

			Test.startTest();
			Map<String, List<String>> result = UserService.getRoles(products);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(products, result.keySet());
		}
	}

	@IsTest
	static void test_getRoleIds_invalid_product() {
		UUID clmAdminId = UUID.randomUUID();
		UUID clmUserId = UUID.randomUUID();
		UUID clmViewerId = UUID.randomUUID();
		Map<String, Map<UUID, Product.Role>> accountRoles = new Map<String, Map<UUID, Product.Role>> {
			Product.CLM => new Map<UUID, Product.Role> {
				clmAdminId => new Product.Role(clmAdminId, Product.CLM, ClmProduct.ROLE_ADMINISTRATOR, Label.Administrator, true),
				clmUserId => new Product.Role(clmUserId, Product.CLM, ClmProduct.ROLE_USER, Label.User, false),
				clmViewerId => new Product.Role(clmViewerId, Product.CLM, ClmProduct.ROLE_VIEWER, Label.Viewer, false)
			}
		};
		Map<String, List<String>> targetRoles = new Map<String, List<String>> {
			Product.CLM => new List<String> { ClmProduct.ROLE_USER },
			Product.GEN => new List<String> { GenProduct.ROLE_GENERATOR }
		};

		Test.startTest();
		try {
			UserService.getRoleIds(accountRoles, targetRoles);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UnsupportedProducts, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getRoleIds_invalid_role() {
		UUID clmAdminId = UUID.randomUUID();
		UUID clmUserId = UUID.randomUUID();
		UUID clmViewerId = UUID.randomUUID();
		Map<String, Map<UUID, Product.Role>> accountRoles = new Map<String, Map<UUID, Product.Role>> {
			Product.CLM => new Map<UUID, Product.Role> {
				clmAdminId => new Product.Role(clmAdminId, Product.CLM, ClmProduct.ROLE_ADMINISTRATOR, Label.Administrator, true),
				clmUserId => new Product.Role(clmUserId, Product.CLM, ClmProduct.ROLE_USER, Label.User, false),
				clmViewerId => new Product.Role(clmViewerId, Product.CLM, ClmProduct.ROLE_VIEWER, Label.Viewer, false)
			}
		};
		Map<String, List<String>> targetRoles = new Map<String, List<String>> {
			Product.CLM => new List<String> { ClmProduct.ROLE_USER, 'bad' }
		};

		Test.startTest();
		try {
			UserService.getRoleIds(accountRoles, targetRoles);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UnsupportedProductRoles, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getRoleIds_success() {
		UUID clmAdminId = UUID.randomUUID();
		UUID clmUserId = UUID.randomUUID();
		UUID clmViewerId = UUID.randomUUID();
		UUID dsAdminId = UUID.randomUUID();
		UUID dsUserId = UUID.randomUUID();
		UUID dsSenderId = UUID.randomUUID();

		Map<String, Map<UUID, Product.Role>> accountRoles = new Map<String, Map<UUID, Product.Role>> {
			Product.CLM => new Map<UUID, Product.Role> {
				clmAdminId => new Product.Role(clmAdminId, Product.CLM, ClmProduct.ROLE_ADMINISTRATOR, Label.Administrator, true),
				clmUserId => new Product.Role(clmUserId, Product.CLM, ClmProduct.ROLE_USER, Label.User, false),
				clmViewerId => new Product.Role(clmViewerId, Product.CLM, ClmProduct.ROLE_VIEWER, Label.Viewer, false)
			},
			Product.ESIGNATURE => new Map<UUID, Product.Role> {
				dsAdminId => new Product.Role(dsAdminId, Product.ESIGNATURE, ESignatureProduct.ROLE_ADMINISTRATOR, Label.Administrator, true),
				dsUserId => new Product.Role(dsUserId, Product.ESIGNATURE, ESignatureProduct.ROLE_USER, Label.User, false),
				dsSenderId => new Product.Role(dsSenderId, Product.ESIGNATURE, ESignatureProduct.ROLE_SENDER, Label.Sender, false)
			}
		};
		Map<String, List<String>> targetRoles = new Map<String, List<String>> {
			Product.CLM => new List<String> { ClmProduct.ROLE_USER, ClmProduct.ROLE_VIEWER },
			Product.ESIGNATURE => new List<String> { ESignatureProduct.ROLE_USER, ESignatureProduct.ROLE_SENDER }
		};

		Test.startTest();
		Set<UUID> result = UserService.getRoleIds(accountRoles, targetRoles);
		Test.stopTest();

		System.assertEquals(new Set<UUID> { clmUserId, clmViewerId, dsUserId, dsSenderId }, result);
	}
}
