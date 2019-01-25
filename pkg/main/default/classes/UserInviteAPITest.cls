@IsTest
private class UserInviteAPITest {

	@IsTest
	static void test_getInstance() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			UserInviteAPI result1 = UserInviteAPI.getInstance();
			UserInviteAPI result2 = UserInviteAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
		}
	}

	@IsTest
	static void test_getErrorCode() {
		System.assertEquals(APIErrorCode.USER_INVITE_ALREADY_EXISTS, UserInviteAPI.getErrorCode('USERINVITE_ALREADY_EXISTS', 400));
		System.assertEquals(APIErrorCode.USER_INVITE_NOT_FOUND, UserInviteAPI.getErrorCode('userinvite_not_found', 400));
		System.assertEquals(APIErrorCode.USER_INVITE_INVALID_STATUS, UserInviteAPI.getErrorCode('userinvite_invalid_status', 400));
		System.assertEquals(400, UserInviteAPI.getErrorCode(null, 400));
		System.assertEquals(400, UserInviteAPI.getErrorCode('  ', 400));
		System.assertEquals(400, UserInviteAPI.getErrorCode('other_error', 400));
	}

	@IsTest
	static void test_getError() {
		UserInviteAPI client = new UserInviteAPI(
			new Url('https://unit.test.docusign.net/'),
			UUID.randomUUID(),
			new Url('https://redirect.invite.test.springcm.com/'),
			new Url('https://callback.invite.test.springcm.com/'),
			'email subject',
			'email body',
			1111L,
			2222L);

		HttpResponse r = new HttpResponse();
		r.setStatusCode(200);
		APIError result = client.getError(r);
		System.assertEquals(APIError.none, result);

		r.setStatusCode(400);
		r.setStatus('BAD_REQUEST');
		result = client.getError(r);
		System.assertEquals(APIError.badRequest, result);

		UUID referenceId = UUID.randomUUID();
		r.setBody('{"error":"userinvite_not_found","error_description":"unit test","reference_id":"' + referenceId + '"}');
		result = client.getError(r);
		System.assertNotEquals(null, result);
		System.assertEquals(APIErrorCode.USER_INVITE_NOT_FOUND, result.code);
		System.assertEquals('unit test', result.description);
		System.assert(result instanceof UserInviteAPI.Error);
		System.assertEquals(referenceId, ((UserInviteAPI.Error)result).referenceId);

		r.setBody('{"error":"unit_test","error_description":"unit test"}');
		result = client.getError(r);
		System.assertNotEquals(null, result);
		System.assertEquals(400, result.code);
		System.assertEquals('unit test', result.description);
		System.assert(result instanceof UserInviteAPI.Error);
		System.assertEquals(null, ((UserInviteAPI.Error)result).referenceId);
	}

	@IsTest
	static void test_getInviteDate() {
		Date d = Date.newInstance(2019, 1, 1);
		System.assertEquals(d, UserInviteAPI.getInviteDate(null, d));
		System.assertEquals(d, UserInviteAPI.getInviteDate(new Map<String, Object>(), d));
		System.assertEquals(d, UserInviteAPI.getInviteDate(new Map<String, Object> {
			'created_on' => 1546329600
		}, null));
	}

	@IsTest
	static void test_handleInviteResponse_error() {
		Account.User u = new Account.User(
			UUID.randomUUID(),
			UserInfo.getUserId(),
			UserInfo.getUserEmail(),
			UserInfo.getFirstName(),
			UserInfo.getLastName(),
			'status',
			null,
			null,
			false,
			'profile',
			APIError.none);
		RestAPI.Response r = new RestAPI.Response(
			new HttpRequest(),
			new HttpResponse(),
			new APIError(APIErrorCode.UNAUTHORIZED, 'test'));

		Test.startTest();
		Account.User result = UserInviteAPI.handleInviteResponse(u, r);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.hasError);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, result.error.code);
		System.assertEquals('test', result.error.description);
	}

	@IsTest
	static void test_handleInviteResponse_empty() {
		Account.User u = new Account.User(
			UUID.randomUUID(),
			UserInfo.getUserId(),
			UserInfo.getUserEmail(),
			UserInfo.getFirstName(),
			UserInfo.getLastName(),
			'status',
			null,
			null,
			false,
			'profile',
			APIError.none);
		RestAPI.Response r = new RestAPI.Response(
			new HttpRequest(),
			new HttpResponse(),
			APIError.none);

		Test.startTest();
		Account.User result = UserInviteAPI.handleInviteResponse(u, r);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.hasError);
		System.assertEquals(APIErrorCode.FAILURE, result.error.code);
		System.assertEquals(Label.UserInviteFailed, result.error.description);
	}

	@IsTest
	static void test_handleInviteResponse_success() {
		Account.User u = new Account.User(
			UUID.randomUUID(),
			UserInfo.getUserId(),
			UserInfo.getUserEmail(),
			UserInfo.getFirstName(),
			UserInfo.getLastName(),
			'status',
			null,
			null,
			false,
			'profile',
			APIError.none);
		UUID inviteId = UUID.randomUUID();
		HttpResponse resp = new HttpResponse();
		resp.setBody(JSON.serialize(new Map<String, Object> {
			'status' => 'pending',
			'user_invite_id' => String.valueOf(inviteId),
			'events' => new Map<String, Object> {
				'created_on' => 1546329600 // 2019-01-01
			}
		}));
		RestAPI.Response r = new RestAPI.Response(
			new HttpRequest(),
			resp,
			APIError.none);

		Test.startTest();
		Account.User result = UserInviteAPI.handleInviteResponse(u, r);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.hasError);
		System.assertEquals('pending', result.status);
		System.assertEquals(inviteId, result.inviteId);
		System.assertEquals(Date.newInstance(2019, 1, 1), result.inviteDate);
	}

	private static UserInviteAPI client;

	private static UserInviteAPI getClient() {
		if (client == null) {
			client = new UserInviteAPI(
				new Url('https://account.test.docusign.net/'),
				UUID.randomUUID(),
				new Url('https://redirect.test.springcm.com/'),
				new Url('https://callback.test.springcm.com/'),
				'email subject',
				'email body',
				1111L,
				2222L);
		}
		return client;
	}

	@IsTest
	static void test_inviteUsers_failure() {
		UserInviteAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			List<Account.User> users = new List<Account.User> {
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					null,
					null,
					null,
					false,
					'profile',
					APIError.none),
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					null,
					null,
					null,
					false,
					'profile',
					APIError.none)
			};

			Test.startTest();
			List<Account.User> result = getClient().inviteUsers(users);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			for (Account.User u : result) {
				System.assertNotEquals(null, u);
				System.assert(u.hasError);
				System.assertEquals(null, u.status);
				System.assertEquals(null, u.inviteId);
				System.assertEquals(null, u.inviteDate);
			}
		}
	}

	@IsTest
	static void test_inviteUsers_success() {
		UserInviteAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			List<Account.User> users = new List<Account.User> {
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					null,
					null,
					null,
					false,
					'profile',
					APIError.none),
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					null,
					null,
					null,
					false,
					'profile',
					APIError.none)
			};

			Test.startTest();
			List<Account.User> result = getClient().inviteUsers(users);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			for (Account.User u : result) {
				System.assertNotEquals(null, u);
				System.assert(!u.hasError);
				System.assertNotEquals(null, u.status);
				System.assertNotEquals(null, u.inviteId);
				System.assertNotEquals(null, u.inviteDate);
			}
		}
	}

	@IsTest
	static void test_resendInvites_failure() {
		UserInviteAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			List<Account.User> users = new List<Account.User> {
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					'pending',
					UUID.randomUUID(),
					Date.today().addDays(-1),
					false,
					'profile',
					APIError.none),
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					'pending',
					UUID.randomUUID(),
					Date.today().addDays(-2),
					false,
					'profile',
					APIError.none)
			};

			Test.startTest();
			List<Account.User> result = getClient().resendInvites(users);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			for (Account.User u : result) {
				System.assertNotEquals(null, u);
				System.assert(u.hasError);
			}
		}
	}

	@IsTest
	static void test_resendInvites_success() {
		UserInviteAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			List<Account.User> users = new List<Account.User> {
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					'pending',
					UUID.randomUUID(),
					Date.today().addDays(-1),
					false,
					'profile',
					APIError.none),
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					'pending',
					UUID.randomUUID(),
					Date.today().addDays(-2),
					false,
					'profile',
					APIError.none)
			};

			Test.startTest();
			List<Account.User> result = getClient().resendInvites(users);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			for (Account.User u : result) {
				System.assertNotEquals(null, u);
				System.assert(!u.hasError);
			}
		}
	}

	@IsTest
	static void test_revokeInvites_failure() {
		UserInviteAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			List<Account.User> users = new List<Account.User> {
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					'pending',
					UUID.randomUUID(),
					Date.today().addDays(-1),
					false,
					'profile',
					APIError.none),
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					'pending',
					UUID.randomUUID(),
					Date.today().addDays(-2),
					false,
					'profile',
					APIError.none)
			};

			Test.startTest();
			List<Account.User> result = getClient().revokeInvites(users);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			for (Account.User u : result) {
				System.assertNotEquals(null, u);
				System.assert(u.hasError);
			}
		}
	}

	@IsTest
	static void test_revokeInvites_success() {
		UserInviteAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			List<Account.User> users = new List<Account.User> {
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					'pending',
					UUID.randomUUID(),
					Date.today().addDays(-1),
					false,
					'profile',
					APIError.none),
				new Account.User(
					UUID.randomUUID(),
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					'pending',
					UUID.randomUUID(),
					Date.today().addDays(-2),
					false,
					'profile',
					APIError.none)
			};

			Test.startTest();
			List<Account.User> result = getClient().revokeInvites(users);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			for (Account.User u : result) {
				System.assertNotEquals(null, u);
				System.assert(!u.hasError);
			}
		}
	}
}
