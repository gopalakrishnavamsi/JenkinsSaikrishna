@IsTest(IsParallel = true)
private class StringUtilsTest {

	@IsTest
	static void test_encode() {
		System.assertEquals('test', StringUtils.encode('test'));
		System.assertEquals('%3Funit%2Ftest+path%3A', StringUtils.encode('?unit/test path:'));
		System.assertEquals('', StringUtils.encode(null));
		System.assertEquals('', StringUtils.encode(''));
		System.assertEquals('', StringUtils.encode(' \n'));
	}

	@IsTest
	static void test_decode() {
		System.assertEquals('test', StringUtils.decode('test'));
		System.assertEquals('?unit/test path:', StringUtils.decode('%3Funit%2Ftest+path%3A'));
		System.assertEquals('', StringUtils.decode(null));
		System.assertEquals('', StringUtils.decode(''));
		System.assertEquals('', StringUtils.decode(' \n'));
	}

	@IsTest
	static void test_parseBoolean() {
		System.assert(StringUtils.parseBoolean('true'));
		System.assert(!StringUtils.parseBoolean('false'));
		System.assert(!StringUtils.parseBoolean(null));
		System.assert(!StringUtils.parseBoolean(''));
		System.assert(!StringUtils.parseBoolean(' \n '));
		System.assert(!StringUtils.parseBoolean('whatever'));
		System.assert(StringUtils.parseBoolean('1'));
		System.assert(!StringUtils.parseBoolean('0'));
		System.assert(StringUtils.parseBoolean(null, true));
		System.assert(StringUtils.parseBoolean(' ', true));
		System.assert(StringUtils.parseBoolean('true', false));
		System.assert(!StringUtils.parseBoolean('\n', false));
	}

	@IsTest
	static void test_parseDecimal() {
		System.assertEquals(1.99, StringUtils.parseDecimal('1.99'));
		System.assertEquals(0, StringUtils.parseDecimal('0'));
		System.assertEquals(-1.99, StringUtils.parseDecimal('-1.99'));
		System.assertEquals(null, StringUtils.parseDecimal(null));
		System.assertEquals(null, StringUtils.parseDecimal(''));
		System.assertEquals(null, StringUtils.parseDecimal('whatever'));
	}

	@IsTest
	static void test_parseInteger() {
		System.assertEquals(1, StringUtils.parseInteger('1'));
		System.assertEquals(0, StringUtils.parseInteger('0'));
		System.assertEquals(-1, StringUtils.parseInteger('-1'));
		System.assertEquals(null, StringUtils.parseInteger(null));
		System.assertEquals(null, StringUtils.parseInteger(''));
		System.assertEquals(null, StringUtils.parseInteger('whatever'));
		System.assertEquals(1, StringUtils.parseInteger('1', 2));
		System.assertEquals(2, StringUtils.parseInteger(null, 2));
		System.assertEquals(2, StringUtils.parseInteger('not-an-integer', 2));
	}

	@IsTest
	static void test_fromString() {
		System.assertEquals(null, StringUtils.fromString(null));
		System.assertEquals(null, StringUtils.fromString(''));
		System.assertEquals(null, StringUtils.fromString('\r'));
		System.assertEquals(null, StringUtils.fromString(Label.UndefinedString));
		System.assertEquals('test', StringUtils.fromString('test'));
	}

	@IsTest
	static void test_parseDatetime() {
		System.assertEquals(
			Datetime.newInstanceGmt(2017, 6, 17, 10, 59, 34),
			StringUtils.parseDatetime('2017-06-17T10:59:34.823Z'));
		System.assertEquals(
			Datetime.newInstanceGmt(2017, 6, 17, 10, 59, 34),
			StringUtils.parseDatetime('2017-06-17T10:59:34Z'));
		System.assertEquals(
			Datetime.newInstanceGmt(2017, 6, 17, 10, 59, 34),
			StringUtils.parseDatetime('2017-06-17T10:59:34'));
		System.assertEquals(
			Datetime.newInstanceGmt(2017, 6, 17),
			StringUtils.parseDatetime('2017-06-17'));
		System.assertEquals(
			null,
			StringUtils.parseDatetime(null));
		System.assertEquals(
			null,
			StringUtils.parseDatetime(''));
		try {
			StringUtils.parseDatetime('Garbage');
			throw new AssertException('Expected exception to be thrown for invalid input');
		} catch (JSONException ex) {
			// OK
		}
		try {
			StringUtils.parseDatetime('1234567890');
			throw new AssertException('Expected exception to be thrown for invalid input');
		} catch (JSONException ex) {
			// OK
		}
	}

