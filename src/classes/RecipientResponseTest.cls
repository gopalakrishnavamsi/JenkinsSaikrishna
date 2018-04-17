@IsTest
private class RecipientResponseTest {

	static testMethod void test_success() {
		Envelope__c dse = TestUtils.createEnvelope();
		Recipient r1 = RecipientService.convert(TestUtils.createEnvelopeRecipient(dse.Id));
		Recipient r2 = RecipientService.convert(TestUtils.createEnvelopeRecipient(dse.Id));
		Set<Id> removedIds = new Set<Id> { r1.id, r2.id };

		Test.startTest();
		RecipientResponse result1 = RecipientResponse.success(new List<Recipient> { r1, r2 });
		RecipientResponse result2 = RecipientResponse.success(removedIds);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.success);
		System.assert(Collection.isEmpty(result1.messages));
		System.assertNotEquals(null, result1.recipients);
		System.assertEquals(null, result1.removedIds);
		System.assertEquals(2, result1.recipients.size());
		System.assert(r1 === result1.recipients[0]);
		System.assert(r2 === result1.recipients[1]);

		System.assertNotEquals(null, result2);
		System.assert(result2.success);
		System.assert(Collection.isEmpty(result2.messages));
		System.assertEquals(null, result2.recipients);
		System.assertEquals(removedIds, result2.removedIds);
	}

	static testMethod void test_failure() {
		Test.startTest();
		RecipientResponse result1 = RecipientResponse.failure(new DocuSignException('fail'));
		RecipientResponse result2 = RecipientResponse.failure(new List<APIError> {
			new APIError(APIErrorCode.BAD_REQUEST, 'fail1'),
			new APIError(APIErrorCode.FAILURE, 'fail2')
		});
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.success);
		System.assert(!Collection.isEmpty(result1.messages));
		System.assertEquals(1, result1.messages.size());
		System.assertEquals('fail', result1.messages[0].description);
		System.assertEquals(null, result1.recipients);
		System.assertEquals(null, result1.removedIds);

		System.assertNotEquals(null, result2);
		System.assert(!result2.success);
		System.assert(!Collection.isEmpty(result2.messages));
		System.assertEquals(2, result2.messages.size());
		System.assertEquals('fail1', result2.messages[0].description);
		System.assertEquals('fail2', result2.messages[1].description);
		System.assertEquals(null, result2.recipients);
		System.assertEquals(null, result2.removedIds);
	}
}
