@IsTest
private class GenAPITest {

	@IsTest
	static void test_getInstance() {
		System.runAs(UserMock.createDocuSignGenerator()) {
			Test.startTest();
			GenAPI result1 = GenAPI.getInstance();
			GenAPI result2 = GenAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
		}
	}
	
	@IsTest
	static void test_queueDocumentGeneration_failure() {
		ScmAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				GenAPI.getInstance().queueDocumentGeneration(UserInfo.getUserId(), UserInfo.getOrganizationId(),
					'<xml/>', 'PDF', 'Unit test');
				throw new AssertException('Expected queueDocumentGeneration to fail');
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
	static void test_queueDocumentGeneration_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Gen.Job result = GenAPI.getInstance().queueDocumentGeneration(UserInfo.getUserId(),
				UserInfo.getOrganizationId(), '<xml/>', 'PDF', 'Unit test');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(UUID.isNotEmpty(result.id));
			System.assertEquals(UserInfo.getUserId(), result.fileId);
			System.assert(String.isNotBlank(result.status));
			System.assertEquals(null, result.message);
			System.assertEquals(null, result.file);
			System.assertEquals(result.status == 'Success', result.success);
		}
	}

	@IsTest
	static void test_getJobStatus_failure() {
		ScmAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				GenAPI.getInstance().getJobStatus(UUID.randomUUID());
				throw new AssertException('Expected getJobStatus to fail');
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
	static void test_getJobStatus_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			UUID jobId = UUID.randomUUID();
			ContentVersion cv = TestUtils.createContentVersion();

			Test.startTest();
			Gen.Job result = GenAPI.getInstance().getJobStatus(jobId);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(jobId, result.id);
			System.assertEquals(cv.Id, result.fileId);
			System.assert(String.isNotBlank(result.status));
			System.assert(String.isNotBlank(result.message));
			System.assertEquals(null, result.file);
			System.assertEquals(result.status == 'Success', result.success);
		}
	}
}
