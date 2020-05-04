@IsTest
private class MergeServiceTest {

	@IsTest
	static void test_Database_querySObject_invalid_args() {
		Id id = UserInfo.getUserId();
		List<String> fields = new List<String> { 'FirstName', 'LastName', 'Email' };

		Test.startTest();
		System.assertEquals(null, MergeService.DB.querySObject(null, fields));
		System.assertEquals(null, MergeService.DB.querySObject(id, null));
		System.assertEquals(null, MergeService.DB.querySObject(id, new List<String>()));
		Test.stopTest();
	}

	@IsTest
	static void test_Database_querySObject_invalid_fields() {
		Id id = UserInfo.getUserId();
		List<String> fields = new List<String> { 'InvalidField' };

		Test.startTest();
		try {
			MergeService.DB.querySObject(id, fields);
			throw new AssertException('Expected failure');
		} catch (QueryException ex) {
			System.assertNotEquals(null, ex);
		}
		Test.stopTest();
	}

	@IsTest
	static void test_Database_querySObject_unauthorized() {
		Id id;
		System.runAs(UserMock.createDocuSignUser()) {
			id = TestUtils.createEnvelope().Id;
		}

		System.runAs(UserMock.createRestrictedUser()) {
			List<String> fields = new List<String> { 'Name', 'dsfs__DocuSign_Email_Subject__c' };

			Test.startTest();
			try {
				MergeService.DB.querySObject(id, fields);
				throw new AssertException('Expected failure');
			} catch (QueryException ex) {
				System.assertNotEquals(null, ex);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_Database_querySObject_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			List<String> fields = new List<String> { 'Name', 'CloseDate', 'Account.Name' };

			Test.startTest();
			SObject result = MergeService.DB.querySObject(o.Id, fields);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result instanceof Opportunity);
			System.assertEquals(o.Id, result.Id);
			System.assertEquals(o.Name, result.get('Name'));
			System.assertEquals(o.CloseDate, result.get('CloseDate'));
			SObject oa = result.getSObject('Account');
			System.assertNotEquals(null, oa);
			System.assertEquals(a.Name, oa.get('Name'));
		}
	}

