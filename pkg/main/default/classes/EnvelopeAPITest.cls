@IsTest
private class EnvelopeAPITest {

	private static final UUID ID1 = UUID.parse('11111111-1111-1111-1111-111111111111');
	private static final UUID ID2 = UUID.parse('22222222-2222-2222-2222-222222222222');
	private static final UUID ID3 = UUID.parse('33333333-3333-3333-3333-333333333333');
	private static final UUID ID4 = UUID.parse('44444444-4444-4444-4444-444444444444');
	private static final UUID ID5 = UUID.parse('55555555-5555-5555-5555-555555555555');

	@IsTest
	static void test_bad_resolver() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.DocumentResolvers__c = 'bad_resolver';
			upsert s;

			Test.startTest();
			try {
				EnvelopeAPI.getInstance();
				throw new AssertException('Expected getInstance to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.InvalidDocumentResolver_1, new List<String> { 'bad_resolver' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getError() {
		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
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
			r3.setBody('{"errorCode":"ACCOUNT_LACKS_PERMISSIONS","message":"Account lacks permissions"}');
			HttpResponse r4 = new HttpResponse();
			r4.setStatusCode(400);
			r4.setStatus('BAD_REQUEST');
			r4.setHeader('Content-Type', 'application/json');
			r4.setBody('{"errorCode":"RECIPIENT_NOT_IN_SEQUENCE","message":"Recipient not in sequence"}');
			HttpResponse r5 = new HttpResponse();
			r5.setStatusCode(400);
			r5.setStatus('BAD_REQUEST');
			r5.setHeader('Content-Type', 'application/json');
			r5.setBody('{"errorCode":"UNKNOWN_ENVELOPE_RECIPIENT","message":"Unknown envelope recipient"}');
			HttpResponse r6 = new HttpResponse();
			r6.setStatusCode(400);
			r6.setStatus('BAD_REQUEST');
			r6.setHeader('Content-Type', 'application/json');
			r6.setBody('{"errorCode":"USER_LACKS_PERMISSIONS","message":"This user lacks sufficient permissions to access this resource."}');

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
			System.assertEquals(APIErrorCode.ACCOUNT_LACKS_PERMISSIONS, e3.code);
			System.assertEquals('Account lacks permissions', e3.description);

			System.assertNotEquals(null, e4);
			System.assert(!(e4 instanceof ESignatureAPI.Error));
			System.assertEquals(APIErrorCode.INVALID_RECIPIENT_SEQUENCE, e4.code);
			System.assertEquals(Label.InvalidRecipientSequence, e4.description);

			System.assertNotEquals(null, e5);
			System.assert(!(e5 instanceof ESignatureAPI.Error));
			System.assertEquals(APIErrorCode.UNKNOWN_RECIPIENT, e5.code);
			System.assertEquals(Label.UnknownEnvelopeRecipient, e5.description);

			System.assertNotEquals(null, e6);
			System.assert(!(e6 instanceof ESignatureAPI.Error));
			System.assertEquals(APIErrorCode.UNAUTHORIZED, e6.code);
			System.assertEquals(Label.UserNotAuthorizedForEnvelope, e6.description);
		}
	}

