@IsTest
private class SigningServiceTest {
	
	static testMethod void test_Database_completeSignNow() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c e = TestUtils.createEnvelope();
			Recipient__c r = new Recipient__c(
				Envelope__c = e.Id,
				SignNow__c = true);
			insert r;

			Test.startTest();
			Boolean result = SigningService.DB.completeSignNow(r.Id);
			Test.stopTest();

			System.assert(result);
			List<Recipient__c> rs = [SELECT SignNow__c FROM Recipient__c WHERE Envelope__c = :e.Id];
			System.assertNotEquals(null, rs);
			System.assertEquals(1, rs.size());
			System.assert(!rs[0].SignNow__c);
		}
	}

	static testMethod void test_getNextSignNowRecipient_allow_sequential() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c dse = TestUtils.createEnvelope();
			EnvelopeSettings__c es = EnvelopeSettings__c.getOrgDefaults();
			es.AllowSequentialSignNow__c = true;
			upsert es;

			List<Recipient__c> dsers = new List<Recipient__c> {
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = 1,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test1',
					Email__c = 'r1@unit.test',
					RoutingOrder__c = 1,
					Role__c = 'Signer 1',
					SignNow__c = false),
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = null,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test2',
					Email__c = 'r2@unit.test',
					RoutingOrder__c = 2,
					Role__c = 'Signer 2',
					SignNow__c = false),
				// Only third recipient is valid for sign now
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = 2,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test3',
					Email__c = 'r3@unit.test',
					RoutingOrder__c = 3,
					Role__c = 'Signer 3',
					SignNow__c = true)
			};
			insert dsers;

			List<Recipient> rs = RecipientService.convert(dsers);
			System.assertNotEquals(null, rs);
			System.assertEquals(3, rs.size());

			Test.startTest();
			Recipient result1 = SigningService.getNextSignNowRecipient(null, null, null, false);
			Recipient result2 = SigningService.getNextSignNowRecipient(rs, 'Unit Test1', 'r1@unit.test', false);
			Recipient result3 = SigningService.getNextSignNowRecipient(rs, 'Unit Test2', 'r2@unit.test', false);
			Recipient result4 = SigningService.getNextSignNowRecipient(rs, 'Unit Test3', 'r3@unit.test', false);
			Test.stopTest();

			System.assertEquals(null, result1);
			System.assertEquals(null, result2);
			System.assertEquals(null, result3);
			System.assertEquals(rs[2], result4);
		}
	}

	static testMethod void test_getNextSignNowRecipient_check_first_only() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c dse = TestUtils.createEnvelope();
			List<Recipient__c> dsers = new List<Recipient__c> {
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = 1,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test1',
					Email__c = 'r1@unit.test',
					RoutingOrder__c = 1,
					Role__c = 'Signer 1',
					SignNow__c = false),
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = null,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test2',
					Email__c = 'r2@unit.test',
					RoutingOrder__c = 2,
					Role__c = 'Signer 2',
					SignNow__c = false),
				// Only third recipient is valid for sign now
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = 2,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test3',
					Email__c = 'r3@unit.test',
					RoutingOrder__c = 3,
					Role__c = 'Signer 3',
					SignNow__c = true)
			};
			insert dsers;

			List<Recipient> rs = RecipientService.convert(dsers);
			System.assertNotEquals(null, rs);
			System.assertEquals(3, rs.size());

			Test.startTest();
			Recipient result = SigningService.getNextSignNowRecipient(rs, 'Unit Test', 'r@unit.test', true);
			Test.stopTest();

			System.assertEquals(null, result);
		}
	}

	static testMethod void test_getNextSignNowRecipient_prohibit_sequential() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Envelope__c dse = TestUtils.createEnvelope();
			EnvelopeSettings__c es = EnvelopeSettings__c.getOrgDefaults();
			es.AllowSequentialSignNow__c = false;
			upsert es;

			List<Recipient__c> dsers = new List<Recipient__c> {
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = 1,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test1',
					Email__c = 'r1@unit.test',
					RoutingOrder__c = 1,
					Role__c = 'Signer 1',
					SignNow__c = false),
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = null,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test2',
					Email__c = 'r2@unit.test',
					RoutingOrder__c = 2,
					Role__c = 'Signer 2',
					SignNow__c = false),
				// Only third recipient is valid for sign now
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = 2,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test3',
					Email__c = 'r3@unit.test',
					RoutingOrder__c = 3,
					Role__c = 'Signer 3',
					SignNow__c = true)
			};
			insert dsers;

			List<Recipient> rs = RecipientService.convert(dsers);
			System.assertNotEquals(null, rs);
			System.assertEquals(3, rs.size());

			Test.startTest();
			Recipient result1 = SigningService.getNextSignNowRecipient(null, null, null, false);
			Recipient result2 = SigningService.getNextSignNowRecipient(rs, 'Unit Test1', 'r1@unit.test', false);
			Recipient result3 = SigningService.getNextSignNowRecipient(rs, 'Unit Test2', 'r2@unit.test', false);
			Recipient result4 = SigningService.getNextSignNowRecipient(rs, 'Unit Test3', 'r3@unit.test', false);
			Test.stopTest();

			System.assertEquals(null, result1);
			System.assertEquals(null, result2);
			System.assertEquals(null, result3);
			System.assertEquals(null, result4);
		}
	}

	static testMethod void test_shouldSignNow() {
		Envelope e1 = new Envelope(null, 'subject1', 'message1', null);
		Envelope e2 = new Envelope(null, 'subject2', 'message2', null)
			.withRecipients(new List<Recipient> {
				Recipient.fromSource('Unit Test1', 'r1@unit.test', null, null, null).withSignNow(false),
				Recipient.fromSource('Unit Test2', 'r2@unit.test', null, null, null).withSignNow(false),
				Recipient.fromSource('Unit Test3', 'r3@unit.test', null, null, null).withSignNow(true)
			});

		Test.startTest();
		Boolean result1 = SigningService.shouldSignNow(null);
		Boolean result2 = SigningService.shouldSignNow(e1);
		Boolean result3 = SigningService.shouldSignNow(e2);
		Test.stopTest();

		System.assert(!result1);
		System.assert(!result2);
		System.assert(result3);
	}

	static testMethod void test_getSigningUrl_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeSettings__c es = EnvelopeSettings__c.getOrgDefaults();
			es.AllowSequentialSignNow__c = true;
			upsert es;

			Envelope__c dse = TestUtils.createEnvelope();
			List<Recipient__c> dsers = new List<Recipient__c> {
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = 1,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test1',
					Email__c = 'r1@unit.test',
					RoutingOrder__c = 1,
					Role__c = 'Signer 1',
					SignNow__c = false),
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = null,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test2',
					Email__c = 'r2@unit.test',
					RoutingOrder__c = 2,
					Role__c = 'Signer 2',
					SignNow__c = false),
				// Only third recipient is valid for sign now
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = 1,
					Type__c = Recipient.TYPE_SIGNER,
					Name = UserInfo.getName(),
					Email__c = UserInfo.getUserEmail(),
					RoutingOrder__c = 3,
					Role__c = 'Signer 3',
					SignNow__c = true)
			};
			insert dsers;

			List<Recipient> rs = RecipientService.convert(dsers);
			System.assertNotEquals(null, rs);
			System.assertEquals(3, rs.size());

			Envelope e1 = new Envelope(null, 'subject', 'message', null)
				.withRecipients(rs);
			Envelope e2 = new Envelope(null, 'subject', 'message', null)
				.withDocuSignId(UUID.randomUUID())
				.withRecipients(rs);
			Url returnUrl = new Url('https://unit.test/return');

			Test.startTest();
			Url result1 = SigningService.getSigningUrl(null, null, false);
			Url result2 = SigningService.getSigningUrl(e1, returnUrl, false);
			Url result3 = SigningService.getSigningUrl(e2, returnUrl, false);
			Test.stopTest();

			System.assertEquals(null, result1);
			System.assertEquals(null, result2);
			System.assertNotEquals(null, result3);
			System.assertEquals('https://unit.test/view/recipient', result3.toExternalForm());

			Recipient__c dser = [SELECT SignNow__c FROM Recipient__c WHERE Id = :dsers[2].Id LIMIT 1];
			System.assertNotEquals(null, dser);
			System.assert(!dser.SignNow__c);
		}
	}

	static testMethod void test_getSigningUrl_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeSettings__c es = EnvelopeSettings__c.getOrgDefaults();
			es.AllowSequentialSignNow__c = true;
			upsert es;

			Envelope__c dse = TestUtils.createEnvelope();
			List<Recipient__c> dsers = new List<Recipient__c> {
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = 1,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test1',
					Email__c = 'r1@unit.test',
					RoutingOrder__c = 1,
					Role__c = 'Signer 1',
					SignNow__c = false),
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = null,
					Type__c = Recipient.TYPE_SIGNER,
					Name = 'Unit Test2',
					Email__c = 'r2@unit.test',
					RoutingOrder__c = 2,
					Role__c = 'Signer 2',
					SignNow__c = false),
				// Only third recipient is valid for sign now
				new Recipient__c(
					Envelope__c = dse.Id,
					Sequence__c = 1,
					Type__c = Recipient.TYPE_SIGNER,
					Name = UserInfo.getName(),
					Email__c = UserInfo.getUserEmail(),
					RoutingOrder__c = 3,
					Role__c = 'Signer 3',
					SignNow__c = true)
			};
			insert dsers;

			List<Recipient> rs = RecipientService.convert(dsers);
			System.assertNotEquals(null, rs);
			System.assertEquals(3, rs.size());

			Envelope e = new Envelope(null, 'subject', 'message', null)
				.withDocuSignId(UUID.randomUUID())
				.withRecipients(rs);
			Url returnUrl = new Url('https://unit.test/return');

			Test.startTest();
			try {
				SigningService.getSigningUrl(e, returnUrl, false);
				throw new AssertException('Expected getSigningUrl to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex);
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.NOT_FOUND, ex.error.code);
			}
			Test.stopTest();

			Recipient__c dser = [SELECT SignNow__c FROM Recipient__c WHERE Id = :dsers[2].Id LIMIT 1];
			System.assertNotEquals(null, dser);
			System.assert(!dser.SignNow__c);
		}
	}
}
