@IsTest
private class UserAPITest {

	private static final UUID ID1 = UUID.parse('11111111-1111-1111-1111-111111111111');
	private static final UUID ID2 = UUID.parse('22222222-2222-2222-2222-222222222222');
	private static final UUID ID3 = UUID.parse('33333333-3333-3333-3333-333333333333');

	@IsTest
	static void test_getError() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			UserAPI client = UserAPI.getInstance();
			HttpResponse r1 = new HttpResponse();
			r1.setStatusCode(200);
			r1.setStatus('OK');
			r1.setHeader('Content-Type', 'application/json');
			r1.setBody('{"some":"value"}');
			HttpResponse r2 = new HttpResponse();
			r2.setStatusCode(400);
			r2.setStatus('BAD_REQUEST');
			r2.setHeader('Content-Type', 'application/json');
			r2.setBody('{"errorCode":"SOME_ERROR","message":"Some error"}');
			HttpResponse r3 = new HttpResponse();
			r3.setStatusCode(400);
			r3.setStatus('BAD_REQUEST');
			r3.setHeader('Content-Type', 'application/json');
			r3.setBody('{"errorCode":"USER_ALREADY_EXISTS_IN_ACCOUNT","message":"User already exists in account"}');
			HttpResponse r4 = new HttpResponse();
			r4.setStatusCode(400);
			r4.setStatus('BAD_REQUEST');
			r4.setHeader('Content-Type', 'application/json');
			r4.setBody('{"errorCode":"USER_DOES_NOT_EXIST_IN_SYSTEM","message":"User does not exist"}');
			HttpResponse r5 = new HttpResponse();
			r5.setStatusCode(400);
			r5.setStatus('BAD_REQUEST');
			r5.setHeader('Content-Type', 'application/json');
			r5.setBody('{"errorCode":"INVALID_USERID","message":"Invalid user ID"}');
			HttpResponse r6 = new HttpResponse();
			r6.setStatusCode(400);
			r6.setStatus('BAD_REQUEST');
			r6.setHeader('Content-Type', 'application/json');
			r6.setBody('{"errorCode":"USER_AWAITING_ACTIVATION","message":"User is awaiting activation"}');

			Test.startTest();
			APIError e1 = client.getError(r1);
			APIError e2 = client.getError(r2);
			APIError e3 = client.getError(r3);
			APIError e4 = client.getError(r4);
			APIError e5 = client.getError(r5);
			APIError e6 = client.getError(r6);
			Test.stopTest();

			System.assertEquals(APIError.none, e1);

			System.assertNotEquals(null, e2);
			System.assert(e2 instanceof ESignatureAPI.Error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, e2.code);
			System.assertEquals('Some error', e2.description);
			System.assertEquals('SOME_ERROR', ((ESignatureAPI.Error)e2).docuSignCode);

			System.assertNotEquals(null, e3);
			System.assert(!(e3 instanceof ESignatureAPI.Error));
			System.assertEquals(APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT, e3.code);
			System.assertEquals('User already exists in account', e3.description);

			System.assertNotEquals(null, e4);
			System.assert(!(e4 instanceof ESignatureAPI.Error));
			System.assertEquals(APIErrorCode.UNKNOWN_USER, e4.code);
			System.assertEquals('User does not exist', e4.description);

			System.assertNotEquals(null, e5);
			System.assert(!(e5 instanceof ESignatureAPI.Error));
			System.assertEquals(APIErrorCode.UNKNOWN_USER, e5.code);
			System.assertEquals('Invalid user ID', e5.description);

