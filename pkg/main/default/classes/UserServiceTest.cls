@IsTest
private class UserServiceTest {

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
			User u1 = UserMock.createDocuSignUser(false);
			User u2 = UserMock.createDocuSignUser(false);
			User u3 = UserMock.createDocuSignUser(false);

			Test.startTest();
			List<Account.User> result = UserService.DB.queryCurrentUsers(2);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			for (Account.User u : result) {
				System.assertNotEquals(null, u);
				System.assertNotEquals(null, u.sourceId);
				System.assert(u.id != null || u.inviteId != null);
			}
		}
	}

	@IsTest
	static void test_Database_queryAvailableUsers() {
		User u1 = UserMock.createUser();
		User u2 = UserMock.createUser();
		User a1 = UserMock.createAdministrator();
		User a2 = UserMock.createAdministrator();
		System.runAs(a1) {
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

			System.assert(Collection.size(result1) >= 4);
			System.assertEquals(2, Collection.size(result2));
			System.assertEquals(1, Collection.size(result3));
		}
	}

	@IsTest
	static void test_Database_updateUsers() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String username = UUID.randomUUID().toString();
			String inviteId = UUID.randomUUID().toString();
			Date inviteDate = Date.today().addDays(-1);
			User u1 = UserMock.createUser();
			u1.Username__c = username;
			u1.Status__c = Account.USER_STATUS_ACTIVE;
			u1.CanManageAccount__c = true;
			User u2 = UserMock.createUser();
			u2.InviteId__c = inviteId;
			u2.InviteDate__c = inviteDate;
			u2.Status__c = Account.USER_STATUS_PENDING;
			User u3 = UserMock.createDocuSignUser(false);
			u3.Username__c = null;
			u3.InviteId__c = null;
			u3.Status__c = Account.USER_STATUS_ACTIVE;
			List<Account.User> users = UserService.DB.convert(new List<User> { u1, u2, u3 });

			Test.startTest();
			List<Account.User> result = UserService.DB.updateUsers(users);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));

			List<User> us = [
				SELECT Id, Username__c, CanManageAccount__c, InviteDate__c, InviteId__c, Status__c
				FROM User
				WHERE Id IN :(NEW List<Id> { u1.Id, u2.Id, u3.Id })
				LIMIT 10
			];
			System.assertEquals(3, Collection.size(us));
			for (User u : us) {
				if (u.Id == u1.Id) {
					System.assertEquals(username, u.Username__c);
					System.assertEquals('Active', u.Status__c);
					System.assertEquals(true, u.CanManageAccount__c);
					System.assertEquals(null, u.InviteId__c);
					System.assertEquals(null, u.InviteDate__c);
				} else if (u.Id == u2.Id) {
					System.assertEquals(null, u.Username__c);
					System.assertEquals('Pending', u.Status__c);
					System.assertEquals(false, u.CanManageAccount__c);
					System.assertEquals(inviteId, u.InviteId__c);
					System.assertEquals(inviteDate, u.InviteDate__c);
				} else if (u.Id == u3.Id) {
					System.assertEquals(null, u.Username__c);
					System.assertEquals(Account.USER_STATUS_INACTIVE, u.Status__c);
					System.assertEquals(false, u.CanManageAccount__c);
					System.assertEquals(null, u.InviteId__c);
					System.assertEquals(null, u.InviteDate__c);
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
	static void test_inviteUsers_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				UserService.inviteUsers(null);
				throw new AssertException('Expected inviteUsers to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_inviteUsers_success() {
		UserInviteAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			List<Account.User> users = new List<Account.User> {
				UserService.DB.convert(UserMock.createUser()),
				UserService.DB.convert(UserMock.createUser())
			};

			Test.startTest();
			List<Account.User> result = UserService.inviteUsers(users);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
		}
	}

	@IsTest
	static void test_resendInvites_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				UserService.resendInvites(null);
				throw new AssertException('Expected resendInvites to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resendInvites_success() {
		UserInviteAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			List<Account.User> users = new List<Account.User> {
				UserService.DB.convert(UserMock.createUser()),
				UserService.DB.convert(UserMock.createUser())
			};

			Test.startTest();
			List<Account.User> result = UserService.resendInvites(users);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
		}
	}

	@IsTest
	static void test_revokeInvites_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				UserService.revokeInvites(null);
				throw new AssertException('Expected revokeInvites to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_revokeInvites_success() {
		UserInviteAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			List<Account.User> users = new List<Account.User> {
				UserService.DB.convert(UserMock.createUser()),
				UserService.DB.convert(UserMock.createUser())
			};

			Test.startTest();
			List<Account.User> result = UserService.revokeInvites(users);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
		}
	}
}