	@IsTest
	static void test_parseMergeFields_no_match() {
		Map<String, Map<String, String>> mergeFields = new Map<String, Map<String, String>> {
			'Opportunity' => new Map<String, String> {
				'Name' => '{!Opportunity.Name}',
				'CloseDate' => '{!Opportunity.CloseDate}',
				'Account.Name' => '{!Opportunity.Account.Name}'
			},
			'Object1__c' => new Map<String, String> {
				'Name' => '{!Object1__c.Name}',
				'Field1__c' => '{!Object1__c.Field1__c}',
				'Field2__c' => '{!Object1__c.Field2__c}'
			},
			'$User' => new Map<String, String> {
				'FirstName' => '{!$User.FirstName}',
				'LastName' => '{!$User.LastName}',
				'Email' => '{!$User.Email}'
			},
			'$Organization' => new Map<String, String> {
				'Name' => '{!$Organization.Name}',
				'Phone' => '{!$Organization.Phone}'
			}
		};

		Test.startTest();
		Map<String, Map<String, String>> result1 = MergeService.parseFields(null, null);
		Map<String, Map<String, String>> result2 = MergeService.parseFields(null, mergeFields);
		Map<String, Map<String, String>> result3 = MergeService.parseFields('No match', mergeFields);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isEmpty());
		System.assertEquals(mergeFields, result2);
		System.assertEquals(mergeFields, result3);
	}

	@IsTest
	static void test_parseFields_match() {
		String input = 'opportunity name = {!Opportunity.Name}, account name = {!Opportunity.Account.Name}, user name = {!$User.Name}, org name = {!$Organization.Name}';

		Test.startTest();
		Map<String, Map<String, String>> result = MergeService.parseFields(input, null);
		Test.stopTest();

		System.assertEquals(new Map<String, Map<String, String>> {
			'Opportunity' => new Map<String, String> {
				'Name' => '{!Opportunity.Name}',
				'Account.Name' => '{!Opportunity.Account.Name}'
			},
			'$User' => new Map<String, String> {
				'Name' => '{!$User.Name}'
			},
			'$Organization' => new Map<String, String> {
				'Name' => '{!$Organization.Name}'
			}
		}, result);
	}

	@IsTest
	static void test_valueOf_null() {
		Test.startTest();
		System.assertEquals('', MergeService.valueOf(null));
		Test.stopTest();
	}

	@IsTest
	static void test_valueOf_Date() {
		Date d = Date.today();

		Test.startTest();
		System.assertEquals(String.valueOf(d), MergeService.valueOf(d));
		Test.stopTest();
	}

	@IsTest
	static void test_valueOf_Datetime() {
		Datetime dt = Datetime.now();

		Test.startTest();
		System.assertEquals(String.valueOf(dt), MergeService.valueOf(dt));
		Test.stopTest();
	}

	@IsTest
	static void test_valueOf_default() {
		Decimal d = 220000.0;

		Test.startTest();
		System.assertEquals(String.valueOf(d), MergeService.valueOf(d));
		Test.stopTest();
	}

	@IsTest
	static void test_getValue_invalid_args() {
		Schema.Account a = TestUtils.createAccount();

		Test.startTest();
		System.assertEquals('', MergeService.getValue(null, null));
		System.assertEquals('', MergeService.getValue(a, null));
		System.assertEquals('', MergeService.getValue(a, '  '));
		Test.stopTest();
	}

	@IsTest
	static void test_getValue_not_found() {
		Schema.Account a = TestUtils.createAccount();

		Test.startTest();
		try {
			MergeService.getValue(a, UUID.randomUUID().toString());
			throw new AssertException('Expected failure');
		} catch (SObjectException ex) {
			System.assertNotEquals(null, ex);
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getValue_simple() {
		Schema.Account a = TestUtils.createAccount();

		Test.startTest();
		System.assertEquals(a.Name, MergeService.getValue(a, 'Name'));
		Test.stopTest();
	}

	@IsTest
	static void test_getValue_lookup() {
		Schema.Account a1 = TestUtils.createAccount();
		Schema.Account a2 = TestUtils.createAccount();
		a2.ParentId = a1.Id;
		update a2;
		Opportunity o = TestUtils.createOpportunity(a2.Id);
		o = [SELECT Account.Name, Account.Parent.Name FROM Opportunity WHERE Id = :o.Id];

		Test.startTest();
		System.assertEquals(a2.Name, MergeService.getValue(o, 'Account.Name'));
		System.assertEquals(a1.Name, MergeService.getValue(o, 'Account.Parent.Name'));
		Test.stopTest();
	}

	@IsTest
	static void test_resolveFields_invalid_args() {
		Id sourceId = UserInfo.getUserId();
		Map<String, Map<String, String>> mergeFields = new Map<String, Map<String, String>> {
			'Opportunity' => new Map<String, String> {
				'Name' => '{!Opportunity.Name}',
				'CloseDate' => '{!Opportunity.CloseDate}',
				'Account.Name' => '{!Opportunity.Account.Name}'
			},
			'Object1__c' => new Map<String, String> {
				'Name' => '{!Object1__c.Name}',
				'Field1__c' => '{!Object1__c.Field1__c}',
				'Field2__c' => '{!Object1__c.Field2__c}'
			},
			'$User' => new Map<String, String> {
				'FirstName' => '{!$User.FirstName}',
				'LastName' => '{!$User.LastName}',
				'Email' => '{!$User.Email}'
			},
			'$Organization' => new Map<String, String> {
				'Name' => '{!$Organization.Name}',
				'Phone' => '{!$Organization.Phone}'
			}
		};

		Test.startTest();
		System.assert(Collection.isEmpty(MergeService.resolveFields(null, mergeFields)));
		System.assert(Collection.isEmpty(MergeService.resolveFields(sourceId, null)));
		System.assert(Collection.isEmpty(MergeService.resolveFields(sourceId, new Map<String, Map<String, String>>())));
		Test.stopTest();
	}

	@IsTest
	static void test_resolveFields_success() {
		Opportunity o = TestUtils.createOpportunity();
		o.CloseDate = Date.today().addDays(30);
		update o;
		o = [SELECT Name, CloseDate, Account.Name FROM Opportunity WHERE Id = :o.Id LIMIT 1];
		Id sourceId = o.Id;
		Map<String, Map<String, String>> mergeFields = new Map<String, Map<String, String>> {
			'Opportunity' => new Map<String, String> {
				'Name' => '{!Opportunity.Name}',
				'CloseDate' => '{!Opportunity.CloseDate}',
				'Account.Name' => '{!Opportunity.Account.Name}'
			},
			'Object1__c' => new Map<String, String> {
				'Name' => '{!Object1__c.Name}',
				'Field1__c' => '{!Object1__c.Field1__c}',
				'Field2__c' => '{!Object1__c.Field2__c}'
			},
			'$User' => new Map<String, String> {
				'FirstName' => '{!$User.FirstName}',
				'LastName' => '{!$User.LastName}',
				'Email' => '{!$User.Email}'
			},
			'$Organization' => new Map<String, String> {
				'Name' => '{!$Organization.Name}',
				'Phone' => '{!$Organization.Phone}'
			},
			'$Recipient' => new Map<String, String> {
				'FirstName' => '{!$Recipient.FirstName}',
				'LastName' => '{!$Recipient.LastName}'
			}
		};

		Test.startTest();
		Map<String, String> result = MergeService.resolveFields(sourceId, mergeFields);
		Test.stopTest();

		Organization org = [SELECT Name, Phone FROM Organization LIMIT 1];
		System.assertEquals(new Map<String, String> {
			'{!Opportunity.Name}' => o.Name,
			'{!Opportunity.CloseDate}' => String.valueOf(o.CloseDate),
			'{!Opportunity.Account.Name}' => o.Account.Name,
			'{!Object1__c.Name}' => '',
			'{!Object1__c.Field1__c}' => '',
			'{!Object1__c.Field2__c}' => '',
			'{!$User.FirstName}' => UserInfo.getFirstName(),
			'{!$User.LastName}' => UserInfo.getLastName(),
			'{!$User.Email}' => UserInfo.getUserEmail(),
			'{!$Organization.Name}' => org.Name == null ? '' : org.Name,
			'{!$Organization.Phone}' => org.Phone == null ? '' : org.Phone,
			'{!$Recipient.FirstName}' => '',
			'{!$Recipient.LastName}' => ''
		}, result);
	}

	@IsTest
	static void test_mergeData_invalid_args() {
		Map<String, String> mergeFields = new Map<String, String> {
			'{!A}' => 'A',
			'{!B}' => 'B',
			'{!C}' => 'C'
		};

		Test.startTest();
		System.assertEquals(null, MergeService.mergeData(null, mergeFields, null));
		System.assertEquals('\t', MergeService.mergeData('\t', mergeFields, null));
		System.assertEquals('input', MergeService.mergeData('input', null, null));
		System.assertEquals('input', MergeService.mergeData('input', new Map<String, String>(), null));
		Test.stopTest();
	}

	@IsTest
	static void test_mergeData_no_match() {
		Map<String, String> mergeFields = new Map<String, String> {
			'{!A}' => 'A',
			'{!B}' => 'B',
			'{!C}' => 'C'
		};

		Test.startTest();
		System.assertEquals('input', MergeService.mergeData('input', mergeFields, null));
		Test.stopTest();
	}

	@IsTest
	static void test_mergeData_match() {
		String input = 'A = {!A.A}, B = {!B.B}, C = {!C.C}, D = {!D.D}, A = {!A.A}, B = {!B.B}';
		Map<String, String> mergeFields = new Map<String, String> {
			'{!A.A}' => 'A',
			'{!B.B}' => 'B',
			'{!C.C}' => 'C'
		};

		Test.startTest();
		System.assertEquals('A = A, B = B, C = C, D = , A = A, B = B', MergeService.mergeData(input, mergeFields, null));
		Test.stopTest();
	}

	@IsTest
	static void test_getRecipientValue() {
		Recipient r1 = Recipient.fromSource('  Unit\tTest  ', 'r1@unit.test', '11111111', 'r1', null);
		Recipient r2 = Recipient.fromSource('UnitTest', 'r2@unit.test', '22222222', null, null);

		Test.startTest();
		System.assertEquals('', MergeService.getRecipientValue('  ', r1));
		System.assertEquals('', MergeService.getRecipientValue('{!$Recipient.Name}', null));
		System.assertEquals('', MergeService.getRecipientValue('{!$Recipient.Whatever}', r1));
		System.assertEquals('Unit\tTest', MergeService.getRecipientValue('{!$Recipient.Name}', r1));
		System.assertEquals('Unit', MergeService.getRecipientValue('{!$Recipient.FirstName}', r1));
		System.assertEquals('Test', MergeService.getRecipientValue('{!$Recipient.LastName}', r1));
		System.assertEquals('r1@unit.test', MergeService.getRecipientValue('{!$Recipient.Email}', r1));
		System.assertEquals('11111111', MergeService.getRecipientValue('{!$Recipient.Phone}', r1));
		System.assertEquals('r1', MergeService.getRecipientValue('{!$Recipient.Role}', r1));
		System.assertEquals('UnitTest', MergeService.getRecipientValue('{!$Recipient.Name}', r2));
		System.assertEquals('UnitTest', MergeService.getRecipientValue('{!$Recipient.FirstName}', r2));
		System.assertEquals('UnitTest', MergeService.getRecipientValue('{!$Recipient.LastName}', r2));
		System.assertEquals('r2@unit.test', MergeService.getRecipientValue('{!$Recipient.Email}', r2));
		System.assertEquals('22222222', MergeService.getRecipientValue('{!$Recipient.Phone}', r2));
		System.assertEquals('', MergeService.getRecipientValue('{!$Recipient.Role}', r2));
		Test.stopTest();
	}

	@IsTest
	static void test_mergeData_recipient() {
		String input = 'A = {!A.A}, B = {!B.B}, Recipient.Name = {!$Recipient.Name}';
		Recipient r1 = Recipient.fromSource('Unit Test', 'r1@unit.test', '11111111', 'r1', null);
		Map<String, String> mergeFields = new Map<String, String> {
			'{!A.A}' => 'A',
			'{!$Recipient.Name}' => ''
		};

		Test.startTest();
		System.assertEquals('A = A, B = , Recipient.Name = Unit Test',
			MergeService.mergeData(input, mergeFields, r1));
		Test.stopTest();
	}
}
