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

	@IsTest
	static void test_buildRelationships_undefined_arguments() {
		SObjectType type = Contact.getSObjectType();
		Set<String> paths = new Set<String> { 'Contact.FirstName' };

		Test.startTest();
		System.assert(Collection.isEmpty(MergeService.buildRelationships(null, paths)));
		System.assert(Collection.isEmpty(MergeService.buildRelationships(type, null)));
		System.assert(Collection.isEmpty(MergeService.buildRelationships(type, new Set<String>())));
		Test.stopTest();
	}

	@IsTest
	static void test_buildRelationships_unauthorized() {
		System.runAs(UserMock.createUser()) {
			SObjectType type = Envelope__c.getSObjectType();
			Set<String> paths = new Set<String> {
				Application.namespacePrefix + 'Envelope__c.'
					+ Application.namespacePrefix + 'Documents__r.'
					+ Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'Envelope__c.'
					+ Application.namespacePrefix + 'Sent__c',
				Application.namespacePrefix + 'Envelope__c.'
					+ 'CreatedBy.'
					+ Application.namespacePrefix + 'Name',
				Application.namespacePrefix + 'Recipient__c.'
					+ Application.namespacePrefix + 'Note__c'
			};

			Test.startTest();
			try {
				MergeService.buildRelationships(type, paths);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(UnauthorizedException.AccessRequirement.SecurityPermission, ex.requirement);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_buildRelationships_success() {
		SObjectType type = Schema.Account.getSObjectType();
		Set<String> paths = new Set<String> {
			'account.name',
			'account.annualrevenue',
			'account.createdby.email',
			'account.cases.isescalated',
			'account.cases.casecontactroles.role',
			'account.cases.casecontactroles.contact.email'
		};

		Test.startTest();
		Map<String, DataModel.Relationship> result = MergeService.buildRelationships(type, paths);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<String> {
			'account.createdby', 'account.cases', 'account.cases.casecontactroles',
			'account.cases.casecontactroles.contact'
		}, result.keySet());

		DataModel.Relationship r = result.get('account.createdby');
		System.assertNotEquals(null, r);
		System.assert(r instanceof DataModel.LookupRelationship);
		System.assertEquals(null, r.parent);

		r = result.get('account.cases');
		System.assertNotEquals(null, r);
		System.assert(r instanceof DataModel.ChildRelationship);
		System.assertEquals(null, r.parent);

		r = result.get('account.cases.casecontactroles');
		System.assertNotEquals(null, r);
		System.assert(r instanceof DataModel.ChildRelationship);
		System.assertEquals(result.get('account.cases'), r.parent);

		r = result.get('account.cases.casecontactroles.contact');
		System.assertNotEquals(null, r);
		System.assert(r instanceof DataModel.LookupRelationship);
		System.assertEquals(result.get('account.cases.casecontactroles'), r.parent);
	}

	@IsTest
	static void test_findParentQuery_undefined_arguments() {
		DataModel.Relationship parent = new DataModel.ChildRelationship(
			'b',
			'a.b',
			1,
			User.getSObjectType(),
			null,
			User.getSObjectType().getDescribe().fields.getMap().get('CreatedById'));
		DataModel.Relationship relationship = new DataModel.LookupRelationship(
			'c',
			'a.b.c',
			2,
			User.getSObjectType(),
			parent,
			null);
		Map<String, Query> queries = new Map<String, Query> {
			'a.b' => Query.newSubQuery(
				'User',
				new List<String> { 'Id' },
				'CreatedBy',
				null,
				null,
				null,
				null)
		};

		Test.startTest();
		System.assertEquals(null, MergeService.findParentQuery(null, queries));
		System.assertEquals(null, MergeService.findParentQuery(relationship, null));
		Test.stopTest();
	}

	@IsTest
	static void test_findParentQuery_success() {
		DataModel.Relationship parent1 = new DataModel.ChildRelationship(
			'b',
			'a.b',
			1,
			User.getSObjectType(),
			null,
			null);
		DataModel.Relationship parent2 = new DataModel.LookupRelationship(
			'c',
			'a.b.c',
			2,
			User.getSObjectType(),
			parent1,
			null);
		DataModel.Relationship relationship = new DataModel.LookupRelationship(
			'd',
			'a.b.c.d',
			3,
			User.getSObjectType(),
			parent2,
			null);
		Map<String, Query> queries = new Map<String, Query> {
			'a.b' => Query.newSubQuery(
				'User',
				new List<String> { 'Id' },
				'CreatedBy',
				null,
				null,
				null,
				null)
		};

		Test.startTest();
		MergeService.FindQueryResult result = MergeService.findParentQuery(relationship, queries);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals('c.d', result.path);
		System.assertNotEquals(null, result.query);
		System.assertEquals('CreatedBy', result.query.relationship);
	}

	@IsTest
	static void test_addLookupQuery_undefined_arguments() {
		DataModel.LookupRelationship relationship = new DataModel.LookupRelationship(
			'c',
			'a.b.c',
			2,
			null,
			null,
			null);
		List<String> fields = new List<String> { 'Id' };
		Map<String, Query> queries = new Map<String, Query> {
			'a.b' => Query.newSubQuery(
				'User',
				new List<String> { 'Id' },
				'CreatedBy',
				null,
				null,
				null,
				null)
		};

		Test.startTest();
		System.assertEquals(queries, MergeService.addLookupQuery(null, fields, queries));
		System.assertEquals(queries, MergeService.addLookupQuery(relationship, null, queries));
		System.assertEquals(new Map<String, Query>(), MergeService.addLookupQuery(relationship, fields, null));
		Test.stopTest();
	}

	@IsTest
	static void test_addLookupQuery_no_parent() {
		DataModel.LookupRelationship relationship = new DataModel.LookupRelationship(
			'd',
			'a.b.c.d',
			1,
			User.getSObjectType(),
			null,
			null);
		List<String> fields = new List<String> { 'Id' };
		Map<String, Query> queries = new Map<String, Query> {
			'a.b' => Query.newSubQuery(
				'User',
				new List<String> { 'Id' },
				'CreatedBy',
				null,
				null,
				null,
				null)
		};

		Test.startTest();
		Map<String, Query> result = MergeService.addLookupQuery(
			relationship,
			fields,
			queries);
		Test.stopTest();

		System.assertEquals(queries, result);
		System.assertEquals(new List<String> { 'Id', 'd.Id' }, fields);
	}

	@IsTest
	static void test_addLookupQuery_lookup_parent() {
		DataModel.Relationship parent1 = new DataModel.LookupRelationship(
			'b',
			'a.b',
			1,
			User.getSObjectType(),
			null,
			null);
		DataModel.Relationship parent2 = new DataModel.LookupRelationship(
			'c',
			'a.b.c',
			2,
			User.getSObjectType(),
			parent1,
			null);
		DataModel.LookupRelationship relationship = new DataModel.LookupRelationship(
			'd',
			'a.b.c.d',
			3,
			User.getSObjectType(),
			parent2,
			null);
		List<String> fields = new List<String> { 'Id' };
		Map<String, Query> queries = new Map<String, Query> {
			'a.b' => Query.newSubQuery(
				'User',
				new List<String> { 'Id' },
				'CreatedBy',
				null,
				null,
				null,
				null)
		};

		Test.startTest();
		Map<String, Query> result = MergeService.addLookupQuery(
			relationship,
			fields,
			queries);
		Test.stopTest();

		System.assertEquals(queries, result);
		System.assertEquals(new List<String> { 'Id', 'b.c.d.Id' }, fields);
	}

	@IsTest
	static void test_addLookupQuery_child_parent() {
		DataModel.Relationship parent1 = new DataModel.ChildRelationship(
			'b',
			'a.b', // E.g Opportunity.OpportunityContactRoles
			1,
			User.getSObjectType(),
			null,
			null);
		DataModel.Relationship parent2 = new DataModel.LookupRelationship(
			'c',
			'a.b.c', // E.g Opportunity.OpportunityContactRoles.Contact
			2,
			User.getSObjectType(),
			parent1,
			null);
		DataModel.LookupRelationship relationship = new DataModel.LookupRelationship(
			'd',
			'a.b.c.d', // E.g Opportunity.OpportunityContactRoles.Contact.Account
			3,
			User.getSObjectType(),
			parent2,
			null);
		List<String> fields = new List<String> { 'Id' };
		Map<String, Query> queries = new Map<String, Query> {
			'a.b' => Query.newSubQuery(
				'User',
				new List<String> { 'Id' },
				'CreatedBy',
				null,
				null,
				null,
				null)
		};

		Test.startTest();
		Map<String, Query> result = MergeService.addLookupQuery(
			relationship,
			fields,
			queries);
		Test.stopTest();

		System.assertEquals(queries, result);
		System.assertEquals(new List<String> { 'Id' }, fields);
		System.assertEquals(new List<String> { 'Id', 'c.d.Id' }, queries.get('a.b').fields);
	}

	@IsTest
	static void test_addChildQuery_undefined_arguments() {
		DataModel.ChildRelationship relationship = new DataModel.ChildRelationship(
			'c',
			'a.b.c',
			2,
			null,
			null,
			null);
		Map<String, Query> queries = new Map<String, Query> {
			'a.b' => Query.newSubQuery(
				'User',
				new List<String> { 'Id' },
				'CreatedBy',
				null,
				null,
				null,
				null)
		};

		Test.startTest();
		System.assertEquals(queries, MergeService.addChildQuery(null, queries, queries));
		System.assertEquals(queries, MergeService.addChildQuery(relationship, null, queries));
		System.assertEquals(new Map<String, Query>(), MergeService.addChildQuery(relationship, queries, null));
		Test.stopTest();
	}

	@IsTest
	static void test_addChildQuery_no_parent() {
		DataModel.ChildRelationship relationship = new DataModel.ChildRelationship(
			'c',
			'a.b.c',
			2,
			User.getSObjectType(),
			null,
			null);
		Map<String, Query> queries = new Map<String, Query> {
			'a.b' => Query.newSubQuery(
				'User',
				new List<String> { 'Id' },
				'CreatedBy',
				null,
				null,
				null,
				null)
		};

		Test.startTest();
		Map<String, Query> result = MergeService.addChildQuery(relationship, queries, queries);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<String> { 'a.b', 'a.b.c' }, result.keySet());
		System.assertNotEquals(null, result.get('a.b.c'));
		System.assertEquals('User', result.get('a.b.c').type);
		System.assertEquals(new List<String> { 'Id' }, result.get('a.b.c').fields);
		System.assertEquals('c', result.get('a.b.c').relationship);
	}

	@IsTest
	static void test_addChildQuery_no_sub_query() {
		DataModel.ChildRelationship parent = new DataModel.ChildRelationship(
			'b',
			'a.b',
			1,
			User.getSObjectType(),
			null,
			null);
		DataModel.ChildRelationship relationship = new DataModel.ChildRelationship(
			'c',
			'a.b.c',
			2,
			User.getSObjectType(),
			parent,
			null);
		Map<String, Query> subQueries = new Map<String, Query>();
		Map<String, Query> allQueries = new Map<String, Query>();

		Test.startTest();
		Map<String, Query> result = MergeService.addChildQuery(relationship, subQueries, allQueries);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<String> { 'a.b.c' }, result.keySet());
		System.assertNotEquals(null, result.get('a.b.c'));
		System.assertEquals(new Set<String> { 'a.b.c' }, subQueries.keySet());
		System.assertNotEquals(null, subQueries.get('a.b.c'));
	}

	@IsTest
	static void test_addChildQuery_child() {
		DataModel.ChildRelationship parent = new DataModel.ChildRelationship(
			'b',
			'a.b',
			1,
			User.getSObjectType(),
			null,
			null);
		DataModel.ChildRelationship relationship = new DataModel.ChildRelationship(
			'c',
			'a.b.c',
			2,
			User.getSObjectType(),
			parent,
			User.getSObjectType().getDescribe().fields.getMap().get('CreatedById'));
		Query subQuery = Query.newSubQuery(
			'User',
			new List<String> { 'Id' },
			'b',
			null,
			null,
			null,
			null);
		Map<String, Query> subQueries = new Map<String, Query> {
			'a.b' => subQuery
		};
		Map<String, Query> allQueries = new Map<String, Query> {
			'a.b' => subQuery
		};

		Test.startTest();
		Map<String, Query> result = MergeService.addChildQuery(relationship, subQueries, allQueries);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<String> { 'a.b', 'a.b.c' }, result.keySet());
		System.assertNotEquals(null, result.get('a.b.c'));
		System.assertEquals('User', result.get('a.b.c').type);
		System.assertEquals(new List<String> { 'Id' }, result.get('a.b.c').fields);
		System.assertEquals('c', result.get('a.b.c').relationship);
		System.assertEquals('CreatedById', result.get('a.b.c').parentIdField);
		System.assertEquals(new Set<String> { 'a.b' }, subQueries.keySet());
		System.assertNotEquals(null, subQueries.get('a.b'));
		System.assertEquals(new List<Query> { result.get('a.b.c') }, subQueries.get('a.b').children);
	}

	@IsTest
	static void test_querySObjects_undefined_arguments() {
		Test.startTest();
		System.assertEquals(null, MergeService.querySObjects(null, null));
		Test.stopTest();
	}

	@IsTest
	static void test_querySObjects_success() {
		Schema.Account a = TestUtils.createAccount();
		Contact c1 = TestUtils.createContact(a.Id);
		Contact c2 = TestUtils.createContact(a.Id);
		Contact c3 = TestUtils.createContact(a.Id);
		Case cs1 = TestUtils.createCase(a.Id, c1.Id);
		Case cs2 = TestUtils.createCase(a.Id, c1.Id);
		TestUtils.createCaseContactRole(cs1.Id, c1.Id);
		TestUtils.createCaseContactRole(cs2.Id, c2.Id);
		TestUtils.createCaseContactRole(cs2.Id, c3.Id);

		DataModel.Relationship r1 = new DataModel.LookupRelationship(
			'CreatedBy',
			'Account.CreatedBy',
			1,
			User.getSObjectType(),
			null,
			Schema.Account.getSObjectType().getDescribe().fields.getMap().get('CreatedById'));
		DataModel.Relationship r2 = new DataModel.ChildRelationship(
			'Cases',
			'Account.Cases',
			1,
			Case.getSObjectType(),
			null,
			Case.getSObjectType().getDescribe().fields.getMap().get('AccountId'));
		DataModel.Relationship r3 = new DataModel.ChildRelationship(
			'CaseContactRoles',
			'Account.Cases.CaseContactRoles',
			2,
			CaseContactRole.getSObjectType(),
			r2,
			CaseContactRole.getSObjectType().getDescribe().fields.getMap().get('CasesId'));
		DataModel.Relationship r4 = new DataModel.LookupRelationship(
			'Contact',
			'Account.Cases.CaseContactRoles.Contact',
			3,
			Contact.getSObjectType(),
			r3,
			CaseContactRole.getSObjectType().getDescribe().fields.getMap().get('ContactId'));

		Id sourceId = a.Id;
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship> {
			r1.path => r1,
			r2.path => r2,
			r3.path => r3,
			r4.path => r4
		};

		Test.startTest();
		Query.Result result = MergeService.querySObjects(sourceId, relationships);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertNotEquals(null, result.result);
		System.assertEquals(sourceId, result.result.Id);
		List<SObject> cs = result.result.getSObjects('Cases');
		System.assertEquals(2, Collection.size(cs));
		System.assertNotEquals(null, cs[0]);
		System.assertNotEquals(null, cs[1]);
		System.assertNotEquals(null, result.children);
		System.assertEquals(new Set<String> { 'CaseContactRoles' }, result.children.keySet());
		System.assertEquals(3, Collection.size(result.children.get('CaseContactRoles')));
	}

	@IsTest
	static void test_buildUpdates_undefined_arguments() {
		String fullPath = 'User.CreatedBy.Name';
		String path = 'User.CreatedBy.Name';
		Object value = UUID.randomUUID().toString();
		SObject obj = new User(Id = UserInfo.getUserId());
		List<SObject> objects = new List<SObject> { obj };
		Map<String, List<SObject>> descendants = new Map<String, List<SObject>>();
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship> {
			'User.CreatedBy' => new DataModel.LookupRelationship(
				'CreatedBy',
				'User.CreatedBy',
				1,
				User.getSObjectType(),
				null,
				null)
		};
		Map<Id, SObject> updates = new Map<Id, SObject>();

		Test.startTest();
		System.assertEquals(new Map<Id, SObject>(), MergeService.buildUpdates(
			null,
			path,
			value,
			objects,
			descendants,
			relationships,
			updates));
		System.assertEquals(new Map<Id, SObject>(), MergeService.buildUpdates(
			fullPath,
			' ',
			value,
			objects,
			descendants,
			relationships,
			updates));
		System.assertEquals(new Map<Id, SObject>(), MergeService.buildUpdates(
			fullPath,
			path,
			value,
			null,
			descendants,
			relationships,
			updates));
		System.assertEquals(new Map<Id, SObject>(), MergeService.buildUpdates(
			fullPath,
			path,
			value,
			objects,
			descendants,
			relationships,
			null));
		Test.stopTest();
	}

	@IsTest
	static void test_buildUpdates_invalid() {
		String path = 'Opportunity.Invalid.Name';
		Object value = UUID.randomUUID().toString();
		SObject obj = new Opportunity();
		Map<String, List<SObject>> descendants = new Map<String, List<SObject>>();
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship> {
			'Opportunity.Account' => new DataModel.LookupRelationship(
				'Account',
				'Opportunity.Account',
				1,
				Schema.Account.getSObjectType(),
				null,
				null),
			'Opportunity.OpportunityContactRoles' => new DataModel.ChildRelationship(
				'OpportunityContactRoles',
				'Opportunity.OpportunityContactRoles',
				1,
				OpportunityContactRole.getSObjectType(),
				null,
				OpportunityContactRole.getSObjectType().getDescribe().fields.getMap().get('OpportunityId')),
			'Opportunity.OpportunityContactRoles.Contact' => new DataModel.LookupRelationship(
				'Contact',
				'Opportunity.OpportunityContactRoles.Contact',
				2,
				Contact.getSObjectType(),
				null,
				OpportunityContactRole.getSObjectType().getDescribe().fields.getMap().get('ContactId'))
		};

		Test.startTest();
		Map<Id, SObject> result = MergeService.buildUpdates(
			path,
			path,
			value,
			new List<SObject> { obj },
			descendants,
			relationships,
			null);
		Test.stopTest();

		System.assertEquals(new Map<Id, SObject>(), result);
	}

	@IsTest
	static void test_buildUpdates_simple() {
		Opportunity o = TestUtils.createOpportunity();

		String path = 'Opportunity.StageName';
		Object value = 'Closed Won';
		SObject obj = new Opportunity(Id = o.Id);
		Map<String, List<SObject>> descendants = null;
		Map<String, DataModel.Relationship> relationships = null;

		Test.startTest();
		Map<Id, SObject> result = MergeService.buildUpdates(
			path,
			path,
			value,
			new List<SObject> { obj },
			descendants,
			relationships,
			null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<Id> { o.Id }, result.keySet());
		System.assertNotEquals(null, result.get(o.Id));
		System.assertEquals(value, result.get(o.Id).get('StageName'));
	}

	@IsTest
	static void test_buildUpdates_lookup() {
		Schema.Account a = TestUtils.createAccount();
		Opportunity o = TestUtils.createOpportunity(a.Id);

		String path = 'Opportunity.Account.Name';
		Object value = UUID.randomUUID().toString();
		SObject obj = new Opportunity(Id = o.Id, Account = new Schema.Account(Id = a.Id));
		Map<String, List<SObject>> descendants = null;
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship> {
			'Opportunity.Account' => new DataModel.LookupRelationship(
				'Account',
				'Opportunity.Account',
				1,
				Schema.Account.getSObjectType(),
				null,
				Opportunity.getSObjectType().getDescribe().fields.getMap().get('AccountId'))
		};

		Test.startTest();
		Map<Id, SObject> result = MergeService.buildUpdates(
			path,
			path,
			value,
			new List<SObject> { obj },
			descendants,
			relationships,
			null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<Id> { a.Id }, result.keySet());
		System.assertNotEquals(null, result.get(a.Id));
		System.assertEquals(value, result.get(a.Id).get('Name'));
	}

	@IsTest
	static void test_buildUpdates_children() {
		Schema.Account a = TestUtils.createAccount();
		Contact c1 = TestUtils.createContact(a.Id);
		Contact c2 = TestUtils.createContact(a.Id);
		Opportunity o = TestUtils.createOpportunity(a.Id);
		OpportunityContactRole ocr1 = TestUtils.createOpportunityContactRole(o.Id, c1.Id);
		OpportunityContactRole ocr2 = TestUtils.createOpportunityContactRole(o.Id, c2.Id);

		String path = 'Opportunity.OpportunityContactRoles.Role';
		Object value = UUID.randomUUID().toString();
		SObject obj = [SELECT Id, (SELECT Id FROM OpportunityContactRoles) FROM Opportunity WHERE Id = :o.Id];
		Map<String, List<SObject>> descendants = null;
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship> {
			'Opportunity.OpportunityContactRoles' => new DataModel.ChildRelationship(
				'OpportunityContactRoles',
				'Opportunity.OpportunityContactRoles',
				1,
				OpportunityContactRole.getSObjectType(),
				null,
				OpportunityContactRole.getSObjectType().getDescribe().fields.getMap().get('OpportunityId'))
		};

		Test.startTest();
		Map<Id, SObject> result = MergeService.buildUpdates(
			path,
			path,
			value,
			new List<SObject> { obj },
			descendants,
			relationships,
			null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<Id> { ocr1.Id, ocr2.Id }, result.keySet());
		System.assertNotEquals(null, result.get(ocr1.Id));
		System.assertEquals(value, result.get(ocr1.Id).get('Role'));
		System.assertNotEquals(null, result.get(ocr2.Id));
		System.assertEquals(value, result.get(ocr2.Id).get('Role'));
	}

	@IsTest
	static void test_buildUpdates_lookup_children() {
		Schema.Account a = TestUtils.createAccount();
		Contact c1 = TestUtils.createContact(a.Id);
		Contact c2 = TestUtils.createContact(a.Id);
		Opportunity o = TestUtils.createOpportunity(a.Id);

		String path = 'Opportunity.Account.Contacts.Phone';
		Object value = String.valueOf(TestUtils.randomInteger(1000000000));
		SObject obj = new Opportunity(Id = o.Id, Account = new Schema.Account(Id = a.Id));
		Map<String, List<SObject>> descendants = new Map<String, List<SObject>> {
			'Contacts' => new List<SObject> {
				new Contact(Id = c1.Id),
				new Contact(Id = c2.Id)
			}
		};
		String path1 = 'Opportunity.Account';
		String path2 = 'Opportunity.Account.Contacts';
		DataModel.Relationship r1 = new DataModel.LookupRelationship(
			'Account',
			path1,
			1,
			Schema.Account.getSObjectType(),
			null,
			Opportunity.getSObjectType().getDescribe().fields.getMap().get('AccountId'));
		DataModel.Relationship r2 = new DataModel.ChildRelationship(
			'Contacts',
			path2,
			2,
			Contact.getSObjectType(),
			r1,
			Contact.getSObjectType().getDescribe().fields.getMap().get('AccountId'));
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship> {
			path1 => r1,
			path2 => r2
		};

		Test.startTest();
		Map<Id, SObject> result = MergeService.buildUpdates(
			path,
			path,
			value,
			new List<SObject> { obj },
			descendants,
			relationships,
			null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<Id> { c1.Id, c2.Id }, result.keySet());
		System.assertNotEquals(null, result.get(c1.Id));
		System.assertEquals(value, result.get(c1.Id).get('Phone'));
		System.assertNotEquals(null, result.get(c2.Id));
		System.assertEquals(value, result.get(c2.Id).get('Phone'));
	}

	@IsTest
	static void test_buildUpdates_children_lookup() {
		Schema.Account a = TestUtils.createAccount();
		Contact c1 = TestUtils.createContact(a.Id);
		Contact c2 = TestUtils.createContact(a.Id);
		Opportunity o = TestUtils.createOpportunity(a.Id);
		OpportunityContactRole ocr1 = TestUtils.createOpportunityContactRole(o.Id, c1.Id);
		OpportunityContactRole ocr2 = TestUtils.createOpportunityContactRole(o.Id, c2.Id);

		String path = 'Opportunity.OpportunityContactRoles.Contact.Phone';
		Object value = String.valueOf(TestUtils.randomInteger(1000000000));
		SObject obj = new Opportunity(Id = o.Id);
		Map<String, List<SObject>> descendants = new Map<String, List<SObject>> {
			'OpportunityContactRoles' => new List<SObject> {
				new OpportunityContactRole(Id = ocr1.Id, Contact = new Contact(Id = c1.Id)),
				new OpportunityContactRole(Id = ocr2.Id, Contact = new Contact(Id = c2.Id))
			}
		};
		String path1 = 'Opportunity.OpportunityContactRoles';
		String path2 = 'Opportunity.OpportunityContactRoles.Contact';
		DataModel.Relationship r1 = new DataModel.ChildRelationship(
			'OpportunityContactRoles',
			path1,
			1,
			OpportunityContactRole.getSObjectType(),
			null,
			OpportunityContactRole.getSObjectType().getDescribe().fields.getMap().get('OpportunityId'));
		DataModel.Relationship r2 = new DataModel.LookupRelationship(
			'Contact',
			path2,
			2,
			Contact.getSObjectType(),
			r1,
			OpportunityContactRole.getSObjectType().getDescribe().fields.getMap().get('ContactId'));
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship> {
			path1 => r1,
			path2 => r2
		};

		Test.startTest();
		Map<Id, SObject> result = MergeService.buildUpdates(
			path,
			path,
			value,
			new List<SObject> { obj },
			descendants,
			relationships,
			null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<Id> { c1.Id, c2.Id }, result.keySet());
		System.assertNotEquals(null, result.get(c1.Id));
		System.assertEquals(value, result.get(c1.Id).get('Phone'));
		System.assertNotEquals(null, result.get(c2.Id));
		System.assertEquals(value, result.get(c2.Id).get('Phone'));
	}

	@IsTest
	static void test_buildUpdates_children_children() {
		Schema.Account a = TestUtils.createAccount();
		Contact c1 = TestUtils.createContact(a.Id);
		Contact c2 = TestUtils.createContact(a.Id);
		Contact c3 = TestUtils.createContact(a.Id);
		Case cs1 = TestUtils.createCase(a.Id, c1.Id);
		Case cs2 = TestUtils.createCase(a.Id, c1.Id);
		CaseContactRole cs1c1 = TestUtils.createCaseContactRole(cs1.Id, c1.Id);
		CaseContactRole cs2c2 = TestUtils.createCaseContactRole(cs2.Id, c2.Id);
		CaseContactRole cs2c3 = TestUtils.createCaseContactRole(cs2.Id, c3.Id);

		String path = 'Account.Cases.CaseContactRoles.Role';
		Object value = UUID.randomUUID().toString();
		SObject obj = [SELECT Id, (SELECT Id FROM Cases) FROM Account WHERE Id = :a.Id];
		Map<String, List<SObject>> descendants = new Map<String, List<SObject>> {
			'CaseContactRoles' => new List<SObject> {
				new CaseContactRole(Id = cs1c1.Id, CasesId = cs1.Id),
				new CaseContactRole(Id = cs2c2.Id, CasesId = cs2.Id),
				new CaseContactRole(Id = cs2c3.Id, CasesId = cs2.Id)
			}
		};
		String path1 = 'Account.Cases';
		String path2 = 'Account.Cases.CaseContactRoles';
		DataModel.Relationship r1 = new DataModel.ChildRelationship(
			'Cases',
			path1,
			1,
			Case.getSObjectType(),
			null,
			Case.getSObjectType().getDescribe().fields.getMap().get('AccountId'));
		DataModel.Relationship r2 = new DataModel.ChildRelationship(
			'CaseContactRoles',
			path2,
			2,
			CaseContactRole.getSObjectType(),
			r1,
			CaseContactRole.getSObjectType().getDescribe().fields.getMap().get('CasesId'));
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship> {
			path1 => r1,
			path2 => r2
		};

		Test.startTest();
		Map<Id, SObject> result = MergeService.buildUpdates(
			path,
			path,
			value,
			new List<SObject> { obj },
			descendants,
			relationships,
			null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<Id> { cs1c1.Id, cs2c2.Id, cs2c3.Id }, result.keySet());
		System.assertNotEquals(null, result.get(cs1c1.Id));
		System.assertEquals(value, result.get(cs1c1.Id).get('Role'));
		System.assertNotEquals(null, result.get(cs2c2.Id));
		System.assertEquals(value, result.get(cs2c2.Id).get('Role'));
		System.assertNotEquals(null, result.get(cs2c3.Id));
		System.assertEquals(value, result.get(cs2c3.Id).get('Role'));
	}

	@IsTest
	static void test_mergeData_update_undefined_arguments() {
		Id sourceId = UserInfo.getUserId();
		Map<String, Object> dataUpdates = new Map<String, Object> {
			'User.Name' => UUID.randomUUID().toString()
		};

		Test.startTest();
		System.assertEquals(new Map<Id, SObject>(), MergeService.mergeData(null, dataUpdates));
		System.assertEquals(new Map<Id, SObject>(), MergeService.mergeData(sourceId, null));
		System.assertEquals(new Map<Id, SObject>(), MergeService.mergeData(sourceId, new Map<String, Object>()));
		Test.stopTest();
	}

	@IsTest
	static void test_mergeData_update_invalid_field() {
		Id sourceId = TestUtils.createAccount().Id;
		Map<String, Object> dataUpdates = new Map<String, Object> {
			'Account.Name' => UUID.randomUUID(),
			'Account.Invalid' => UUID.randomUUID(),
			'Account.AnnualRevenue' => TestUtils.randomInteger(100000)
		};

		Test.startTest();
		try {
			MergeService.mergeData(sourceId, dataUpdates);
			throw new AssertException('Expected failure');
		} catch (UnauthorizedException ex) {
			System.assertEquals(UnauthorizedException.AccessRequirement.SecurityPermission, ex.requirement);
		}
		Test.stopTest();
	}

	@IsTest
	static void test_mergeData_update_success() {
		System.runAs(UserMock.getAdministrator()) {
			Schema.Account a = TestUtils.createAccount();
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			Contact c3 = TestUtils.createContact(a.Id);
			Case cs1 = TestUtils.createCase(a.Id, c1.Id);
			Case cs2 = TestUtils.createCase(a.Id, c2.Id);
			CaseContactRole cs1c1 = TestUtils.createCaseContactRole(cs1.Id, c1.Id);
			CaseContactRole cs2c2 = TestUtils.createCaseContactRole(cs2.Id, c2.Id);
			CaseContactRole cs2c3 = TestUtils.createCaseContactRole(cs2.Id, c3.Id);

			String newAccountName = UUID.randomUUID().toString();
			Decimal newAccountRevenue = TestUtils.randomInteger(1000000);
			String newCreatedByEmail = UUID.randomUUID() + '@unit.test';
			Boolean newCaseIsEscalated = true;
			String newCaseContactRole = UUID.randomUUID().toString();
			String newContactEmail = UUID.randomUUID() + '@unit.test';

			Id sourceId = a.Id;
			Map<String, Object> dataUpdates = new Map<String, Object> {
				'account.name' => newAccountName,
				'account.annualrevenue' => newAccountRevenue,
				'account.createdby.email' => newCreatedByEmail,
				'account.cases.isescalated' => newCaseIsEscalated,
				'account.cases.casecontactroles.role' => newCaseContactRole,
				'account.cases.casecontactroles.contact.email' => newContactEmail
			};

			Test.startTest();
			Map<Id, SObject> result = MergeService.mergeData(sourceId, dataUpdates);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(new Set<Id> {
				a.Id, UserInfo.getUserId(), cs1.Id, cs2.Id, cs1c1.Id, cs2c2.Id, cs2c3.Id, c1.Id, c2.Id, c3.Id
			}, result.keySet());

			System.assertNotEquals(null, result.get(a.Id));
			System.assertEquals(dataUpdates.get('account.name'), result.get(a.Id).get('Name'));
			System.assertEquals(dataUpdates.get('account.annualrevenue'), result.get(a.Id).get('AnnualRevenue'));
			System.assertEquals(dataUpdates.get('account.createdby.email'), result.get(UserInfo.getUserId()).get('Email'));
			System.assertEquals(dataUpdates.get('account.cases.isescalated'), result.get(cs1.Id).get('IsEscalated'));
			System.assertEquals(dataUpdates.get('account.cases.isescalated'), result.get(cs2.Id).get('IsEscalated'));
			System.assertEquals(dataUpdates.get('account.cases.casecontactroles.role'), result.get(cs1c1.Id).get('Role'));
			System.assertEquals(dataUpdates.get('account.cases.casecontactroles.role'), result.get(cs2c2.Id).get('Role'));
			System.assertEquals(dataUpdates.get('account.cases.casecontactroles.role'), result.get(cs2c3.Id).get('Role'));
			System.assertEquals(dataUpdates.get('account.cases.casecontactroles.contact.email'), result.get(c1.Id).get('Email'));
			System.assertEquals(dataUpdates.get('account.cases.casecontactroles.contact.email'), result.get(c2.Id).get('Email'));
			System.assertEquals(dataUpdates.get('account.cases.casecontactroles.contact.email'), result.get(c3.Id).get('Email'));

			a = [SELECT Name, AnnualRevenue, CreatedBy.Email, (SELECT IsEscalated FROM Cases) FROM Account WHERE Id = :a.Id];
			System.assertEquals(dataUpdates.get('account.name'), a.Name);
			System.assertEquals(dataUpdates.get('account.annualrevenue'), a.AnnualRevenue);
			System.assertEquals(dataUpdates.get('account.createdby.email'), a.CreatedBy.Email);
			for (Case c : a.Cases) {
				System.assertEquals(dataUpdates.get('account.cases.isescalated'), c.IsEscalated);
			}

			for (CaseContactRole ccr : [SELECT Role, Contact.Email FROM CaseContactRole WHERE Cases.AccountId = :a.Id]) {
				System.assertEquals(dataUpdates.get('account.cases.casecontactroles.role'), ccr.Role);
				System.assertEquals(dataUpdates.get('account.cases.casecontactroles.contact.email'), ccr.Contact.Email);
			}
		}
	}
}
