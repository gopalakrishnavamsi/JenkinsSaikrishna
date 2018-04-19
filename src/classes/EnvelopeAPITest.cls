@IsTest
private class EnvelopeAPITest {

	static testMethod void test_bad_resolver() {
		System.runAs(TestUtils.createDocuSignUser()) {
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

	static testMethod void test_getError() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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

			Test.startTest();
			APIError e1 = client.getError(r1);
			APIError e2 = client.getError(r2);
			APIError e3 = client.getError(r3);
			APIError e4 = client.getError(r4);
			APIError e5 = client.getError(r5);
			Test.stopTest();

			System.assertEquals(APIError.none, e1);

			System.assertNotEquals(null, e2);
			System.assert(e2 instanceof DocuSignAPI.Error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, e2.code);
			System.assertEquals('Some error', e2.description);
			System.assertEquals('SOME_ERROR', ((DocuSignAPI.Error)e2).docuSignCode);

			System.assertNotEquals(null, e3);
			System.assert(!(e3 instanceof DocuSignAPI.Error));
			System.assertEquals(APIErrorCode.ACCOUNT_LACKS_PERMISSIONS, e3.code);
			System.assertEquals('Account lacks permissions', e3.description);

			System.assertNotEquals(null, e4);
			System.assert(!(e4 instanceof DocuSignAPI.Error));
			System.assertEquals(APIErrorCode.INVALID_RECIPIENT_SEQUENCE, e4.code);
			System.assertEquals('Recipient not in sequence', e4.description);

			System.assertNotEquals(null, e5);
			System.assert(!(e5 instanceof DocuSignAPI.Error));
			System.assertEquals(APIErrorCode.UNKNOWN_RECIPIENT, e5.code);
			System.assertEquals('Unknown envelope recipient', e5.description);
		}
	}

