@IsTest
private class UserAPITest {

	private static final UUID ID1 = UUID.parse('11111111-1111-1111-1111-111111111111');

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

			Test.startTest();
			APIError e1 = client.getError(r1);
			APIError e2 = client.getError(r2);
			APIError e3 = client.getError(r3);
			APIError e4 = client.getError(r4);
			APIError e5 = client.getError(r5);
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
			response.setBody('{"users": [{"userId":"11111111-1111-1111-1111-111111111111","errorDetails": {"errorCode": "INVALID_USERID","message": "Invalid UserId."}}]}');
			return response;
		}
	}

	@IsTest
	static void test_removeUsers_not_found() {
		Test.setMock(HttpCalloutMock.class, new UnknownUserMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			UserAPI client = UserAPI.getInstance();

			Test.startTest();
			List<Account.User> users = client.removeUsers(new List<Account.User> {
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
					null)
			});
			Test.stopTest();

			System.assertNotEquals(null, users);
			System.assertEquals(1, users.size());
			System.assertNotEquals(null, users[0]);
			System.assertNotEquals(null, users[0].error);
			System.assert(users[0].hasError);
			System.assertEquals(APIErrorCode.UNKNOWN_USER, users[0].error.code);
			System.assertEquals('Invalid UserId.', users[0].error.description);
		}
	}
}
