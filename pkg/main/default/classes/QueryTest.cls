@IsTest
private class QueryTest {

	@IsTest
	static void test_validate_invalid_undefined() {
		Query q = new Query(null, null, null, null, null, null,
			null, null);

		Test.startTest();
		ValidationResult result1 = Query.validate(null, null, null);
		ValidationResult result2 = Query.validate(q, null, null);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.isValid);
		System.assertEquals(Label.UndefinedArgument, result1.toString());

		System.assertNotEquals(null, result2);
		System.assert(!result2.isValid);
		System.assertEquals(Label.UndefinedType, result2.toString());
	}

	@IsTest
	static void test_validate_invalid_root() {
		Query q = new Query('Account', new List<String> { 'Name' }, null, null,
			'CreatedDate > TODAY()', 'CreatedDate DESC', 20, null);

		Test.startTest();
		ValidationResult result = Query.validate(q, null, 1);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals(String.format('Account: {0}\nAccount: {1}\nAccount: {2}', new List<String> {
			Label.CannotFilterSourceObjectResults,
			Label.CannotOrderSourceObjectResults,
			Label.CannotLimitSourceObjectResults
		}), result.toString());
	}

	@IsTest
	static void test_validate_invalid_limit() {
		Query q1 = new Query('Account', new List<String> { 'Name' }, 'Accounts', null,
			'CreatedDate > TODAY()', 'CreatedDate DESC', -1, null);
		Query q2 = new Query('Account', new List<String> { 'Name' }, 'Accounts', null,
			'CreatedDate > TODAY()', 'CreatedDate DESC', 0, null);
		Query q3 = new Query('Account', new List<String> { 'Name' }, 'Accounts', null,
			'CreatedDate > TODAY()', 'CreatedDate DESC', Query.MAXIMUM_RECORDS + 1,
			null);

		Test.startTest();
		ValidationResult result1 = Query.validate(q1, null, 2);
		ValidationResult result2 = Query.validate(q2, null, 2);
		ValidationResult result3 = Query.validate(q3, null, 2);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.isValid);
		System.assertEquals('Account: ' + String.format(Label.InvalidLimit_1, new List<Object> { Query.MAXIMUM_RECORDS }),
			result1.toString());

		System.assertNotEquals(null, result2);
		System.assert(!result2.isValid);
		System.assertEquals('Account: ' + String.format(Label.InvalidLimit_1, new List<Object> { Query.MAXIMUM_RECORDS }),
			result2.toString());

		System.assertNotEquals(null, result3);
		System.assert(!result3.isValid);
		System.assertEquals('Account: ' + String.format(Label.InvalidLimit_1, new List<Object> { Query.MAXIMUM_RECORDS }),
			result3.toString());
	}

	@IsTest
	static void test_validate_invalid_descendant_depth() {
		Query q = new Query('Account', new List<String> { 'Name' }, 'Accounts', 'AccountId',
			'CreatedDate > TODAY()', 'CreatedDate DESC', 10, new List<Query> {
				Query.newChildQuery('Case', new List<String> { 'CaseNumber' }, 'Cases',
					'AccountId', null, null, null)
			});

		Test.startTest();
		ValidationResult result = Query.validate(q, null, MergeField.MAX_CHILD_DEPTH + 1);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals('Account: ' + String.format(Label.MaxDescendantQueryDepthExceeded_1,
			new List<Object> { MergeField.MAX_CHILD_DEPTH }), result.toString());
	}

	@IsTest
	static void test_validate_invalid_relationship() {
		Query q = new Query('Account', new List<String> { 'Name' }, 'Accounts', 'AccountId',
			'CreatedDate > TODAY()', 'CreatedDate DESC', 10, new List<Query> {
				Query.newChildQuery('Case', new List<String> { 'CaseNumber' }, '',
					'AccountId', null, null, null)
			});

		Test.startTest();
		ValidationResult result = Query.validate(q, null, MergeField.MAX_CHILD_DEPTH);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals('Case: ' + Label.UndefinedChildRelationship, result.toString());
	}

	@IsTest
	static void test_validate_invalid_parent_id() {
		Query q = new Query('Account', new List<String> { 'Name' }, 'Accounts', 'AccountId',
			'CreatedDate > TODAY()', 'CreatedDate DESC', 10, new List<Query> {
				Query.newChildQuery('Case', new List<String> { 'CaseNumber' }, 'Cases',
					null, null, null, null)
			});

		Test.startTest();
		ValidationResult result = Query.validate(q, null, MergeField.MAX_CHILD_DEPTH);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals('Account.Cases: ' + Label.UndefinedParent, result.toString());
	}

	@IsTest
	static void test_validate_invalid_child() {
		Query q = new Query('Account', new List<String> { 'Name' }, null, null,
			null, null, 1, new List<Query> {
				Query.newChildQuery('Case', new List<String> { 'CaseNumber' }, 'Cases',
					'AccountId', null, null, -1)
			});

		Test.startTest();
		ValidationResult result = Query.validate(q, null, 1);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assertEquals('Account.Cases: ' + String.format(Label.InvalidLimit_1,
			new List<Object> { Query.MAXIMUM_RECORDS }), result.toString());
	}

	@IsTest
	static void test_validate_unauthorized() {
		System.runAs(UserMock.createRestrictedUser()) {
			Query q = new Query('Envelope__c', new List<String> { 'Name' }, null, null,
				null, null, 1, new List<Query> {
					Query.newSubQuery('Recipient__c', new List<String> { 'Name' }, 'Recipients', null, null, null, null)
				});

			Test.startTest();
			ValidationResult result = Query.validate(q, null, 1);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.isValid);
			System.assertEquals(String.format('{0} {1}Recipient__c\n{0} {1}Envelope__c', new List<String> {
				Label.CannotQueryObject, Application.namespacePrefix
			}), result.toString());
		}
	}

	@IsTest
	static void test_validate_invalid_soql() {
		Query q = new Query('Account', new List<String> { 'Name' }, null, null,
			null, null, 1, new List<Query> {
				Query.newSubQuery('Case', new List<String> { 'CaseNumber' }, 'Cases', 'bad filter', 'bad order by', null, null)
			});

		Test.startTest();
		ValidationResult result = Query.validate(q, null, 1);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isValid);
		System.assert(String.isNotBlank(result.toString()));
	}

	@IsTest
	static void test_validate_exception() {
		Test.startTest();
		try {
			Query.validate(null);
			throw new AssertException('Expected failure');
		} catch (ValidationException ex) {
			System.assert(ex.getMessage().startsWith(Label.InvalidQuery));
		}
		Test.stopTest();
	}

	@IsTest
	static void test_execute() {
		Schema.Account a = TestUtils.createAccount();

		Contact ct1 = TestUtils.createContact(a.Id);
		Contact ct2 = TestUtils.createContact(a.Id);

		Opportunity o1 = new Opportunity(AccountId = a.Id, Name = 'UNIT TEST 10', CloseDate = Date.today(), StageName = 'Negotiation/Review');
		Opportunity o2 = new Opportunity(AccountId = a.Id, Name = 'UNIT TEST 11', CloseDate = Date.today(), StageName = 'Negotiation/Review');
		Opportunity o3 = new Opportunity(AccountId = a.Id, Name = 'UNIT TEST 20', CloseDate = Date.today(), StageName = 'Negotiation/Review');
		insert new List<Opportunity> { o1, o2, o3 };

		Case cs1 = new Case(AccountId = a.Id, ContactId = ct1.Id);
		Case cs2 = new Case(AccountId = a.Id, ContactId = ct2.Id);

		insert new List<Case> { cs1, cs2 };

		Query q = Query.newQuery(
			'Account',
			new List<String> { 'Name', 'Owner.Name' },
			new List<Query> {
				Query.newSubQuery(
					'Contact',
					new List<String> { 'Name' },
					'Contacts',
					null,
					'Name DESC',
					100,
					new List<Query> {
						Query.newChildQuery(
							'Case',
							new List<String> { 'CaseNumber' },
							'Cases',
							'ContactId',
							null,
							null,
							100)
					}),
				Query.newSubQuery(
					'Opportunity',
					new List<String> { 'Name' },
					'Opportunities',
					'Name LIKE \'UNIT TEST 1%\'',
					null,
					null,
					null)
			});

		Test.startTest();
		Query.Result result = q.execute(a.Id);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertNotEquals(null, result.result);
		System.assert(result.result instanceof Schema.Account);
		Schema.Account aa = (Schema.Account)result.result;
		System.assertEquals(2, Collection.size(aa.Opportunities));
		System.assertEquals(2, Collection.size(aa.Contacts));
		System.assertNotEquals(null, aa.Owner);
		System.assertEquals(UserInfo.getName(), aa.Owner.Name);

		System.assertNotEquals(null, result.children);
		System.assertEquals(1, result.children.size());
		System.assertEquals(2, Collection.size(result.children.get('Cases')));
	}
}
