@IsTest
private class EnvelopeResponseTest {

	static testMethod void test_success() {
		Envelope e = new Envelope(null, null, null, null, null, null, null, null, 'subject', 'message', null, null);

		Test.startTest();
		EnvelopeResponse er1 = EnvelopeResponse.success(e);
		Test.stopTest();

		System.assertNotEquals(null, er1);
		System.assert(er1.success);
		System.assert(Collection.isEmpty(er1.messages));
		System.assert(e === er1.envelope);
		System.assert(String.isBlank(er1.url));
	}

	static testMethod void test_failure() {
		Test.startTest();
		EnvelopeResponse er1 = EnvelopeResponse.failure(new DocuSignException('fail'));
		EnvelopeResponse er2 = EnvelopeResponse.failure(new List<APIError> {
			new APIError(APIErrorCode.BAD_REQUEST, 'fail1'),
			new APIError(APIErrorCode.FAILURE, 'fail2')
		});
		Test.stopTest();

		System.assertNotEquals(null, er1);
		System.assert(!er1.success);
		System.assert(!Collection.isEmpty(er1.messages));
		System.assertEquals(1, er1.messages.size());
		System.assertEquals('fail', er1.messages[0].description);
		System.assertEquals(null, er1.envelope);
		System.assert(String.isBlank(er1.url));

		System.assertNotEquals(null, er2);
		System.assert(!er2.success);
		System.assert(!Collection.isEmpty(er2.messages));
		System.assertEquals(2, er2.messages.size());
		System.assertEquals('fail1', er2.messages[0].description);
		System.assertEquals('fail2', er2.messages[1].description);
		System.assertEquals(null, er2.envelope);
		System.assert(String.isBlank(er2.url));
	}

	static testMethod void test_navigateTo() {
		Test.startTest();
		EnvelopeResponse er1 = EnvelopeResponse.navigateTo('https://unit.test');
		EnvelopeResponse er2 = EnvelopeResponse.navigateTo(UserInfo.getUserId());
		Test.stopTest();

		System.assertNotEquals(null, er1);
		System.assert(er1.success);
		System.assert(Collection.isEmpty(er1.messages));
		System.assertEquals(null, er1.envelope);
		System.assertEquals('https://unit.test', er1.url);

		System.assertNotEquals(null, er2);
		System.assert(er2.success);
		System.assert(Collection.isEmpty(er2.messages));
		System.assertEquals(null, er2.envelope);
		System.assertEquals(UserInfo.getUserId(), er2.url);
	}
}
