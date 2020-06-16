@IsTest
public class XMLSerializerTest {

	@IsTest
	static void fromPrimitiveStringTest() {
		String email = 'Test@TestEmail.com';

		Test.startTest();

		String result = XMLSerializer.fromPrimitive(email, 'Email');

		Test.stopTest();

		System.assert(XMLSerializer.isValid(result));
		System.assert(result.startsWith('<'));
	}

	@IsTest
	static void fromPrimitiveIntegerTest() {
		Integer expirationDays = 3;

		Test.startTest();

		String result = XMLSerializer.fromPrimitive(expirationDays, 'ExpirationDays');

		Test.stopTest();

		System.assert(XMLSerializer.isValid(result));
		System.assert(result.startsWith('<'));
	}

	@IsTest
	static void fromPrimitiveDoubleTest() {
		Double cost = 19.99;

		Test.startTest();

		String result = XMLSerializer.fromPrimitive(cost, 'Cost');

		Test.stopTest();

		System.assert(XMLSerializer.isValid(result));
		System.assert(result.startsWith('<'));
	}

	@IsTest
	static void fromObjectTest() {
		Envelope.Options eos = new Envelope.Options(
			false,
			null,
			null,
			null);

		Test.startTest();
		String result = XMLSerializer.fromObject(
			new Set<String> { 'includeDefaultAutoPlaceTags', 'documentWriteBack', 'envelopeEventUpdates', 'recipientEventUpdates' },
			eos, 'Envelope.Options', false);
		Test.stopTest();

		System.assert(XMLSerializer.isValid(result));
		System.assert(result.startsWith('<'));
	}

	@IsTest
	static void fromIterableUUIDTest() {
		List<UUID> ids = new List<UUID> { UUID.parse('382bd222-1536-e911-9c1d-3ca82a1e3f41'), UUID.parse('382bd222-1536-e911-9c1d-3ca82a1e3f42'), UUID.parse('382bd222-1536-e911-9c1d-3ca82a1e3f45') };

		Test.startTest();
		String result = XMLSerializer.fromIterable(new Set<String> { 'Value' }, ids, 'Documents', 'Document', false);
		Test.stopTest();

		System.assert(XMLSerializer.isValid(result));
		System.assert(result.startsWith('<'));
	}
}