	@IsTest
	static void test_buildCustomFields() {
		System.runAs(UserMock.createDocuSignUser()) {
			CustomField cf1 = CustomField.newTextField('n1', 'v1', true, false);
			CustomField cf2 = CustomField.newTextField('n2', 'v2', false, true);
			CustomField cf3 = CustomField.newListField('n3', 'v3', new List<String> { 'v1', 'v2', 'v3' }, true, true);
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);

			Test.startTest();
			EnvelopeAPI.APICustomFields result = EnvelopeAPI.buildCustomFields(
				new List<CustomField> { cf1, cf2, cf3 },
				new Envelope.Options(
					false,
					new Envelope.DocumentWriteBack(
						o.Id,
						Envelope.FORMAT_NAME_PDF,
						true,
						false),
					null,
					null),
				Entity.resolve(o.Id));
			Test.stopTest();

			System.assertNotEquals(null, result);

			System.assertNotEquals(null, result.textCustomFields);
			System.assertEquals(9, result.textCustomFields.size());

			System.assertNotEquals(null, result.listCustomFields);
			System.assertEquals(1, result.listCustomFields.size());
			System.assertEquals('n3', result.listCustomFields[0].name);
			System.assertEquals('v3', result.listCustomFields[0].value);
			System.assertEquals(new List<String> { 'v1', 'v2', 'v3' }, result.listCustomFields[0].listItems);
			System.assertEquals('true', result.listCustomFields[0].required);
			System.assertEquals('true', result.listCustomFields[0].show);

			for (EnvelopeAPI.APITextCustomField cf : result.textCustomFields) {
				System.assertNotEquals(null, cf);
				switch on cf.name {
					when '##SFUsername' {
						System.assertEquals(UserInfo.getUserName(), cf.value);
					} when '##SFBaseUrl' {
						System.assertEquals(Salesforce.baseUrl.toExternalForm(), cf.value);
					} when '##SFTokenEndpoint' {
						System.assertEquals('https://' + (Salesforce.isSandbox ? 'test' : 'login') + '.salesforce.com', cf.value);
					} when '##SFApplication' {
						System.assertEquals(Application.name + ' ' + String.valueOf(Application.version), cf.value);
					} when 'Company' {
						System.assertEquals(UserInfo.getOrganizationName(), cf.value);
					}
				}
			}
		}
	}

	@IsTest
	static void test_getDocumentContent_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();
			Schema.Document d1 = TestUtils.createDocument();
			Document t1 = Document.fromTemplate(UUID.randomUUID(), 'UnitTestTemplate');
			Document scm1 = Document.fromFile(UUID.randomUUID(), 'UnitTestScmFile', 'adf');
			Document cd1 = new Document(
				null,
				Document.TYPE_FILE,
				4,
				cv2.Title,
				cv2.FileExtension,
				cv2.ContentSize,
				cv2.LastModifiedDate,
				cv2.ContentDocumentId,
				false,
				false,
				null);

			Test.startTest();
			Map<String, Blob> result1 = EnvelopeAPI.getDocumentContent(new List<Document> {
				t1,
				scm1,
				Document.fromFile(cv1),
				cd1,
				Document.fromDocument(d1)
			}, false);
			Map<String, Blob> result2 = EnvelopeAPI.getDocumentContent(new List<Document> {
				t1,
				scm1,
				Document.fromFile(cv1),
				cd1,
				Document.fromDocument(d1)
			}, true);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertEquals(4, result1.size());
			System.assertEquals('scm:' + scm1.sourceId, result1.get(scm1.sourceId).toString());
			System.assertEquals(cv1.VersionData.toString(), result1.get(cv1.Id).toString());
			System.assertEquals(cv2.VersionData.toString(), result1.get(cv2.ContentDocumentId).toString());
			System.assertEquals(d1.Body.toString(), result1.get(d1.Id).toString());

			System.assertNotEquals(null, result2);
			System.assertEquals(4, result2.size());
			System.assertEquals('scm:' + scm1.sourceId, result2.get(scm1.sourceId).toString());
			System.assertEquals(cv1.Id, result2.get(cv1.Id).toString());
			System.assertEquals(cv2.Id, result2.get(cv2.ContentDocumentId).toString());
			System.assertEquals(d1.Id, result2.get(d1.Id).toString());
		}
	}

	@IsTest
	static void test_getDocumentContent_error() {
		System.runAs(UserMock.createDocuSignUser()) {
			ContentVersion cv1 = TestUtils.createContentVersion();

			Test.startTest();
			try {
				EnvelopeAPI.getDocumentContent(new List<Document> {
					new Document(null, Document.TYPE_FILE, null, 'UnitTest1.pdf', 'pdf', 1234, Datetime.now(), UserInfo.getUserId()),
					Document.fromFile(cv1),
					new Document(null, Document.TYPE_FILE, null, 'UnitTest2.pdf', 'pdf', 1234, Datetime.now(), UserInfo.getOrganizationId()),
					new Document(null, Document.TYPE_TEMPLATE, null, 'UnitTestTemplate', null, null, Datetime.now(), UUID.randomUUID().toString())
				}, false);
				throw new AssertException('Expected getDocumentContent to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotReadDocumentContent_1, new List<String> {
					'UnitTest1.pdf (' + UserInfo.getUserId() + '), UnitTest2.pdf (' + UserInfo.getOrganizationId() + ')'
				}), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSenderViewUrl_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			Url u = client.getSenderViewUrl(UUID.randomUUID(), new Url('https://unit.test.return/'));
			Test.stopTest();

			System.assertNotEquals(null, u);
		}
	}

	@IsTest
	static void test_getSenderViewUrl_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getSenderViewUrl(UUID.randomUUID(), new Url('https://unit.test.return/'));
				throw new AssertException('Expected getSenderViewUrl call to fail');
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
	static void test_getRecipientViewUrl_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			Url u = client.getRecipientViewUrl(
				UUID.randomUUID(), new Url('https://unit.test.return/'), 'a@b.c', 'a@b.c', 1);
			Test.stopTest();

			System.assertNotEquals(null, u);
		}
	}

	@IsTest
	static void test_getRecipientViewUrl_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getRecipientViewUrl(
					UUID.randomUUID(), new Url('https://unit.test.return/'), 'a@b.c', 'a@b.c', 1);
				throw new AssertException('Expected getRecipientView call to fail');
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
	static void test_getEmbeddedRecipientViewUrl_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			Url u = client.getEmbeddedRecipientViewUrl(
				UUID.randomUUID(), new Url('https://unit.test.return/'), 'a@b.c', UserInfo.getName());
			Test.stopTest();

			System.assertNotEquals(null, u);
		}
	}

	@IsTest
	static void test_getEmbeddedRecipientViewUrl_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getEmbeddedRecipientViewUrl(
					UUID.randomUUID(), new Url('https://unit.test.return/'), 'a@b.c', UserInfo.getName());
				throw new AssertException('Expected getEmbeddedRecipientView call to fail');
			} catch (APIException ex2) {
				ex = ex2;

			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}

	private class UnknownRecipientMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"UNKNOWN_ENVELOPE_RECIPIENT","message":"whatever"}');
			return response;
		}
	}

	@IsTest
	static void test_getRecipientViewUrl_unknown_recipient() {
		Test.setMock(HttpCalloutMock.class, new UnknownRecipientMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				EnvelopeAPI.getInstance().getRecipientViewUrl(UUID.randomUUID(), new Url('https://unit.test.return/'),
					'a@b.c', 'a@b.c', 1);
				throw new AssertException('Expected getRecipientView call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.UNKNOWN_RECIPIENT, ex.error.code);
				System.assertEquals(Label.UnknownEnvelopeRecipient, ex.error.description);
			}
			Test.stopTest();
		}
	}

	private class InvalidSequenceMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"RECIPIENT_NOT_IN_SEQUENCE","message":"whatever"}');
			return response;
		}
	}

	@IsTest
	static void test_getRecipientViewUrl_invalid_sequence() {
		Test.setMock(HttpCalloutMock.class, new InvalidSequenceMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				EnvelopeAPI.getInstance().getRecipientViewUrl(UUID.randomUUID(), new Url('https://unit.test.return/'),
					'a@b.c', 'a@b.c', 1);
				throw new AssertException('Expected getRecipientView call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.INVALID_RECIPIENT_SEQUENCE, ex.error.code);
				System.assertEquals(Label.InvalidRecipientSequence, ex.error.description);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getConsoleViewUrl_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			Url u = client.getConsoleViewUrl(UUID.randomUUID(), new Url('https://unit.test/return'));
			Test.stopTest();

			System.assertNotEquals(null, u);
		}
	}

	@IsTest
	static void test_getConsoleViewUrl_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getConsoleViewUrl(UUID.randomUUID(), new Url('https://unit.test/return'));
				throw new AssertException('Expected getConsoleView call to fail');
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
	static void test_getCorrectViewUrl_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			Url u = client.getCorrectViewUrl(UUID.randomUUID(), new Url('https://unit.test/return'));
			Test.stopTest();

			System.assertNotEquals(null, u);
		}
	}

	@IsTest
	static void test_getCorrectViewUrl_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getCorrectViewUrl(UUID.randomUUID(), new Url('https://unit.test/return'));
				throw new AssertException('Expected getCorrectView call to fail');
			} catch (APIException ex2) {
				ex = ex2;

			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}

	private class CorrectViewErrorMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			String endpoint = request.getEndpoint();
			if (endpoint.contains(ID1.toString())) {
				response.setBody('{"errorCode":"INVALID_ENVELOPE_STATE","message":"Only envelopes in the \'Sent\' or \'Delivered\' states may be corrected."}');
			} else if (endpoint.contains(ID2.toString())) {
				response.setBody('{"errorCode":"ENVELOPE_LOCKED","message":"The envelope is locked."}');
			} else if (endpoint.contains(ID3.toString())) {
				response.setBody('{"errorCode":"USER_NOT_SENDER","message":"This user is not the sender of the envelope."}');
			} else if (endpoint.contains(ID4.toString())) {
				response.setBody('{"errorCode":"ENVELOPE_NOT_FOUND","message":"The envelope specified either does not exist or you have no rights to it"}');
			} else {
				response.setBody('{"errorCode":"RANDOM_ERROR","message":"Random error"}');
			}
			return response;
		}
	}

	@IsTest
	static void test_getCorrectViewUrl_error() {
		Test.setMock(HttpCalloutMock.class, new CorrectViewErrorMock());

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			Url returnUrl = new Url('https://unit.test/return');
			APIException ex1, ex2, ex3, ex4, ex5;

			Test.startTest();
			try {
				client.getCorrectViewUrl(ID1, returnUrl);
				throw new AssertException('Expected getCorrectViewUrl to fail');
			} catch (APIException ex) {
				ex1 = ex;
			}
			try {
				client.getCorrectViewUrl(ID2, returnUrl);
				throw new AssertException('Expected getCorrectViewUrl to fail');
			} catch (APIException ex) {
				ex2 = ex;
			}
			try {
				client.getCorrectViewUrl(ID3, returnUrl);
				throw new AssertException('Expected getCorrectViewUrl to fail');
			} catch (APIException ex) {
				ex3 = ex;
			}
			try {
				client.getCorrectViewUrl(ID4, returnUrl);
				throw new AssertException('Expected getCorrectViewUrl to fail');
			} catch (APIException ex) {
				ex4 = ex;
			}
			try {
				client.getCorrectViewUrl(ID5, returnUrl);
				throw new AssertException('Expected getCorrectViewUrl to fail');
			} catch (APIException ex) {
				ex5 = ex;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex1);
			System.assertNotEquals(null, ex1.error);
			System.assertEquals(Label.InvalidCorrectionState, ex1.error.description);

			System.assertNotEquals(null, ex2);
			System.assertNotEquals(null, ex2.error);
			System.assertEquals(Label.EnvelopeLockedCorrectionInProgress, ex2.error.description);

			System.assertNotEquals(null, ex3);
			System.assertNotEquals(null, ex3.error);
			System.assertEquals(Label.NotEnvelopeOwner, ex3.error.description);

			System.assertNotEquals(null, ex4);
			System.assertNotEquals(null, ex4.error);
			System.assertEquals(Label.EnvelopeNotFoundOrUnauthorized, ex4.error.description);

			System.assertNotEquals(null, ex5);
			System.assertNotEquals(null, ex5.error);
			System.assertEquals('Random error', ex5.error.description);
		}
	}

	@IsTest
	static void test_resendEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			System.assert(client.resendEnvelope(UUID.randomUUID()));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resendEnvelope_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.resendEnvelope(UUID.randomUUID());
				throw new AssertException('Expected resendEnvelope to fail');
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
	static void test_resendRecipients_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			List<Recipient.ResendResult> result = EnvelopeAPI.getInstance().resendRecipients(UUID.randomUUID(), new List<Recipient> {
				Recipient.fromSource('n', 'r@unit.test', null, null, null)
			});
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
		}
	}

	private class ResendRecipientsPartialSuccessMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"recipientUpdateResults": [{"recipientId": "1","errorDetails": {"errorCode": "SUCCESS","message": null}},{"recipientId": "2","errorDetails": {"errorCode": "UNIT_TEST","message": "Unit test error 1"}},{"recipientId": "3","errorDetails": {"errorCode": "SUCCESS","message": null}},{"recipientId": "4","errorDetails": {"errorCode": "SUCCESS","message": null}},{"recipientId": "5","errorDetails": {"errorCode": "UNKNOWN_ENVELOPE_RECIPIENT","message": "Recipient not found"}},{"recipientId": "6","errorDetails": {"errorCode": "SUCCESS","message": null}}]}');
			return response;
		}
	}

	@IsTest
	static void test_resendRecipients_success_partial() {
		Test.setMock(HttpCalloutMock.class, new ResendRecipientsPartialSuccessMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			List<Recipient.ResendResult> result = EnvelopeAPI.getInstance().resendRecipients(UUID.randomUUID(), new List<Recipient> {
				Recipient.fromSource('n', 'r@unit.test', null, null, null)
			});
			Test.stopTest();

			System.assertEquals(6, Collection.size(result));
			Integer sequence = 1;
			for (Recipient.ResendResult rr : result) {
				System.assertNotEquals(null, rr);
				System.assertEquals(sequence, rr.sequence);
				System.assertNotEquals(null, rr.error);
				if (sequence == 2) {
					System.assertEquals(APIErrorCode.BAD_REQUEST, rr.error.code);
					System.assertEquals('Unit test error 1', rr.error.description);
				} else if (sequence == 5) {
					System.assertEquals(APIErrorCode.UNKNOWN_RECIPIENT, rr.error.code);
					System.assertEquals(Label.UnknownEnvelopeRecipient, rr.error.description);
				} else {
					System.assertEquals(APIError.none, rr.error);
				}
				sequence++;
			}
		}
	}

	@IsTest
	static void test_resendRecipients_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				EnvelopeAPI.getInstance().resendRecipients(UUID.randomUUID(), new List<Recipient> {
					Recipient.fromSource('n', 'r@unit.test', null, null, null)
				});
				throw new AssertException('Expected resendRecipients to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateInPersonSigner_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			System.assert(client.updateInPersonSigner(UUID.randomUUID(), 'unit@test.com'));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateInPersonSigner_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex;

			Test.startTest();
			try {
				client.updateInPersonSigner(UUID.randomUUID(), 'unit@test.com');
				throw new AssertException('Expected updateInPersonSigner to fail');
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
	static void test_voidEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			System.assert(client.voidEnvelope(UUID.randomUUID(), 'Just because'));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_voidEnvelope_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex1;

			Test.startTest();
			try {
				client.voidEnvelope(UUID.randomUUID(), 'Just because');
				throw new AssertException('Expected voidEnvelope to fail');
			} catch (APIException ex) {
				ex1 = ex;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex1);
			System.assertNotEquals(null, ex1.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex1.error.code);
		}
	}

	private class VoidEnvelopeErrorMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			if (request.getEndpoint().contains(ID1.toString())) {
				response.setBody('{"errorCode":"USER_NOT_SENDER","message":"This user is not the sender of the envelope."}');
			} else {
				response.setBody('{"errorCode":"GENERIC_ERROR","message":"Some error"}');
			}
			return response;
		}
	}

	@IsTest
	static void test_voidEnvelope_errors() {
		Test.setMock(HttpCalloutMock.class, new VoidEnvelopeErrorMock());

		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex1, ex2;

			Test.startTest();
			try {
				client.voidEnvelope(ID1, 'Just because');
				throw new AssertException('Expected voidEnvelope to fail');
			} catch (APIException ex) {
				ex1 = ex;
			}
			try {
				client.voidEnvelope(ID2, 'Just because');
				throw new AssertException('Expected voidEnvelope to fail');
			} catch (APIException ex) {
				ex2 = ex;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex1);
			System.assertNotEquals(null, ex1.error);
			System.assertEquals(Label.NotEnvelopeOwner, ex1.error.description);

			System.assertNotEquals(null, ex2);
			System.assertNotEquals(null, ex2.error);
			System.assertEquals('Some error', ex2.error.description);
		}
	}

	@IsTest
	static void test_createEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			TestUtils.createEnvelopeLocalization(Localization.DE);

			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope e2 = new Envelope(
				e1.Id,
				e1.Name,
				null,
				null,
				new List<Document> {
					new Document(null, Document.TYPE_TEMPLATE, 1, 'Doc1', null, 100, Datetime.now(), UUID.randomUUID().toString()),
					Document.fromFile(TestUtils.createContentVersion()).withSequence(2)
				},
				new List<Recipient> {
					Recipient.newInPersonSigner(1, new Recipient.Role('Signer 1', 1), 'Recipient One', 'r1@unit.test',
						'Host One', 'h1@unit.test', new Recipient.Authentication('1234', true,
							new List<String> { '5555555555' }), 'note1', true).withSequence(1),
					Recipient.newRecipient(2, Recipient.TYPE_SIGNER, new Recipient.Role('Signer 2', 2), 'Recipient Two',
						'r2@unit.test', null, 'note2', false)
						.withSequence(2)
						.withEmailSettings(new Recipient.EmailSettings('DE', Label.German, 'DE subject', 'DE message'))
				},
				new List<CustomField> {
					CustomField.newTextField('cf1', '1', true, true),
					CustomField.newListField('cf2', '2', new List<String> { '1', '2', '3' }, true, true)
				},
				new Notifications(false, 0, 0, false, 0, 0),
				'subject',
				'body',
				new Entity(o.Id),
				null);
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			UUID result = client.createEnvelope(
				e2,
				true,
				'Unit Test');
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_createEnvelope_success_with_Recipient_EmailSettings() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			TestUtils.createEnvelopeLocalization(Localization.DE);

			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope e2 = new Envelope(
				e1.Id,
				e1.Name,
				null,
				null,
				new List<Document> {
					new Document(null, Document.TYPE_TEMPLATE, 1, 'Doc1', null, 100, Datetime.now(), UUID.randomUUID().toString()),
					Document.fromFile(TestUtils.createContentVersion()).withSequence(2)
				},
				new List<Recipient> {
					Recipient.newInPersonSigner(1, new Recipient.Role('Signer 1', 1), 'Recipient One', 'r1@unit.test',
						'Host One', 'h1@unit.test', new Recipient.Authentication('1234', true,
							new List<String> { '5555555555' }), 'note1', true).withSequence(1).withEmailSettings(new Recipient.EmailSettings(
						Localization.KO,
						Localization.getLabel(Localization.KO),
						'ko subject',
						'ko message')),
					Recipient.newRecipient(2, Recipient.TYPE_SIGNER, new Recipient.Role('Signer 2', 2), 'Recipient Two',
						'r2@unit.test', null, 'note2', false).withSequence(2).withEmailSettings(new Recipient.EmailSettings(
						Localization.NL,
						Localization.getLabel(Localization.NL),
						'nl subject',
						'nl message'))
				},
				new List<CustomField> {
					CustomField.newTextField('cf1', '1', true, true),
					CustomField.newListField('cf2', '2', new List<String> { '1', '2', '3' }, true, true)
				},
				null,
				'subject',
				'body',
				new Entity(o.Id),
				null);
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			UUID result = client.createEnvelope(
				e2,
				true,
				'Unit Test');
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_buildCompositeTemplates_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Envelope__c e1 = TestUtils.createEnvelope();
			Document doc = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(e1.Id));
			List<CustomField> cfs = new List<CustomField> {
				CustomField.newTextField('cf1', '1', true, true),
				CustomField.newListField('cf2', '2', new List<String> { '1', '2', '3' }, true, true)
			};
			Map<String, Blob> content = EnvelopeAPI.getDocumentContent(
				new List<Document> { doc }, true);

			Test.startTest();
			List<EnvelopeAPI.APICompositeTemplate> compositeTemplatesList = EnvelopeAPI.buildCompositeTemplates(
				new List<Document> {
					new Document(null, Document.TYPE_TEMPLATE, 1, 'Doc1', null, 100, Datetime.now(), UUID.randomUUID().toString()),
					doc
				},
				new List<Recipient> {
					Recipient.newInPersonSigner(1, new Recipient.Role('Signer 1', 1), 'Recipient One', 'r1@unit.test',
						'Host One', 'h1@unit.test', new Recipient.Authentication('1234', true,
							new List<String> { '5555555555' }), 'note1', true),
					Recipient.newRecipient(2, Recipient.TYPE_SIGNER, new Recipient.Role('Signer 2', 2),
						'Recipient Two', 'r2@unit.test', null, 'note2', false)
				},
				content,
				cfs,
				new Envelope.Options(
					false,
					null,
					null,
					null),
				new Entity(o.Id));
			Test.stopTest();

			System.assertEquals(2, compositeTemplatesList.size());
			System.assertEquals(1, compositeTemplatesList[0].serverTemplates.size());
			System.assertEquals(1, compositeTemplatesList[1].inlineTemplates.size());
			System.assertEquals('2', compositeTemplatesList[1].inlineTemplates[0].recipients.signers[0].routingOrder);
			System.assertNotEquals(null, compositeTemplatesList[0].inlineTemplates[0].customFields);
			System.assertNotEquals(null, compositeTemplatesList[0].inlineTemplates[0].customFields.listCustomFields);
			System.assertNotEquals(null, compositeTemplatesList[0].inlineTemplates[0].customFields.textCustomFields);
			System.assertEquals(1, compositeTemplatesList[0].inlineTemplates[0].customFields.listCustomFields.size());
			System.assertNotEquals(null, compositeTemplatesList[1].inlineTemplates[0].customFields);
			System.assertNotEquals(null, compositeTemplatesList[1].inlineTemplates[0].customFields.listCustomFields);
			System.assertNotEquals(null, compositeTemplatesList[1].inlineTemplates[0].customFields.textCustomFields);
			System.assertEquals(1, compositeTemplatesList[1].inlineTemplates[0].customFields.listCustomFields.size());
		}
	}

	@IsTest
	static void test_createEnvelope_recipient_types() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			TestUtils.createEnvelopeDocument(e1.Id);
			Envelope e2 = new Envelope(e1.Id, e1.Name, null, null,
				new List<Document>(),
				new List<Recipient> {
					Recipient.newRecipient(1, Recipient.TYPE_AGENT, new Recipient.Role('Signer 1', 1),
						'Recipient One', 'r1@unit.test', null, null, false),
					Recipient.newRecipient(2, Recipient.TYPE_CARBON_COPY, new Recipient.Role('Signer 2', 2),
						'Recipient Two', 'r2@unit.test', null, null, false),
					Recipient.newRecipient(3, Recipient.TYPE_CERTIFIED_DELIVERY, new Recipient.Role('Signer 3', 3),
						'Recipient Three', 'r3@unit.test', null, null, false),
					Recipient.newRecipient(4, Recipient.TYPE_EDITOR, new Recipient.Role('Signer 4', 4),
						'Recipient Four', 'r4@unit.test', null, null, false),
					Recipient.newRecipient(5, Recipient.TYPE_INTERMEDIARY, new Recipient.Role('Signer 5', 5),
						'Recipient Five', 'r5@unit.test', null, null, false)
				},
				new List<CustomField>(),
				new Notifications(false, 0, 0, false, 0, 0), 'subject', 'body',
				null, null);
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			UUID result = client.createEnvelope(
				e2,
				true,
				'Unit Test');
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_createEnvelope_document_types() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Envelope__c e1 = TestUtils.createEnvelope();
			Document__c d1 = TestUtils.createEnvelopeDocument(e1.Id, TestUtils.createDocument(UserInfo.getUserId()), 1);
			Document__c d2 = TestUtils.createEnvelopeDocument(e1.Id, TestUtils.createContentVersion(), 2);
			Document__c d3 = TestUtils.createEnvelopeDocument(e1.Id, TestUtils.createContentVersion(), 3);
			Integer sequence = 1;
			List<Document> docs = new List<Document> {
				new Document(d1.Id, d1.Type__c, sequence++, d1.Name, d1.Extension__c, Integer.valueOf(d1.Size__c), d1.LastModified__c, d1.SourceId__c),
				new Document(d2.Id, d2.Type__c, sequence++, d2.Name, d2.Extension__c, Integer.valueOf(d2.Size__c), d2.LastModified__c, d2.SourceId__c),
				new Document(d3.Id, d3.Type__c, sequence++, d3.Name, d3.Extension__c, Integer.valueOf(d3.Size__c), d3.LastModified__c, d3.SourceId__c)
			};
			Envelope e2 = new Envelope(e1.Id, e1.Name, null, null,
				docs,
				new List<Recipient>(),
				new List<CustomField>(),
				new Notifications(false, 0, 0, false, 0, 0),
				'subject',
				'body',
				null,
				null);
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			Test.startTest();
			UUID result = client.createEnvelope(
				e2,
				true,
				'Unit Test');
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_createEnvelope_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(
					e,
					true,
					'Unit Test');
				throw new AssertException('Expected createEnvelope to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createEnvelope_null_envelope() {
		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(
					null,
					true,
					'Unit Test');
				throw new AssertException('Expected createEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedEnvelope, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createEnvelope_fetch_invalid_document() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());
		System.runAs(UserMock.createDocuSignUser()) {
			Permissions.sessionParameters = new Map<String, Boolean> {
				Permissions.KEY_IMPERSONATING => false,
				Permissions.KEY_API_ENABLED => false // force disable document fetch
			};
			Envelope__c e1 = TestUtils.createEnvelope();
			Document__c d = new Document__c(
				Envelope__c = e1.Id,
				Name = 'Unit Test',
				SourceId__c = UserInfo.getUserId(), // Bad document type
				LastModified__c = Datetime.now(),
				Sequence__c = 1,
				Size__c = 1234,
				Extension__c = 'pdf',
				Type__c = Document.TYPE_FILE);
			insert d;
			Envelope e2 = new Envelope(e1.Id, e1.Name, null, null,
				new List<Document> { DocumentService.DB.convert(d) },
				new List<Recipient>(),
				new List<CustomField>(),
				new Notifications(false, 0, 0, false, 0, 0),
				'subject',
				'body',
				null,
				null);
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(
					e2,
					true,
					'Unit Test');
				throw new AssertException('Expected createEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotReadDocumentContent_1,
					new List<String> { d.Name + ' (' + d.SourceId__c + ')' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	class CfrErrorMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"CFR_ERROR","message":"Signers that are required to meet 21 CFR part 11"}');
			return response;
		}
	}

	@IsTest
	static void test_createEnvelope_error_21_cfr_part_11() {
		Test.setMock(HttpCalloutMock.class, new CfrErrorMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(
					e,
					false,
					'Unit Test');
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.FAILED_TO_MEET_21_CFR_PART_11, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class UserNotActivatedErrorMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"USER_NOT_ACTIVATED","message":"Account settings indicate the recipient must be an active DocuSign user"}');
			return response;
		}
	}

	@IsTest
	static void test_createEnvelope_error_user_not_activated() {
		Test.setMock(HttpCalloutMock.class, new UserNotActivatedErrorMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(
					e,
					false,
					'Unit Test');
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.USER_NOT_ACTIVATED, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class TrialExpiredErrorMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"TRIAL_ACCOUNT_EXPIRED","message":"trialexpired"}');
			return response;
		}
	}

	@IsTest
	static void test_createEnvelope_error_trial_expired() {
		Test.setMock(HttpCalloutMock.class, new TrialExpiredErrorMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(
					e,
					false,
					'Unit Test');
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.TRIAL_ACCOUNT_EXPIRED, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class AccountPermissionErrorMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"ACCOUNT_LACKS_PERMISSIONS","message":"account lacks sufficient permissions"}');
			return response;
		}
	}

	@IsTest
	static void test_createEnvelope_error_account_permissions() {
		Test.setMock(HttpCalloutMock.class, new AccountPermissionErrorMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(
					e,
					false,
					'Unit Test');
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.ACCOUNT_LACKS_PERMISSIONS, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class InvalidDocumentErrorMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"INVALID_DOCUMENT","message":"unable to convert this document"}');
			return response;
		}
	}

	@IsTest
	static void test_createEnvelope_error_invalid_document() {
		Test.setMock(HttpCalloutMock.class, new InvalidDocumentErrorMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(
					e,
					false,
					'Unit Test');
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.INVALID_DOCUMENT, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class InvalidSigningGroupErrorMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"INVALID_SIGNING_GROUP","message":"Group has no members"}');
			return response;
		}
	}

	@IsTest
	static void test_createEnvelope_error_invalid_signing_group() {
		Test.setMock(HttpCalloutMock.class, new InvalidSigningGroupErrorMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(
					e,
					false,
					'Unit Test');
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.INVALID_SIGNING_GROUP, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class InvalidRecipientErrorMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"INVALID_RECIPIENT","message":"user name for the recipient is invalid"}');
			return response;
		}
	}

	@IsTest
	static void test_createEnvelope_error_invalid_recipient() {
		Test.setMock(HttpCalloutMock.class, new InvalidRecipientErrorMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(
					e,
					false,
					'Unit Test');
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.INVALID_RECIPIENT, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRecipientCustomFields() {
		System.runAs(UserMock.createDocuSignUser()) {
			Recipient r = Recipient.newRecipient(1, Recipient.TYPE_SIGNER, null, 'UNIT TEST', 'r@unit.test', null, null, false);
			Entity e = Entity.resolve(UserInfo.getUserId());

			Test.startTest();
			System.assertEquals(null, EnvelopeAPI.getRecipientCustomFields(null));
			System.assertEquals(null, EnvelopeAPI.getRecipientCustomFields(r));
			System.assertEquals(new List<String> { '##SFSource:' + UserInfo.getUserId() + '~User' },
				EnvelopeAPI.getRecipientCustomFields(r.withSource(e)));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEnvelopeStatus_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				EnvelopeAPI.getInstance().getEnvelopeStatus(UUID.randomUUID(), true);
				throw new AssertException('Expected getEnvelopeStatus to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	private class StatusCreatedMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"status":"created","emailSubject":"Unit test subject","emailBlurb":"Unit test message","envelopeId":"11111111-1111-1111-1111-111111111111","createdDateTime":"2018-04-18T22:05:43.7670000Z","lastModifiedDateTime":"2018-04-18T22:05:51.0800000Z","notification":{"reminders":{"reminderEnabled":"true","reminderDelay":"2","reminderFrequency":"1"},"expirations":{"expireEnabled":"true","expireAfter":"10","expireWarn":"5"}},"recipients":{"signers":[{"name":"Signer","email":"signer@unit.test","recipientId":"1","recipientIdGuid":"11111111-1111-1111-1111-111111111111","userId":"11111111-1111-1111-1111-111111111111","routingOrder":"1","status":"created"}],"agents":[{"name":"Agent","email":"agent@unit.test","recipientId":"2","recipientIdGuid":"22222222-2222-2222-2222-222222222222","userId":"22222222-2222-2222-2222-222222222222","routingOrder":"2","status":"created"}],"editors":[{"name":"Editor","email":"editor@unit.test","recipientId":"3","recipientIdGuid":"33333333-3333-3333-3333-333333333333","userId":"33333333-3333-3333-3333-333333333333","routingOrder":"3","status":"created"}],"intermediaries":[{"name":"Intermediary","email":"intermediary@unit.test","recipientId":"4","recipientIdGuid":"44444444-4444-4444-4444-444444444444","userId":"44444444-4444-4444-4444-444444444444","routingOrder":"4","status":"created"}],"carbonCopies":[{"name":"Carbon Copy","email":"carbon.copy@unit.test","recipientId":"5","recipientIdGuid":"55555555-5555-5555-5555-555555555555","userId":"55555555-5555-5555-5555-555555555555","routingOrder":"5","status":"created"}],"certifiedDeliveries":[{"name":"Certified Delivery","email":"carbon.copy.1@unit.test","recipientId":"6","recipientIdGuid":"66666666-6666-6666-6666-666666666666","userId":"66666666-6666-6666-6666-666666666666","routingOrder":"6","status":"created"}],"inPersonSigners":[{"hostName":"Host","hostEmail":"host@unit.test","signerName":"In Person Signer","signerEmail":"in.person.signer@unit.test","recipientId":"7","recipientIdGuid":"77777777-7777-7777-7777-777777777777","userId":"77777777-7777-7777-7777-777777777777","routingOrder":"7","status":"created"}]}}');
			return response;
		}
	}

	@IsTest
	static void test_getEnvelopeStatus_created() {
		Test.setMock(HttpCalloutMock.class, new StatusCreatedMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Envelope.Status result = EnvelopeAPI.getInstance().getEnvelopeStatus(UUID.randomUUID(), true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Envelope.STATUS_CREATED, result.status);
			System.assertEquals(UserInfo.getName(), result.senderName);
			System.assertEquals(UserInfo.getUserEmail(), result.senderEmail);
			System.assertEquals(null, result.sent);
			System.assertEquals(null, result.expires);
			System.assertEquals(null, result.completed);
			System.assertEquals('Unit test subject', result.emailSubject);
			System.assertEquals(null, result.reason);
			System.assertNotEquals(null, result.lastStatusUpdate);
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(7, result.recipients.size());
			Integer i = 1;
			for (Recipient.Status rs : result.recipients) {
				System.assertNotEquals(null, rs);
				System.assertEquals(Recipient.STATUS_CREATED, rs.status);
				System.assertEquals(i, rs.sequence);
				System.assertNotEquals(null, rs.type);
				System.assertNotEquals(null, rs.name);
				System.assertNotEquals(null, rs.email);
				System.assertEquals(i, rs.routingOrder);
				System.assertEquals(null, rs.sent);
				System.assertEquals(null, rs.completed);
				System.assertEquals(null, rs.reason);
				System.assertNotEquals(null, rs.lastStatusUpdate);
				i++;
			}
		}
	}

	private class StatusSentMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"status":"sent","emailSubject":"Unit test subject","emailBlurb":"Unit test message","envelopeId":"11111111-1111-1111-1111-111111111111","createdDateTime":"2018-04-18T22:05:43.7670000Z","lastModifiedDateTime":"2018-04-18T22:05:51.0800000Z","deliveredDateTime":"2018-04-18T22:06:15.1370000Z","initialSentDateTime":"2018-04-18T22:05:51.6100000Z","sentDateTime":"2018-04-18T22:06:06.2770000Z","statusChangedDateTime":"2018-04-18T22:06:22.5730000Z","notification":{"reminders":{"reminderEnabled":"true","reminderDelay":"2","reminderFrequency":"1"},"expirations":{"expireEnabled":"true","expireAfter":"10","expireWarn":"5"}},"recipients":{"signers":[{"name":"Signer","email":"signer@unit.test","recipientId":"1","recipientIdGuid":"11111111-1111-1111-1111-111111111111","userId":"11111111-1111-1111-1111-111111111111","routingOrder":"1","status":"delivered","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"agents":[{"name":"Agent","email":"agent@unit.test","recipientId":"2","recipientIdGuid":"22222222-2222-2222-2222-222222222222","userId":"22222222-2222-2222-2222-222222222222","routingOrder":"2","status":"created"}],"editors":[{"name":"Editor","email":"editor@unit.test","recipientId":"3","recipientIdGuid":"33333333-3333-3333-3333-333333333333","userId":"33333333-3333-3333-3333-333333333333","routingOrder":"3","status":"created"}],"intermediaries":[{"name":"Intermediary","email":"intermediary@unit.test","recipientId":"4","recipientIdGuid":"44444444-4444-4444-4444-444444444444","userId":"44444444-4444-4444-4444-444444444444","routingOrder":"4","status":"created"}],"carbonCopies":[{"name":"Carbon Copy","email":"carbon.copy@unit.test","recipientId":"5","recipientIdGuid":"55555555-5555-5555-5555-555555555555","userId":"55555555-5555-5555-5555-555555555555","routingOrder":"5","status":"created"}],"certifiedDeliveries":[{"name":"Certified Delivery","email":"carbon.copy.1@unit.test","recipientId":"6","recipientIdGuid":"66666666-6666-6666-6666-666666666666","userId":"66666666-6666-6666-6666-666666666666","routingOrder":"6","status":"created"}],"inPersonSigners":[{"hostName":"Host","hostEmail":"host@unit.test","signerName":"In Person Signer","signerEmail":"in.person.signer@unit.test","recipientId":"7","recipientIdGuid":"77777777-7777-7777-7777-777777777777","userId":"77777777-7777-7777-7777-777777777777","routingOrder":"7","status":"created"}]}}');
			return response;
		}
	}

	@IsTest
	static void test_getEnvelopeStatus_sent() {
		Test.setMock(HttpCalloutMock.class, new StatusSentMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Envelope.Status result = EnvelopeAPI.getInstance().getEnvelopeStatus(UUID.randomUUID(), true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Envelope.STATUS_SENT, result.status);
			System.assertNotEquals(null, result.sent);
			System.assertNotEquals(null, result.expires);
			System.assertEquals(10, Date.valueOf(result.sent).daysBetween(Date.valueOf(result.expires)));
			System.assertEquals(null, result.completed);
			System.assertEquals('Unit test subject', result.emailSubject);
			System.assertEquals(null, result.reason);
			System.assertNotEquals(null, result.lastStatusUpdate);
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(7, result.recipients.size());
			Integer i = 1;
			for (Recipient.Status rs : result.recipients) {
				System.assertNotEquals(null, rs);
				System.assertEquals(i, rs.sequence);
				System.assertNotEquals(null, rs.type);
				System.assertNotEquals(null, rs.name);
				System.assertNotEquals(null, rs.email);
				System.assertEquals(i, rs.routingOrder);
				System.assertEquals(null, rs.completed);
				System.assertEquals(null, rs.reason);
				System.assertNotEquals(null, rs.lastStatusUpdate);
				if (i == 1) {
					System.assertEquals(Recipient.STATUS_DELIVERED, rs.status);
					System.assertNotEquals(null, rs.sent);
				} else {
					System.assertEquals(Recipient.STATUS_CREATED, rs.status);
					System.assertEquals(null, rs.sent);
				}
				i++;
			}
		}
	}

	private class StatusCompletedMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"status":"completed","emailSubject":"Unit test subject","emailBlurb":"Unit test message","envelopeId":"11111111-1111-1111-1111-111111111111","createdDateTime":"2018-04-18T22:05:43.7670000Z","lastModifiedDateTime":"2018-04-18T22:05:51.0800000Z","deliveredDateTime":"2018-04-18T22:06:15.1370000Z","initialSentDateTime":"2018-04-18T22:05:51.6100000Z","sentDateTime":"2018-04-18T22:06:06.2770000Z","completedDateTime":"2018-04-18T22:06:22.5730000Z","statusChangedDateTime":"2018-04-18T22:06:22.5730000Z","recipients":{"signers":[{"name":"Signer","email":"signer@unit.test","recipientId":"1","recipientIdGuid":"11111111-1111-1111-1111-111111111111","userId":"11111111-1111-1111-1111-111111111111","routingOrder":"1","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"agents":[{"name":"Agent","email":"agent@unit.test","recipientId":"2","recipientIdGuid":"22222222-2222-2222-2222-222222222222","userId":"22222222-2222-2222-2222-222222222222","routingOrder":"2","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"editors":[{"name":"Editor","email":"editor@unit.test","recipientId":"3","recipientIdGuid":"33333333-3333-3333-3333-333333333333","userId":"33333333-3333-3333-3333-333333333333","routingOrder":"3","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"intermediaries":[{"name":"Intermediary","email":"intermediary@unit.test","recipientId":"4","recipientIdGuid":"44444444-4444-4444-4444-444444444444","userId":"44444444-4444-4444-4444-444444444444","routingOrder":"4","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"carbonCopies":[{"name":"Carbon Copy","email":"carbon.copy@unit.test","recipientId":"5","recipientIdGuid":"55555555-5555-5555-5555-555555555555","userId":"55555555-5555-5555-5555-555555555555","routingOrder":"5","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"certifiedDeliveries":[{"name":"Certified Delivery","email":"carbon.copy.1@unit.test","recipientId":"6","recipientIdGuid":"66666666-6666-6666-6666-666666666666","userId":"66666666-6666-6666-6666-666666666666","routingOrder":"6","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"inPersonSigners":[{"hostName":"Host","hostEmail":"host@unit.test","signerName":"In Person Signer","signerEmail":"in.person.signer@unit.test","recipientId":"7","recipientIdGuid":"77777777-7777-7777-7777-777777777777","userId":"77777777-7777-7777-7777-777777777777","routingOrder":"7","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}]}}');
			return response;
		}
	}

	@IsTest
	static void test_getEnvelopeStatus_completed() {
		Test.setMock(HttpCalloutMock.class, new StatusCompletedMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Envelope.Status result = EnvelopeAPI.getInstance().getEnvelopeStatus(UUID.randomUUID(), true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Envelope.STATUS_COMPLETED, result.status);
			System.assertNotEquals(null, result.sent);
			System.assertNotEquals(null, result.completed);
			System.assertEquals('Unit test subject', result.emailSubject);
			System.assertEquals(null, result.reason);
			System.assertNotEquals(null, result.lastStatusUpdate);
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(7, result.recipients.size());
			Integer i = 1;
			for (Recipient.Status rs : result.recipients) {
				System.assertNotEquals(null, rs);
				System.assertEquals(i, rs.sequence);
				System.assertEquals(Recipient.STATUS_COMPLETED, rs.status);
				System.assertNotEquals(null, rs.type);
				System.assertNotEquals(null, rs.name);
				System.assertNotEquals(null, rs.email);
				System.assertEquals(i, rs.routingOrder);
				System.assertNotEquals(null, rs.sent);
				System.assertNotEquals(null, rs.completed);
				System.assertEquals(null, rs.reason);
				System.assertNotEquals(null, rs.lastStatusUpdate);
				i++;
			}
		}
	}

	private class StatusDeclinedMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"status":"declined","emailSubject":"Unit test subject","emailBlurb":"Unit test message","envelopeId":"11111111-1111-1111-1111-111111111111","createdDateTime":"2018-04-18T22:05:43.7670000Z","lastModifiedDateTime":"2018-04-18T22:05:51.0800000Z","deliveredDateTime":"2018-04-18T22:06:15.1370000Z","initialSentDateTime":"2018-04-18T22:05:51.6100000Z","sentDateTime":"2018-04-18T22:06:06.2770000Z","completedDateTime":"2018-04-18T22:06:22.5730000Z","declinedDateTime":"2018-04-18T22:06:22.5730000Z","statusChangedDateTime":"2018-04-18T22:06:22.5730000Z","recipients":{"signers":[{"name":"Signer","email":"signer@unit.test","recipientId":"1","recipientIdGuid":"11111111-1111-1111-1111-111111111111","userId":"11111111-1111-1111-1111-111111111111","routingOrder":"1","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"agents":[{"name":"Agent","email":"agent@unit.test","recipientId":"2","recipientIdGuid":"22222222-2222-2222-2222-222222222222","userId":"22222222-2222-2222-2222-222222222222","routingOrder":"2","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"editors":[{"name":"Editor","email":"editor@unit.test","recipientId":"3","recipientIdGuid":"33333333-3333-3333-3333-333333333333","userId":"33333333-3333-3333-3333-333333333333","routingOrder":"3","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"intermediaries":[{"name":"Intermediary","email":"intermediary@unit.test","recipientId":"4","recipientIdGuid":"44444444-4444-4444-4444-444444444444","userId":"44444444-4444-4444-4444-444444444444","routingOrder":"4","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"carbonCopies":[{"name":"Carbon Copy","email":"carbon.copy@unit.test","recipientId":"5","recipientIdGuid":"55555555-5555-5555-5555-555555555555","userId":"55555555-5555-5555-5555-555555555555","routingOrder":"5","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"certifiedDeliveries":[{"name":"Certified Delivery","email":"carbon.copy.1@unit.test","recipientId":"6","recipientIdGuid":"66666666-6666-6666-6666-666666666666","userId":"66666666-6666-6666-6666-666666666666","routingOrder":"6","status":"declined","deliveredDateTime":"2018-04-18T22:05:57.9470000Z","declinedDateTime":"2018-04-18T22:05:57.9470000Z","declinedReason":"declined to sign"}],"inPersonSigners":[{"hostName":"Host","hostEmail":"host@unit.test","signerName":"In Person Signer","signerEmail":"in.person.signer@unit.test","recipientId":"7","recipientIdGuid":"77777777-7777-7777-7777-777777777777","userId":"77777777-7777-7777-7777-777777777777","routingOrder":"7","status":"created"}]}}');
			return response;
		}
	}

	@IsTest
	static void test_getEnvelopeStatus_declined() {
		Test.setMock(HttpCalloutMock.class, new StatusDeclinedMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Envelope.Status result = EnvelopeAPI.getInstance().getEnvelopeStatus(UUID.randomUUID(), true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Envelope.STATUS_DECLINED, result.status);
			System.assertNotEquals(null, result.sent);
			System.assertNotEquals(null, result.completed);
			System.assertEquals('Unit test subject', result.emailSubject);
			System.assertEquals(null, result.reason);
			System.assertNotEquals(null, result.lastStatusUpdate);
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(7, result.recipients.size());
			Integer i = 1;
			for (Recipient.Status rs : result.recipients) {
				System.assertNotEquals(null, rs);
				System.assertEquals(i, rs.sequence);
				if (i == 7) {
					System.assertEquals(Recipient.STATUS_CREATED, rs.status);
					System.assertEquals(null, rs.sent);
					System.assertEquals(null, rs.completed);
					System.assertEquals(null, rs.reason);
				} else if (i == 6) {
					System.assertEquals(Recipient.STATUS_DECLINED, rs.status);
					System.assertNotEquals(null, rs.sent);
					System.assertNotEquals(null, rs.completed);
					System.assertEquals('declined to sign', rs.reason);
				} else {
					System.assertEquals(Recipient.STATUS_COMPLETED, rs.status);
					System.assertNotEquals(null, rs.sent);
					System.assertNotEquals(null, rs.completed);
					System.assertEquals(null, rs.reason);
				}
				System.assertNotEquals(null, rs.type);
				System.assertNotEquals(null, rs.name);
				System.assertNotEquals(null, rs.email);
				System.assertEquals(i, rs.routingOrder);
				System.assertNotEquals(null, rs.lastStatusUpdate);
				i++;
			}
		}
	}

	private class StatusVoidedMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"status":"voided","emailSubject":"Unit test subject","emailBlurb":"Unit test message","envelopeId":"11111111-1111-1111-1111-111111111111","createdDateTime":"2018-04-18T22:05:43.7670000Z","lastModifiedDateTime":"2018-04-18T22:05:51.0800000Z","deliveredDateTime":"2018-04-18T22:06:15.1370000Z","initialSentDateTime":"2018-04-18T22:05:51.6100000Z","sentDateTime":"2018-04-18T22:06:06.2770000Z","completedDateTime":"2018-04-18T22:06:22.5730000Z","statusChangedDateTime":"2018-04-18T22:06:22.5730000Z","voidedDateTime":"2018-04-19T01:01:01.10000000Z","voidedReason":"voided envelope","recipients":{"signers":[{"name":"Signer","email":"signer@unit.test","recipientId":"1","recipientIdGuid":"11111111-1111-1111-1111-111111111111","userId":"11111111-1111-1111-1111-111111111111","routingOrder":"1","status":"delivered","deliveredDateTime":"2018-04-18T22:06:06.2770000Z"}],"agents":[{"name":"Agent","email":"agent@unit.test","recipientId":"2","recipientIdGuid":"22222222-2222-2222-2222-222222222222","userId":"22222222-2222-2222-2222-222222222222","routingOrder":"2","status":"created"}],"editors":[{"name":"Editor","email":"editor@unit.test","recipientId":"3","recipientIdGuid":"33333333-3333-3333-3333-333333333333","userId":"33333333-3333-3333-3333-333333333333","routingOrder":"3","status":"created"}],"intermediaries":[{"name":"Intermediary","email":"intermediary@unit.test","recipientId":"4","recipientIdGuid":"44444444-4444-4444-4444-444444444444","userId":"44444444-4444-4444-4444-444444444444","routingOrder":"4","status":"created"}],"carbonCopies":[{"name":"Carbon Copy","email":"carbon.copy@unit.test","recipientId":"5","recipientIdGuid":"55555555-5555-5555-5555-555555555555","userId":"55555555-5555-5555-5555-555555555555","routingOrder":"5","status":"created"}],"certifiedDeliveries":[{"name":"Certified Delivery","email":"carbon.copy.1@unit.test","recipientId":"6","recipientIdGuid":"66666666-6666-6666-6666-666666666666","userId":"66666666-6666-6666-6666-666666666666","routingOrder":"6","status":"created"}],"inPersonSigners":[{"hostName":"Host","hostEmail":"host@unit.test","signerName":"In Person Signer","signerEmail":"in.person.signer@unit.test","recipientId":"7","recipientIdGuid":"77777777-7777-7777-7777-777777777777","userId":"77777777-7777-7777-7777-777777777777","routingOrder":"7","status":"created"}]}}');
			return response;
		}
	}

	@IsTest
	static void test_getEnvelopeStatus_voided() {
		Test.setMock(HttpCalloutMock.class, new StatusVoidedMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Envelope.Status result = EnvelopeAPI.getInstance().getEnvelopeStatus(UUID.randomUUID(), true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Envelope.STATUS_VOIDED, result.status);
			System.assertNotEquals(null, result.sent);
			System.assertNotEquals(null, result.completed);
			System.assertEquals('Unit test subject', result.emailSubject);
			System.assertEquals('voided envelope', result.reason);
			System.assertNotEquals(null, result.lastStatusUpdate);
			System.assertNotEquals(null, result.recipients);
			System.assertEquals(7, result.recipients.size());
			Integer i = 1;
			for (Recipient.Status rs : result.recipients) {
				System.assertNotEquals(null, rs);
				System.assertEquals(i, rs.sequence);
				if (i == 1) {
					System.assertEquals(Recipient.STATUS_DELIVERED, rs.status);
					System.assertNotEquals(null, rs.sent);
				} else {
					System.assertEquals(Recipient.STATUS_CREATED, rs.status);
					System.assertEquals(null, rs.sent);
				}
				System.assertEquals(null, rs.completed);
				System.assertEquals(null, rs.reason);
				System.assertNotEquals(null, rs.type);
				System.assertNotEquals(null, rs.name);
				System.assertNotEquals(null, rs.email);
				System.assertEquals(i, rs.routingOrder);
				System.assertNotEquals(null, rs.lastStatusUpdate);
				i++;
			}
		}
	}

	private class StatusSentNoRecipientsMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			String endpoint = request.getEndpoint();
			if (endpoint.contains('include=recipients')) {
				response.setStatusCode(400);
				response.setStatus('BAD_REQUEST');
			} else {
				response.setStatusCode(200);
				response.setStatus('OK');
				response.setHeader('Content-Type', 'application/json; charset=utf-8');
				response.setBody('{"status":"sent","emailSubject":"Unit test subject","emailBlurb":"Unit test message","envelopeId":"11111111-1111-1111-1111-111111111111","createdDateTime":"2018-04-18T22:05:43.7670000Z","lastModifiedDateTime":"2018-04-18T22:05:51.0800000Z","deliveredDateTime":"2018-04-18T22:06:15.1370000Z","initialSentDateTime":"2018-04-18T22:05:51.6100000Z","sentDateTime":"2018-04-18T22:06:06.2770000Z","statusChangedDateTime":"2018-04-18T22:06:22.5730000Z"}');
			}
			return response;
		}
	}

	@IsTest
	static void test_getEnvelopeStatus_without_recipients() {
		Test.setMock(HttpCalloutMock.class, new StatusSentNoRecipientsMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Envelope.Status result = EnvelopeAPI.getInstance().getEnvelopeStatus(UUID.randomUUID(), false);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(Envelope.STATUS_SENT, result.status);
			System.assertNotEquals(null, result.sent);
			System.assertEquals(null, result.completed);
			System.assertEquals('Unit test subject', result.emailSubject);
			System.assertEquals(null, result.reason);
			System.assertNotEquals(null, result.lastStatusUpdate);
			System.assert(Collection.isEmpty(result.recipients));
		}
	}

	@IsTest
	static void test_APIRecipient_anchor_tag_conversion() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Recipient r1 = Recipient.fromSource('r1', 'r1@unit.test', null, null, null)
				.withType(Recipient.TYPE_EMBEDDED_SIGNER, true)
				.withRole(new Recipient.Role('DefaultRole1', 1));
			Recipient r2 = Recipient.fromSource('r2', 'r2@unit.test', null, 'TemplateRole', null);
			Recipient r3 = Recipient.fromSource('r3', 'r3@unit.test', null, null, null);

			Test.startTest();
			EnvelopeAPI.APIRecipient result1 = new EnvelopeAPI.APIRecipient(r1, '1', false); // no auto anchor tags
			EnvelopeAPI.APIRecipient result2 = new EnvelopeAPI.APIRecipient(r1, '1', true); // with auto anchor tags, with role value
			EnvelopeAPI.APIRecipient result3 = new EnvelopeAPI.APIRecipient(r2, '1', true); // with auto anchor tags, with no role value
			EnvelopeAPI.APIRecipient result4 = new EnvelopeAPI.APIRecipient(r3, '1', true); // with auto anchor tags, with null role
			Test.stopTest();

			EnvelopeAPI.APIRecipient r = result1;
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.tabs);
			System.assertEquals(0, Collection.size(r.tabs.approveTabs));
			System.assertEquals(0, Collection.size(r.tabs.checkboxTabs));
			System.assertEquals(0, Collection.size(r.tabs.companyTabs));
			System.assertEquals(0, Collection.size(r.tabs.dateSignedTabs));
			System.assertEquals(0, Collection.size(r.tabs.dateTabs));
			System.assertEquals(0, Collection.size(r.tabs.declineTabs));
			System.assertEquals(0, Collection.size(r.tabs.emailAddressTabs));
			System.assertEquals(0, Collection.size(r.tabs.emailTabs));
			System.assertEquals(0, Collection.size(r.tabs.envelopeIdTabs));
			System.assertEquals(0, Collection.size(r.tabs.firstNameTabs));
			System.assertEquals(0, Collection.size(r.tabs.formulaTabs));
			System.assertEquals(0, Collection.size(r.tabs.fullNameTabs));
			System.assertEquals(0, Collection.size(r.tabs.initialHereTabs));
			System.assertEquals(0, Collection.size(r.tabs.lastNameTabs));
			System.assertEquals(0, Collection.size(r.tabs.listTabs));
			System.assertEquals(0, Collection.size(r.tabs.notarizeTabs));
			System.assertEquals(0, Collection.size(r.tabs.noteTabs));
			System.assertEquals(0, Collection.size(r.tabs.numberTabs));
			System.assertEquals(0, Collection.size(r.tabs.radioGroupTabs));
			System.assertEquals(0, Collection.size(r.tabs.signerAttachmentTabs));
			System.assertEquals(0, Collection.size(r.tabs.signHereTabs));
			System.assertEquals(0, Collection.size(r.tabs.smartSectionTabs));
			System.assertEquals(0, Collection.size(r.tabs.ssnTabs));
			System.assertEquals(0, Collection.size(r.tabs.textTabs));
			System.assertEquals(0, Collection.size(r.tabs.titleTabs));
			System.assertEquals(0, Collection.size(r.tabs.viewTabs));
			System.assertEquals(0, Collection.size(r.tabs.zipTabs));

			r = result2;
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.tabs);
			System.assertEquals(0, Collection.size(r.tabs.approveTabs));
			System.assertEquals(0, Collection.size(r.tabs.checkboxTabs));
			System.assertEquals(1, Collection.size(r.tabs.companyTabs));
			System.assertEquals(1, Collection.size(r.tabs.dateSignedTabs));
			System.assertEquals(0, Collection.size(r.tabs.dateTabs));
			System.assertEquals(0, Collection.size(r.tabs.declineTabs));
			System.assertEquals(0, Collection.size(r.tabs.emailAddressTabs));
			System.assertEquals(0, Collection.size(r.tabs.emailTabs));
			System.assertEquals(0, Collection.size(r.tabs.envelopeIdTabs));
			System.assertEquals(0, Collection.size(r.tabs.firstNameTabs));
			System.assertEquals(0, Collection.size(r.tabs.formulaTabs));
			System.assertEquals(1, Collection.size(r.tabs.fullNameTabs));
			System.assertEquals(2, Collection.size(r.tabs.initialHereTabs));
			System.assertEquals(0, Collection.size(r.tabs.lastNameTabs));
			System.assertEquals(0, Collection.size(r.tabs.listTabs));
			System.assertEquals(0, Collection.size(r.tabs.notarizeTabs));
			System.assertEquals(0, Collection.size(r.tabs.noteTabs));
			System.assertEquals(0, Collection.size(r.tabs.numberTabs));
			System.assertEquals(0, Collection.size(r.tabs.radioGroupTabs));
			System.assertEquals(0, Collection.size(r.tabs.signerAttachmentTabs));
			System.assertEquals(1, Collection.size(r.tabs.signHereTabs));
			System.assertEquals(0, Collection.size(r.tabs.smartSectionTabs));
			System.assertEquals(0, Collection.size(r.tabs.ssnTabs));
			System.assertEquals(2, Collection.size(r.tabs.textTabs));
			System.assertEquals(1, Collection.size(r.tabs.titleTabs));
			System.assertEquals(0, Collection.size(r.tabs.viewTabs));
			System.assertEquals(0, Collection.size(r.tabs.zipTabs));

			r = result3;
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.tabs);
			System.assertEquals(0, Collection.size(r.tabs.approveTabs));
			System.assertEquals(0, Collection.size(r.tabs.checkboxTabs));
			System.assertEquals(0, Collection.size(r.tabs.companyTabs));
			System.assertEquals(0, Collection.size(r.tabs.dateSignedTabs));
			System.assertEquals(0, Collection.size(r.tabs.dateTabs));
			System.assertEquals(0, Collection.size(r.tabs.declineTabs));
			System.assertEquals(0, Collection.size(r.tabs.emailAddressTabs));
			System.assertEquals(0, Collection.size(r.tabs.emailTabs));
			System.assertEquals(0, Collection.size(r.tabs.envelopeIdTabs));
			System.assertEquals(0, Collection.size(r.tabs.firstNameTabs));
			System.assertEquals(0, Collection.size(r.tabs.formulaTabs));
			System.assertEquals(0, Collection.size(r.tabs.fullNameTabs));
			System.assertEquals(0, Collection.size(r.tabs.initialHereTabs));
			System.assertEquals(0, Collection.size(r.tabs.lastNameTabs));
			System.assertEquals(0, Collection.size(r.tabs.listTabs));
			System.assertEquals(0, Collection.size(r.tabs.notarizeTabs));
			System.assertEquals(0, Collection.size(r.tabs.noteTabs));
			System.assertEquals(0, Collection.size(r.tabs.numberTabs));
			System.assertEquals(0, Collection.size(r.tabs.radioGroupTabs));
			System.assertEquals(0, Collection.size(r.tabs.signerAttachmentTabs));
			System.assertEquals(0, Collection.size(r.tabs.signHereTabs));
			System.assertEquals(0, Collection.size(r.tabs.smartSectionTabs));
			System.assertEquals(0, Collection.size(r.tabs.ssnTabs));
			System.assertEquals(0, Collection.size(r.tabs.textTabs));
			System.assertEquals(0, Collection.size(r.tabs.titleTabs));
			System.assertEquals(0, Collection.size(r.tabs.viewTabs));
			System.assertEquals(0, Collection.size(r.tabs.zipTabs));

			r = result4;
			System.assertNotEquals(null, r);
			System.assertNotEquals(null, r.tabs);
			System.assertEquals(0, Collection.size(r.tabs.approveTabs));
			System.assertEquals(0, Collection.size(r.tabs.checkboxTabs));
			System.assertEquals(0, Collection.size(r.tabs.companyTabs));
			System.assertEquals(0, Collection.size(r.tabs.dateSignedTabs));
			System.assertEquals(0, Collection.size(r.tabs.dateTabs));
			System.assertEquals(0, Collection.size(r.tabs.declineTabs));
			System.assertEquals(0, Collection.size(r.tabs.emailAddressTabs));
			System.assertEquals(0, Collection.size(r.tabs.emailTabs));
			System.assertEquals(0, Collection.size(r.tabs.envelopeIdTabs));
			System.assertEquals(0, Collection.size(r.tabs.firstNameTabs));
			System.assertEquals(0, Collection.size(r.tabs.formulaTabs));
			System.assertEquals(0, Collection.size(r.tabs.fullNameTabs));
			System.assertEquals(0, Collection.size(r.tabs.initialHereTabs));
			System.assertEquals(0, Collection.size(r.tabs.lastNameTabs));
			System.assertEquals(0, Collection.size(r.tabs.listTabs));
			System.assertEquals(0, Collection.size(r.tabs.notarizeTabs));
			System.assertEquals(0, Collection.size(r.tabs.noteTabs));
			System.assertEquals(0, Collection.size(r.tabs.numberTabs));
			System.assertEquals(0, Collection.size(r.tabs.radioGroupTabs));
			System.assertEquals(0, Collection.size(r.tabs.signerAttachmentTabs));
			System.assertEquals(0, Collection.size(r.tabs.signHereTabs));
			System.assertEquals(0, Collection.size(r.tabs.smartSectionTabs));
			System.assertEquals(0, Collection.size(r.tabs.ssnTabs));
			System.assertEquals(0, Collection.size(r.tabs.textTabs));
			System.assertEquals(0, Collection.size(r.tabs.titleTabs));
			System.assertEquals(0, Collection.size(r.tabs.viewTabs));
			System.assertEquals(0, Collection.size(r.tabs.zipTabs));
		}
	}

	@IsTest
	static void test_APIRecipient_template_conversion() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Recipient r1 = Recipient.fromSource('r1', 'r1@unit.test', null, 'TemplateRole', null).withRoutingOrder(1);
			Recipient r2 = Recipient.fromSource('r2', 'r2@unit.test', null, null, null).withRoutingOrder(2);

			Test.startTest();
			EnvelopeAPI.APIRecipient result1 = new EnvelopeAPI.APIRecipient(r1, '1', false); // no template, has role
			EnvelopeAPI.APIRecipient result2 = new EnvelopeAPI.APIRecipient(r2, '1', false); // no template, no role
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertEquals('TemplateRole', result1.roleName);
			System.assertEquals('1', result1.routingOrder);

			System.assertNotEquals(null, result2);
			System.assertEquals('', result2.roleName);
			System.assertEquals('2', result2.routingOrder);
		}
	}

	@IsTest
	static void test_APIEnvelope_recipient_email_settings() {
		Envelope e = new Envelope(null, 'Envelope subject', 'Envelope message', null)
			.withRecipients(new List<Recipient> {
				Recipient.fromSource('r1', 'r1@unit.test', null, 'r1', null)
					.withEmailSettings(new Recipient.EmailSettings(Localization.FR, Label.French, 'r1 subject', 'r1 message')),
				Recipient.fromSource('r2', 'r2@unit.test', null, 'r2', null)
					.withEmailSettings(new Recipient.EmailSettings(Localization.EN, Label.English, 'r2 subject', 'r2 message')),
				Recipient.fromSource('r3', 'r3@unit.test', null, 'r3', null)
					.withEmailSettings(new Recipient.EmailSettings(Localization.ZH_CN, Label.ChineseSimplified, null, ''))
			});

		Test.startTest();
		EnvelopeAPI.APIEnvelope result = new EnvelopeAPI.APIEnvelope(e, false, false);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals('Envelope subject', result.emailSubject);
		System.assertEquals('Envelope message', result.emailBlurb);
		System.assertNotEquals(null, result.recipients);
		System.assertEquals(3, Collection.size(result.recipients.signers));
		System.assertNotEquals(null, result.recipients.signers[0].emailNotification);
		System.assertEquals('r1 subject', result.recipients.signers[0].emailNotification.emailSubject);
		System.assertEquals('r1 message', result.recipients.signers[0].emailNotification.emailBody);
		System.assertNotEquals(null, result.recipients.signers[1].emailNotification);
		System.assertEquals('r2 subject', result.recipients.signers[1].emailNotification.emailSubject);
		System.assertEquals('r2 message', result.recipients.signers[1].emailNotification.emailBody);
		System.assertEquals(null, result.recipients.signers[2].emailNotification);
	}

	@IsTest
	static void test_APIEnvelope_contentFile() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.DocumentResolvers__c = Application.classNamespacePrefix + 'DefaultDocumentResolver';
		insert s;
		Envelope__c e1 = TestUtils.createEnvelope();
		ContentVersion cv1 = new ContentVersion(
			Title = 'test1',
			PathOnClient = 'test1.pdf',
			VersionData = Blob.valueOf('test'),
			IsMajorVersion = true);
		ContentVersion cv2 = new ContentVersion(
			Title = 'test2',
			PathOnClient = 'test2.html',
			VersionData = Blob.valueOf('<html/>'),
			IsMajorVersion = true);
		insert new List<ContentVersion> { cv1, cv2 };
		cv1 = [SELECT Id, Title, ContentSize, FileExtension FROM ContentVersion WHERE Id = :cv1.Id];
		cv2 = [SELECT Id, Title, ContentSize, FileExtension FROM ContentVersion WHERE Id = :cv2.Id];
		Document__c d1 = TestUtils.createEnvelopeDocument(e1.Id, cv1, 1);
		Document__c d2 = TestUtils.createEnvelopeDocument(e1.Id, cv2, 2);
		Envelope e2 = new Envelope(null, 'Envelope subject', 'Envelope message', null)
			.withDocuments(new List<Document> {
				DocumentService.DB.convert(d1),
				DocumentService.DB.convert(d2)
			});

		Test.startTest();
		EnvelopeAPI.APIEnvelope result = new EnvelopeAPI.APIEnvelope(e2, false, true);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(2, Collection.size(result.documents));
		System.assertNotEquals(null, result.documents[0]);
		System.assertEquals(EncodingUtil.base64Encode(Blob.valueOf(cv1.Id)), result.documents[0].documentBase64);
		System.assertEquals(null, result.documents[0].htmlDefinition);
		System.assertNotEquals(null, result.documents[1]);
		System.assertEquals(null, result.documents[1].documentBase64);
		System.assertNotEquals(null, result.documents[1].htmlDefinition);
		System.assertEquals('<html/>', result.documents[1].htmlDefinition.source);
	}

	@IsTest
	static void test_APIEnvelope_scmFile() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.DocumentResolvers__c = Application.classNamespacePrefix + 'DefaultDocumentResolver';
		Document d1 = Document.fromFile(UUID.randomUUID(), 'UnitTestScmFile1', 'doc');
		Document d2 = Document.fromFile(UUID.randomUUID(), 'UnitTestScmFile2', 'html');
		Envelope e2 = new Envelope(null, 'Envelope subject', 'Envelope message', null)
			.withDocuments(new List<Document> { d1, d2 });

		Test.startTest();
		EnvelopeAPI.APIEnvelope result = new EnvelopeAPI.APIEnvelope(e2, true, true);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(2, Collection.size(result.documents));
		System.assertNotEquals(null, result.documents[0]);
		System.assertNotEquals(null, result.documents[0].documentBase64);
		System.assertNotEquals(null, result.documents[1]);
		System.assertNotEquals(null, result.documents[1].htmlDefinition);
	}

	@IsTest
	static void test_APIEnvelope_template_roles() {
		Envelope e = new Envelope(null, 's', 'm', null)
			.withDocuments(new List<Document> {
				Document.fromTemplate(UUID.randomUUID(), 't')
			})
			.withRecipients(new List<Recipient> {
				Recipient.fromSource('r1', 'r1@unit.test', null, 'r1', null)
					.withRoutingOrder(1),
				Recipient.fromSource('r2', 'r2@unit.test', null, 'r2', null)
					.withRoutingOrder(2),
				Recipient.fromSource('r3', 'r3@unit.test', null, 'r3', null)
					.withRoutingOrder(2)
			});

		Test.startTest();
		EnvelopeAPI.APIEnvelope result = new EnvelopeAPI.APIEnvelope(
			e,
			true,
			true);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(1, Collection.size(result.compositeTemplates));
		System.assertNotEquals(null, result.compositeTemplates[0]);
		System.assertEquals(1, Collection.size(result.compositeTemplates[0].inlineTemplates));
		System.assertNotEquals(null, result.compositeTemplates[0].inlineTemplates[0]);
		System.assertNotEquals(null, result.compositeTemplates[0].inlineTemplates[0].recipients);
		List<EnvelopeAPI.APIRecipient> recipients = result.compositeTemplates[0].inlineTemplates[0].recipients.signers;
		System.assertEquals(3, Collection.size(recipients));
		System.assertNotEquals(null, recipients[0]);
		System.assertEquals('1', recipients[0].recipientId);
		System.assertEquals('1', recipients[0].routingOrder);
		System.assertNotEquals(null, recipients[1]);
		System.assertEquals('2', recipients[1].recipientId);
		System.assertEquals('2', recipients[1].routingOrder);
		System.assertNotEquals(null, recipients[2]);
		System.assertEquals('3', recipients[2].recipientId);
		System.assertEquals('2', recipients[2].routingOrder);
	}

	@IsTest
	static void test_getTemplate_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			final Template t = client.getTemplate(UUID.randomUUID());
			Test.stopTest();

			System.assertNotEquals(null, t);
			System.assertNotEquals(null, t.id);
			System.assertNotEquals(null, t.name);
			System.assertNotEquals(null, t.lastModified);
			System.assertNotEquals(null, t.customFields);
			System.assertEquals(3, t.customFields.size());
			System.assertEquals('textField1', t.customFields[0].name);
			System.assertEquals('textValue1', t.customFields[0].value);
			System.assert(!t.customFields[0].required);
			System.assert(t.customFields[0].show);
			System.assertEquals('listField1', t.customFields[2].name);
			System.assertEquals('listField1Value2', t.customFields[2].value);
			System.assertEquals(new List<String> { 'listField1Value1', 'listField1Value2', 'listField1Value3' }, t.customFields[2].items);
			System.assert(t.customFields[2].required);
			System.assert(t.customFields[2].show);
			System.assertNotEquals(null, t.notifications);
			System.assert(t.notifications.remind);
			System.assertEquals(10, t.notifications.remindAfterDays);
			System.assertEquals(5, t.notifications.remindFrequencyDays);
			System.assert(t.notifications.expires);
			System.assertEquals(11, t.notifications.expireAfterDays);
			System.assertEquals(6, t.notifications.expireWarnDays);
			System.assertNotEquals(null, t.emailSubject);
			System.assertNotEquals(null, t.emailMessage);
			System.assertNotEquals(null, t.recipients);
			System.assertEquals(9, t.recipients.size());
			Integer sequence = 1;
			for (Recipient r : t.recipients) {
				System.assertNotEquals(null, r);
				System.assertEquals(sequence, r.sequence);
				System.assertEquals(sequence, r.routingOrder);
				if (sequence == 1) {
					System.assertEquals(Recipient.TYPE_INTERMEDIARY, r.type);
					System.assertEquals(null, r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('INTERMEDIARY', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertNotEquals(null, r.authentication);
					System.assertEquals('1234', r.authentication.accessCode);
					System.assert(!r.authentication.idCheckRequired);
					System.assertEquals(null, r.authentication.smsPhoneNumbers);
					System.assertEquals(null, r.note);
					System.assertEquals(null, r.emailSettings);
					System.assert(!r.readOnly);
					System.assert(!r.required);
				} else if (sequence == 2) {
					System.assertEquals(Recipient.TYPE_IN_PERSON_SIGNER, r.type);
					System.assertEquals('In-Person Signer', r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals('h1@unit.test', r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('IN_PERSON_SIGNER', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertEquals(null, r.authentication);
					System.assertEquals(null, r.note);
					System.assertEquals(null, r.emailSettings);
					System.assert(!r.readOnly);
					System.assert(!r.required);
				} else if (sequence == 3) {
					System.assertEquals(Recipient.TYPE_CARBON_COPY, r.type);
					System.assertEquals(null, r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('CARBON_COPY', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertNotEquals(null, r.authentication);
					System.assertEquals(null, r.authentication.accessCode);
					System.assert(r.authentication.idCheckRequired);
					System.assertNotEquals(null, r.authentication.smsPhoneNumbers);
					System.assertEquals(1, r.authentication.smsPhoneNumbers.size());
					System.assertEquals('+1 415-555-5555', r.authentication.smsPhoneNumbers[0]);
					System.assertEquals(null, r.note);
					System.assertEquals(null, r.emailSettings);
					System.assert(!r.readOnly);
					System.assert(!r.required);
				} else if (sequence == 4) {
					System.assertEquals(Recipient.TYPE_CERTIFIED_DELIVERY, r.type);
					System.assertEquals(null, r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('CERTIFIED_DELIVERY', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertEquals(null, r.authentication);
					System.assertEquals('unit test', r.note);
					System.assertEquals(null, r.emailSettings);
					System.assert(!r.readOnly);
					System.assert(!r.required);
				} else if (sequence == 5) {
					System.assertEquals(Recipient.TYPE_AGENT, r.type);
					System.assertEquals(null, r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('AGENT', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertEquals(null, r.authentication);
					System.assertEquals(null, r.note);
					System.assertNotEquals(null, r.emailSettings);
					// "Unsupported" language Bulgarian
					System.assertEquals('bg', r.emailSettings.language);
					System.assertEquals('', r.emailSettings.languageLabel);
					System.assertEquals('bg subject', r.emailSettings.subject);
					System.assertEquals('bg message', r.emailSettings.message);
					System.assert(!r.readOnly);
				} else if (sequence == 6) {
					System.assertEquals(Recipient.TYPE_EDITOR, r.type);
					System.assertEquals(null, r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('EDITOR', r.role.name);
					System.assertEquals(null, r.signingGroup);
					System.assertEquals(null, r.authentication);
					System.assertEquals(null, r.note);
					System.assertEquals(null, r.emailSettings);
					System.assert(!r.readOnly);
					System.assert(!r.required);
				} else if (sequence == 7) {
					System.assertEquals(Recipient.TYPE_SIGNER, r.type);
					System.assertEquals('SG1', r.name);
					System.assertEquals(null, r.email);
					System.assertEquals(null, r.hostName);
					System.assertEquals(null, r.hostEmail);
					System.assertNotEquals(null, r.role);
					System.assertEquals('SIGNER', r.role.name);
					System.assertNotEquals(null, r.signingGroup);
					System.assertNotEquals(null, r.signingGroup.id);
					System.assertEquals('SG1', r.signingGroup.name);
					System.assertEquals(null, r.authentication);
					System.assertEquals(null, r.note);
					System.assertNotEquals(null, r.emailSettings);
					// "Supported" language French
					System.assertEquals('fr', r.emailSettings.language);
					System.assertEquals(Label.French, r.emailSettings.languageLabel);
					System.assertEquals('fr subject', r.emailSettings.subject);
					System.assertEquals('fr message', r.emailSettings.message);
					System.assert(r.readOnly);
					System.assert(r.required);
				} else if (sequence == 8) {
					System.assertEquals(Recipient.TYPE_SEAL, r.type);
				} else if (sequence == 9) {
					System.assertEquals(Recipient.TYPE_WITNESS, r.type);
				}
				sequence++;
			}
		}
	}

	@IsTest
	static void test_getTemplate_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex;

			Test.startTest();
			try {
				client.getTemplate(UUID.randomUUID());
				throw new AssertException('Expected getTemplate to fail');
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
	static void test_getTemplates_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			List<Template> templates = client.getTemplates();
			Test.stopTest();

			System.assertNotEquals(null, templates);
			System.assertEquals(3, templates.size());

			System.assertNotEquals(null, templates[0].id);
			System.assertNotEquals(null, templates[0].name);
			System.assertNotEquals(null, templates[0].lastModified);
			System.assert(Collection.isEmpty(templates[0].customFields));

			System.assertNotEquals(null, templates[1].id);
			System.assertNotEquals(null, templates[1].name);
			System.assertNotEquals(null, templates[1].lastModified);
			System.assert(Collection.isEmpty(templates[1].customFields));

			System.assertNotEquals(null, templates[2].id);
			System.assertNotEquals(null, templates[2].name);
			System.assertNotEquals(null, templates[2].lastModified);
			System.assert(Collection.isEmpty(templates[2].customFields));
		}
	}

	@IsTest
	static void test_getTemplates_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getTemplates();
				throw new AssertException('Expected getTemplates to fail');
			} catch (APIException ex1) {
				ex = ex1;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}

	@IsTest
	static void test_createTemplate_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			CustomField cf1 = CustomField.newListField('lf', 'v1', new List<String> { 'v1', 'v2', 'v3' }, false, true);
			CustomField cf2 = CustomField.newTextField('tf', 'v1', true, true);
			Notifications n = new Notifications(true, 10, 2, true, 20, 18);
			Document d1 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(1);
			Document d2 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(2);
			Contact c1 = TestUtils.createContact();
			Recipient r1 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				String.valueOf(TestUtils.randomInteger(1000000)),
				UUID.randomUUID().toString(),
				new Entity(c1.Id))
				.withSequence(1)
				.withRoutingOrder(1);
			Recipient r2 = Recipient.newInPersonSigner(
				2,
				new Recipient.Role(UUID.randomUUID().toString()),
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				UUID.randomUUID().toString(),
				true)
				.withSequence(2);
			Template t = new Template(
				null,
				UUID.randomUUID().toString(),
				new List<CustomField> { cf1, cf2 },
				n,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				new List<Document> { d1, d2 },
				new List<Recipient> { r1, r2 },
				null);

			Test.startTest();
			Template result = EnvelopeAPI.getInstance().createTemplate(t);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(t.name, result.name);
			System.assertEquals(2, Collection.size(result.customFields));
			System.assertNotEquals(null, result.customFields[0]);
			System.assertEquals(cf1.type, result.customFields[0].type);
			System.assertEquals(cf1.name, result.customFields[0].name);
			System.assertEquals(cf1.value, result.customFields[0].value);
			System.assertEquals(cf1.items, result.customFields[0].items);
			System.assertEquals(cf1.required, result.customFields[0].required);
			System.assertEquals(cf1.show, result.customFields[0].show);
			System.assertNotEquals(null, result.customFields[1]);
			System.assertEquals(cf2.type, result.customFields[1].type);
			System.assertEquals(cf2.name, result.customFields[1].name);
			System.assertEquals(cf2.value, result.customFields[1].value);
			System.assertEquals(cf2.items, result.customFields[1].items);
			System.assertEquals(cf2.required, result.customFields[1].required);
			System.assertEquals(cf2.show, result.customFields[1].show);
			System.assertNotEquals(null, result.notifications);
			System.assertEquals(n.remind, result.notifications.remind);
			System.assertEquals(n.remindAfterDays, result.notifications.remindAfterDays);
			System.assertEquals(n.remindFrequencyDays, result.notifications.remindFrequencyDays);
			System.assertEquals(n.expires, result.notifications.expires);
			System.assertEquals(n.expireAfterDays, result.notifications.expireAfterDays);
			System.assertEquals(n.expireWarnDays, result.notifications.expireWarnDays);
			System.assertEquals(t.emailSubject, result.emailSubject);
			System.assertEquals(t.emailMessage, result.emailMessage);
			System.assertEquals(2, Collection.size(result.documents));
			System.assertNotEquals(null, result.documents[0]);
			System.assertEquals(d1.type, result.documents[0].type);
			System.assertEquals(d1.sequence, result.documents[0].sequence);
			System.assertEquals(d1.name, result.documents[0].name);
			System.assertEquals(d1.extension, result.documents[0].extension);
			System.assertEquals(d1.size, result.documents[0].size);
			System.assertEquals(d1.lastModified, result.documents[0].lastModified);
			System.assertEquals(d1.sourceId, result.documents[0].sourceId);
			System.assertEquals(d1.readOnly, result.documents[0].readOnly);
			System.assertEquals(d1.required, result.documents[0].required);
			System.assertNotEquals(null, result.documents[1]);
			System.assertEquals(d2.type, result.documents[1].type);
			System.assertEquals(d2.sequence, result.documents[1].sequence);
			System.assertEquals(d2.name, result.documents[1].name);
			System.assertEquals(d2.extension, result.documents[1].extension);
			System.assertEquals(d2.size, result.documents[1].size);
			System.assertEquals(d2.lastModified, result.documents[1].lastModified);
			System.assertEquals(d2.sourceId, result.documents[1].sourceId);
			System.assertEquals(d2.readOnly, result.documents[1].readOnly);
			System.assertEquals(d2.required, result.documents[1].required);
			System.assertEquals(2, Collection.size(result.recipients));
			System.assertNotEquals(null, result.recipients[0]);
			System.assertEquals(r1.envelopeRecipientId, result.recipients[0].envelopeRecipientId);
			System.assertEquals(r1.type, result.recipients[0].type);
			System.assertEquals(r1.sequence, result.recipients[0].sequence);
			System.assertEquals(r1.routingOrder, result.recipients[0].routingOrder);
			System.assertNotEquals(null, result.recipients[0].role);
			System.assertEquals(r1.role.name, result.recipients[0].role.name);
			System.assertEquals(r1.name, result.recipients[0].name);
			System.assertEquals(r1.email, result.recipients[0].email);
			System.assertEquals(null, result.recipients[0].signingGroup);
			System.assertEquals(r1.phone, result.recipients[0].phone);
			System.assertEquals(null, result.recipients[0].authentication);
			System.assertEquals(r1.note, result.recipients[0].note);
			System.assertEquals(null, result.recipients[0].emailSettings);
			System.assertEquals(r1.hostName, result.recipients[0].hostName);
			System.assertEquals(r1.hostEmail, result.recipients[0].hostEmail);
			System.assertEquals(r1.signNow, result.recipients[0].signNow);
			System.assertEquals(r1.tabs, result.recipients[0].tabs);
			System.assertEquals(r1.source, result.recipients[0].source);
			System.assertEquals(r1.readOnly, result.recipients[0].readOnly);
			System.assertEquals(r1.required, result.recipients[0].required);
			System.assertNotEquals(null, result.recipients[1]);
			System.assertEquals(r2.envelopeRecipientId, result.recipients[1].envelopeRecipientId);
			System.assertEquals(r2.type, result.recipients[1].type);
			System.assertEquals(r2.sequence, result.recipients[1].sequence);
			System.assertEquals(r2.routingOrder, result.recipients[1].routingOrder);
			System.assertNotEquals(null, result.recipients[1].role);
			System.assertEquals(r2.role.name, result.recipients[1].role.name);
			System.assertEquals(r2.name, result.recipients[1].name);
			System.assertEquals(r2.email, result.recipients[1].email);
			System.assertEquals(null, result.recipients[1].signingGroup);
			System.assertEquals(r2.phone, result.recipients[1].phone);
			System.assertEquals(null, result.recipients[1].authentication);
			System.assertEquals(r2.note, result.recipients[1].note);
			System.assertEquals(null, result.recipients[1].emailSettings);
			System.assertEquals(r2.hostName, result.recipients[1].hostName);
			System.assertEquals(r2.hostEmail, result.recipients[1].hostEmail);
			System.assertEquals(r2.signNow, result.recipients[1].signNow);
			System.assertEquals(r2.tabs, result.recipients[1].tabs);
			System.assertEquals(r2.source, result.recipients[1].source);
			System.assertEquals(r2.readOnly, result.recipients[1].readOnly);
			System.assertEquals(r2.required, result.recipients[1].required);
			System.assertNotEquals(null, result.lastModified);
		}
	}

	@IsTest
	static void test_createTemplate_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Template t = new Template(
				UUID.randomUUID(),
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null);

			Test.startTest();
			try {
				EnvelopeAPI.getInstance().createTemplate(t);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplateEditUrl_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Url result = EnvelopeAPI.getInstance().getTemplateEditUrl(
				UUID.randomUUID(),
				new Url('https://return.unit.test'));
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getTemplateEditUrl_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				EnvelopeAPI.getInstance().getTemplateEditUrl(
					UUID.randomUUID(),
					new Url('https://return.unit.test'));
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateTemplate_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			CustomField cf1 = CustomField.newListField('lf', 'v1', new List<String> { 'v1', 'v2', 'v3' }, false, true);
			CustomField cf2 = CustomField.newTextField('tf', 'v1', true, true);
			Notifications n = new Notifications(true, 10, 2, true, 20, 18);
			Document d1 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(1);
			Document d2 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(2);
			Contact c1 = TestUtils.createContact();
			Recipient r1 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				String.valueOf(TestUtils.randomInteger(1000000)),
				UUID.randomUUID().toString(),
				new Entity(c1.Id))
				.withSequence(1)
				.withRoutingOrder(1);
			Recipient r2 = Recipient.newInPersonSigner(
				2,
				new Recipient.Role(UUID.randomUUID().toString()),
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				UUID.randomUUID().toString(),
				true)
				.withSequence(2);
			Datetime lm = Datetime.now().addDays(-1);
			Template t = new Template(
				UUID.randomUUID(),
				UUID.randomUUID().toString(),
				new List<CustomField> { cf1, cf2 },
				n,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				new List<Document> { d1, d2 },
				new List<Recipient> { r1, r2 },
				lm);

			//Delete and add recipient/document

			Document d3 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(2);
			Document d4 = Document.fromFile(TestUtils.createContentVersion())
				.withSequence(3);

			Recipient r3 = Recipient.newInPersonSigner(
				2,
				new Recipient.Role(UUID.randomUUID().toString()),
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				null,
				UUID.randomUUID().toString(),
				true)
				.withSequence(2);

			Contact c2 = TestUtils.createContact();
			Recipient r4 = Recipient.fromSource(
				UUID.randomUUID().toString(),
				UUID.randomUUID() + '@unit.test',
				String.valueOf(TestUtils.randomInteger(1000000)),
				UUID.randomUUID().toString(),
				new Entity(c2.Id))
				.withSequence(3)
				.withRoutingOrder(3);

			Template t2 = new Template(
				UUID.randomUUID(),
				UUID.randomUUID().toString(),
				new List<CustomField> { cf1, cf2 },
				n,
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString(),
				new List<Document> { d1, d3, d4 },
				new List<Recipient> { r1, r3, r4 },
				lm);

			Test.startTest();

			//create template api call
			Template result = EnvelopeAPI.getInstance().createTemplate(t);
			//update template api call
			Template result2 = EnvelopeAPI.getInstance().updateTemplate(t2);

			Test.stopTest();

			//validate create result
			System.assertNotEquals(null, result);
			System.assertEquals(t.id, result.id);
			System.assertEquals(t2.id, result2.id);
			System.assertEquals(t.name, result.name);
			System.assertEquals(t2.name, result2.name);
			System.assertEquals(2, Collection.size(result.customFields));
			System.assertNotEquals(null, result.customFields[0]);
			System.assertEquals(cf1.type, result.customFields[0].type);
			System.assertEquals(cf1.name, result.customFields[0].name);
			System.assertEquals(cf1.value, result.customFields[0].value);
			System.assertEquals(cf1.items, result.customFields[0].items);
			System.assertEquals(cf1.required, result.customFields[0].required);
			System.assertEquals(cf1.show, result.customFields[0].show);
			System.assertNotEquals(null, result.customFields[1]);
			System.assertEquals(cf2.type, result.customFields[1].type);
			System.assertEquals(cf2.name, result.customFields[1].name);
			System.assertEquals(cf2.value, result.customFields[1].value);
			System.assertEquals(cf2.items, result.customFields[1].items);
			System.assertEquals(cf2.required, result.customFields[1].required);
			System.assertEquals(cf2.show, result.customFields[1].show);
			System.assertNotEquals(null, result.notifications);
			System.assertEquals(n.remind, result.notifications.remind);
			System.assertEquals(n.remindAfterDays, result.notifications.remindAfterDays);
			System.assertEquals(n.remindFrequencyDays, result.notifications.remindFrequencyDays);
			System.assertEquals(n.expires, result.notifications.expires);
			System.assertEquals(n.expireAfterDays, result.notifications.expireAfterDays);
			System.assertEquals(n.expireWarnDays, result.notifications.expireWarnDays);
			System.assertEquals(t.emailSubject, result.emailSubject);
			System.assertEquals(t.emailMessage, result.emailMessage);
			System.assertEquals(2, Collection.size(result.documents));
			System.assertNotEquals(null, result.documents[0]);
			System.assertEquals(d1.type, result.documents[0].type);
			System.assertEquals(d1.sequence, result.documents[0].sequence);
			System.assertEquals(d1.name, result.documents[0].name);
			System.assertEquals(d1.extension, result.documents[0].extension);
			System.assertEquals(d1.size, result.documents[0].size);
			System.assertEquals(d1.lastModified, result.documents[0].lastModified);
			System.assertEquals(d1.sourceId, result.documents[0].sourceId);
			System.assertEquals(d1.readOnly, result.documents[0].readOnly);
			System.assertEquals(d1.required, result.documents[0].required);
			System.assertNotEquals(null, result.documents[1]);
			System.assertEquals(d2.type, result.documents[1].type);
			System.assertEquals(d2.sequence, result.documents[1].sequence);
			System.assertEquals(d2.name, result.documents[1].name);
			System.assertEquals(d2.extension, result.documents[1].extension);
			System.assertEquals(d2.size, result.documents[1].size);
			System.assertEquals(d2.lastModified, result.documents[1].lastModified);
			System.assertEquals(d2.sourceId, result.documents[1].sourceId);
			System.assertEquals(d2.readOnly, result.documents[1].readOnly);
			System.assertEquals(d2.required, result.documents[1].required);
			System.assertEquals(2, Collection.size(result.recipients));
			System.assertNotEquals(null, result.recipients[0]);
			System.assertEquals(r1.envelopeRecipientId, result.recipients[0].envelopeRecipientId);
			System.assertEquals(r1.type, result.recipients[0].type);
			System.assertEquals(r1.sequence, result.recipients[0].sequence);
			System.assertEquals(r1.routingOrder, result.recipients[0].routingOrder);
			System.assertNotEquals(null, result.recipients[0].role);
			System.assertEquals(r1.role.name, result.recipients[0].role.name);
			System.assertEquals(r1.name, result.recipients[0].name);
			System.assertEquals(r1.email, result.recipients[0].email);
			System.assertEquals(null, result.recipients[0].signingGroup);
			System.assertEquals(r1.phone, result.recipients[0].phone);
			System.assertEquals(null, result.recipients[0].authentication);
			System.assertEquals(r1.note, result.recipients[0].note);
			System.assertEquals(null, result.recipients[0].emailSettings);
			System.assertEquals(r1.hostName, result.recipients[0].hostName);
			System.assertEquals(r1.hostEmail, result.recipients[0].hostEmail);
			System.assertEquals(r1.signNow, result.recipients[0].signNow);
			System.assertEquals(r1.tabs, result.recipients[0].tabs);
			System.assertEquals(r1.source, result.recipients[0].source);
			System.assertEquals(r1.readOnly, result.recipients[0].readOnly);
			System.assertEquals(r1.required, result.recipients[0].required);
			System.assertNotEquals(null, result.recipients[1]);
			System.assertEquals(r2.envelopeRecipientId, result.recipients[1].envelopeRecipientId);
			System.assertEquals(r2.type, result.recipients[1].type);
			System.assertEquals(r2.sequence, result.recipients[1].sequence);
			System.assertEquals(r2.routingOrder, result.recipients[1].routingOrder);
			System.assertNotEquals(null, result.recipients[1].role);
			System.assertEquals(r2.role.name, result.recipients[1].role.name);
			System.assertEquals(r2.name, result.recipients[1].name);
			System.assertEquals(r2.email, result.recipients[1].email);
			System.assertEquals(null, result.recipients[1].signingGroup);
			System.assertEquals(r2.phone, result.recipients[1].phone);
			System.assertEquals(null, result.recipients[1].authentication);
			System.assertEquals(r2.note, result.recipients[1].note);
			System.assertEquals(null, result.recipients[1].emailSettings);
			System.assertEquals(r2.hostName, result.recipients[1].hostName);
			System.assertEquals(r2.hostEmail, result.recipients[1].hostEmail);
			System.assertEquals(r2.signNow, result.recipients[1].signNow);
			System.assertEquals(r2.tabs, result.recipients[1].tabs);
			System.assertEquals(r2.source, result.recipients[1].source);
			System.assertEquals(r2.readOnly, result.recipients[1].readOnly);
			System.assertEquals(r2.required, result.recipients[1].required);
			System.assertNotEquals(lm, result.lastModified);

			//validate update result
			System.assertNotEquals(null, result2);
			System.assertEquals(t2.id, result2.id);
			System.assertEquals(t2.name, result2.name);
			System.assertEquals(2, Collection.size(result2.customFields));
			System.assertNotEquals(null, result2.customFields[0]);
			System.assertEquals(cf1.type, result2.customFields[0].type);
			System.assertEquals(cf1.name, result2.customFields[0].name);
			System.assertEquals(cf1.value, result2.customFields[0].value);
			System.assertEquals(cf1.items, result2.customFields[0].items);
			System.assertEquals(cf1.required, result2.customFields[0].required);
			System.assertEquals(cf1.show, result2.customFields[0].show);
			System.assertNotEquals(null, result2.customFields[1]);
			System.assertEquals(cf2.type, result2.customFields[1].type);
			System.assertEquals(cf2.name, result2.customFields[1].name);
			System.assertEquals(cf2.value, result2.customFields[1].value);
			System.assertEquals(cf2.items, result2.customFields[1].items);
			System.assertEquals(cf2.required, result2.customFields[1].required);
			System.assertEquals(cf2.show, result2.customFields[1].show);
			System.assertNotEquals(null, result2.notifications);
			System.assertEquals(n.remind, result2.notifications.remind);
			System.assertEquals(n.remindAfterDays, result2.notifications.remindAfterDays);
			System.assertEquals(n.remindFrequencyDays, result2.notifications.remindFrequencyDays);
			System.assertEquals(n.expires, result2.notifications.expires);
			System.assertEquals(n.expireAfterDays, result2.notifications.expireAfterDays);
			System.assertEquals(n.expireWarnDays, result2.notifications.expireWarnDays);
			System.assertEquals(t2.emailSubject, result2.emailSubject);
			System.assertEquals(t2.emailMessage, result2.emailMessage);
			System.assertEquals(3, Collection.size(result2.documents));
			System.assertNotEquals(null, result2.documents[0]);
			System.assertEquals(d1.type, result2.documents[0].type);
			System.assertEquals(d1.sequence, result2.documents[0].sequence);
			System.assertEquals(d1.name, result2.documents[0].name);
			System.assertEquals(d1.extension, result2.documents[0].extension);
			System.assertEquals(d1.size, result2.documents[0].size);
			System.assertEquals(d1.lastModified, result2.documents[0].lastModified);
			System.assertEquals(d1.sourceId, result2.documents[0].sourceId);
			System.assertEquals(d1.readOnly, result2.documents[0].readOnly);
			System.assertEquals(d1.required, result2.documents[0].required);
			System.assertNotEquals(null, result2.documents[1]);
			System.assertEquals(d3.type, result2.documents[1].type);
			System.assertEquals(d3.sequence, result2.documents[1].sequence);
			System.assertEquals(d3.name, result2.documents[1].name);
			System.assertEquals(d3.extension, result2.documents[1].extension);
			System.assertEquals(d3.size, result2.documents[1].size);
			System.assertEquals(d3.lastModified, result2.documents[1].lastModified);
			System.assertEquals(d3.sourceId, result2.documents[1].sourceId);
			System.assertEquals(d3.readOnly, result2.documents[1].readOnly);
			System.assertEquals(d3.required, result2.documents[1].required);
			System.assertNotEquals(null, result2.documents[2]);
			System.assertEquals(d4.type, result2.documents[2].type);
			System.assertEquals(d4.sequence, result2.documents[2].sequence);
			System.assertEquals(d4.name, result2.documents[2].name);
			System.assertEquals(d4.extension, result2.documents[2].extension);
			System.assertEquals(d4.size, result2.documents[2].size);
			System.assertEquals(d4.lastModified, result2.documents[2].lastModified);
			System.assertEquals(d4.sourceId, result2.documents[2].sourceId);
			System.assertEquals(d4.readOnly, result2.documents[2].readOnly);
			System.assertEquals(d4.required, result2.documents[2].required);
			System.assertEquals(3, Collection.size(result2.recipients));
			System.assertNotEquals(null, result2.recipients[0]);
			System.assertEquals(r1.envelopeRecipientId, result2.recipients[0].envelopeRecipientId);
			System.assertEquals(r1.type, result2.recipients[0].type);
			System.assertEquals(r1.sequence, result2.recipients[0].sequence);
			System.assertEquals(r1.routingOrder, result2.recipients[0].routingOrder);
			System.assertNotEquals(null, result2.recipients[0].role);
			System.assertEquals(r1.role.name, result.recipients[0].role.name);
			System.assertEquals(r1.name, result2.recipients[0].name);
			System.assertEquals(r1.email, result2.recipients[0].email);
			System.assertEquals(null, result2.recipients[0].signingGroup);
			System.assertEquals(r1.phone, result2.recipients[0].phone);
			System.assertEquals(null, result2.recipients[0].authentication);
			System.assertEquals(r1.note, result2.recipients[0].note);
			System.assertEquals(null, result2.recipients[0].emailSettings);
			System.assertEquals(r1.hostName, result2.recipients[0].hostName);
			System.assertEquals(r1.hostEmail, result2.recipients[0].hostEmail);
			System.assertEquals(r1.signNow, result2.recipients[0].signNow);
			System.assertEquals(r1.tabs, result2.recipients[0].tabs);
			System.assertEquals(r1.source, result2.recipients[0].source);
			System.assertEquals(r1.readOnly, result2.recipients[0].readOnly);
			System.assertEquals(r1.required, result2.recipients[0].required);
			System.assertNotEquals(null, result2.recipients[1]);
			System.assertEquals(r3.envelopeRecipientId, result2.recipients[1].envelopeRecipientId);
			System.assertEquals(r3.type, result2.recipients[1].type);
			System.assertEquals(r3.sequence, result2.recipients[1].sequence);
			System.assertEquals(r3.routingOrder, result2.recipients[1].routingOrder);
			System.assertNotEquals(null, result2.recipients[1].role);
			System.assertEquals(r3.role.name, result2.recipients[1].role.name);
			System.assertEquals(r3.name, result2.recipients[1].name);
			System.assertEquals(r3.email, result2.recipients[1].email);
			System.assertEquals(null, result2.recipients[1].signingGroup);
			System.assertEquals(r3.phone, result2.recipients[1].phone);
			System.assertEquals(null, result2.recipients[1].authentication);
			System.assertEquals(r3.note, result2.recipients[1].note);
			System.assertEquals(null, result2.recipients[1].emailSettings);
			System.assertEquals(r3.hostName, result2.recipients[1].hostName);
			System.assertEquals(r3.hostEmail, result2.recipients[1].hostEmail);
			System.assertEquals(r3.signNow, result2.recipients[1].signNow);
			System.assertEquals(r3.tabs, result2.recipients[1].tabs);
			System.assertEquals(r3.source, result2.recipients[1].source);
			System.assertEquals(r3.readOnly, result2.recipients[1].readOnly);
			System.assertEquals(r3.required, result2.recipients[1].required);
			System.assertNotEquals(null, result2.recipients[2]);
			System.assertEquals(r4.envelopeRecipientId, result2.recipients[2].envelopeRecipientId);
			System.assertEquals(r4.type, result2.recipients[2].type);
			System.assertEquals(r4.sequence, result2.recipients[2].sequence);
			System.assertEquals(r4.routingOrder, result2.recipients[2].routingOrder);
			System.assertNotEquals(null, result2.recipients[2].role);
			System.assertEquals(r4.role.name, result2.recipients[2].role.name);
			System.assertEquals(r4.name, result2.recipients[2].name);
			System.assertEquals(r4.email, result2.recipients[2].email);
			System.assertEquals(null, result2.recipients[2].signingGroup);
			System.assertEquals(r4.phone, result2.recipients[2].phone);
			System.assertEquals(null, result2.recipients[2].authentication);
			System.assertEquals(r4.note, result2.recipients[2].note);
			System.assertEquals(null, result2.recipients[2].emailSettings);
			System.assertEquals(r4.hostName, result2.recipients[2].hostName);
			System.assertEquals(r4.hostEmail, result2.recipients[2].hostEmail);
			System.assertEquals(r4.signNow, result2.recipients[2].signNow);
			System.assertEquals(r4.tabs, result2.recipients[2].tabs);
			System.assertEquals(r4.source, result2.recipients[2].source);
			System.assertEquals(r4.readOnly, result2.recipients[2].readOnly);
			System.assertEquals(r4.required, result2.recipients[2].required);
			System.assertNotEquals(lm, result2.lastModified);
		}
	}

	@IsTest
	static void test_updateTemplate_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Template t = new Template(
				UUID.randomUUID(),
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null);

			Test.startTest();
			try {
				EnvelopeAPI.getInstance().updateTemplate(t);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateAPITemplate_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				EnvelopeAPI.getInstance().updateAPITemplate(null, UUID.randomUUID(), 100);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteTemplateDocuments_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				EnvelopeAPI.getInstance().deleteTemplateDocuments(null, UUID.randomUUID(), 100);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateTemplateDocuments_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				EnvelopeAPI.getInstance().updateTemplateDocuments(null, UUID.randomUUID(), 100);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteTemplateRecipients_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				EnvelopeAPI.getInstance().deleteTemplateRecipients(null, UUID.randomUUID(), 100);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteTemplate_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			System.assert(EnvelopeAPI.getInstance().deleteTemplate(UUID.randomUUID()));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteTemplate_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				EnvelopeAPI.getInstance().deleteTemplate(UUID.randomUUID());
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	static Tab newMergeField(final String type) {
		return Tab.newMergeField(
			type,
			'Account.Name',
			false,
			false)
			.withAutoPlaceText(UUID.randomUUID().toString());
	}

	@IsTest
	static void test_APIRecipients_new() {
		List<Tab> tabs = new List<Tab> {
			newMergeField(Tab.TYPE_APPROVE),
			newMergeField(Tab.TYPE_CHECKBOX),
			newMergeField(Tab.TYPE_COMPANY),
			newMergeField(Tab.TYPE_DATE_SIGNED),
			newMergeField(Tab.TYPE_DATE),
			newMergeField(Tab.TYPE_DECLINE),
			newMergeField(Tab.TYPE_EMAIL_ADDRESS),
			newMergeField(Tab.TYPE_EMAIL),
			newMergeField(Tab.TYPE_ENVELOPE_ID),
			newMergeField(Tab.TYPE_FIRST_NAME),
			newMergeField(Tab.TYPE_FORMULA),
			newMergeField(Tab.TYPE_FULL_NAME),
			newMergeField(Tab.TYPE_INITIAL_HERE),
			newMergeField(Tab.TYPE_LAST_NAME),
			newMergeField(Tab.TYPE_LIST),
			newMergeField(Tab.TYPE_NOTARIZE),
			newMergeField(Tab.TYPE_NOTE),
			newMergeField(Tab.TYPE_NUMBER),
			newMergeField(Tab.TYPE_RADIO_GROUP),
			newMergeField(Tab.TYPE_SIGNER_ATTACHMENT),
			newMergeField(Tab.TYPE_SIGN_HERE),
			newMergeField(Tab.TYPE_SMART_SECTION),
			newMergeField(Tab.TYPE_SSN),
			newMergeField(Tab.TYPE_TEXT),
			newMergeField(Tab.TYPE_TITLE),
			newMergeField(Tab.TYPE_VIEW),
			newMergeField(Tab.TYPE_ZIP)
		};

		List<Recipient> recipients = new List<Recipient> {
			Recipient.fromSource('s1', 's1@unit.test', null, null, null)
				.withType(Recipient.TYPE_SEAL, false)
				.withSequence(1)
				.withTabs(tabs),
			Recipient.fromSource('w1', 'w1@unit.test', null, null, null)
				.withType(Recipient.TYPE_WITNESS, false)
				.withSequence(2)
		};
		EnvelopeAPI.APIRecipients apiRecipients = new EnvelopeAPI.APIRecipients(
			recipients,
			'1',
			false);

		Test.startTest();
		List<Recipient.Status> result1 = apiRecipients.toStatus();
		List<Recipient> result2 = apiRecipients.toRecipients();
		Test.stopTest();

		System.assertEquals(2, Collection.size(result1));
		System.assertNotEquals(null, result1[0]);
		System.assertEquals(Recipient.TYPE_SEAL, result1[0].type);
		System.assertNotEquals(null, result1[1]);
		System.assertEquals(Recipient.TYPE_WITNESS, result1[1].type);

		System.assertEquals(2, Collection.size(result2));
		System.assertNotEquals(null, result2[0]);
		System.assertEquals(Recipient.TYPE_SEAL, result2[0].type);
		System.assertEquals(27, Collection.size(result2[0].tabs));
		System.assertNotEquals(null, result2[1]);
		System.assertEquals(Recipient.TYPE_WITNESS, result2[1].type);
		System.assertEquals(0, Collection.size(result2[1].tabs));
	}

	@IsTest
	static void test_getEnvelopeMergeFields_all() {
		ESignatureAPIMock.success(); // Should return 9 merge fields
		System.runAs(UserMock.createDocuSignAdministrator()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			List<Tab> result = client.getEnvelopeMergeFields(UUID.randomUUID(), false);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(9, Collection.size(result));
			for (Tab t : result) {
				System.assertNotEquals(null, t);
				System.assert(String.isNotBlank(t.type));
				System.assert(String.isNotBlank(t.name));
				System.assert(String.isNotBlank(t.key));
				System.assert(String.isNotBlank(t.path));
				if (t.type == Tab.TYPE_CHECKBOX) {
					System.assertNotEquals(null, t.value);
					System.assert(t.value instanceof Boolean);
				} else if (t.type == Tab.TYPE_DATE || t.type == Tab.TYPE_DATE_SIGNED) {
					System.assertNotEquals(null, t.value);
					System.assert(t.value instanceof Date);
				} else if (t.type == Tab.TYPE_NUMBER || t.type == Tab.TYPE_FORMULA) {
					System.assertNotEquals(null, t.value);
					System.assert(t.value instanceof Decimal);
				} else if (Tab.isValidMergeFieldType(t.type)) {
					System.assertNotEquals(null, t.value);
					System.assert(t.value instanceof String);
				}
			}
		}
	}

	@IsTest
	static void test_getEnvelopeMergeFields_write_back_only() {
		ESignatureAPIMock.success(); // Should return 5 merge fields
		System.runAs(UserMock.createDocuSignAdministrator()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			List<Tab> result = client.getEnvelopeMergeFields(UUID.randomUUID(), true);
			Test.stopTest();

			System.assertEquals(5, Collection.size(result));
			for (Tab t : result) {
				System.assertNotEquals(null, t);
				System.assert(String.isNotBlank(t.type));
				System.assert(String.isNotBlank(t.name));
				System.assert(String.isNotBlank(t.key));
				System.assert(String.isNotBlank(t.path));
				if (t.type == Tab.TYPE_CHECKBOX) {
					System.assertNotEquals(null, t.value);
					System.assert(t.value instanceof Boolean);
				} else if (t.type == Tab.TYPE_DATE || t.type == Tab.TYPE_DATE_SIGNED) {
					System.assertNotEquals(null, t.value);
					System.assert(t.value instanceof Date);
				} else if (t.type == Tab.TYPE_NUMBER || t.type == Tab.TYPE_FORMULA) {
					System.assertNotEquals(null, t.value);
					System.assert(t.value instanceof Decimal);
				} else if (Tab.isValidMergeFieldType(t.type)) {
					System.assertNotEquals(null, t.value);
					System.assert(t.value instanceof String);
				}
			}
		}
	}

	@IsTest
	static void test_getEnvelopeMergeFields_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.getEnvelopeMergeFields(UUID.randomUUID(), false);
				throw new AssertException('Expected failure');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}
}