	static testMethod void test_buildCustomFields() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			CustomField cf1 = new CustomField('n1', 'v1', true, false);
			CustomField cf2 = new CustomField('n2', 'v2', false, true);
			CustomField cf3 = new CustomField('n3', 'v3', new List<String> { 'v1', 'v2', 'v3' }, true, true);
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);

			Test.startTest();
			EnvelopeAPI.CustomFields result = EnvelopeAPI.buildCustomFields(new List<CustomField> { cf1, cf2, cf3 },
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
		}
	}

	static testMethod void test_getDocumentContent_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			ContentVersion cv1 = TestUtils.createContentVersion();
			ContentVersion cv2 = TestUtils.createContentVersion();
			Schema.Document d1 = TestUtils.createDocument();
			Document t1 = new Document(null, Document.TYPE_TEMPLATE, null, 'UnitTestTemplate', null, null, UUID.randomUUID().toString());

			Test.startTest();
			Map<Id, Blob> result1 = EnvelopeAPI.getDocumentContent(new List<Document> {
				t1,
				Document.fromContentVersion(cv1),
				Document.fromContentVersion(cv2),
				Document.fromDocument(d1)
			}, false);
			Map<Id, Blob> result2 = EnvelopeAPI.getDocumentContent(new List<Document> {
				t1,
				Document.fromContentVersion(cv1),
				Document.fromContentVersion(cv2),
				Document.fromDocument(d1)
			}, true);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertEquals(3, result1.size());
			System.assertEquals(cv1.VersionData.toString(), result1.get(cv1.Id).toString());
			System.assertEquals(cv2.VersionData.toString(), result1.get(cv2.Id).toString());
			System.assertEquals(d1.Body.toString(), result1.get(d1.Id).toString());

			System.assertNotEquals(null, result2);
			System.assertEquals(3, result2.size());
			System.assertEquals(cv1.Id, result2.get(cv1.Id).toString());
			System.assertEquals(cv2.Id, result2.get(cv2.Id).toString());
			System.assertEquals(d1.Id, result2.get(d1.Id).toString());
		}
	}

	static testMethod void test_getDocumentContent_error() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			ContentVersion cv1 = TestUtils.createContentVersion();

			Test.startTest();
			try {
				EnvelopeAPI.getDocumentContent(new List<Document> {
					new Document(null, Document.TYPE_FILE, null, 'UnitTest1.pdf', 'pdf', 1234, UserInfo.getUserId()),
					Document.fromContentVersion(cv1),
					new Document(null, Document.TYPE_FILE, null, 'UnitTest2.pdf', 'pdf', 1234, UserInfo.getOrganizationId()),
					new Document(null, Document.TYPE_TEMPLATE, null, 'UnitTestTemplate', null, null, UUID.randomUUID().toString())
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

	static testMethod void test_getSenderViewURL_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			URL u = client.getSenderViewURL(UUID.randomUUID(), new URL('https://unit.test.return/'));
			Test.stopTest();

			System.assertNotEquals(null, u);
			System.assertEquals('https://unit.test/view/sender', u.toExternalForm());
		}
	}

	static testMethod void test_getSenderViewURL_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getSenderViewURL(UUID.randomUUID(), new URL('https://unit.test.return/'));
				throw new AssertException('Expected getSenderViewURL call to fail');
			} catch (APIException ex2) {
				ex = ex2;

			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(400, ex.error.code);
		}
	}

	static testMethod void test_getRecipientViewURL_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			URL u = client.getRecipientViewURL(
				UUID.randomUUID(), new URL('https://unit.test.return/'), 'a@b.c', 'a@b.c', 1);
			Test.stopTest();

			System.assertNotEquals(null, u);
			System.assertEquals('https://unit.test/view/recipient', u.toExternalForm());
		}
	}

	static testMethod void test_getRecipientViewURL_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getRecipientViewURL(
					UUID.randomUUID(), new URL('https://unit.test.return/'), 'a@b.c', 'a@b.c', 1);
				throw new AssertException('Expected getRecipientView call to fail');
			} catch (APIException ex2) {
				ex = ex2;

			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(404, ex.error.code);
		}
	}

	static testMethod void test_getConsoleViewURL_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			URL u = client.getConsoleViewURL(UUID.randomUUID(), new URL('https://unit.test/return'));
			Test.stopTest();

			System.assertNotEquals(null, u);
			System.assertEquals('https://unit.test/view/console', u.toExternalForm());
		}
	}

	static testMethod void test_getConsoleViewURL_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getConsoleViewURL(UUID.randomUUID(), new URL('https://unit.test/return'));
				throw new AssertException('Expected getConsoleView call to fail');
			} catch (APIException ex2) {
				ex = ex2;

			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(422, ex.error.code);
		}
	}

	static testMethod void test_getCorrectViewURL_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			URL u = client.getCorrectViewURL(UUID.randomUUID(), new URL('https://unit.test/return'));
			Test.stopTest();

			System.assertNotEquals(null, u);
			System.assertEquals('https://unit.test/view/correct', u.toExternalForm());
		}
	}

	static testMethod void test_getCorrectViewURL_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getCorrectViewURL(UUID.randomUUID(), new URL('https://unit.test/return'));
				throw new AssertException('Expected getCorrectView call to fail');
			} catch (APIException ex2) {
				ex = ex2;

			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(400, ex.error.code);
		}
	}

	private class CorrectViewErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			String endpoint = request.getEndpoint();
			if (endpoint.contains(TestUtils.ID1.toString())) {
				response.setBody('{"errorCode":"INVALID_ENVELOPE_STATE","message":"Only envelopes in the \'Sent\' or \'Delivered\' states may be corrected."}');
			} else if (endpoint.contains(TestUtils.ID2.toString())) {
				response.setBody('{"errorCode":"ENVELOPE_LOCKED","message":"The envelope is locked."}');
			} else if (endpoint.contains(TestUtils.ID3.toString())) {
				response.setBody('{"errorCode":"USER_NOT_SENDER","message":"This user is not the sender of the envelope."}');
			} else if (endpoint.contains(TestUtils.ID4.toString())) {
				response.setBody('{"errorCode":"ENVELOPE_NOT_FOUND","message":"The envelope specified either does not exist or you have no rights to it"}');
			} else {
				response.setBody('{"errorCode":"RANDOM_ERROR","message":"Random error"}');
			}
			return response;
		}
	}

	static testMethod void test_getCorrectViewURL_error() {
		Test.setMock(HttpCalloutMock.class, new CorrectViewErrorMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			URL returnURL = new URL('https://unit.test/return');
			APIException ex1, ex2, ex3, ex4, ex5;

			Test.startTest();
			try {
				client.getCorrectViewURL(TestUtils.ID1, returnURL);
				throw new AssertException('Expected getCorrectViewURL to fail');
			} catch (APIException ex) {
				ex1 = ex;
			}
			try {
				client.getCorrectViewURL(TestUtils.ID2, returnURL);
				throw new AssertException('Expected getCorrectViewURL to fail');
			} catch (APIException ex) {
				ex2 = ex;
			}
			try {
				client.getCorrectViewURL(TestUtils.ID3, returnURL);
				throw new AssertException('Expected getCorrectViewURL to fail');
			} catch (APIException ex) {
				ex3 = ex;
			}
			try {
				client.getCorrectViewURL(TestUtils.ID4, returnURL);
				throw new AssertException('Expected getCorrectViewURL to fail');
			} catch (APIException ex) {
				ex4 = ex;
			}
			try {
				client.getCorrectViewURL(TestUtils.ID5, returnURL);
				throw new AssertException('Expected getCorrectViewURL to fail');
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

	static testMethod void test_resendEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			System.assert(client.resendEnvelope(UUID.randomUUID()));
			Test.stopTest();
		}
	}

	static testMethod void test_resendEnvelope_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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
			System.assertEquals(415, ex.error.code);
		}
	}

	static testMethod void test_getSigningGroups_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			List<SigningGroup> signingGroups1 = client.getSigningGroups();
			// Call again to get cached version
			List<SigningGroup> signingGroups2 = client.getSigningGroups();
			Test.stopTest();

			System.assertNotEquals(null, signingGroups1);
			System.assertEquals(3, signingGroups1.size());
			System.assert(signingGroups1 === signingGroups2); // Check reference equality

			System.assertEquals(1L, signingGroups1[0].id);
			System.assertEquals('SG1', signingGroups1[0].name);
			System.assert(signingGroups1[0].isValid);
			System.assertNotEquals(null, signingGroups1[0].members);
			System.assertEquals(2, signingGroups1[0].members.size());
			System.assertEquals('sg1.u1', signingGroups1[0].members[0].username);
			System.assertEquals('sg1.u1@unit.test', signingGroups1[0].members[0].email);
			System.assertEquals('sg1.u2', signingGroups1[0].members[1].username);
			System.assertEquals('sg1.u2@unit.test', signingGroups1[0].members[1].email);

			System.assertEquals(2L, signingGroups1[1].id);
			System.assertEquals('SG2', signingGroups1[1].name);
			System.assert(!signingGroups1[1].isValid);
			System.assertNotEquals(null, signingGroups1[1].members);
			System.assertEquals(0, signingGroups1[1].members.size());

			System.assertEquals(3L, signingGroups1[2].id);
			System.assertEquals('SG3', signingGroups1[2].name);
			System.assert(signingGroups1[2].isValid);
			System.assertNotEquals(null, signingGroups1[2].members);
			System.assertEquals(1, signingGroups1[2].members.size());
			System.assertEquals('sg3.u1', signingGroups1[2].members[0].username);
			System.assertEquals('sg3.u1@unit.test', signingGroups1[2].members[0].email);
		}
	}

	static testMethod void test_getSigningGroups_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client1 = EnvelopeAPI.getInstance();
			client1.getBaseURL();
			EnvelopeAPI client2 = new EnvelopeAPI(new Credentials(Environment.demo, TestUtils.ID1,
				UUID.randomUUID().toString(), UUID.randomUUID().toString(), true, UUID.randomUUID().toString(), false));
			APIException ex1, ex2 = null;

			Test.startTest();
			try {
				client1.getSigningGroups();
				throw new AssertException('Expected getSigningGroups to fail');
			} catch (APIException ex3) {
				ex1 = ex3;
			}

			try {
				client2.getSigningGroups();
				throw new AssertException('Expected getSigningGroups to fail');
			} catch (APIException ex4) {
				ex2 = ex4;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex1);
			System.assertEquals('just stop', ex1.getMessage());

			System.assertNotEquals(null, ex2);
			System.assertEquals(Label.SigningGroupsProhibited, ex2.getMessage());
		}
	}

	static testMethod void test_updateInPersonSigner_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			System.assert(client.updateInPersonSigner(UUID.randomUUID(), 'unit@test.com'));
			Test.stopTest();
		}
	}

	static testMethod void test_updateInPersonSigner_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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
			System.assertEquals(400, ex.error.code);
		}
	}

	static testMethod void test_voidEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			System.assert(client.voidEnvelope(UUID.randomUUID(), 'Just because'));
			Test.stopTest();
		}
	}

	static testMethod void test_voidEnvelope_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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
			System.assertEquals(400, ex1.error.code);
		}
	}

	private class VoidEnvelopeErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			if (request.getEndpoint().contains(TestUtils.ID1.toString())) {
				response.setBody('{"errorCode":"USER_NOT_SENDER","message":"This user is not the sender of the envelope."}');
			} else {
				response.setBody('{"errorCode":"GENERIC_ERROR","message":"Some error"}');
			}
			return response;
		}
	}

	static testMethod void test_voidEnvelope_errors() {
		Test.setMock(HttpCalloutMock.class, new VoidEnvelopeErrorMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			APIException ex1, ex2;

			Test.startTest();
			try {
				client.voidEnvelope(TestUtils.ID1, 'Just because');
				throw new AssertException('Expected voidEnvelope to fail');
			} catch (APIException ex) {
				ex1 = ex;
			}
			try {
				client.voidEnvelope(TestUtils.ID2, 'Just because');
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

	static testMethod void test_createEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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
					new Document(null, Document.TYPE_TEMPLATE, 1, 'Doc1', null, 100, UUID.randomUUID().toString()),
					Document.fromContentVersion(TestUtils.createContentVersion()).withSequence(2)
				},
				new List<Recipient> {
					Recipient.newInPersonSigner(1, new Recipient.Role('Signer 1', 1), 'Recipient One', 'r1@unit.test',
						'Host One', 'h1@unit.test', new Recipient.Authentication('1234', true,
							new List<String> { '5555555555' }), 'note1', true).withSequence(1),
					Recipient.newRecipient(2, Recipient.TYPE_SIGNER, new Recipient.Role('Signer 2', 2), 'Recipient Two',
						'r2@unit.test', null, 'note2', false).withSequence(2)
				},
				new List<CustomField> {
					new CustomField('cf1', '1', true, true),
					new CustomField('cf2', '2', new List<String> { '1', '2', '3' }, true, true)
				},
				new Envelope.Notifications(false, 0, 0, false, 0, 0, false),
				'subject',
				'body',
				new Entity(o.Id),
				null);
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			UUID result = client.createEnvelope(e2, new Envelope.Options(true, true, true, true));
			Test.stopTest();

			System.assertEquals(TestUtils.id1, result);
		}
	}

	static testMethod void test_createEnvelope_success_with_Recipient_EmailSettings() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
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
					new Document(null, Document.TYPE_TEMPLATE, 1, 'Doc1', null, 100, UUID.randomUUID().toString()),
					Document.fromContentVersion(TestUtils.createContentVersion()).withSequence(2)
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
					new CustomField('cf1', '1', true, true),
					new CustomField('cf2', '2', new List<String> { '1', '2', '3' }, true, true)
				},
				null,
				'subject',
				'body',
				new Entity(o.Id),
				null);
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			UUID result = client.createEnvelope(e2, new Envelope.Options(true, true, true, true));
			Test.stopTest();

			System.assertEquals(TestUtils.id1, result);
		}
	}

	static testMethod void test_buildCompositeTemplates_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Envelope__c e1 = TestUtils.createEnvelope();
			Document doc = DocumentService.DB.convert(TestUtils.createEnvelopeDocument(e1.Id));

			Map<Id, Blob> content = EnvelopeAPI.getDocumentContent(new List<Document> { doc }, true);

			Test.startTest();
			List<EnvelopeAPI.CompositeTemplate> compositeTemplatesList = EnvelopeAPI.buildCompositeTemplates(
				new List<Document> {
					new Document(null, Document.TYPE_TEMPLATE, 1, 'Doc1', null, 100, UUID.randomUUID().toString()),
					doc
				},
				new List<Recipient> {
					Recipient.newInPersonSigner(1, new Recipient.Role('Signer 1', 1), 'Recipient One', 'r1@unit.test',
						'Host One', 'h1@unit.test', new Recipient.Authentication('1234', true,
							new List<String> { '5555555555' }), 'note1', true),
					Recipient.newRecipient(2, Recipient.TYPE_SIGNER, new Recipient.Role('Signer 2', 2),
						'Recipient Two', 'r2@unit.test', null, 'note2', false)
				},
				true,
				content);
			Test.stopTest();
			System.assertEquals(2, compositeTemplatesList.size());
			System.assertEquals(1, compositeTemplatesList[0].serverTemplates.size());
			System.assertEquals(1, compositeTemplatesList[1].inlineTemplates.size());
		}
	}

	static testMethod void test_createEnvelope_recipient_types() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope__c e1 = TestUtils.createEnvelope();
			Document__c d = TestUtils.createEnvelopeDocument(e1.Id);
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
				new Envelope.Notifications(false, 0, 0, false, 0, 0, false), 'subject', 'body',
				null, null);
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			UUID result = client.createEnvelope(e2, new Envelope.Options(true, true, true, true));
			Test.stopTest();

			System.assertEquals(TestUtils.id1, result);
		}
	}

	static testMethod void test_createEnvelope_document_types() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			Envelope__c e1 = TestUtils.createEnvelope();
			Document__c d1 = TestUtils.createEnvelopeDocument(e1.Id, TestUtils.createDocument(UserInfo.getUserId()), 1);
			Document__c d2 = TestUtils.createEnvelopeDocument(e1.Id, TestUtils.createContentVersion(), 2);
			Document__c d3 = TestUtils.createEnvelopeDocument(e1.Id, TestUtils.createContentVersion(), 3);
			Integer sequence = 1;
			List<Document> docs = new List<Document> {
				new Document(d1.Id, d1.Type__c, sequence++, d1.Name, d1.Extension__c, Integer.valueOf(d1.Size__c), d1.SourceId__c),
				new Document(d2.Id, d2.Type__c, sequence++, d2.Name, d2.Extension__c, Integer.valueOf(d2.Size__c), d2.SourceId__c),
				new Document(d3.Id, d3.Type__c, sequence++, d3.Name, d3.Extension__c, Integer.valueOf(d3.Size__c), d3.SourceId__c)
			};
			Envelope e2 = new Envelope(e1.Id, e1.Name, null, null,
				docs,
				new List<Recipient>(),
				new List<CustomField>(),
				new Envelope.Notifications(false, 0, 0, false, 0, 0, false), 'subject', 'body',
				null, null);
			EnvelopeAPI client = EnvelopeAPI.getInstance();
			Test.startTest();
			UUID result = client.createEnvelope(e2, new Envelope.Options(true, true, false, true));
			Test.stopTest();

			System.assertEquals(TestUtils.id1, result);
		}
	}

	static testMethod void test_createEnvelope_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(e, new Envelope.Options(true, true, true, true));
				throw new AssertException('Expected createEnvelope to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(400, ex.error.code);
			}
			Test.stopTest();
		}
	}

	static testMethod void test_createEnvelope_null_envelope() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(null, new Envelope.Options(true, true, true, true));
				throw new AssertException('Expected createEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedEnvelope, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	static testMethod void test_createEnvelope_fetch_invalid_document() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope__c e1 = TestUtils.createEnvelope();
			Document__c d = new Document__c(
				Envelope__c = e1.Id,
				Name = 'Unit Test',
				SourceId__c = UserInfo.getUserId(), // Bad document type
				Sequence__c = 1,
				Size__c = 1234,
				Extension__c = 'pdf',
				Type__c = Document.TYPE_FILE);
			insert d;
			Envelope e2 = new Envelope(e1.Id, e1.Name, null, null,
				new List<Document> { DocumentService.DB.convert(d) },
				new List<Recipient>(),
				new List<CustomField>(),
				new Envelope.Notifications(false, 0, 0, false, 0, 0, false), 'subject', 'body',
				null, null);
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(e2, new Envelope.Options(true, true, false, true));
				throw new AssertException('Expected createEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.CannotReadDocumentContent_1,
					new List<String> { d.Name + ' (' + d.SourceId__c + ')' }), ex.getMessage());
			}
			Test.stopTest();
		}
	}

	class CfrErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"CFR_ERROR","message":"Signers that are required to meet 21 CFR part 11"}');
			return response;
		}
	}

	static testMethod void test_createEnvelope_error_21_cfr_part_11() {
		Test.setMock(HttpCalloutMock.class, new CfrErrorMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(e, new Envelope.Options(false, true, true, true));
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.FAILED_TO_MEET_21_CFR_PART_11, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class UserNotActivatedErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"USER_NOT_ACTIVATED","message":"Account settings indicate the recipient must be an active DocuSign user"}');
			return response;
		}
	}

	static testMethod void test_createEnvelope_error_user_not_activated() {
		Test.setMock(HttpCalloutMock.class, new UserNotActivatedErrorMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(e, new Envelope.Options(false, true, true, true));
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.USER_NOT_ACTIVATED, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class TrialExpiredErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"TRIAL_ACCOUNT_EXPIRED","message":"trialexpired"}');
			return response;
		}
	}

	static testMethod void test_createEnvelope_error_trial_expired() {
		Test.setMock(HttpCalloutMock.class, new TrialExpiredErrorMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(e, new Envelope.Options(false, true, true, true));
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.TRIAL_ACCOUNT_EXPIRED, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class AccountPermissionErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"ACCOUNT_LACKS_PERMISSIONS","message":"account lacks sufficient permissions"}');
			return response;
		}
	}

	static testMethod void test_createEnvelope_error_account_permissions() {
		Test.setMock(HttpCalloutMock.class, new AccountPermissionErrorMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(e, new Envelope.Options(false, true, true, true));
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.ACCOUNT_LACKS_PERMISSIONS, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class UserPermissionErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"USER_LACKS_PERMISSIONS","message":"user lacks sufficient permissions"}');
			return response;
		}
	}

	static testMethod void test_createEnvelope_error_user_permissions() {
		Test.setMock(HttpCalloutMock.class, new UserPermissionErrorMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(e, new Envelope.Options(false, true, true, true));
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.ACCOUNT_LACKS_PERMISSIONS, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class InvalidDocumentErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"INVALID_DOCUMENT","message":"unable to convert this document"}');
			return response;
		}
	}

	static testMethod void test_createEnvelope_error_invalid_document() {
		Test.setMock(HttpCalloutMock.class, new InvalidDocumentErrorMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(e, new Envelope.Options(false, true, true, true));
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.INVALID_DOCUMENT, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class InvalidSigningGroupErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"INVALID_SIGNING_GROUP","message":"Group has no members"}');
			return response;
		}
	}

	static testMethod void test_createEnvelope_error_invalid_signing_group() {
		Test.setMock(HttpCalloutMock.class, new InvalidSigningGroupErrorMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(e, new Envelope.Options(false, true, true, true));
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.INVALID_SIGNING_GROUP, ex.error.code);
			}
			Test.stopTest();
		}
	}

	class InvalidRecipientErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"INVALID_RECIPIENT","message":"user name for the recipient is invalid"}');
			return response;
		}
	}

	static testMethod void test_createEnvelope_error_invalid_recipient() {
		Test.setMock(HttpCalloutMock.class, new InvalidRecipientErrorMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
			EnvelopeAPI client = EnvelopeAPI.getInstance();

			Test.startTest();
			try {
				client.createEnvelope(e, new Envelope.Options(false, true, true, true));
				throw new AssertException('Expected createEnvelope call to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.INVALID_RECIPIENT, ex.error.code);
			}
			Test.stopTest();
		}
	}

	static testMethod void test_getRecipientCustomFields() {
		TestUtils.createAccountConfiguration();
		Recipient r = Recipient.newRecipient(1, Recipient.TYPE_SIGNER, null, 'UNIT TEST', 'r@unit.test', null, null, false);
		Entity e = Entity.resolve(UserInfo.getUserId());

		Test.startTest();
		System.assertEquals(null, EnvelopeAPI.getRecipientCustomFields(null));
		System.assertEquals(null, EnvelopeAPI.getRecipientCustomFields(r));
		System.assertEquals(new List<String> { '##SFUser:' + UserInfo.getUserId() }, EnvelopeAPI.getRecipientCustomFields(r.withSource(e)));
		Test.stopTest();
	}
}
