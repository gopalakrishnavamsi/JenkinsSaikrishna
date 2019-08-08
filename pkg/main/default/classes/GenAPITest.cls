@IsTest
private class GenAPITest {

	@IsTest
	static void test_getError() {
		System.runAs(UserMock.createDocuSignUser()) {
			GenAPI client = GenAPI.getInstance();

			HttpResponse r1 = new HttpResponse();
			r1.setStatusCode(200);
			System.assertEquals(APIError.none, client.getError(r1));

			HttpResponse r2 = new HttpResponse();
			r2.setStatusCode(401);
			r2.setBody('{"Error":{"HttpStatusCode":500,"UserMessage":"User","DeveloperMessage":"Developer","ErrorCode":1234,"ReferenceId":"11111111-1111-1111-1111-111111111111"}}');
			APIError e2 = client.getError(r2);
			System.assertNotEquals(null, e2);
			System.assertEquals(1234, e2.code);
			System.assertEquals('User', e2.description);
			System.assert(e2 instanceof GenAPI.Error);
			System.assertEquals(UUID.parse('11111111-1111-1111-1111-111111111111'), ((GenAPI.Error)e2).referenceId);

			HttpResponse r3 = new HttpResponse();
			r3.setStatusCode(422);
			r3.setStatus('UNIT_TEST');
			APIError e3 = client.getError(r3);
			System.assertEquals(422, e3.code);
			System.assertEquals('UNIT_TEST', e3.description);
			System.assert(!(e3 instanceof GenAPI.Error));
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_failure() {
		GenAPIMock.failure();
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
				System.assert(ex.error instanceof GenAPI.Error);
				System.assert(UUID.isNotEmpty(((GenAPI.Error)ex.error).referenceId));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_success() {
		GenAPIMock.success();
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
		GenAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				GenAPI.getInstance().getJobStatus(UUID.randomUUID());
				throw new AssertException('Expected getJobStatus to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertNotEquals(null, ex.error.code);
				System.assertNotEquals(null, ex.error.description);
				System.assert(ex.error instanceof GenAPI.Error);
				System.assert(UUID.isNotEmpty(((GenAPI.Error)ex.error).referenceId));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getJobStatus_success() {
		GenAPIMock.success();
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
