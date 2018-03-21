@IsTest
private class QueryStringTest {

	static final Map<String, String> params = new Map<String, String> {
		'booleanTrue' => 'true',
		'booleanFalse' => 'false',
		'boolean0' => '0',
		'boolean1' => '1',
		'booleanNull' => null,
		'booleanEmpty' => '',
		'booleanWhitespace' => ' ',
		'booleanInvalid' => 'notABoolean',
		'integerMin' => '-2147483647',
		'integerNeg1' => '-1',
		'integer0' => '0',
		'integer1' => '1',
		'integerMax' => '2147483647',
		'integerNull' => null,
		'integerEmpty' => '',
		'integerWhitespace' => '\n',
		'integerInvalid' => 'notAnInteger',
		'id0' => '000000000000000000',
		'idNull' => null,
		'idEmpty' => '',
		'idWhitespace' => '\t',
		'idInvalid' => 'notAnId',
		'stringABCD' => 'abcd',
		'stringNull' => null,
		'stringEmpty' => '',
		'stringWhitespace' => '\r ',
		'stringEscapedWhitespace' => 'start\\r\\n\\t\\b\\fend',
		'uuid0' => '00000000-0000-0000-0000-000000000000',
		'uuidNull' => null,
		'uuidEmpty' => '',
		'uuidWhitespace' => ' \f',
		'uuidInvalid' => 'notAUuid'
	};

	static final Map<String, String> params2 = new Map<String, String> {
		'notBlank' => 'someValue',
		'nonEncodedKey' => '<encoded%value>',
		'encoded &key' => 'nonEncodedValue',
		'null' => null,
		'empty' => '',
		'whitespace' => '\f'
	};

	static testMethod void test_constructor() {
		final QueryString qs = new QueryString(params);
		final Set<String> validKeys = new Set<String>();
		for (String k : params.keySet()) {
			String v = params.get(k);
			if (String.isNotBlank(v)) {
				validKeys.add(k);
			}
		}
		final Set<String> keys = new Set<String> { 'test' };

		System.assertEquals(validKeys, qs.Keys);
		System.assertEquals(new QueryString(new Map<String, String>()), QueryString.empty);
		System.assertEquals(new QueryString(null), QueryString.empty);
		final QueryString qs2 = new QueryString('test', 'value');
		System.assertEquals(keys, qs2.keys);
		System.assertEquals('value', qs2.get('test'));
	}

	static testMethod void test_equality() {
		final QueryString qs = new QueryString(params);

		System.assertEquals(qs, qs);
		System.assertEquals(new QueryString(params).hashCode(), new QueryString(params).hashCode());
		System.assertEquals(new QueryString(params), new QueryString(params));
		System.assertNotEquals(QueryString.empty, new QueryString(params));
	}

	static testMethod void test_toString() {
		System.assertEquals('notBlank=someValue&nonEncodedKey=%3Cencoded%25value%3E&encoded+%26key=nonEncodedValue',
			new QueryString(params2).toString());
		System.assertEquals('', QueryString.empty.toString());
	}

	static testMethod void test_isEmpty() {
		System.assert(QueryString.empty.isEmpty());
		System.assert(new QueryString(null).isEmpty());
		System.assert(new QueryString(new Map<String, String>()).isEmpty());
	}

	static testMethod void test_fromCurrentPage() {
		System.assertEquals(QueryString.empty, QueryString.fromCurrentPage());

		PageReference p1 = new PageReference('/apex/UnitTest');
		p1.getParameters().put('param1', 'one');
		p1.getParameters().put('param2', 'two');
		PageReference p2 = new PageReference('/apex/UnitTest');
		Test.setCurrentPage(p1);

		System.assertEquals(new QueryString(new Map<String, String> { 'param1' => 'one', 'param2' => 'two' }), QueryString.fromCurrentPage());
		Test.setCurrentPage(p2);
		System.assertEquals(QueryString.empty, QueryString.fromCurrentPage());
	}

	static testMethod void test_fromString() {
		System.assertEquals(QueryString.empty, QueryString.fromString(null));
		System.assertEquals(QueryString.empty, QueryString.fromString(''));
		System.assertEquals(QueryString.empty, QueryString.fromString('\t\n'));
		final QueryString qs1 = new QueryString(new Map<String, String> {
			'key1' => 'value1'
		});
		System.assertEquals(qs1, QueryString.fromString(qs1.toString()));
		final QueryString qs2 = new QueryString(new Map<String, String> {
			'key1' => 'value1',
			'key2' => 'value2'
		});
		System.assertEquals(qs2, QueryString.fromString(qs2.toString()));
	}

