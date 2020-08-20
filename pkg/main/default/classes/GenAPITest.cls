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
	static void test_APITaskStatus_getStatusLabel() {
		GenAPI.APITaskStatus s = new GenAPI.APITaskStatus();

		Test.startTest();
		System.assertEquals(Label.Unknown, s.getStatusLabel());
		s.Status = '';
		System.assertEquals(Label.Unknown, s.getStatusLabel());
		s.Status = '  \t';
		System.assertEquals(Label.Unknown, s.getStatusLabel());
		s.Status = 'Success';
		System.assertEquals(Label.Success, s.getStatusLabel());
		s.Status = 'failure';
		System.assertEquals(Label.Failure, s.getStatusLabel());
		s.Status = 'PROCESSING';
		System.assertEquals(Label.Processing, s.getStatusLabel());
		s.Status = 'something';
		System.assertEquals('something', s.getStatusLabel());
		Test.stopTest();
	}

	@IsTest
	static void test_enqueueJob_failure() {
		ScmAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Gen.Job job = new Gen.Job(
				UserInfo.getUserId(),
				new Entity(UserInfo.getOrganizationId()),
				'en-US',
				new List<Gen.Task>());

			Test.startTest();
			try {
				GenAPI.getInstance().enqueueJob(job);
				throw new AssertException('Expected enqueueJob to fail');
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
	static void test_enqueueJob_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();
			Gen.Job job = new Gen.Job(
				UserInfo.getUserId(),
				new Entity(UserInfo.getOrganizationId()),
				'en-US',
				new List<Gen.Task> {
					new Gen.Task(
						new Gen.File(
							cv1.Id,
							cv1.Title,
							cv1.FileExtension,
							cv1.ContentSize,
							'PDF',
							null,
							null,
							cv1.ContentDocumentId,
							null),
						'file1'),
					new Gen.Task(
						new Gen.File(
							cv2.Id,
							cv2.Title,
							cv2.FileExtension,
							cv2.ContentSize,
							'Word',
							null,
							null,
							cv2.ContentDocumentId,
							null),
						'file2')
				});

			Test.startTest();
			Gen.Job result = GenAPI.getInstance().enqueueJob(job);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(job.templateId, result.templateId);
			System.assertEquals(job.source, result.source);
			System.assertEquals(job.locale, result.locale);
			System.assertEquals(2, Collection.size(result.tasks));
			for (Gen.Task t : result.tasks) {
				System.assertNotEquals(null, t);
				System.assertNotEquals(null, t.id);
				System.assertEquals(null, t.contentVersionId);
				System.assertEquals(Label.Processing, t.status);
				System.assertEquals(null, t.message);
				System.assertNotEquals(null, t.file);
				System.assertNotEquals(null, t.outputFileName);
				System.assert(!t.success);
				System.assert(!t.complete);
			}
		}
	}

	class UnknownTaskMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setHeader('Content-Type', 'application/json');
			GenAPI.APITaskStatus s = new GenAPI.APITaskStatus();
			s.Status = 'Processing';
			s.Href = 'https://unit.test.springcm.com/gen/' + UUID.randomUUID();
			List<GenAPI.APITaskStatus> ts = new List<GenAPI.APITaskStatus> { s };
			response.setBody(JSON.serialize(ts));
			return response;
		}
	}

	@IsTest
	static void test_enqueueJob_unknown() {
		Test.setMock(HttpCalloutMock.class, new UnknownTaskMock());
		System.runAs(UserMock.createDocuSignUser()) {
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();
			Gen.Job job = new Gen.Job(
				UserInfo.getUserId(),
				new Entity(UserInfo.getOrganizationId()),
				'en-US',
				new List<Gen.Task> {
					new Gen.Task(
						new Gen.File(
							cv1.Id,
							cv1.Title,
							cv1.FileExtension,
							cv1.ContentSize,
							'PDF',
							null,
							null,
							cv1.ContentDocumentId,
							null),
						'file1'),
					new Gen.Task(
						new Gen.File(
							cv2.Id,
							cv2.Title,
							cv2.FileExtension,
							cv2.ContentSize,
							'Word',
							null,
							null,
							cv2.ContentDocumentId,
							null),
						'file2')
				});

			Test.startTest();
			Gen.Job result = GenAPI.getInstance().enqueueJob(job);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, Collection.size(result.tasks));
			System.assertNotEquals(null, result.tasks[0]);
			System.assertNotEquals(null, result.tasks[0].id);
			System.assertEquals(Label.Processing, result.tasks[0].status);
			System.assertNotEquals(null, result.tasks[1]);
			System.assertEquals(null, result.tasks[1].id);
			System.assertEquals(Label.Unknown, result.tasks[1].status);
		}
	}

	@IsTest
	static void test_getTaskStatus_failure() {
		ScmAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				GenAPI.getInstance().getTaskStatus(UUID.randomUUID());
				throw new AssertException('Expected getTaskStatus to fail');
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
	static void test_getTaskStatus_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			UUID taskId = UUID.randomUUID();
			ContentVersion cv = TestUtils.createContentVersion();

			Test.startTest();
			Gen.Task result = GenAPI.getInstance().getTaskStatus(taskId);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(taskId, result.id);
			System.assertEquals(cv.Id, result.contentVersionId);
			System.assert(String.isNotBlank(result.status));
			System.assert(String.isNotBlank(result.message));
			System.assertEquals(null, result.file);
			System.assertEquals(result.status == 'Success', result.success);
		}
	}

	@IsTest
	static void test_task_localized_complete() {
		User u = UserMock.createUser();
		u.LanguageLocaleKey = 'pt_BR';
		update u;

		System.runAs(u) {
			Test.startTest();
			System.assert(!new Gen.Task(
				UUID.randomUUID(),
				null,
				'Processing',
				null).complete);
			System.assert(!new Gen.Task(
				UUID.randomUUID(),
				null,
				Label.Processing,
				null).complete);
			System.assert(new Gen.Task(
				UUID.randomUUID(),
				null,
				'Success',
				null).complete);
			System.assert(new Gen.Task(
				UUID.randomUUID(),
				null,
				Label.Success,
				null).complete);
			System.assert(new Gen.Task(
				UUID.randomUUID(),
				null,
				'Failure',
				null).complete);
			System.assert(new Gen.Task(
				UUID.randomUUID(),
				null,
				Label.Failure,
				null).complete);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_task_localized_success() {
		User u = UserMock.createUser();
		u.LanguageLocaleKey = 'pt_BR';
		update u;

		System.runAs(u) {
			Test.startTest();
			System.assert(!new Gen.Task(
				UUID.randomUUID(),
				null,
				'Processing',
				null).success);
			System.assert(!new Gen.Task(
				UUID.randomUUID(),
				null,
				Label.Processing,
				null).success);
			System.assert(new Gen.Task(
				UUID.randomUUID(),
				null,
				'Success',
				null).success);
			System.assert(new Gen.Task(
				UUID.randomUUID(),
				null,
				Label.Success,
				null).success);
			System.assert(!new Gen.Task(
				UUID.randomUUID(),
				null,
				'Failure',
				null).success);
			System.assert(!new Gen.Task(
				UUID.randomUUID(),
				null,
				Label.Failure,
				null).success);
			Test.stopTest();
		}
	}
}