	@IsTest
	static void test_parseDate() {
		System.assertEquals(
			Date.newInstance(2017, 6, 17),
			StringUtils.parseDate('2017-06-17T10:59:34.823Z'));
		System.assertEquals(
			null,
			StringUtils.parseDate(null));
		System.assertEquals(
			null,
			StringUtils.parseDate(''));
		try {
			StringUtils.parseDate('Garbage');
			throw new AssertException('Expected exception to be thrown for invalid input');
		} catch (JSONException ex) {
			// OK
		}
		try {
			StringUtils.parseDate('1234567890');
			throw new AssertException('Expected exception to be thrown for invalid input');
		} catch (JSONException ex) {
			// OK
		}
	}

	@IsTest
	static void test_isValidEmail() {
		String email1 = 'abc.EFG@gmail.com';
		System.assertEquals(true, StringUtils.isValidEmail(email1));

		String email2 = 'abcdefg@@gmail.com';
		System.assertEquals(false, StringUtils.isValidEmail(email2));

		String email3 = 'abc+efg@gmail.com';
		System.assertEquals(true, StringUtils.isValidEmail(email3));

		String email4 = 'abc\'efg@gmail.com';
		System.assertEquals(true, StringUtils.isValidEmail(email4));

		String email5 = 'abc efg@gmail.com';
		System.assertEquals(false, StringUtils.isValidEmail(email5));

		String email6 = 'abcefg@gmail';
		System.assertEquals(false, StringUtils.isValidEmail(email6));

		String email7 = ' abcefg@gmail.com';
		System.assertEquals(true, StringUtils.isValidEmail(email7));

		String email8 = 'abcefg@gmail.com\t';
		System.assertEquals(true, StringUtils.isValidEmail(email8));

		System.assert(!StringUtils.isValidEmail(null));
		System.assert(!StringUtils.isValidEmail(''));
		System.assert(!StringUtils.isValidEmail('\r\n '));
	}

	@IsTest
	static void test_mkName() {
		Test.startTest();
		String n1 = StringUtils.mkName(null, ' ');
		String n2 = StringUtils.mkName('', 'Last ');
		String n3 = StringUtils.mkName('\tFirst ', ' Last\n');
		Test.stopTest();

		System.assertEquals('', n1);
		System.assertEquals('Last', n2);
		System.assertEquals('First Last', n3);
	}

	@IsTest
	static void test_replaceUserTags() {
		Test.startTest();
		System.assertEquals(null, StringUtils.replaceUserTags(null));
		System.assertEquals('', StringUtils.replaceUserTags(''));
		System.assertEquals('   ', StringUtils.replaceUserTags('   '));
		System.assertEquals('Replaced ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), StringUtils.replaceUserTags('Replaced [FirstName] [LastName]'));
		System.assertEquals(UserInfo.getUserEmail(), StringUtils.replaceUserTags('[Email]'));
		Test.stopTest();
	}

	@IsTest
	static void test_replaceNoteTags() {
		Test.startTest();
		System.assertEquals(',', StringUtils.replaceNoteTags('_COMMA_'));
		System.assertEquals(';', StringUtils.replaceNoteTags('_SEMI_'));
		System.assertEquals('~', StringUtils.replaceNoteTags('_TILDE_'));
		System.assertEquals('\n', StringUtils.replaceNoteTags('\\n'));
		System.assertEquals('COMMA: ,\nSEMICOLON: ;\nTILDE: ~', StringUtils.replaceNoteTags('COMMA: _COMMA_\\nSEMICOLON: _SEMI_\\nTILDE: _TILDE_'));
		System.assertEquals(null, StringUtils.replaceNoteTags(null));
		System.assertEquals(null, StringUtils.replaceNoteTags(''));
		System.assertEquals(null, StringUtils.replaceNoteTags('\t '));
		Test.stopTest();
	}

	@IsTest
	static void test_formatDatetime() {
		Test.startTest();
		System.assertEquals(null, StringUtils.formatDatetime(null));
		Datetime dt = Datetime.now();
		System.assertEquals(dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''), StringUtils.formatDatetime(dt));
		Test.stopTest();
	}
}