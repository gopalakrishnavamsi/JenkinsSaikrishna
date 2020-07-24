@IsTest
private class BulkSendAPITest {

	@IsTest
	static void test_getInstance() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			BulkSendAPI result1 = BulkSendAPI.getInstance();
			BulkSendAPI result2 = BulkSendAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
			System.assertNotEquals(null, result1);
			System.assert(result1.getBaseUrl().toExternalForm().contains('v2.1'));
		}
	}

	@IsTest
	static void test_createList_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			BulkList bl = new BulkList(
				UserInfo.getUserId(),
				null, // null DocuSign ID before API creation
				'unit test',
				new List<Envelope> {
					EnvelopeService.DB.convert(TestUtils.createEnvelope()),
					EnvelopeService.DB.convert(TestUtils.createEnvelope())
				},
				new Entity(UserInfo.getUserId()));

			Test.startTest();
			BulkList result = BulkSendAPI.getInstance().createList(bl);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!UUID.isEmpty(result.docuSignId));
		}
	}

	@IsTest
	static void test_createList_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			BulkList bl = new BulkList(
				UserInfo.getUserId(),
				null, // null DocuSign ID before API creation
				'unit test',
				new List<Envelope> {
					EnvelopeService.DB.convert(TestUtils.createEnvelope()),
					EnvelopeService.DB.convert(TestUtils.createEnvelope())
				},
				new Entity(UserInfo.getUserId()));

			Test.startTest();
			try {
				BulkSendAPI.getInstance().createList(bl);
				throw new AssertException('Expected createList to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateList_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			BulkList bl = new BulkList(
				UserInfo.getUserId(),
				UUID.randomUUID(),
				'unit test',
				new List<Envelope> {
					EnvelopeService.DB.convert(TestUtils.createEnvelope()).withCustomFields(new List<CustomField> {
						CustomField.newTextField('unit', 'test', false, false)
					}),
					EnvelopeService.DB.convert(TestUtils.createEnvelope()).withRecipients(new List<Recipient> {
						Recipient.fromSource('Unit Test', 'r1@unit.test', '5555555555', 'Signer 1',
							new Entity(UserInfo.getUserId())).withAuthentication(
							new Recipient.Authentication('1234', true, new List<String> { '5555555555' }))
					})
				},
				new Entity(UserInfo.getUserId()));

			Test.startTest();
			BulkList result = BulkSendAPI.getInstance().updateList(bl);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!UUID.isEmpty(result.docuSignId));
		}
	}

	@IsTest
	static void test_updateList_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			BulkList bl = new BulkList(
				UserInfo.getUserId(),
				UUID.randomUUID(),
				'unit test',
				new List<Envelope> {
					EnvelopeService.DB.convert(TestUtils.createEnvelope()),
					EnvelopeService.DB.convert(TestUtils.createEnvelope())
				},
				new Entity(UserInfo.getUserId()));

			Test.startTest();
			try {
				BulkSendAPI.getInstance().updateList(bl);
				throw new AssertException('Expected updateList to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteList_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Boolean result = BulkSendAPI.getInstance().deleteList(UUID.randomUUID());
			Test.stopTest();

			System.assert(result);
		}
	}

	@IsTest
	static void test_deleteList_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				BulkSendAPI.getInstance().deleteList(null);
				throw new AssertException('Expected deleteList to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			BulkList.Result result = BulkSendAPI.getInstance().sendEnvelope(UUID.randomUUID(), UUID.randomUUID());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!UUID.isEmpty(result.batchId));
		}
	}

	@IsTest
	static void test_sendEnvelope_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				BulkSendAPI.getInstance().sendEnvelope(UUID.randomUUID(), UUID.randomUUID());
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	private class SendErrorMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
			response.setBody('{"envelopeOrTemplateId":"11111111-1111-1111-1111-111111111111","batchId":"00000000-0000-0000-0000-000000000000","validationErrors":["ERROR_1","ERROR_2","ERROR_3"],"validationErrorDetails":["Error 1 detail","Error 2 detail"]}');
			return response;
		}
	}

	private class BulkSendFailureMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(APIErrorCode.BAD_REQUEST);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"envelopeOrTemplateId":"306db774-dcb9-442d-aa1e-9b0eb7ee3e3c","batchId":"00000000-0000-0000-0000-000000000000","batchSize":"2","totalQueued":"0","queueLimit":"2000","errors":["BULK_SEND_RECIPIENT_ID_DOES_NOT_EXIST_IN_ENVELOPE"],"errorDetails":["test error message 1","test error message 2"]}');
			return response;
		}
	}

	@IsTest
	static void test_sendEnvelope_error() {
		Test.setMock(HttpCalloutMock.class, new SendErrorMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			BulkList.Result result = BulkSendAPI.getInstance().sendEnvelope(UUID.randomUUID(), UUID.randomUUID());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.success);
			System.assertEquals(null, result.batchId);
			System.assert(Collection.size(result.errors) == 3);
			ESignatureAPI.Error e = (ESignatureAPI.Error)result.errors[0];
			System.assertNotEquals(null, e);
			System.assertEquals(APIErrorCode.BAD_REQUEST, e.code);
			System.assertEquals('ERROR_1', e.docuSignCode);
			System.assertEquals('Error 1 detail', e.description);
			e = (ESignatureAPI.Error)result.errors[1];
			System.assertNotEquals(null, e);
			System.assertEquals(APIErrorCode.BAD_REQUEST, e.code);
			System.assertEquals('ERROR_2', e.docuSignCode);
			System.assertEquals('Error 2 detail', e.description);
			e = (ESignatureAPI.Error)result.errors[2];
			System.assertNotEquals(null, e);
			System.assertEquals(APIErrorCode.BAD_REQUEST, e.code);
			System.assertEquals('ERROR_3', e.docuSignCode);
			System.assertEquals('ERROR_3', e.description);
		}
	}

	@IsTest
	static void test_getStatus_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			BulkList.Status result = BulkSendAPI.getInstance().getStatus(UUID.randomUUID());
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!UUID.isEmpty(result.docuSignId));
		}
	}

	@IsTest
	static void test_getStatus_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				BulkSendAPI.getInstance().getStatus(UUID.randomUUID());
				throw new AssertException('Expected getStatus to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_BulkSendFailureMock_failure() {
		Test.setMock(HttpCalloutMock.class, new BulkSendFailureMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				BulkList.Result result = BulkSendAPI.getInstance().sendEnvelope(UUID.randomUUID(), UUID.randomUUID());
				throw new AssertException('Expected getStatus to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
				System.assertEquals(ex.error.description, 'test error message 1,test error message 2');
			}
			Test.stopTest();
		}
	}
}
