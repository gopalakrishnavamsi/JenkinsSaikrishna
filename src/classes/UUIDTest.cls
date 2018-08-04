@IsTest(isParallel = true)
private class UUIDTest {

	static testmethod void test_randomUUID() {
		UUID u1, u2, u3;

		Test.startTest();
		u1 = UUID.randomUUID();
		u2 = UUID.randomUUID();
		u3 = UUID.randomUUID();
		Test.stopTest();

		System.assert(String.isNotBlank(u1.toString())
			&& String.isNotBlank(u1.toShortString()));
		System.assertEquals(u1.toString().replace('-', ''), u1.toShortString());
		System.assert(String.isNotBlank(u2.toString())
			&& String.isNotBlank(u2.toShortString()));
		System.assertEquals(u2.toString().replace('-', ''), u2.toShortString());
		System.assert(String.isNotBlank(u3.toString())
			&& String.isNotBlank(u3.toShortString()));
		System.assertEquals(u3.toString().replace('-', ''), u3.toShortString());

		System.assertNotEquals(u1.toString(), u2.toString());
		System.assertNotEquals(u1.toString(), u3.toString());
		System.assertNotEquals(u2.toString(), u3.toString());
	}

	static testmethod void test_fromString() {
		// Valid canonical UUIDs
		String s1 = '01234567-89AB-CDEF-0123-456789ABCDEF';
		String s2 = '01234567-89ab-cdef-0123-456789abcdef';
		String s3 = '01234567-89Ab-CdEf-0123-456789AbCdEf';
		UUID u1, u2, u3;

		// Invalid canonical UUIDs
		String s4 = '0123456789abcdef0123456789abcdef';
		String s5 = 'uuid';
		String s6 = null;
		String s7 = '';
		String s8 = ' \n';
		Boolean r4, r5, r6, r7, r8 = false;

		Test.startTest();
		u1 = UUID.parse(s1);
		u2 = UUID.parse(s2);
		u3 = UUID.parse(s3);

		try {
			UUID.parse(s4);
		} catch (StringException ex) {
			if (ex.getMessage().equals(Label.InvalidUUID)) r4 = true;
		}

		try {
			UUID.parse(s5);
		} catch (StringException ex) {
			if (ex.getMessage().equals(Label.InvalidUUID)) r5 = true;
		}

		try {
			UUID.parse(s6);
		} catch (StringException ex) {
			if (ex.getMessage().equals(Label.InvalidUUID)) r6 = true;
		}

		try {
			UUID.parse(s7);
		} catch (StringException ex) {
			if (ex.getMessage().equals(Label.InvalidUUID)) r7 = true;
		}

		try {
			UUID.parse(s8);
		} catch (StringException ex) {
			if (ex.getMessage().equals(Label.InvalidUUID)) r8 = true;
		}

		Test.stopTest();

		System.assertEquals(s1.toLowerCase(), u1.toString());
		System.assertEquals(s2.toLowerCase(), u2.toString());
		System.assertEquals(s3.toLowerCase(), u3.toString());
		System.assert(r4, 'String should be invalid UUID: ' + s4);
		System.assert(r5, 'String should be invalid UUID: ' + s5);
		System.assert(r6, 'String should be invalid UUID: ' + s6);
		System.assert(r7, 'String should be invalid UUID: ' + s7);
		System.assert(r8, 'String should be invalid UUID: ' + s8);
	}

	static testmethod void test_equality() {
		UUID u1 = UUID.parse('01234567-89ab-cdef-0123-456789abcdef');
		UUID u2 = UUID.parse('01234567-89ab-cdef-0123-456789abcdef');
		UUID u3 = UUID.parse('fedcba98-7654-3210-fedc-ba9876543210');

		System.assertEquals(u1, u2);
		System.assertEquals(u1.hashCode(), u2.hashCode());
		System.assertNotEquals(u1, u3);
		System.assertNotEquals(u1.hashCode(), u3.hashCode());
	}

	static testmethod void test_tryParse() {
		System.assertEquals(null, UUID.tryParse(null));
		System.assertEquals(null, UUID.tryParse(''));
		System.assertEquals(null, UUID.tryParse('  \n\t'));
		System.assertEquals(null, UUID.tryParse('not-a-uuid'));
		System.assertEquals(UUID.parse('01234567-89ab-CDEF-0123-456789abcdef'),
			UUID.tryParse('01234567-89ab-cdef-0123-456789ABcdef'));
	}

	static testmethod void test_toString() {
		String s = '01234567-89ab-cdef-0123-456789abcdef';
		UUID u1 = UUID.parse(s);
		UUID u2 = UUID.parse(s.toUpperCase());

		System.assertEquals(u1.toString(), s);
		System.assertEquals(u1.toString(), u1.toString());
		System.assertEquals(u2.toString(), s);
		System.assertEquals(u2.toString(), u2.toString());

		System.assertEquals(u1.toString(), UUID.toString(u1));
		System.assertEquals('', UUID.toString((UUID)null));
	}

	@IsTest
	static void test_isDefined() {
		System.assert(UUID.isDefined(UUID.randomUUID()));
		System.assert(!UUID.isDefined(null));
		System.assert(!UUID.isDefined((UUID)JSON.deserialize('{"value":""}', UUID.class)));
		System.assert(!UUID.isDefined((UUID)JSON.deserialize('{"value":null}', UUID.class)));
		System.assert(!UUID.isDefined((UUID)JSON.deserialize('{"value":"  "}', UUID.class)));
		System.assert(UUID.isDefined((UUID)JSON.deserialize('{"value":"11111111-1111-1111-1111-111111111111"}', UUID.class)));
	}
}
