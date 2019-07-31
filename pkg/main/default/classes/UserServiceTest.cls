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
			List<Account.User> result = UserService.DB.queryCurrentUsers(2);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			for (Account.User u : result) {
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
	static void test_Database_updateUsers() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String username = UUID.randomUUID().toString();
			String username2 = UUID.randomUUID().toString();
			Date provisionedDate = Date.today().addDays(-1);
			User u1 = UserMock.createUser();
			u1.Username__c = username;
			u1.Status__c = Account.USER_STATUS_ACTIVE;
			u1.CanManageAccount__c = true;
			u1.Provisioned__c = provisionedDate;
			User u2 = UserMock.createUser();
			u2.Username__c = username2;
			u2.Status__c = Account.USER_STATUS_PENDING;
			User u3 = UserMock.createDocuSignUser(false);
			u3.Username__c = null;
			u3.Status__c = Account.USER_STATUS_ACTIVE;
			u3.Provisioned__c = provisionedDate;
			List<Account.User> users = UserService.DB.convert(new List<User> { u1, u2, u3 });

			Test.startTest();
			List<Account.User> result = UserService.DB.updateUsers(users);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));

			List<User> us = [
				SELECT Id, Username__c, CanManageAccount__c, Status__c, Provisioned__c
				FROM User
				WHERE Id IN :(NEW List<Id> { u1.Id, u2.Id, u3.Id })
				LIMIT 10
			];
			System.assertEquals(3, Collection.size(us));
			for (User u : us) {
				if (u.Id == u1.Id) {
					System.assertEquals(username, u.Username__c);
					System.assertEquals(Account.USER_STATUS_ACTIVE, u.Status__c);
					System.assertEquals(true, u.CanManageAccount__c);
					System.assertEquals(provisionedDate, u.Provisioned__c);
				} else if (u.Id == u2.Id) {
					System.assertEquals(username2, u.Username__c);
					System.assertEquals(Account.USER_STATUS_PENDING, u.Status__c);
					System.assertEquals(false, u.CanManageAccount__c);
					System.assertEquals(null, u.Provisioned__c);
				} else if (u.Id == u3.Id) {
					System.assertEquals(null, u.Username__c);
					System.assertEquals(Account.USER_STATUS_INACTIVE, u.Status__c);
					System.assertEquals(false, u.CanManageAccount__c);
					System.assertEquals(null, u.Provisioned__c);
				} else {
					throw new AssertException('Unexpected user: ' + u);
				}
			}

			Id dsaId = Permissions.getDocuSignAdministratorPermissionSetId();
			Id dsuId = Permissions.getDocuSignUserPermissionSetId();
			Id dssId = Permissions.getDocuSignSenderPermissionSetId();
			Set<Id> psIds = new Set<Id> { dsaId, dsuId, dssId };

			List<PermissionSetAssignment> psas = [
				SELECT PermissionSetId
				FROM PermissionSetAssignment
				WHERE AssigneeId = :u1.Id
				AND PermissionSetId IN :psIds
				LIMIT 100
			];
			System.assertEquals(1, Collection.size(psas));
			System.assertEquals(dsaId, psas[0].PermissionSetId);

			psas = [
				SELECT PermissionSetId
				FROM PermissionSetAssignment
				WHERE AssigneeId = :u2.Id
				AND PermissionSetId IN :psIds
				LIMIT 100
			];
			System.assertEquals(1, Collection.size(psas));
			System.assertEquals(dsuId, psas[0].PermissionSetId);

			System.assertEquals(0, Collection.size([
				SELECT PermissionSetId
				FROM PermissionSetAssignment
				WHERE AssigneeId = :u3.Id
				AND PermissionSetId IN :psIds
				LIMIT 100
			]));
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
	static void test_getCurrentUsers_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				UserService.getCurrentUsers(null);
				throw new AssertException('Expected getCurrentUsers to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getCurrentUsers_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			List<Account.User> result = UserService.getCurrentUsers(1);
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
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
			});
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
			});
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
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, null, false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, null, false);

			Test.startTest();
			List<Account.User> result = UserService.addUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, 'User', 'Two', false)
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
}