			System.assertNotEquals(null, e6);
			System.assert(!(e6 instanceof ESignatureAPI.Error));
			System.assertEquals(APIErrorCode.USER_PENDING, e6.code);
			System.assertEquals('User is awaiting activation', e6.description);
		}
	}

	@IsTest
	static void test_getUser_error() {
		DocuSignAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				UserAPI.getInstance().getUser(
					new Account.User(UUID.randomUUID(), UserInfo.getUserId()),
					10000);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getUser_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			UUID userId = UUID.randomUUID();

			Test.startTest();
			Account.User result = UserAPI.getInstance().getUser(
				new Account.User(userId, UserInfo.getUserId()),
				10000);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(userId, result.id);
			System.assertEquals(UserInfo.getUserId(), result.sourceId);
			System.assert(String.isNotBlank(result.status));
		}
	}

	@IsTest
	static void test_addUsers_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, null, false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, null, true);
			UserAPI client = UserAPI.getInstance();

			Test.startTest();
			List<Account.User> users = client.addUsers(new List<Account.User> {
				new Account.User(
					null,
					u1.Id,
					u1Email,
					'User',
					'One',
					Account.USER_STATUS_ACTIVE,
					null,
					u1.CanManageAccount__c,
					null,
					null,
					null),
				new Account.User(
					null,
					u2.Id,
					u2Email,
					'User',
					'Two',
					Account.USER_STATUS_PENDING,
					null,
					u2.CanManageAccount__c,
					null,
					null,
					null)
			});
			Test.stopTest();

			System.assertNotEquals(null, users);
			System.assertEquals(2, users.size());

			System.assertNotEquals(null, users[0]);
			System.assert(!users[0].hasError);
			System.assertNotEquals(null, users[0].id);
			System.assertEquals(u1Email, users[0].email);
			System.assertEquals('User', users[0].firstName);
			System.assertEquals('One', users[0].lastName);
			System.assertEquals(u1.Id, users[0].sourceId);
			System.assertEquals(Account.USER_STATUS_PENDING, users[0].status);
			System.assert(!users[0].canManageAccount);

			System.assertNotEquals(null, users[1]);
			System.assert(!users[1].hasError);
			System.assertNotEquals(null, users[1].id);
			System.assertEquals(u2Email, users[1].email);
			System.assertEquals('User', users[1].firstName);
			System.assertEquals('Two', users[1].lastName);
			System.assertEquals(u2.Id, users[1].sourceId);
			System.assertEquals(Account.USER_STATUS_PENDING, users[1].status);
			System.assert(users[1].canManageAccount);
		}
	}

	private class UserAlreadyExistsMock extends OAuthTokenMock {
		override public HttpResponse getResponse(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"newUsers": [{"errorDetails": {"errorCode": "USER_ALREADY_EXISTS_IN_ACCOUNT","message": "User already exists"}}]}');
			return response;
		}
	}

	@IsTest
	static void test_addUsers_user_already_exists() {
		Test.setMock(HttpCalloutMock.class, new UserAlreadyExistsMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			UserAPI client = UserAPI.getInstance();

			Test.startTest();
			List<Account.User> newUsers = client.addUsers(new List<Account.User> {
				new Account.User(
					ID1,
					null,
					'user1@test.com',
					'User',
					'One',
					Account.USER_STATUS_ACTIVE,
					Date.today(),
					true,
					null,
					null,
					null)
			});
			Test.stopTest();

			System.assertNotEquals(null, newUsers);
			System.assertEquals(1, newUsers.size());
			System.assertNotEquals(null, newUsers[0]);
			System.assertNotEquals(null, newUsers[0].error);
			System.assert(newUsers[0].hasError);
			System.assertEquals(APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT, newUsers[0].error.code);
			System.assertEquals('User already exists', newUsers[0].error.description);
		}
	}

	private class UserPendingMock extends OAuthTokenMock {
		override public HttpResponse getResponse(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"newUsers": [{"errorDetails": {"errorCode": "USER_AWAITING_ACTIVATION","message": "User is awaiting activation"}}]}');
			return response;
		}
	}

	@IsTest
	static void test_addUsers_user_pending() {
		Test.setMock(HttpCalloutMock.class, new UserPendingMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			UserAPI client = UserAPI.getInstance();

			Test.startTest();
			List<Account.User> newUsers = client.addUsers(new List<Account.User> {
				new Account.User(
					ID1,
					null,
					'user1@test.com',
					'User',
					'One',
					Account.USER_STATUS_ACTIVE,
					Date.today(),
					true,
					null,
					null,
					null)
			});
			Test.stopTest();

			System.assertNotEquals(null, newUsers);
			System.assertEquals(1, newUsers.size());
			System.assertNotEquals(null, newUsers[0]);
			System.assertNotEquals(null, newUsers[0].error);
			System.assert(newUsers[0].hasError);
			System.assertEquals(APIErrorCode.USER_PENDING, newUsers[0].error.code);
			System.assertEquals('User is awaiting activation', newUsers[0].error.description);
		}
	}

	private static List<Account.User> testUsers;
	static List<Account.User> getTestUsers() {
		if (testUsers == null) {
			testUsers = new List<Account.User> {
				new Account.User(
					null,
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					null,
					Date.today().addDays(-3),
					true,
					'System Administrator',
					null,
					null),
				new Account.User(
					null,
					UserInfo.getProfileId(),
					UUID.randomUUID().toString() + '@unit.test',
					UUID.randomUUID().toString(),
					UUID.randomUUID().toString(),
					null,
					Date.today().addDays(-2),
					true,
					'System Administrator',
					null,
					null),
				new Account.User(
					null,
					UserInfo.getOrganizationId(),
					UUID.randomUUID().toString() + '@unit.test',
					UUID.randomUUID().toString(),
					UUID.randomUUID().toString(),
					null,
					Date.today().addDays(-3),
					true,
					'System Administrator',
					null,
					null)
			};
		}
		return testUsers;
	}

	class UserPartialSuccessMock extends OAuthTokenMock {

		override public HttpResponse getResponse(HttpRequest request) {
			List<Account.User> us = getTestUsers();
			System.assertEquals(3, Collection.size(us));

			HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json; charset=utf-8');

			if (request.getMethod() == 'GET') {
				response.setStatusCode(200);
				response.setStatus('OK');

				if (request.getEndpoint().contains(ID1.toString())) {
					UserAPI.APIUser u = new UserAPI.APIUser(us[0]);
					u.userId = ID1.toString();
					u.userStatus = 'Active';
					response.setBody(JSON.serialize(u));
				} else {
					UserAPI.APIUser u = new UserAPI.APIUser(us[0]);
					u.userId = ID2.toString();
					u.userStatus = 'ActivationRequired';
					response.setBody(JSON.serialize(u));
				}
			} else {
				response.setStatusCode(201);
				response.setStatus('CREATED');

				UserAPI.NewUsers newUsers = new UserAPI.NewUsers(us);

				newUsers.newUsers[0].userId = ID1.toString();
				newUsers.newUsers[0].userStatus = null;
				ESignatureAPI.ErrorDetails ed1 = new ESignatureAPI.ErrorDetails();
				ed1.errorCode = 'USER_ALREADY_EXISTS_IN_ACCOUNT';
				ed1.message = 'Already exists';
				newUsers.newUsers[0].errorDetails = ed1;

				newUsers.newUsers[1].userId = ID2.toString();
				newUsers.newUsers[1].userStatus = null;
				ESignatureAPI.ErrorDetails ed2 = new ESignatureAPI.ErrorDetails();
				ed2.errorCode = 'USER_AWAITING_ACTIVATION';
				ed2.message = 'Pending activation';
				newUsers.newUsers[1].errorDetails = ed2;

				newUsers.newUsers[2].userId = ID3.toString();
				newUsers.newUsers[2].userStatus = 'closed';

				response.setBody(JSON.serialize(newUsers));
			}
			return response;
		}
	}

	@IsTest
	static void test_addUsers_partial_success() {
		Test.setMock(HttpCalloutMock.class, new UserPartialSuccessMock());
		System.runAs(UserMock.createDocuSignAdministrator()) {
			List<Account.User> users = getTestUsers();
			System.assertEquals(3, Collection.size(users));

			Test.startTest();
			List<Account.User> result = UserAPI.getInstance().addUsers(users);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result));
			for (Account.User u : result) {
				System.assertNotEquals(null, u);
				System.assert(UUID.isNotEmpty(u.id));
				if (u.id == ID1) {
					System.assertEquals(Account.USER_STATUS_ACTIVE, u.status);
				} else if (u.id == ID2) {
					System.assertEquals(Account.USER_STATUS_PENDING, u.status);
				} else if (u.id == ID3) {
					System.assertEquals(Account.USER_STATUS_INACTIVE, u.status);
				} else {
					throw new AssertException('Unexpected user:\n' + JSON.serializePretty(u));
				}
			}
		}
	}

	private class UserOtherErrorMock extends OAuthTokenMock {

		override public HttpResponse getResponse(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"newUsers": [{"errorDetails": {"errorCode": "SOME_ERROR","message": "Some error"}}]}');
			return response;
		}
	}

	@IsTest
	static void test_addUsers_other_error() {
		Test.setMock(HttpCalloutMock.class, new UserOtherErrorMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			UserAPI client = UserAPI.getInstance();

			Test.startTest();
			List<Account.User> newUsers = client.addUsers(new List<Account.User> {
				new Account.User(
					ID1,
					null,
					'user1@test.com',
					'User',
					'One',
					Account.USER_STATUS_ACTIVE,
					Date.today(),
					true,
					null,
					null,
					null)
			});
			Test.stopTest();

			System.assertNotEquals(null, newUsers);
			System.assertEquals(1, newUsers.size());
			System.assertNotEquals(null, newUsers[0]);
			System.assertNotEquals(null, newUsers[0].error);
			System.assert(newUsers[0].hasError);
			System.assertEquals(APIErrorCode.BAD_REQUEST, newUsers[0].error.code);
			System.assertEquals('[SOME_ERROR] Some error', newUsers[0].error.description);
		}
	}

	@IsTest
	static void test_addUsers_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignAdministrator()) {
			UserAPI client = UserAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.addUsers(new List<Account.User> {
					new Account.User(
						UUID.randomUUID(),
						null,
						'',
						'',
						'',
						null,
						null,
						true,
						null,
						null,
						null)
				});
				throw new AssertException('Expected addUsers to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}

	@IsTest
	static void test_removeUsers_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			UserAPI client = UserAPI.getInstance();
			UUID id1 = UUID.randomUUID(), id2 = UUID.randomUUID();

			Test.startTest();
			List<Account.User> users = client.removeUsers(new List<Account.User> {
				new Account.User(
					id1,
					UserInfo.getUserId(),
					'user1@test.com',
					'User',
					'One',
					Account.USER_STATUS_ACTIVE,
					Date.today(),
					true,
					null,
					null,
					null),
				new Account.User(
					id2,
					null,
					'user2@test.com',
					'User',
					'Two',
					Account.USER_STATUS_PENDING,
					Date.today(),
					false,
					null,
					null,
					null)
			});
			Test.stopTest();

			System.assertNotEquals(null, users);
			System.assertEquals(2, users.size());

			System.assertNotEquals(null, users[0]);
			System.assertEquals(id1, users[0].id);
			System.assert(!users[0].hasError);

			System.assertNotEquals(null, users[1]);
			System.assertEquals(id2, users[1].id);
			System.assert(!users[1].hasError);
		}
	}

	@IsTest
	static void test_removeUsers_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignAdministrator()) {
			UserAPI client = UserAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.removeUsers(new List<Account.User> {
					new Account.User(
						UUID.randomUUID(),
						null,
						'',
						'',
						'',
						null,
						null,
						true,
						null,
						null,
						null)
				});
				throw new AssertException('Expected removeUsers to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}

	private class UnknownUserMock extends OAuthTokenMock {
		override public HttpResponse getResponse(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"users": [{"userId":"11111111-1111-1111-1111-111111111111","email":"user1@unit.test","errorDetails": {"errorCode": "INVALID_USERID","message": "Invalid UserId."}},{"userId":"22222222-2222-2222-2222-222222222222","email":"user2@unit.test","errorDetails": {"errorCode": "USER_DOES_NOT_EXIST_IN_SYSTEM","message": "User does not exist."}}]}');
			return response;
		}
	}

	@IsTest
	static void test_removeUsers_unknown_user() {
		Test.setMock(HttpCalloutMock.class, new UnknownUserMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			UserAPI client = UserAPI.getInstance();

			Test.startTest();
			List<Account.User> result = client.removeUsers(new List<Account.User> {
				new Account.User(
					ID1,
					UserInfo.getUserId(),
					'user1@unit.test',
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
					UserInfo.getProfileId(),
					'user2@unit.test',
					'User',
					'Two',
					Account.USER_STATUS_PENDING,
					Date.today(),
					false,
					null,
					null,
					null)
			});
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(UserInfo.getUserId(), result[0].sourceId);
			System.assertEquals(null, result[0].error);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(UserInfo.getProfileId(), result[1].sourceId);
			System.assertEquals(null, result[1].error);
		}
	}

	@IsTest
	static void test_APIUser_getStatusExternalForm() {
		UserAPI.APIUser u1 = new UserAPI.APIUser(new Account.User(UUID.randomUUID(), UserInfo.getUserId()));

		Test.startTest();
		System.assertEquals(null, u1.getStatusExternalForm());
		u1.userStatus = 'whatever';
		System.assertEquals('whatever', u1.getStatusExternalForm());
		u1.userStatus = 'Active';
		System.assertEquals(Account.USER_STATUS_ACTIVE, u1.getStatusExternalForm());
		u1.userStatus = 'ActivationRequired';
		System.assertEquals(Account.USER_STATUS_PENDING, u1.getStatusExternalForm());
		u1.userStatus = 'ACTIVATIONSENT';
		System.assertEquals(Account.USER_STATUS_PENDING, u1.getStatusExternalForm());
		u1.userStatus = 'closed';
		System.assertEquals(Account.USER_STATUS_INACTIVE, u1.getStatusExternalForm());
		u1.userStatus = 'Disabled';
		System.assertEquals(Account.USER_STATUS_INACTIVE, u1.getStatusExternalForm());
		Test.stopTest();
	}
}