	static testMethod void test_get() {
		final QueryString qs = new QueryString(params);

		System.assertEquals('abcd', qs.get('stringABCD'));
		System.assertEquals(null, qs.get('missingKey'));
		System.assertEquals(null, qs.get(''));
		System.assertEquals(null, qs.get(' \r\n'));
		System.assertEquals(null, qs.get(null));
	}

	static testMethod void test_getBoolean() {
		final QueryString qs = new QueryString(params);

		System.assertEquals(true, qs.getBoolean('booleanTrue'));
		System.assertEquals(false, qs.getBoolean('booleanFalse'));
		System.assertEquals(true, qs.getBoolean('boolean1'));
		System.assertEquals(false, qs.getBoolean('boolean0'));
		System.assertEquals(true, qs.getBoolean('boolean1', false));
		System.assertEquals(true, qs.getBoolean('booleanMissing', true));
		System.assertEquals(true, qs.getBoolean('booleanInvalid', true));
		System.assertEquals(true, qs.getBoolean(null, true));
		System.assertEquals(false, qs.getBoolean('', false));
		System.assertEquals(false, qs.getBoolean('\t', false));
		String key;
		try {
			key = null;
			qs.getBoolean(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'booleanMissing';
			qs.getBoolean(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'booleanNull';
			qs.getBoolean(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'booleanEmpty';
			qs.getBoolean(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'booleanWhitespace';
			qs.getBoolean(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'booleanInvalid';
			qs.getBoolean(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
	}

	static testMethod void test_getId() {
		final QueryString qs = new QueryString(params);

		System.assertEquals('000000000000000000', qs.getId('id0'));
		System.assertEquals('000000000000000000', qs.getId('id0', Id.valueOf('a0041000007UKaTAAW')));
		System.assertEquals('a0041000007UKaTAAW', qs.getId('idMissing', Id.valueOf('a0041000007UKaTAAW')));
		System.assertEquals('a0041000007UKaTAAW', qs.getId('idInvalid', Id.valueOf('a0041000007UKaTAAW')));
		System.assertEquals('a0041000007UKaTAAW', qs.getId(null, Id.valueOf('a0041000007UKaTAAW')));
		System.assertEquals('a0041000007UKaTAAW', qs.getId('', Id.valueOf('a0041000007UKaTAAW')));
		System.assertEquals('a0041000007UKaTAAW', qs.getId('\t', Id.valueOf('a0041000007UKaTAAW')));
		String key;
		try {
			key = null;
			qs.getId(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'idMissing';
			qs.getId(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'idNull';
			qs.getId(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'idEmpty';
			qs.getId(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'idWhitespace';
			qs.getId(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'idInvalid';
			qs.getId(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
	}

	static testMethod void test_getInteger() {
		final QueryString qs = new QueryString(params);

		System.assertEquals(-2147483647, qs.getInteger('integerMin'));
		System.assertEquals(-1, qs.getInteger('integerNeg1'));
		System.assertEquals(0, qs.getInteger('integer0'));
		System.assertEquals(1, qs.getInteger('integer1'));
		System.assertEquals(2147483647, qs.getInteger('integerMax'));
		System.assertEquals(1, qs.getInteger('integer1', 9999));
		System.assertEquals(9999, qs.getInteger('integerMissing', 9999));
		System.assertEquals(9999, qs.getInteger('integerInvalid', 9999));
		System.assertEquals(9999, qs.getInteger(null, 9999));
		System.assertEquals(9999, qs.getInteger('', 9999));
		System.assertEquals(9999, qs.getInteger('\t', 9999));
		String key;
		try {
			key = null;
			qs.getInteger(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'integerMissing';
			qs.getInteger(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'integerNull';
			qs.getInteger(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'integerEmpty';
			qs.getInteger(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'integerWhitespace';
			qs.getInteger(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'integerInvalid';
			qs.getInteger(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
	}

	static testMethod void test_getString() {
		final QueryString qs = new QueryString(params);

		System.assertEquals('abcd', qs.getString('stringABCD'));
		System.assertEquals('start\r\n\t\b\fend', qs.getString('stringEscapedWhitespace'));
		System.assertEquals('abcd', qs.getString('stringABCD', 'wxyz'));
		System.assertEquals('wxyz', qs.getString('stringMissing', 'wxyz'));
		System.assertEquals('wxyz', qs.getString(null, 'wxyz'));
		System.assertEquals('wxyz', qs.getString('', 'wxyz'));
		System.assertEquals('wxyz', qs.getString('\t', 'wxyz'));
		String key;
		try {
			key = null;
			qs.getString(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'stringMissing';
			qs.getString(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'stringNull';
			qs.getString(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'stringEmpty';
			qs.getString(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'stringWhitespace';
			qs.getString(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
	}

	static testMethod void test_getUUID() {
		final UUID uuid0 = UUID.fromString('00000000-0000-0000-0000-000000000000');
		final UUID uuid1 = UUID.fromString('11111111-1111-1111-1111-111111111111');
		final QueryString qs = new QueryString(params);

		System.assertEquals(uuid0, qs.getUUID('uuid0'));
		System.assertEquals(uuid0, qs.getUUID('uuid0', uuid1));
		System.assertEquals(uuid1, qs.getUUID('uuidMissing', uuid1));
		System.assertEquals(uuid1, qs.getUUID('uuidInvalid', uuid1));
		System.assertEquals(uuid1, qs.getUUID(null, uuid1));
		System.assertEquals(uuid1, qs.getUUID('', uuid1));
		System.assertEquals(uuid1, qs.getUUID('\t', uuid1));
		String key;
		try {
			key = null;
			qs.getUUID(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'uuidMissing';
			qs.getUUID(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'uuidNull';
			qs.getUUID(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'uuidEmpty';
			qs.getUUID(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'uuidWhitespace';
			qs.getUUID(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
		try {
			key = 'uuidInvalid';
			qs.getUUID(key);
			throw new AssertException('Expected failure for key \'' + key + '\'');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidUrlParameter, ex.getMessage());
		}
	}

	static testMethod void test_copyTo() {
		final Map<String, String> paramsEmpty = new Map<String, String>();
		final Map<String, String> paramsSome = new Map<String, String> { 'param1' => 'one', 'param2' => 'two' };
		final Map<String, String> params2Copy = new Map<String, String>(params2);
		final Map<String, String> paramsNull = null;
		final QueryString qs = new QueryString(params2);

		qs.copyTo(paramsEmpty);
		System.assertEquals(qs, new QueryString(params2));

		params2Copy.putAll(paramsSome);
		qs.copyTo(paramsSome);
		System.assertEquals(new QueryString(params2Copy), new QueryString(paramsSome));

		qs.copyTo(paramsNull);
		System.assertEquals(QueryString.empty, new QueryString(paramsNull));
	}

	static testMethod void test_taggerParameters() {
		final Id eId = 'a07d0000018Lf9gAAC';
		final Id sId = 'a0Od000000bk6A0';
		final UUID envelopeId = UUID.fromString('78e5dfd5-aee7-4ba9-b849-4cd892dfe364');

		Test.setCurrentPage(new PageReference(Application.namespacePrefix + 'docusign_tagenvelope?eId=' + eId + '&sId='
			+ sId + '&envelopeId=' + envelopeId + '&nw'));
		final QueryString qs = QueryString.fromCurrentPage();

		System.assertEquals(eId, qs.getId('eId'));
		System.assertEquals(sId, qs.getId('sId'));
		System.assertEquals(envelopeId, qs.getUUID('envelopeId'));
		System.assertEquals(false, qs.getBoolean('nw', false));
	}

	static testMethod void test_isDefined() {
		QueryString qs = new QueryString(params);

		System.assert(qs.isDefined('booleanTrue'));
		System.assert(qs.isDefined('booleanFalse'));
		System.assert(qs.isDefined('boolean0'));
		System.assert(qs.isDefined('boolean1'));
		System.assert(qs.isDefined('booleanInvalid'));
		System.assert(!qs.isDefined('booleanNull'));
		System.assert(!qs.isDefined('booleanEmpty'));
		System.assert(!qs.isDefined('booleanWhitespace'));
		System.assert(!qs.isDefined(null));
		System.assert(!qs.isDefined(''));
		System.assert(!qs.isDefined('\n  '));
		System.assert(!qs.isDefined('invalid-key'));
	}
}
