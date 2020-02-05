@IsTest
private class ScmTokenAPITest {

	@IsTest
	static void test_getInstance() {
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			ScmTokenAPI result1 = ScmTokenAPI.getInstance();
			ScmTokenAPI result2 = ScmTokenAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
		}
	}

	@IsTest
	static void test_generateLimitedAccessToken_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			UUID entityId = UUID.randomUUID();

			Test.startTest();
			LimitedAccessToken limitedAccessToken = ScmTokenAPI.getInstance().generateLimitedAccessToken(entityId, 'unit.test');
			Test.stopTest();

			System.assertNotEquals(null, limitedAccessToken);
			System.assert(String.isNotBlank(limitedAccessToken.token));
			System.assert(String.isNotBlank(limitedAccessToken.apiBaseUrl));
			System.assert(String.isNotBlank(limitedAccessToken.apiDownloadBaseUrl));
			System.assert(String.isNotBlank(limitedAccessToken.apiUploadBaseUrl));
			System.assertEquals(entityId, limitedAccessToken.entityId);
		}
	}

	@IsTest
	static void test_generateLimitedAccessToken_failure() {
		ScmAPIMock.failure();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			try {
				ScmTokenAPI.getInstance().generateLimitedAccessToken(UUID.randomUUID(), 'unit.test');
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertNotEquals(null, ex.error.code);
				System.assertNotEquals(null, ex.error.description);
				System.assert(ex.error instanceof ScmAPI.Error);
				System.assert(UUID.isNotEmpty(((ScmAPI.Error)ex.error).referenceId));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getResourceToken_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			UUID documentId = UUID.randomUUID();

			Test.startTest();
			Url result = ScmTokenAPI.getInstance().getResourceToken(documentId);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.toExternalForm().contains(documentId.toString()));
		}
	}

	@IsTest
	static void test_getResourceToken_fail() {
		ScmAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				ScmTokenAPI.getInstance().getResourceToken(UUID.randomUUID());
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertNotEquals(null, ex.error.code);
				System.assertNotEquals(null, ex.error.description);
				System.assert(ex.error instanceof ScmAPI.Error);
				System.assert(UUID.isNotEmpty(((ScmAPI.Error)ex.error).referenceId));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getCompareUrl_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			UUID compareTaskId = UUID.randomUUID();

			Test.startTest();
			Url result = ScmTokenAPI.getInstance().getCompareUrl(compareTaskId);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.toExternalForm().contains(compareTaskId.toString()));
		}
	}

	@IsTest
	static void test_getCompareUrl_failure() {
		ScmAPIMock.failure();
		System.runAs(UserMock.createDocuSignNegotiator()) {
			Test.startTest();
			try {
				ScmTokenAPI.getInstance().getCompareUrl(UUID.randomUUID());
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertNotEquals(null, ex.error.code);
				System.assertNotEquals(null, ex.error.description);
				System.assert(ex.error instanceof ScmAPI.Error);
				System.assert(UUID.isNotEmpty(((ScmAPI.Error)ex.error).referenceId));
			}
			Test.stopTest();
		}

	}
}
