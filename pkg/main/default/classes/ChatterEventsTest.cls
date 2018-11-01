@IsTest(isParallel = true)
private class ChatterEventsTest {

	@IsTest
	static void test_pack() {
		Test.startTest();
		System.assertEquals(788, ChatterEvents.pack(new ChatterEvents(false, false, true, false, true, false, false, false, true, true)));
		Test.stopTest();
	}

	@IsTest
	static void test_unpack() {
		Test.startTest();
		ChatterEvents result = ChatterEvents.unpack(788);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.postEnvelopeSent);
		System.assert(!result.postEnvelopeDelivered);
		System.assert(result.postEnvelopeCompleted);
		System.assert(!result.postEnvelopeDeclined);
		System.assert(result.postEnvelopeVoided);
		System.assert(!result.postRecipientSent);
		System.assert(!result.postRecipientDelivered);
		System.assert(!result.postRecipientCompleted);
		System.assert(result.postRecipientSigned);
		System.assert(result.postRecipientDeclined);
	}

	@IsTest
	static void test_getInstance() {
		Test.startTest();
		ChatterEvents result1 = ChatterEvents.getInstance();
		ChatterEvents result2 = ChatterEvents.getInstance();
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1 === result2);
	}

	@IsTest
	static void test_save() {
		ChatterEvents events = new ChatterEvents(false, false, true, false, true, false, false, false, true, true);

		Test.startTest();
		ChatterEvents result = ChatterEvents.save(events);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!(result === events));
		System.assertEquals(events.postEnvelopeSent, result.postEnvelopeSent);
		System.assertEquals(events.postEnvelopeDelivered, result.postEnvelopeDelivered);
		System.assertEquals(events.postEnvelopeCompleted, result.postEnvelopeCompleted);
		System.assertEquals(events.postEnvelopeDeclined, result.postEnvelopeDeclined);
		System.assertEquals(events.postEnvelopeVoided, result.postEnvelopeVoided);
		System.assertEquals(events.postRecipientSent, result.postRecipientSent);
		System.assertEquals(events.postRecipientDelivered, result.postRecipientDelivered);
		System.assertEquals(events.postRecipientCompleted, result.postRecipientCompleted);
		System.assertEquals(events.postRecipientSigned, result.postRecipientSigned);
		System.assertEquals(events.postRecipientDeclined, result.postRecipientDeclined);
	}
}