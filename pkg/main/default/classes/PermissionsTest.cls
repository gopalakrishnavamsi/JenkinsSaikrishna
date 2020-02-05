@IsTest
private class PermissionsTest {

	static final SObjectType OBJECT_TYPE = Envelope__c.getSObjectType();
	static final String OBJECT_NAME = OBJECT_TYPE.getDescribe().getName();
	static final String FIELD_NAME = Application.namespacePrefix + 'DocuSignId__c';

	@IsTest
	static void test_isFlsSupported() {
		String orgType = null;
		List<Organization> orgs = [SELECT Id, OrganizationType FROM Organization LIMIT 1];
		if (Collection.isNotEmpty(orgs)) {
			orgType = orgs[0].OrganizationType;
		}
		System.assertEquals((orgType == 'Developer Edition' || orgType == 'Enterprise Edition' || orgType == 'Unlimited Edition'),
			Permissions.IS_FLS_SUPPORTED);
	}

	@IsTest
	static void test_describeField() {
		Test.startTest();
		DescribeFieldResult r1 = Permissions.describeField(OBJECT_NAME, FIELD_NAME, null);
		DescribeFieldResult r2 = Permissions.describeField(OBJECT_NAME, FIELD_NAME, OBJECT_TYPE.getDescribe().fields.getMap().get(FIELD_NAME));
		Test.stopTest();

		System.assertEquals(null, r1);
		System.assertNotEquals(null, r2);
		System.assertEquals(FIELD_NAME, r2.getName());
	}

	@IsTest
	static void test_FlsResult() {
		Test.startTest();
		Permissions.FlsResult r1 = new Permissions.FlsResult('Test', Permissions.FlsStatus.OK);
		Permissions.FlsResult r2 = new Permissions.FlsResult('Test', Permissions.FlsStatus.Unauthorized);
		Permissions.FlsResult r3 = new Permissions.FlsResult('Test', Permissions.FlsStatus.BadRequest);
		Permissions.FlsResult r4 = new Permissions.FlsResult('Test', Permissions.FlsStatus.NotFound);
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(r1.isAuthorized);
		System.assertEquals('Test', r1.toString());
		System.assertNotEquals(null, r2);
		System.assert(!r2.isAuthorized);
		System.assertEquals('Test', r2.toString());
		System.assertNotEquals(null, r3);
		System.assert(!r3.isAuthorized);
		System.assertEquals('Test (BadRequest)', r3.toString());
		System.assertNotEquals(null, r4);
		System.assert(!r4.isAuthorized);
		System.assertEquals('Test (NotFound)', r4.toString());
	}

	@IsTest
	static void test_FlsResults() {
		Test.startTest();
		Permissions.FlsResults r1 = new Permissions.FlsResults(
			Permissions.FlsAccess.Queryable,
			false,
			null,
			null);
		Permissions.FlsResults r2 = new Permissions.FlsResults(
			Permissions.FlsAccess.Deletable,
			false,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.Unauthorized),
			new List<Permissions.FlsResult> {
				new Permissions.FlsResult('Test', Permissions.FlsStatus.BadRequest)
			});
		Permissions.FlsResults r3 = new Permissions.FlsResults(
			Permissions.FlsAccess.Createable,
			false,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.OK),
			new List<Permissions.FlsResult> {
				new Permissions.FlsResult('Test1', Permissions.FlsStatus.Unauthorized),
				new Permissions.FlsResult('Test2', Permissions.FlsStatus.OK)
			});
		Permissions.FlsResults r4 = new Permissions.FlsResults(
			Permissions.FlsAccess.Updateable,
			true,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.OK),
			new List<Permissions.FlsResult> {
				new Permissions.FlsResult('Test1', Permissions.FlsStatus.OK),
				new Permissions.FlsResult('Test2', Permissions.FlsStatus.OK)
			});
		Permissions.FlsResults r5 = new Permissions.FlsResults(
			Permissions.FlsAccess.Createable,
			false,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.BadRequest),
			null);
		Permissions.FlsResults r6 = new Permissions.FlsResults(
			Permissions.FlsAccess.Updateable,
			false,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.Unauthorized),
			null);
		Permissions.FlsResults r7 = new Permissions.FlsResults(
			Permissions.FlsAccess.Updateable,
			false,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.OK),
			new List<Permissions.FlsResult> {
				new Permissions.FlsResult('Test1', Permissions.FlsStatus.NotFound)
			});
		Permissions.FlsResults r8 = new Permissions.FlsResults(
			Permissions.FlsAccess.Queryable,
			false,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.OK),
			new List<Permissions.FlsResult> {
				new Permissions.FlsResult('Test1', Permissions.FlsStatus.Unauthorized),
				new Permissions.FlsResult('Test2', Permissions.FlsStatus.Unauthorized)
			});
		Permissions.FlsResults r9 = new Permissions.FlsResults(
			Permissions.FlsAccess.Filterable,
			false,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.OK),
			new List<Permissions.FlsResult> {
				new Permissions.FlsResult('Test1', Permissions.FlsStatus.Unauthorized),
				new Permissions.FlsResult('Test2', Permissions.FlsStatus.Unauthorized)
			});
		Permissions.FlsResults r10 = new Permissions.FlsResults(
			Permissions.FlsAccess.Unencrypted,
			false,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.OK),
			new List<Permissions.FlsResult> {
				new Permissions.FlsResult('Test1', Permissions.FlsStatus.Unauthorized),
				new Permissions.FlsResult('Test2', Permissions.FlsStatus.Unauthorized)
			});
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(!r1.isAuthorized);
		System.assertEquals(0, r1.filterUnauthorizedFields().size());
		System.assertEquals(Label.CannotQueryObject + ' ' + Label.Unknown, r1.getErrorMessage());
		System.assertNotEquals(null, r2);
		System.assert(!r2.isAuthorized);
		System.assertEquals(1, r2.filterUnauthorizedFields().size());
		System.assertEquals(Label.CannotDeleteObject + ' Unit', r2.getErrorMessage());
		System.assertNotEquals(null, r3);
		System.assert(!r3.isAuthorized);
		System.assertEquals(1, r3.filterUnauthorizedFields().size());
		System.assertEquals(String.format(Label.CannotCreateFields_2, new List<String> { 'Unit', 'Test1' }), r3.getErrorMessage());
		System.assertNotEquals(null, r4);
		System.assert(r4.isAuthorized);
		System.assertEquals(0, r4.filterUnauthorizedFields().size());
		System.assertEquals('', r4.getErrorMessage());
		System.assertNotEquals(null, r5);
		System.assert(!r5.isAuthorized);
		System.assertEquals(0, r5.filterUnauthorizedFields().size());
		System.assertEquals(Label.CannotCreateObject + ' Unit', r5.getErrorMessage());
		System.assertNotEquals(null, r6);
		System.assert(!r6.isAuthorized);
		System.assertEquals(0, r6.filterUnauthorizedFields().size());
		System.assertEquals(Label.CannotUpdateObject + ' Unit', r6.getErrorMessage());
		System.assertNotEquals(null, r7);
		System.assert(!r7.isAuthorized);
		System.assertEquals(1, r7.filterUnauthorizedFields().size());
		System.assertEquals(String.format(Label.CannotUpdateFields_2, new List<String> { 'Unit', 'Test1 (NotFound)' }), r7.getErrorMessage());
		System.assertNotEquals(null, r8);
		System.assert(!r8.isAuthorized);
		System.assertEquals(2, r8.filterUnauthorizedFields().size());
		System.assertEquals(String.format(Label.CannotQueryFields_2, new List<String> { 'Unit', 'Test1, Test2' }), r8.getErrorMessage());
		System.assert(!r9.isAuthorized);
		System.assertEquals(2, r9.filterUnauthorizedFields().size());
		System.assertEquals(String.format(Label.CannotFilterFields_2, new List<String> { 'Unit', 'Test1, Test2' }), r9.getErrorMessage());
		System.assert(!r10.isAuthorized);
		System.assertEquals(2, r10.filterUnauthorizedFields().size());
		System.assertEquals(String.format(Label.EncryptedFields_2, new List<String> { 'Unit', 'Test1, Test2' }), r10.getErrorMessage());
	}

	@IsTest
	static void test_getFlsResult_authorized() {
		User u = UserMock.createDocuSignAdministrator();
		Permissions.FlsResult r1, r2, r3, r4, r5, r6, r7;

		Test.startTest();
		System.runAs(u) {
			DescribeFieldResult dfr = Permissions.describeField(OBJECT_NAME, FIELD_NAME, OBJECT_TYPE.getDescribe().fields.getMap().get(FIELD_NAME));
			r1 = Permissions.getFlsResult(Permissions.FlsAccess.Createable, FIELD_NAME, dfr);
			r2 = Permissions.getFlsResult(Permissions.FlsAccess.Queryable, FIELD_NAME, dfr);
			r3 = Permissions.getFlsResult(Permissions.FlsAccess.Updateable, FIELD_NAME, dfr);
			r4 = Permissions.getFlsResult(Permissions.FlsAccess.Createable, OBJECT_NAME, OBJECT_TYPE.getDescribe());
			r5 = Permissions.getFlsResult(Permissions.FlsAccess.Queryable, OBJECT_NAME, OBJECT_TYPE.getDescribe());
			r6 = Permissions.getFlsResult(Permissions.FlsAccess.Updateable, OBJECT_NAME, OBJECT_TYPE.getDescribe());
			r7 = Permissions.getFlsResult(Permissions.FlsAccess.Deletable, OBJECT_NAME, OBJECT_TYPE.getDescribe());
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(r2.isAuthorized);
		System.assertNotEquals(null, r3);
		System.assert(r3.isAuthorized);
		System.assertNotEquals(null, r4);
		System.assert(r4.isAuthorized);
		System.assertNotEquals(null, r5);
		System.assert(r5.isAuthorized);
		System.assertNotEquals(null, r6);
		System.assert(r6.isAuthorized);
		System.assertNotEquals(null, r7);
		System.assert(r7.isAuthorized);
	}

	@IsTest
	static void test_getFlsResult_unauthorized() {
		Permissions.FlsResult r1, r2, r3, r4, r5, r6, r7;

		Test.startTest();
		System.runAs(UserMock.createRestrictedUser()) {
			DescribeFieldResult dfr = Permissions.describeField(OBJECT_NAME, FIELD_NAME, OBJECT_TYPE.getDescribe().fields.getMap().get(FIELD_NAME));
			r1 = Permissions.getFlsResult(Permissions.FlsAccess.Createable, FIELD_NAME, dfr);
			r2 = Permissions.getFlsResult(Permissions.FlsAccess.Queryable, FIELD_NAME, dfr);
			r3 = Permissions.getFlsResult(Permissions.FlsAccess.Updateable, FIELD_NAME, dfr);
			r4 = Permissions.getFlsResult(Permissions.FlsAccess.Createable, OBJECT_NAME, OBJECT_TYPE.getDescribe());
			r5 = Permissions.getFlsResult(Permissions.FlsAccess.Queryable, OBJECT_NAME, OBJECT_TYPE.getDescribe());
			r6 = Permissions.getFlsResult(Permissions.FlsAccess.Updateable, OBJECT_NAME, OBJECT_TYPE.getDescribe());
			r7 = Permissions.getFlsResult(Permissions.FlsAccess.Deletable, OBJECT_NAME, OBJECT_TYPE.getDescribe());
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(!r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(!r2.isAuthorized);
		System.assertNotEquals(null, r3);
		System.assert(!r3.isAuthorized);
		System.assertNotEquals(null, r4);
		System.assert(!r4.isAuthorized);
		System.assertNotEquals(null, r5);
		System.assert(!r5.isAuthorized);
		System.assertNotEquals(null, r6);
		System.assert(!r6.isAuthorized);
		System.assertNotEquals(null, r7);
		System.assert(!r7.isAuthorized);
	}

	@IsTest
	static void test_getFlsResults_authorized() {
		User u = UserMock.createDocuSignAdministrator();
		Permissions.FlsResults r1, r2, r3, r4, r5, r6, r7, r8, r9;

		Test.startTest();
		System.runAs(u) {
			Map<String, SObjectField> fieldMap = OBJECT_TYPE.getDescribe().fields.getMap();
			r1 = Permissions.getFlsResults(Permissions.FlsAccess.Createable, null, null);
			r2 = Permissions.getFlsResults(Permissions.FlsAccess.Createable, OBJECT_TYPE, null);
			r3 = Permissions.getFlsResults(Permissions.FlsAccess.Createable, OBJECT_TYPE, new List<String> { FIELD_NAME });
			r4 = Permissions.getFlsResults(Permissions.FlsAccess.Queryable, OBJECT_TYPE, new List<String> { FIELD_NAME });
			r5 = Permissions.getFlsResults(Permissions.FlsAccess.Updateable, OBJECT_TYPE, new List<String> { FIELD_NAME });
			r6 = Permissions.getFlsResults(Permissions.FlsAccess.Deletable, OBJECT_TYPE, null);
			r7 = Permissions.getFlsResults(Permissions.FlsAccess.Queryable, null, OBJECT_TYPE.getDescribe(), null, fieldMap);
			r8 = Permissions.getFlsResults(Permissions.FlsAccess.Deletable, null, null);
			r9 = Permissions.getFlsResults(Permissions.FlsAccess.Queryable, OBJECT_NAME, OBJECT_TYPE.getDescribe(), new List<String> { '' }, fieldMap);
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(!r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(r2.isAuthorized);
		System.assertNotEquals(null, r3);
		System.assert(r3.isAuthorized);
		System.assertNotEquals(null, r4);
		System.assert(r4.isAuthorized);
		System.assertNotEquals(null, r5);
		System.assert(r5.isAuthorized);
		System.assertNotEquals(null, r6);
		System.assert(r6.isAuthorized);
		System.assertNotEquals(null, r7);
		System.assert(!r7.isAuthorized);
		System.assertNotEquals(null, r8);
		System.assert(!r8.isAuthorized);
		System.assertNotEquals(null, r9);
		System.assert(!r9.isAuthorized);
	}

	@IsTest
	static void test_getFlsResults_unauthorized() {
		User u = UserMock.createRestrictedUser();
		Permissions.FlsResults r1, r2, r3, r4, r5, r6, r7, r8, r9, r10;

		Test.startTest();
		System.runAs(u) {
			Map<String, SObjectField> fieldMap = OBJECT_TYPE.getDescribe().fields.getMap();
			r1 = Permissions.getFlsResults(Permissions.FlsAccess.Createable, null, null);
			r2 = Permissions.getFlsResults(Permissions.FlsAccess.Createable, OBJECT_TYPE, null);
			r3 = Permissions.getFlsResults(Permissions.FlsAccess.Createable, OBJECT_TYPE, new List<String> { FIELD_NAME });
			r4 = Permissions.getFlsResults(Permissions.FlsAccess.Queryable, OBJECT_TYPE, new List<String> { FIELD_NAME });
			r5 = Permissions.getFlsResults(Permissions.FlsAccess.Updateable, OBJECT_TYPE, new List<String> { FIELD_NAME });
			r6 = Permissions.getFlsResults(Permissions.FlsAccess.Deletable, OBJECT_TYPE, null);
			r7 = Permissions.getFlsResults(Permissions.FlsAccess.Queryable, null, OBJECT_TYPE.getDescribe(), null, fieldMap);
			r8 = Permissions.getFlsResults(Permissions.FlsAccess.Deletable, null, null);
			r9 = Permissions.getFlsResults(Permissions.FlsAccess.Queryable, OBJECT_NAME, OBJECT_TYPE.getDescribe(), new List<String> { '' }, fieldMap);
			r10 = Permissions.getFlsResults(Permissions.FlsAccess.Queryable, OBJECT_NAME, OBJECT_TYPE.getDescribe(), new List<String> { 'Invalid__c' }, fieldMap);
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(!r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(!r2.isAuthorized);
		System.assertNotEquals(null, r3);
		System.assert(!r3.isAuthorized);
		System.assertNotEquals(null, r4);
		System.assert(!r4.isAuthorized);
		System.assertNotEquals(null, r5);
		System.assert(!r5.isAuthorized);
		System.assertNotEquals(null, r6);
		System.assert(!r6.isAuthorized);
		System.assertNotEquals(null, r7);
		System.assert(!r7.isAuthorized);
		System.assertNotEquals(null, r8);
		System.assert(!r8.isAuthorized);
		System.assertNotEquals(null, r9);
		System.assert(!r9.isAuthorized);
		System.assertNotEquals(null, r10);
		System.assert(!r10.isAuthorized);
	}

	@IsTest
	static void test_formatIdPointingField() {
		Test.startTest();
		System.assertEquals('testid', Permissions.formatIdPointingField('TEST'));
		Test.stopTest();
	}

	@IsTest
	static void test_isCreateable_authorized() {
		User u = UserMock.createDocuSignUser();
		Permissions.FlsResults r1, r2;

		Test.startTest();
		System.runAs(u) {
			r1 = Permissions.isCreateable(OBJECT_TYPE, null);
			r2 = Permissions.isCreateable(OBJECT_TYPE, new List<String> { FIELD_NAME });
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(r2.isAuthorized);
	}

	@IsTest
	static void test_isCreateable_unauthorized() {
		User u = UserMock.createRestrictedUser();
		Permissions.FlsResults r1, r2;

		Test.startTest();
		System.runAs(u) {
			r1 = Permissions.isCreateable(OBJECT_TYPE, null);
			r2 = Permissions.isCreateable(OBJECT_TYPE, new List<String> { FIELD_NAME });
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(!r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(!r2.isAuthorized);
	}

	@IsTest
	static void test_verifyIsCreateable_authorized() {
		User u = UserMock.createDocuSignUser();
		UnauthorizedException ex1, ex2;

		Test.startTest();
		System.runAs(u) {
			try {
				Permissions.verifyIsCreateable(OBJECT_TYPE, null);
			} catch (UnauthorizedException ex) {
				ex1 = ex;
			}
			try {
				Permissions.verifyIsCreateable(OBJECT_TYPE, new List<String> { FIELD_NAME });
			} catch (UnauthorizedException ex) {
				ex2 = ex;
			}
		}
		Test.stopTest();

		System.assertEquals(null, ex1);
		System.assertEquals(null, ex2);
	}

	@IsTest
	static void test_verifyIsCreateable_unauthorized() {
		User u = UserMock.createRestrictedUser();
		UnauthorizedException ex1, ex2;

		Test.startTest();
		System.runAs(u) {
			try {
				Permissions.verifyIsCreateable(OBJECT_TYPE, null);
				throw new AssertException('Expected verifyIsCreateable to throw exception');
			} catch (UnauthorizedException ex) {
				ex1 = ex;
			}
			try {
				Permissions.verifyIsCreateable(OBJECT_TYPE, new List<String> { FIELD_NAME });
				throw new AssertException('Expected verifyIsCreateable to throw exception');
			} catch (UnauthorizedException ex) {
				ex2 = ex;
			}
		}
		Test.stopTest();

		System.assertNotEquals(null, ex1);
		System.assertEquals(Label.CannotCreateObject + ' ' + OBJECT_NAME, ex1.getMessage());
		System.assertNotEquals(null, ex2);
		System.assertEquals(Label.CannotCreateObject + ' ' + OBJECT_NAME, ex1.getMessage());
	}

	@IsTest
	static void test_isDeletable_authorized() {
		User u = UserMock.createDocuSignUser();
		Permissions.FlsResults r1, r2;

		Test.startTest();
		System.runAs(u) {
			r1 = Permissions.isDeletable(null);
			r2 = Permissions.isDeletable(OBJECT_TYPE);
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(!r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(r2.isAuthorized);
	}

	@IsTest
	static void test_isDeletable_unauthorized() {
		User u = UserMock.createRestrictedUser();
		Permissions.FlsResults r1, r2;

		Test.startTest();
		System.runAs(u) {
			r1 = Permissions.isDeletable(null);
			r2 = Permissions.isDeletable(OBJECT_TYPE);
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(!r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(!r2.isAuthorized);
	}

	@IsTest
	static void test_verifyIsDeletable_authorized() {
		User u = UserMock.createDocuSignUser();
		UnauthorizedException ex1, ex2;

		Test.startTest();
		System.runAs(u) {
			try {
				Permissions.verifyIsDeletable(null);
			} catch (UnauthorizedException ex) {
				ex1 = ex;
			}
			try {
				Permissions.verifyIsDeletable(OBJECT_TYPE);
			} catch (UnauthorizedException ex) {
				ex2 = ex;
			}
		}
		Test.stopTest();

		System.assertNotEquals(null, ex1);
		System.assertEquals(Label.CannotDeleteObject + ' ' + Label.Unknown, ex1.getMessage());
		System.assertEquals(null, ex2);
	}

	@IsTest
	static void test_verifyIsDeletable_unauthorized() {
		User u = UserMock.createRestrictedUser();
		UnauthorizedException ex1, ex2;

		Test.startTest();
		System.runAs(u) {
			try {
				Permissions.verifyIsDeletable(null);
			} catch (UnauthorizedException ex) {
				ex1 = ex;
			}
			try {
				Permissions.verifyIsDeletable(OBJECT_TYPE);
			} catch (UnauthorizedException ex) {
				ex2 = ex;
			}
		}
		Test.stopTest();

		System.assertNotEquals(null, ex1);
		System.assertEquals(Label.CannotDeleteObject + ' ' + Label.Unknown, ex1.getMessage());
		System.assertNotEquals(null, ex2);
		System.assertEquals(Label.CannotDeleteObject + ' ' + OBJECT_NAME, ex2.getMessage());
	}

	@IsTest
	static void test_isQueryable_authorized() {
		User u = UserMock.createDocuSignUser();
		Permissions.FlsResults r1, r2;

		Test.startTest();
		System.runAs(u) {
			r1 = Permissions.isQueryable(OBJECT_TYPE, null);
			r2 = Permissions.isQueryable(OBJECT_TYPE, new List<String> { FIELD_NAME });
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(r2.isAuthorized);
	}

	@IsTest
	static void test_isQueryable_unauthorized() {
		User u1 = UserMock.createRestrictedUser();
		User u2 = UserMock.createDocuSignUser();
		Permissions.FlsResults r1, r2;

		Test.startTest();
		System.runAs(u1) {
			r1 = Permissions.isQueryable(OBJECT_TYPE);
		}
		System.runAs(u2) {
			r2 = Permissions.isQueryable(OBJECT_TYPE, new List<String> { 'Invalid__c' });
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(!r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(!r2.isAuthorized);
	}

	@IsTest
	static void test_verifyIsQueryable_authorized() {
		User u = UserMock.createDocuSignUser();
		UnauthorizedException ex1, ex2;

		Test.startTest();
		System.runAs(u) {
			try {
				Permissions.verifyIsQueryable(OBJECT_TYPE);
			} catch (UnauthorizedException ex) {
				ex1 = ex;
			}
			try {
				Permissions.verifyIsQueryable(OBJECT_TYPE, new List<String> { FIELD_NAME });
			} catch (UnauthorizedException ex) {
				ex2 = ex;
			}
		}
		Test.stopTest();

		System.assertEquals(null, ex1);
		System.assertEquals(null, ex2);
	}

	@IsTest
	static void test_verifyIsQueryable_unauthorized() {
		User u1 = UserMock.createRestrictedUser();
		User u2 = UserMock.createDocuSignUser();
		UnauthorizedException ex1, ex2;

		Test.startTest();
		System.runAs(u1) {
			try {
				Permissions.verifyIsQueryable(OBJECT_TYPE, null);
			} catch (UnauthorizedException ex) {
				ex1 = ex;
			}
		}
		System.runAs(u2) {
			try {
				Permissions.verifyIsQueryable(OBJECT_TYPE, new List<String> { 'Invalid__c' });
			} catch (UnauthorizedException ex) {
				ex2 = ex;
			}
		}
		Test.stopTest();

		System.assertNotEquals(null, ex1);
		System.assertEquals(Label.CannotQueryObject + ' ' + OBJECT_NAME, ex1.getMessage());
		System.assertNotEquals(null, ex2);
		System.assertEquals(String.format(Label.CannotQueryFields_2, new List<String> { OBJECT_NAME, 'Invalid__c (NotFound)' }), ex2.getMessage());
	}

	@IsTest
	static void test_isUpdateable_authorized() {
		User u = UserMock.createDocuSignUser();
		Permissions.FlsResults r1, r2;

		Test.startTest();
		System.runAs(u) {
			r1 = Permissions.isUpdateable(OBJECT_TYPE, null);
			r2 = Permissions.isUpdateable(OBJECT_TYPE, new List<String> { FIELD_NAME });
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(r2.isAuthorized);
	}

	@IsTest
	static void test_isUpdateable_unauthorized() {
		User u = UserMock.createRestrictedUser();
		Permissions.FlsResults r1, r2;

		Test.startTest();
		System.runAs(u) {
			r1 = Permissions.isUpdateable(OBJECT_TYPE, null);
			r2 = Permissions.isUpdateable(OBJECT_TYPE, new List<String> { FIELD_NAME });
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(!r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(!r2.isAuthorized);
	}

	@IsTest
	static void test_verifyIsUpdateable_authorized() {
		User u = UserMock.createDocuSignUser();
		UnauthorizedException ex1, ex2;

		Test.startTest();
		System.runAs(u) {
			try {
				Permissions.verifyIsUpdateable(OBJECT_TYPE, null);
			} catch (UnauthorizedException ex) {
				ex1 = ex;
			}
			try {
				Permissions.verifyIsUpdateable(OBJECT_TYPE, new List<String> { FIELD_NAME });
			} catch (UnauthorizedException ex) {
				ex2 = ex;
			}
		}
		Test.stopTest();

		System.assertEquals(null, ex1);
		System.assertEquals(null, ex2);
	}

	@IsTest
	static void test_verifyIsUpdateable_unauthorized() {
		User u1 = UserMock.createRestrictedUser();
		User u2 = UserMock.createDocuSignAdministrator();
		UnauthorizedException ex1, ex2;

		Test.startTest();
		System.runAs(u1) {
			try {
				Permissions.verifyIsUpdateable(OBJECT_TYPE, null);
			} catch (UnauthorizedException ex) {
				ex1 = ex;
			}
		}
		System.runAs(u2) {
			try {
				Permissions.verifyIsUpdateable(OBJECT_TYPE, new List<String> { 'Invalid__c' });
			} catch (UnauthorizedException ex) {
				ex2 = ex;
			}
		}
		Test.stopTest();

		System.assertNotEquals(null, ex1);
		System.assertEquals(Label.CannotUpdateObject + ' ' + OBJECT_NAME, ex1.getMessage());
		System.assertNotEquals(null, ex2);
		System.assertEquals(String.format(Label.CannotUpdateFields_2, new List<String> { OBJECT_NAME, 'Invalid__c (NotFound)' }), ex2.getMessage());
	}

	@IsTest
	static void test_isFilterable_authorized() {
		User u = UserMock.createDocuSignUser();
		Permissions.FlsResults r1, r2;

		Test.startTest();
		System.runAs(u) {
			r1 = Permissions.isFilterable(OBJECT_TYPE, null);
			r2 = Permissions.isFilterable(OBJECT_TYPE, new List<String> { FIELD_NAME });
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(r2.isAuthorized);
	}

//	@IsTest
//	static void test_isFilterable_unauthorized() {
//		// No good way to test this. Would need to toggle Shield/PE on standard fields.
//	}

	@IsTest
	static void test_verifyIsFilterable_authorized() {
		User u = UserMock.createDocuSignUser();
		UnauthorizedException ex1, ex2;

		Test.startTest();
		System.runAs(u) {
			try {
				Permissions.verifyIsFilterable(OBJECT_TYPE, null);
			} catch (UnauthorizedException ex) {
				ex1 = ex;
			}
			try {
				Permissions.verifyIsFilterable(OBJECT_TYPE, new List<String> { FIELD_NAME });
			} catch (UnauthorizedException ex) {
				ex2 = ex;
			}
		}
		Test.stopTest();

		System.assertEquals(null, ex1);
		System.assertEquals(null, ex2);
	}

//	@IsTest
//	static void test_verifyIsFilterable_unauthorized() {
//		// No good way to test this. Would need to toggle Shield/PE on standard fields.
//	}

	@IsTest
	static void test_isUnencrypted_authorized() {
		User u = UserMock.createDocuSignUser();
		Permissions.FlsResults r1, r2;

		Test.startTest();
		System.runAs(u) {
			r1 = Permissions.isUnencrypted(OBJECT_TYPE, null);
			r2 = Permissions.isUnencrypted(OBJECT_TYPE, new List<String> { FIELD_NAME });
		}
		Test.stopTest();

		System.assertNotEquals(null, r1);
		System.assert(r1.isAuthorized);
		System.assertNotEquals(null, r2);
		System.assert(r2.isAuthorized);
	}

//	@IsTest
//	static void test_isUnencrypted_unauthorized() {
//		// No good way to test this. Would need to toggle Shield/PE on standard fields.
//	}

	@IsTest
	static void test_verifyIsUnencrypted_authorized() {
		User u = UserMock.createDocuSignUser();
		UnauthorizedException ex1, ex2;

		Test.startTest();
		System.runAs(u) {
			try {
				Permissions.verifyIsUnencrypted(OBJECT_TYPE, null);
			} catch (UnauthorizedException ex) {
				ex1 = ex;
			}
			try {
				Permissions.verifyIsUnencrypted(OBJECT_TYPE, new List<String> { FIELD_NAME });
			} catch (UnauthorizedException ex) {
				ex2 = ex;
			}
		}
		Test.stopTest();

		System.assertEquals(null, ex1);
		System.assertEquals(null, ex2);
	}

//	@IsTest
//	static void test_verifyIsUnencrypted_unauthorized() {
//		// No good way to test this. Would need to toggle Shield/PE on standard fields.
//	}

	@IsTest
	static void test_assignPermissionSets_invalid_arguments() {
		Test.startTest();
		System.assert(!Permissions.assignPermissionSets(null, new Set<String> { 'whatever' }));
		System.assert(!Permissions.assignPermissionSets(new Set<Id>(), new Set<String> { 'whatever' }));
		System.assert(!Permissions.assignPermissionSets(new Set<Id> { UserInfo.getUserId() }, null));
		System.assert(!Permissions.assignPermissionSets(new Set<Id> { UserInfo.getUserId() }, new Set<String>()));
		Test.stopTest();
	}

	@IsTest
	static void test_assignPermissionSets_ds_administrator() {
		final User testUser = UserMock.createUser();

		Test.startTest();
		// Verify the user doesn't have the permission set before assigning
		System.assert(!Permissions.isDocuSignSender(testUser.Id));
		System.assert(!Permissions.isDocuSignUser(testUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(testUser.Id));
		// Assign docusign user permission set to user
		System.assert(Permissions.assignPermissionSets(new Set<Id> { testUser.Id }, new Set<String> { Permissions.DOCUSIGN_ADMINISTRATOR }));
		// Verify the user has the permission set before assigning
		System.assert(Permissions.isDocuSignSender(testUser.Id));
		System.assert(Permissions.isDocuSignUser(testUser.Id));
		System.assert(Permissions.isDocuSignAdministrator(testUser.Id));
		Test.stopTest();
	}

	@IsTest
	static void test_assignPermissionSets_ds_user() {
		final User testUser = UserMock.createUser();

		Test.startTest();
		// Verify the user doesn't have the permission set before assigning
		System.assert(!Permissions.isDocuSignSender(testUser.Id));
		System.assert(!Permissions.isDocuSignUser(testUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(testUser.Id));
		// Assign docusign user permission set to user
		System.assert(Permissions.assignPermissionSets(new Set<Id> { testUser.Id }, new Set<String> { Permissions.DOCUSIGN_USER }));
		// Verify the user has the permission set before assigning
		System.assert(Permissions.isDocuSignSender(testUser.Id));
		System.assert(Permissions.isDocuSignUser(testUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(testUser.Id));
		Test.stopTest();
	}

	@IsTest
	static void test_assignPermissionSets_ds_sender() {
		final User testUser = UserMock.createUser();

		Test.startTest();
		// Verify the user doesn't have the permission set before assigning
		System.assert(!Permissions.isDocuSignSender(testUser.Id));
		System.assert(!Permissions.isDocuSignUser(testUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(testUser.Id));
		// Assign docusign user permission set to user
		System.assert(Permissions.assignPermissionSets(new Set<Id> { testUser.Id }, new Set<String> { Permissions.DOCUSIGN_SENDER }));
		// Verify the user has the permission set before assigning
		System.assert(Permissions.isDocuSignSender(testUser.Id));
		System.assert(!Permissions.isDocuSignUser(testUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(testUser.Id));
		Test.stopTest();
	}

	@IsTest
	static void test_assignPermissionSets_generator() {
		final User testUser = UserMock.createUser();

		Test.startTest();
		// Verify the user doesn't have the permission set before assigning
		System.assert(!Permissions.isDocuSignGenerator(testUser.Id));
		// Assign permission set to user
		System.assert(Permissions.assignPermissionSets(new Set<Id> { testUser.Id }, new Set<String> { Permissions.DOCUSIGN_GENERATOR }));
		// Verify the user has the permission set before assigning
		System.assert(Permissions.isDocuSignGenerator(testUser.Id));
		Test.stopTest();
	}

	@IsTest
	static void test_assignPermissionSets_negotiator() {
		final User testUser = UserMock.createUser();

		Test.startTest();
		// Verify the user doesn't have the permission set before assigning
		System.assert(!Permissions.isDocuSignNegotiator(testUser.Id));
		// Assign permission set to user
		System.assert(Permissions.assignPermissionSets(new Set<Id> { testUser.Id }, new Set<String> { Permissions.DOCUSIGN_NEGOTIATOR }));
		// Verify the user has the permission set before assigning
		System.assert(Permissions.isDocuSignNegotiator(testUser.Id));
		Test.stopTest();
	}

	@IsTest
	static void test_assignPermissionSets_clm_administrator() {
		User testUser = UserMock.createUser();

		// Verify the user doesn't have the permission set before assigning
		System.assert(!Permissions.isClmAdministrator(testUser.Id));
		System.assert(!Permissions.isClmUser(testUser.Id));
		System.assert(!Permissions.isClmViewer(testUser.Id));

		Test.startTest();
		// Assign permission set to user
		System.assert(Permissions.assignPermissionSets(new Set<Id> { testUser.Id }, new Set<String> { Permissions.CLM_ADMINISTRATOR }));
		Test.stopTest();

		// Verify the user has the permission set after assignment
		System.assert(Permissions.isClmAdministrator(testUser.Id));
		System.assert(Permissions.isClmUser(testUser.Id));
		System.assert(Permissions.isClmViewer(testUser.Id));
	}

	@IsTest
	static void test_assignPermissionSets_clm_user() {
		final User testUser = UserMock.createUser();

		Test.startTest();
		// Verify the user doesn't have the permission set before assigning
		System.assert(!Permissions.isClmAdministrator(testUser.Id));
		System.assert(!Permissions.isClmUser(testUser.Id));
		System.assert(!Permissions.isClmViewer(testUser.Id));
		// Assign permission set to user
		System.assert(Permissions.assignPermissionSets(new Set<Id> { testUser.Id }, new Set<String> { Permissions.CLM_USER }));
		// Verify the user has the permission set after assignment
		System.assert(!Permissions.isClmAdministrator(testUser.Id));
		System.assert(Permissions.isClmUser(testUser.Id));
		System.assert(Permissions.isClmViewer(testUser.Id));
		Test.stopTest();
	}

	@IsTest
	static void test_assignPermissionSets_clm_viewer() {
		final User testUser = UserMock.createUser();

		Test.startTest();
		// Verify the user doesn't have the permission set before assigning
		System.assert(!Permissions.isClmAdministrator(testUser.Id));
		System.assert(!Permissions.isClmUser(testUser.Id));
		System.assert(!Permissions.isClmViewer(testUser.Id));
		// Assign permission set to user
		System.assert(Permissions.assignPermissionSets(new Set<Id> { testUser.Id }, new Set<String> { Permissions.CLM_VIEWER }));
		// Verify the user has the permission set after assignment
		System.assert(!Permissions.isClmAdministrator(testUser.Id));
		System.assert(!Permissions.isClmUser(testUser.Id));
		System.assert(Permissions.isClmViewer(testUser.Id));
		Test.stopTest();
	}

	@IsTest
	static void test_clear() {
		User dsSender = UserMock.createDocuSignSender(false);
		User dsUser = UserMock.createDocuSignUser(false);
		User dsAdmin = UserMock.createDocuSignAdministrator(false);
		User dsGenerator = UserMock.createDocuSignGenerator(false);
		User dsNegotiator = UserMock.createDocuSignNegotiator(false);
		User clmAdmin = UserMock.createClmAdministrator(false);
		User clmSub = UserMock.createClmUser(false);
		User clmGuest = UserMock.createClmViewer(false);
		User nonDocuSignUser = UserMock.createUser();

		System.assert(Permissions.isDocuSignSender(dsSender.Id));
		System.assert(!Permissions.isDocuSignUser(dsSender.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsSender.Id));
		System.assert(Permissions.isDocuSignSender(dsUser.Id));
		System.assert(Permissions.isDocuSignUser(dsUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsUser.Id));
		System.assert(Permissions.isDocuSignSender(dsAdmin.Id));
		System.assert(Permissions.isDocuSignUser(dsAdmin.Id));
		System.assert(Permissions.isDocuSignAdministrator(dsAdmin.Id));
		System.assert(!Permissions.isDocuSignSender(nonDocuSignUser.Id));
		System.assert(!Permissions.isDocuSignUser(nonDocuSignUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(nonDocuSignUser.Id));
		System.assert(Permissions.isDocuSignGenerator(dsGenerator.Id));
		System.assert(Permissions.isDocuSignNegotiator(dsNegotiator.Id));
		System.assert(Permissions.isClmAdministrator(clmAdmin.Id));
		System.assert(Permissions.isClmUser(clmAdmin.Id));
		System.assert(Permissions.isClmViewer(clmAdmin.Id));
		System.assert(!Permissions.isClmAdministrator(clmSub.Id));
		System.assert(Permissions.isClmUser(clmSub.Id));
		System.assert(Permissions.isClmViewer(clmSub.Id));
		System.assert(!Permissions.isClmAdministrator(clmGuest.Id));
		System.assert(!Permissions.isClmUser(clmGuest.Id));
		System.assert(Permissions.isClmViewer(clmGuest.Id));

		Test.startTest();
		Boolean result = Permissions.clear(new Set<Id> {
			dsSender.Id, dsUser.Id, dsAdmin.Id,
			dsGenerator.Id,
			dsNegotiator.Id,
			clmAdmin.Id, clmSub.Id, clmGuest.Id,
			nonDocuSignUser.Id
		});
		Test.stopTest();

		System.assert(result);
		System.assert(!Permissions.isDocuSignSender(dsSender.Id));
		System.assert(!Permissions.isDocuSignUser(dsSender.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsSender.Id));
		System.assert(!Permissions.isDocuSignSender(dsUser.Id));
		System.assert(!Permissions.isDocuSignUser(dsUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsUser.Id));
		System.assert(!Permissions.isDocuSignSender(dsAdmin.Id));
		System.assert(!Permissions.isDocuSignUser(dsAdmin.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsAdmin.Id));
		System.assert(!Permissions.isDocuSignGenerator(dsGenerator.Id));
		System.assert(!Permissions.isDocuSignNegotiator(dsNegotiator.Id));
		System.assert(!Permissions.isClmAdministrator(clmAdmin.Id));
		System.assert(!Permissions.isClmUser(clmAdmin.Id));
		System.assert(!Permissions.isClmViewer(clmAdmin.Id));
		System.assert(!Permissions.isClmAdministrator(clmSub.Id));
		System.assert(!Permissions.isClmUser(clmSub.Id));
		System.assert(!Permissions.isClmViewer(clmSub.Id));
		System.assert(!Permissions.isClmAdministrator(clmGuest.Id));
		System.assert(!Permissions.isClmUser(clmGuest.Id));
		System.assert(!Permissions.isClmViewer(clmGuest.Id));
		System.assert(!Permissions.isDocuSignSender(nonDocuSignUser.Id));
		System.assert(!Permissions.isDocuSignUser(nonDocuSignUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(nonDocuSignUser.Id));
	}

	@IsTest
	static void test_isDocuSignAdministrator() {
		// Create 4 users: 1) no DocuSign permission set, 2) sender DocuSign permission set,
		// 3) user DocuSign permission set, 4) admin DocuSign permission set
		// Verify only #4 is a DocuSign admin
		final User nonDocuSignUser = UserMock.createUser();
		final User dsSender = UserMock.createDocuSignSender(false);
		final User dsUser = UserMock.createDocuSignUser(false);
		final User dsAdmin = UserMock.createDocuSignAdministrator(false);

		Test.startTest();
		System.assert(!Permissions.isDocuSignAdministrator(null));
		System.assert(!Permissions.isDocuSignAdministrator(nonDocuSignUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsSender.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsUser.Id));
		System.assert(Permissions.isDocuSignAdministrator(dsAdmin.Id));
		Permissions.verifyIsDocuSignAdministrator(dsAdmin.Id);
		System.runAs(dsAdmin) {
			System.assert(Permissions.isDocuSignAdministrator());
			Permissions.verifyIsDocuSignAdministrator();
		}
		System.runAs(nonDocuSignUser) {
			try {
				System.assert(!Permissions.isDocuSignAdministrator());
				Permissions.verifyIsDocuSignAdministrator();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
		}
		System.runAs(dsUser) {
			try {
				System.assert(!Permissions.isDocuSignAdministrator());
				Permissions.verifyIsDocuSignAdministrator();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
		}
		System.runAs(dsSender) {
			try {
				System.assert(!Permissions.isDocuSignAdministrator());
				Permissions.verifyIsDocuSignAdministrator();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
		}
		try {
			Permissions.verifyIsDocuSignAdministrator(null);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
		}
		try {
			Permissions.verifyIsDocuSignAdministrator(nonDocuSignUser.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
		}
		try {
			Permissions.verifyIsDocuSignAdministrator(dsUser.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
		}
		try {
			Permissions.verifyIsDocuSignAdministrator(dsSender.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_isDocuSignUser() {
		// Create 4 users: 1) no DocuSign permission set, 2) sender DocuSign permission set,
		// 3) user DocuSign permission set, 4) admin DocuSign permission set
		// Verify only users #3 and #4 are DocuSign users
		final User nonDocuSignUser = UserMock.createUser();
		final User dsSender = UserMock.createDocuSignSender(false);
		final User dsUser = UserMock.createDocuSignUser(false);
		final User dsAdmin = UserMock.createDocuSignAdministrator(false);

		Test.startTest();
		System.assert(!Permissions.isDocuSignUser(null));
		System.assert(!Permissions.isDocuSignUser(nonDocuSignUser.Id));
		System.assert(!Permissions.isDocuSignUser(dsSender.Id));
		System.assert(Permissions.isDocuSignUser(dsUser.Id));
		System.assert(Permissions.isDocuSignUser(dsAdmin.Id));
		try {
			Permissions.verifyIsDocuSignUser(dsSender.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
		}
		Permissions.verifyIsDocuSignUser(dsUser.Id);
		Permissions.verifyIsDocuSignUser(dsAdmin.Id);
		System.runAs(dsSender) {
			try {
				System.assert(!Permissions.isDocuSignUser());
				Permissions.verifyIsDocuSignUser();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
		}
		System.runAs(dsUser) {
			System.assert(Permissions.isDocuSignUser());
			Permissions.verifyIsDocuSignUser();
		}
		System.runAs(dsAdmin) {
			System.assert(Permissions.isDocuSignUser());
			Permissions.verifyIsDocuSignUser();
		}
		System.runAs(nonDocuSignUser) {
			try {
				System.assert(!Permissions.isDocuSignUser());
				Permissions.verifyIsDocuSignUser();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
		}
		try {
			Permissions.verifyIsDocuSignUser(null);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
		}
		try {
			Permissions.verifyIsDocuSignUser(nonDocuSignUser.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_isDocuSignSender() {
		// Create 4 users: 1) no DocuSign permission set, 2) sender DocuSign permission set,
		// 3) user DocuSign permission set, 4) admin DocuSign permission set
		// Verify only users #2, #3, and #4 are DocuSign users
		final User nonDocuSignUser = UserMock.createUser();
		final User dsSender = UserMock.createDocuSignSender(false);
		final User dsUser = UserMock.createDocuSignUser(false);
		final User dsAdmin = UserMock.createDocuSignAdministrator(false);

		Test.startTest();
		System.assert(!Permissions.isDocuSignSender(null));
		System.assert(!Permissions.isDocuSignSender(nonDocuSignUser.Id));
		System.assert(Permissions.isDocuSignSender(dsSender.Id));
		System.assert(Permissions.isDocuSignSender(dsUser.Id));
		System.assert(Permissions.isDocuSignSender(dsAdmin.Id));
		Permissions.verifyIsDocuSignSender(dsSender.Id);
		Permissions.verifyIsDocuSignSender(dsUser.Id);
		Permissions.verifyIsDocuSignSender(dsAdmin.Id);
		System.runAs(dsSender) {
			System.assert(Permissions.isDocuSignSender());
			Permissions.verifyIsDocuSignSender();
		}
		System.runAs(dsUser) {
			System.assert(Permissions.isDocuSignSender());
			Permissions.verifyIsDocuSignSender();
		}
		System.runAs(dsAdmin) {
			System.assert(Permissions.isDocuSignSender());
			Permissions.verifyIsDocuSignSender();
		}
		System.runAs(nonDocuSignUser) {
			try {
				System.assert(!Permissions.isDocuSignUser());
				Permissions.verifyIsDocuSignSender();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
			}
		}
		try {
			Permissions.verifyIsDocuSignSender(null);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
		}
		try {
			Permissions.verifyIsDocuSignSender(nonDocuSignUser.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_isDocuSignGenerator() {
		final User nonDocuSignUser = UserMock.createUser();
		final User dsGenerator = UserMock.createDocuSignGenerator(false);

		Test.startTest();
		System.assert(!Permissions.isDocuSignGenerator(null));
		System.assert(!Permissions.isDocuSignGenerator(nonDocuSignUser.Id));
		System.assert(Permissions.isDocuSignGenerator(dsGenerator.Id));
		Permissions.verifyIsDocuSignGenerator(dsGenerator.Id);
		System.runAs(dsGenerator) {
			System.assert(Permissions.isDocuSignGenerator());
			Permissions.verifyIsDocuSignGenerator();
		}
		System.runAs(nonDocuSignUser) {
			try {
				System.assert(!Permissions.isDocuSignGenerator());
				Permissions.verifyIsDocuSignGenerator();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
		}
		try {
			Permissions.verifyIsDocuSignGenerator(null);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
		}
		try {
			Permissions.verifyIsDocuSignGenerator(nonDocuSignUser.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_isDocuSignNegotiator() {
		final User nonDocuSignUser = UserMock.createUser();
		final User dsNegotiator = UserMock.createDocuSignNegotiator(false);

		Test.startTest();
		System.assert(!Permissions.isDocuSignNegotiator(null));
		System.assert(!Permissions.isDocuSignNegotiator(nonDocuSignUser.Id));
		System.assert(Permissions.isDocuSignNegotiator(dsNegotiator.Id));
		Permissions.verifyIsDocuSignNegotiator(dsNegotiator.Id);
		System.runAs(dsNegotiator) {
			System.assert(Permissions.isDocuSignNegotiator());
			Permissions.verifyIsDocuSignNegotiator();
		}
		System.runAs(nonDocuSignUser) {
			try {
				System.assert(!Permissions.isDocuSignNegotiator());
				Permissions.verifyIsDocuSignNegotiator();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
		}
		try {
			Permissions.verifyIsDocuSignNegotiator(null);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
		}
		try {
			Permissions.verifyIsDocuSignNegotiator(nonDocuSignUser.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_isClmAdministrator() {
		User nonDocuSignUser = UserMock.createUser();
		User clmGuest = UserMock.createClmViewer(false);
		User clmSub = UserMock.createClmUser(false);
		User clmAdmin = UserMock.createClmAdministrator(false);

		Test.startTest();
		System.assert(!Permissions.isClmAdministrator(null));
		System.assert(!Permissions.isClmAdministrator(nonDocuSignUser.Id));
		System.assert(!Permissions.isClmAdministrator(clmGuest.Id));
		System.assert(!Permissions.isClmAdministrator(clmSub.Id));
		System.assert(Permissions.isClmAdministrator(clmAdmin.Id));
		Permissions.verifyIsClmAdministrator(clmAdmin.Id);
		System.runAs(clmAdmin) {
			System.assert(Permissions.isClmAdministrator());
			Permissions.verifyIsClmAdministrator();
		}
		System.runAs(nonDocuSignUser) {
			try {
				System.assert(!Permissions.isClmAdministrator());
				Permissions.verifyIsClmAdministrator();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeClmAdministrator, ex.getMessage());
			}
		}
		System.runAs(clmSub) {
			try {
				System.assert(!Permissions.isClmAdministrator());
				Permissions.verifyIsClmAdministrator();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeClmAdministrator, ex.getMessage());
			}
		}
		System.runAs(clmGuest) {
			try {
				System.assert(!Permissions.isClmAdministrator());
				Permissions.verifyIsClmAdministrator();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeClmAdministrator, ex.getMessage());
			}
		}
		try {
			Permissions.verifyIsClmAdministrator(null);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeClmAdministrator, ex.getMessage());
		}
		try {
			Permissions.verifyIsClmAdministrator(nonDocuSignUser.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeClmAdministrator, ex.getMessage());
		}
		try {
			Permissions.verifyIsClmAdministrator(clmGuest.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeClmAdministrator, ex.getMessage());
		}
		try {
			Permissions.verifyIsClmAdministrator(clmSub.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeClmAdministrator, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_isClmUser() {
		User nonDocuSignUser = UserMock.createUser();
		User clmGuest = UserMock.createClmViewer(false);
		User clmSub = UserMock.createClmUser(false);
		User clmAdmin = UserMock.createClmAdministrator(false);

		Test.startTest();
		System.assert(!Permissions.isClmUser(null));
		System.assert(!Permissions.isClmUser(nonDocuSignUser.Id));
		System.assert(!Permissions.isClmUser(clmGuest.Id));
		System.assert(Permissions.isClmUser(clmSub.Id));
		System.assert(Permissions.isClmUser(clmAdmin.Id));
		Permissions.verifyIsClmUser(clmSub.Id);
		System.runAs(clmAdmin) {
			System.assert(Permissions.isClmUser());
			Permissions.verifyIsClmUser();
		}
		System.runAs(nonDocuSignUser) {
			try {
				System.assert(!Permissions.isClmUser());
				Permissions.verifyIsClmUser();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeClmUser, ex.getMessage());
			}
		}
		System.runAs(clmSub) {
			System.assert(Permissions.isClmUser());
			Permissions.verifyIsClmUser();
		}
		System.runAs(clmGuest) {
			try {
				System.assert(!Permissions.isClmUser());
				Permissions.verifyIsClmUser();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeClmUser, ex.getMessage());
			}
		}
		try {
			Permissions.verifyIsClmUser(null);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeClmUser, ex.getMessage());
		}
		try {
			Permissions.verifyIsClmUser(nonDocuSignUser.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeClmUser, ex.getMessage());
		}
		try {
			Permissions.verifyIsClmUser(clmGuest.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeClmUser, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_isClmViewer() {
		User nonDocuSignUser = UserMock.createUser();
		User clmGuest = UserMock.createClmViewer(false);
		User clmSub = UserMock.createClmUser(false);
		User clmAdmin = UserMock.createClmAdministrator(false);

		Test.startTest();
		System.assert(!Permissions.isClmViewer(null));
		System.assert(!Permissions.isClmViewer(nonDocuSignUser.Id));
		System.assert(Permissions.isClmViewer(clmGuest.Id));
		System.assert(Permissions.isClmUser(clmSub.Id));
		System.assert(Permissions.isClmUser(clmAdmin.Id));
		Permissions.verifyIsClmViewer(clmGuest.Id);
		System.runAs(clmAdmin) {
			System.assert(Permissions.isClmViewer());
			Permissions.verifyIsClmViewer();
		}
		System.runAs(nonDocuSignUser) {
			try {
				System.assert(!Permissions.isClmViewer());
				Permissions.verifyIsClmViewer();
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeClmViewer, ex.getMessage());
			}
		}
		System.runAs(clmSub) {
			System.assert(Permissions.isClmViewer());
			Permissions.verifyIsClmViewer();
		}
		System.runAs(clmGuest) {
			System.assert(Permissions.isClmViewer());
			Permissions.verifyIsClmViewer();
		}
		try {
			Permissions.verifyIsClmViewer(null);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeClmViewer, ex.getMessage());
		}
		try {
			Permissions.verifyIsClmViewer(nonDocuSignUser.Id);
			throw new AssertException('Expected UnauthorizedException');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.MustBeClmViewer, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_isOwner() {
		System.runAs(UserMock.createAdministrator()) {
			final User u1 = UserMock.createDocuSignUser(false);
			final User u2 = UserMock.createDocuSignUser(false);
			final UUID dsEnvelopeId = UUID.randomUUID();
			final Envelope__c envelope = TestUtils.createEnvelope();
			envelope.OwnerId = u1.Id;
			envelope.DocuSignId__c = dsEnvelopeId.toString();
			update envelope;

			Test.startTest();
			System.assert(Permissions.isOwner(new Set<Id> { envelope.Id }, u1.Id));
			System.assert(Permissions.isOwner(new Set<UUID> { dsEnvelopeId }, u1.Id));
			System.assert(!Permissions.isOwner(new Set<Id> { envelope.Id }, u2.Id));
			System.assert(!Permissions.isOwner(new Set<UUID> { dsEnvelopeId }, u2.Id));
			try {
				Permissions.verifyIsOwner(new Set<Id> { envelope.Id }, u2.Id);
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			try {
				Permissions.verifyIsOwner(new Set<UUID> { dsEnvelopeId }, u2.Id);
				throw new AssertException('Expected UnauthorizedException');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			try {
				Permissions.verifyIsOwner(new Set<Id> { u1.Id }, u1.Id);
			} catch (DocuSignException ex) {
				System.assertEquals(Label.EnvelopeNotFound, ex.getMessage());
			}
			System.runAs(u1) {
				System.assert(Permissions.isOwner(envelope.Id));
				System.assert(Permissions.isOwner(new Set<Id> { envelope.Id }));
				System.assert(Permissions.isOwner(dsEnvelopeId));
				System.assert(Permissions.isOwner(new Set<UUID> { dsEnvelopeId }));
				Permissions.verifyIsOwner(envelope.Id);
				Permissions.verifyIsOwner(new Set<Id> { envelope.Id });
				Permissions.verifyIsOwner(dsEnvelopeId);
				Permissions.verifyIsOwner(new Set<UUID> { dsEnvelopeId });
			}
			System.runAs(u2) {
				System.assert(!Permissions.isOwner(envelope.Id));
				System.assert(!Permissions.isOwner(new Set<Id> { envelope.Id }));
				System.assert(!Permissions.isOwner(dsEnvelopeId));
				System.assert(!Permissions.isOwner(new Set<UUID> { dsEnvelopeId }));
				try {
					Permissions.verifyIsOwner(envelope.Id);
					throw new AssertException('Expected UnauthorizedException');
				} catch (UnauthorizedException ex) {
					System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
				}
				try {
					Permissions.verifyIsOwner(new Set<Id> { envelope.Id });
					throw new AssertException('Expected UnauthorizedException');
				} catch (UnauthorizedException ex) {
					System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
				}
				try {
					Permissions.verifyIsOwner(dsEnvelopeId);
					throw new AssertException('Expected UnauthorizedException');
				} catch (UnauthorizedException ex) {
					System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
				}
				try {
					Permissions.verifyIsOwner(new Set<UUID> { dsEnvelopeId });
					throw new AssertException('Expected UnauthorizedException');
				} catch (UnauthorizedException ex) {
					System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
				}
			}
			System.assert(!Permissions.isOwner((Id)null));
			System.assert(!Permissions.isOwner((Set<Id>)null));
			System.assert(!Permissions.isOwner((UUID)null));
			System.assert(!Permissions.isOwner((Set<UUID>)null));
			System.assert(!Permissions.isOwner(new Set<Id> { envelope.Id }, null));
			System.assert(!Permissions.isOwner(new Set<UUID> { dsEnvelopeId }, null));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_reducePermissionSets_invalid() {
		Test.startTest();
		try {
			Permissions.reducePermissionSets(new Set<String> { Permissions.DOCUSIGN_USER, null, Permissions.DOCUSIGN_GENERATOR });
			throw new AssertException('Expected reducePermissionSets to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(String.format(Label.InvalidPermissionSet_1, new List<String> { null }), ex.getMessage());
		}
		try {
			Permissions.reducePermissionSets(new Set<String> { '\t' });
			throw new AssertException('Expected reducePermissionSets to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(String.format(Label.InvalidPermissionSet_1, new List<String> { '\t' }), ex.getMessage());
		}
		try {
			Permissions.reducePermissionSets(new Set<String> { 'BAD', Permissions.DOCUSIGN_GENERATOR });
			throw new AssertException('Expected reducePermissionSets to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(String.format(Label.InvalidPermissionSet_1, new List<String> { 'BAD' }), ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_reducePermissionSets_valid() {
		Test.startTest();
		Set<String> result = Permissions.reducePermissionSets(new Set<String> {
			Permissions.DOCUSIGN_ADMINISTRATOR,
			Permissions.DOCUSIGN_GENERATOR,
			Permissions.DOCUSIGN_NEGOTIATOR,
			Permissions.CLM_ADMINISTRATOR
		});
		Test.stopTest();

		System.assertEquals(new Set<String> {
			Permissions.DOCUSIGN_ADMINISTRATOR,
			Permissions.DOCUSIGN_GENERATOR,
			Permissions.DOCUSIGN_NEGOTIATOR,
			Permissions.CLM_ADMINISTRATOR
		}, result);
	}

	@IsTest
	static void test_reducePermissionSets_eSignature() {
		Test.startTest();
		Set<String> result1 = Permissions.reducePermissionSets(new Set<String> {
			Permissions.DOCUSIGN_ADMINISTRATOR,
			Permissions.DOCUSIGN_USER
		});
		Set<String> result2 = Permissions.reducePermissionSets(new Set<String> {
			Permissions.DOCUSIGN_USER,
			Permissions.DOCUSIGN_SENDER
		});
		Set<String> result3 = Permissions.reducePermissionSets(new Set<String> {
			Permissions.DOCUSIGN_SENDER
		});
		Test.stopTest();

		System.assertEquals(new Set<String> { Permissions.DOCUSIGN_ADMINISTRATOR }, result1);
		System.assertEquals(new Set<String> { Permissions.DOCUSIGN_USER }, result2);
		System.assertEquals(new Set<String> { Permissions.DOCUSIGN_SENDER }, result3);
	}

	@IsTest
	static void test_reducePermissionSets_clm() {
		Test.startTest();
		Set<String> result1 = Permissions.reducePermissionSets(new Set<String> {
			Permissions.CLM_ADMINISTRATOR,
			Permissions.CLM_USER
		});
		Set<String> result2 = Permissions.reducePermissionSets(new Set<String> {
			Permissions.CLM_USER,
			Permissions.CLM_VIEWER
		});
		Set<String> result3 = Permissions.reducePermissionSets(new Set<String> {
			Permissions.CLM_VIEWER
		});
		Test.stopTest();

		System.assertEquals(new Set<String> { Permissions.CLM_ADMINISTRATOR, Permissions.DOCUSIGN_ADMINISTRATOR }, result1);
		System.assertEquals(new Set<String> { Permissions.CLM_USER }, result2);
		System.assertEquals(new Set<String> { Permissions.CLM_VIEWER }, result3);
	}

	@IsTest
	static void test_getPermissionSetNames_success() {
		Test.startTest();
		Set<String> result = Permissions.getPermissionSetNames(new Map<String, String> {
			Product.ESIGNATURE => ESignatureProduct.ROLE_USER,
			Product.GEN => GenProduct.ROLE_GENERATOR
		});
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(2, result.size());
	}

	@IsTest
	static void test_getPermissionSetNames_failure() {
		Test.startTest();
		try {
			Permissions.getPermissionSetNames(new Map<String, String> {
				'foo' => 'bar'
			});
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UnsupportedProducts, ex.getMessage());
		}
		Test.stopTest();
	}

	static Id getPermissionSetId(final String name) {
		return [
			SELECT Id
			FROM PermissionSet
			WHERE NamespacePrefix = :Application.packageNamespace
			AND Name = :name
			LIMIT 1
		].Id;
	}

	@IsTest
	static void test_updateCurrentUserPermissionSets_update() {
		System.runAs(UserMock.createClmAdministrator(false)) {
			insert new PermissionSetAssignment(
				AssigneeId = UserInfo.getUserId(),
				PermissionSetId = getPermissionSetId(Permissions.DOCUSIGN_GENERATOR));

			Test.startTest();
			System.assert(Permissions.updateCurrentUserPermissionSets(
				new Set<String> {
					Permissions.DOCUSIGN_SENDER,
					Permissions.CLM_VIEWER,
					Permissions.DOCUSIGN_NEGOTIATOR
				}));
			Test.stopTest();

			System.assert(Permissions.isDocuSignAdministrator());
			System.assert(Permissions.isClmAdministrator());
			System.assert(!Permissions.isDocuSignGenerator());
			System.assert(Permissions.isDocuSignNegotiator());

			Set<String> pss = Permissions.getAssignedPermissionSets(UserInfo.getUserId());
			System.assert(!pss.contains(Permissions.DOCUSIGN_USER));
			System.assert(!pss.contains(Permissions.DOCUSIGN_SENDER));
			System.assert(!pss.contains(Permissions.CLM_USER));
			System.assert(!pss.contains(Permissions.CLM_VIEWER));
		}
	}

	@IsTest
	static void test_updateCurrentUserPermissionSets_no_update() {
		System.runAs(UserMock.createClmAdministrator(false)) {
			insert new PermissionSetAssignment(
				AssigneeId = UserInfo.getUserId(),
				PermissionSetId = getPermissionSetId(Permissions.DOCUSIGN_GENERATOR));

			Test.startTest();
			System.assert(!Permissions.updateCurrentUserPermissionSets(
				new Set<String> {
					Permissions.DOCUSIGN_USER,
					Permissions.CLM_USER,
					Permissions.DOCUSIGN_GENERATOR
				}));
			Test.stopTest();

			System.assert(Permissions.isDocuSignAdministrator());
			System.assert(Permissions.isClmAdministrator());
			System.assert(Permissions.isDocuSignGenerator());
			System.assert(!Permissions.isDocuSignNegotiator());

			Set<String> pss = Permissions.getAssignedPermissionSets(UserInfo.getUserId());
			System.assert(!pss.contains(Permissions.DOCUSIGN_USER));
			System.assert(!pss.contains(Permissions.DOCUSIGN_SENDER));
			System.assert(!pss.contains(Permissions.CLM_USER));
			System.assert(!pss.contains(Permissions.CLM_VIEWER));
		}
	}

	@IsTest
	static void test_replaceRoles_empty() {
		Test.startTest();
		System.assert(!Permissions.replaceRoles(null, null));
		System.assert(!Permissions.replaceRoles(new Set<Id>(), new Map<String, String>()));
		System.assert(!Permissions.replaceRoles(null, new Map<String, String> { Product.CLM => Permissions.CLM_VIEWER }));
		System.assert(!Permissions.replaceRoles(new Set<Id>(), new Map<String, String> { Product.CLM => Permissions.CLM_VIEWER }));
		Test.stopTest();
	}

	@IsTest
	static void test_replaceRoles_non_clm() {
		User dsAdmin = UserMock.createDocuSignAdministrator(false);
		User dsUser = UserMock.createDocuSignAdministrator(false);
		User dsSender = UserMock.createDocuSignAdministrator(false);
		User dsGenerator = UserMock.createDocuSignGenerator(false);
		User dsNegotiator = UserMock.createDocuSignNegotiator(false);
		User nonDSUser = UserMock.createUser();

		System.runAs(UserMock.getAdministrator()) {
			Test.startTest();
			System.assert(Permissions.replaceRoles(new Set<Id> {
				dsAdmin.Id, dsUser.Id, dsSender.Id, dsGenerator.Id, dsNegotiator.Id, nonDSUser.Id
			}, new Map<String, String> {
				Product.ESIGNATURE => ESignatureProduct.ROLE_USER,
				Product.NEGOTIATE => NegotiateProduct.ROLE_NEGOTIATOR
			}));
			Test.stopTest();
		}

		System.assert(!Permissions.isDocuSignAdministrator(dsAdmin.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsSender.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsGenerator.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsNegotiator.Id));
		System.assert(!Permissions.isDocuSignAdministrator(nonDSUser.Id));
		System.assert(Permissions.isDocuSignUser(dsAdmin.Id));
		System.assert(Permissions.isDocuSignUser(dsUser.Id));
		System.assert(Permissions.isDocuSignUser(dsSender.Id));
		System.assert(Permissions.isDocuSignUser(dsGenerator.Id));
		System.assert(Permissions.isDocuSignUser(dsNegotiator.Id));
		System.assert(Permissions.isDocuSignUser(nonDSUser.Id));
		System.assert(Permissions.isDocuSignSender(dsAdmin.Id));
		System.assert(Permissions.isDocuSignSender(dsUser.Id));
		System.assert(Permissions.isDocuSignSender(dsSender.Id));
		System.assert(Permissions.isDocuSignSender(dsGenerator.Id));
		System.assert(Permissions.isDocuSignSender(dsNegotiator.Id));
		System.assert(Permissions.isDocuSignSender(nonDSUser.Id));
		System.assert(!Permissions.isDocuSignGenerator(dsAdmin.Id));
		System.assert(!Permissions.isDocuSignGenerator(dsUser.Id));
		System.assert(!Permissions.isDocuSignGenerator(dsSender.Id));
		System.assert(!Permissions.isDocuSignGenerator(dsGenerator.Id));
		System.assert(!Permissions.isDocuSignGenerator(dsNegotiator.Id));
		System.assert(!Permissions.isDocuSignGenerator(nonDSUser.Id));
		System.assert(Permissions.isDocuSignNegotiator(dsAdmin.Id));
		System.assert(Permissions.isDocuSignNegotiator(dsUser.Id));
		System.assert(Permissions.isDocuSignNegotiator(dsSender.Id));
		System.assert(Permissions.isDocuSignNegotiator(dsGenerator.Id));
		System.assert(Permissions.isDocuSignNegotiator(dsNegotiator.Id));
		System.assert(Permissions.isDocuSignNegotiator(nonDSUser.Id));
	}

	@IsTest
	static void test_replaceRoles_clm() {
		User clmAdmin = UserMock.createClmAdministrator(false);
		User clmSub = UserMock.createClmUser(false);
		User clmGuest = UserMock.createClmViewer(false);
		User nonClmUser = UserMock.createUser();

		System.runAs(UserMock.getAdministrator()) {
			Test.startTest();
			System.assert(Permissions.replaceRoles(new Set<Id> {
				clmAdmin.Id, clmSub.Id, clmGuest.Id, nonClmUser.Id
			}, new Map<String, String> {
				Product.CLM => ClmProduct.ROLE_USER
			}));
			Test.stopTest();
		}

		System.assert(!Permissions.isClmAdministrator(clmAdmin.Id));
		System.assert(!Permissions.isClmAdministrator(clmSub.Id));
		System.assert(!Permissions.isClmAdministrator(clmGuest.Id));
		System.assert(!Permissions.isClmAdministrator(nonClmUser.Id));
		System.assert(Permissions.isClmUser(clmAdmin.Id));
		System.assert(Permissions.isClmUser(clmSub.Id));
		System.assert(Permissions.isClmUser(clmGuest.Id));
		System.assert(Permissions.isClmUser(nonClmUser.Id));
		System.assert(Permissions.isClmViewer(clmAdmin.Id));
		System.assert(Permissions.isClmViewer(clmSub.Id));
		System.assert(Permissions.isClmViewer(clmGuest.Id));
		System.assert(Permissions.isClmViewer(nonClmUser.Id));
	}

	@IsTest
	static void test_replace_roles_current_user() {
		System.runAs(UserMock.createClmAdministrator()) {
			insert new PermissionSetAssignment(
				AssigneeId = UserInfo.getUserId(),
				PermissionSetId = getPermissionSetId(Permissions.DOCUSIGN_GENERATOR));

			Test.startTest();
			System.assert(Permissions.replaceRoles(
				new Set<Id> { UserInfo.getUserId() },
				new Map<String, String> {
					Product.ESIGNATURE => ESignatureProduct.ROLE_USER,
					Product.CLM => ClmProduct.ROLE_VIEWER,
					Product.NEGOTIATE => NegotiateProduct.ROLE_NEGOTIATOR
				}));
			Test.stopTest();

			System.assert(Permissions.isDocuSignAdministrator());
			System.assert(Permissions.isClmAdministrator());
			System.assert(!Permissions.isDocuSignGenerator());
			System.assert(Permissions.isDocuSignNegotiator());

			Set<String> pss = Permissions.getAssignedPermissionSets(UserInfo.getUserId());
			System.assert(!pss.contains(Permissions.DOCUSIGN_USER));
			System.assert(!pss.contains(Permissions.DOCUSIGN_SENDER));
			System.assert(!pss.contains(Permissions.CLM_USER));
			System.assert(!pss.contains(Permissions.CLM_VIEWER));
		}
	}

	@IsTest
	static void test_clear_current_user() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			insert new List<PermissionSetAssignment> {
				new PermissionSetAssignment(
					AssigneeId = UserInfo.getUserId(),
					PermissionSetId = getPermissionSetId(Permissions.DOCUSIGN_USER)),
				new PermissionSetAssignment(
					AssigneeId = UserInfo.getUserId(),
					PermissionSetId = getPermissionSetId(Permissions.DOCUSIGN_GENERATOR)),
				new PermissionSetAssignment(
					AssigneeId = UserInfo.getUserId(),
					PermissionSetId = getPermissionSetId(Permissions.CLM_VIEWER))
			};

			Test.startTest();
			System.assert(Permissions.clear(new Set<Id> { UserInfo.getUserId() }));
			Test.stopTest();

			System.assertEquals(new Set<String> { Permissions.DOCUSIGN_ADMINISTRATOR },
				Permissions.getAssignedPermissionSets(UserInfo.getUserId()));
		}
	}

	@IsTest
	static void test_clear_filter_not_current_user() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			User u1 = UserMock.createDocuSignAdministrator(false);
			User u2 = UserMock.createClmUser(false);

			Test.startTest();
			System.assert(Permissions.clear(new Set<Id> { UserInfo.getUserId(), u1.Id, u2.Id }));
			Test.stopTest();

			System.assertEquals(1, Collection.size([
				SELECT Id
				FROM PermissionSetAssignment
				WHERE AssigneeId = :UserInfo.getUserId()
				AND PermissionSet.NamespacePrefix = :Application.packageNamespace
				AND PermissionSet.Name = :Permissions.DOCUSIGN_ADMINISTRATOR
			]));
			System.assertEquals(0, Collection.size([
				SELECT Id
				FROM PermissionSetAssignment
				WHERE AssigneeId = :(NEW Set<Id> { u1.Id, u2.Id })
				AND PermissionSet.NamespacePrefix = :Application.packageNamespace
				AND PermissionSet.Name IN :Permissions.VALID_PERMISSION_SETS
			]));
		}
	}

	@IsTest
	static void test_replaceRoles_filter_not_current_user() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			User u1 = UserMock.createDocuSignAdministrator(false);
			User u2 = UserMock.createClmUser(false);

			Test.startTest();
			System.assert(Permissions.replaceRoles(
				new Set<Id> { UserInfo.getUserId(), u1.Id, u2.Id },
				new Map<String, String> {
					Product.NEGOTIATE => NegotiateProduct.ROLE_NEGOTIATOR,
					Product.CLM => ClmProduct.ROLE_VIEWER
				}));
			Test.stopTest();

			System.assertEquals(1, Collection.size([
				SELECT Id
				FROM PermissionSetAssignment
				WHERE AssigneeId = :UserInfo.getUserId()
				AND PermissionSet.NamespacePrefix = :Application.packageNamespace
				AND PermissionSet.Name = :Permissions.DOCUSIGN_ADMINISTRATOR
			]));
			System.assertEquals(0, Collection.size([
				SELECT Id
				FROM PermissionSetAssignment
				WHERE AssigneeId = :(NEW Set<Id> { u1.Id, u2.Id })
				AND PermissionSet.NamespacePrefix = :Application.packageNamespace
				AND PermissionSet.Name IN :(NEW Set<String> {
					Permissions.DOCUSIGN_ADMINISTRATOR,
					Permissions.CLM_USER
				})
			]));
			System.assertEquals(4, Collection.size([
				SELECT Id
				FROM PermissionSetAssignment
				WHERE AssigneeId = :(NEW Set<Id> { u1.Id, u2.Id })
				AND PermissionSet.NamespacePrefix = :Application.packageNamespace
				AND PermissionSet.Name IN :(NEW Set<String> {
					Permissions.DOCUSIGN_NEGOTIATOR,
					Permissions.CLM_VIEWER
				})
			]));
		}
	}

	@IsTest
	static void test_filterNotCurrentUserId() {
		System.runAs(UserMock.getAdministrator()) {
			Id u0 = UserInfo.getUserId();
			Id u1 = UserMock.createUser().Id;
			Id u2 = UserMock.createUser().Id;

			Test.startTest();
			System.assertEquals(new Set<Id>(), Permissions.filterNotCurrentUserId(null));
			System.assertEquals(new Set<Id> { u1, u2 }, Permissions.filterNotCurrentUserId(new Set<Id> { u1, u2 }));
			System.assertEquals(new Set<Id> { u1, u2 }, Permissions.filterNotCurrentUserId(new Set<Id> { u0, u1, u2 }));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_verifyMaximumBatchSize() {
		System.runAs(UserMock.getAdministrator()) {
			Id u0 = UserInfo.getUserId();
			Id u1 = UserMock.createUser().Id;
			Id u2 = UserMock.createUser().Id;
			Set<Id> ids = new Set<Id> { u0, u1, u2 };

			Test.startTest();
			System.assertEquals(ids, Permissions.verifyMaximumBatchSize(ids, null));
			System.assertEquals(ids, Permissions.verifyMaximumBatchSize(ids, -1));
			System.assertEquals(ids, Permissions.verifyMaximumBatchSize(ids, 0));
			System.assertEquals(ids, Permissions.verifyMaximumBatchSize(ids, Application.batchLimit));
			System.assertEquals(ids, Permissions.verifyMaximumBatchSize(ids, 3));
			try {
				Permissions.verifyMaximumBatchSize(ids, 2);
				throw new AssertException('Expected verifyMaximumBatchSize to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.MaximumBatchSizeExceeded_2, new List<Object> { 3, 2 }),
					ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getUserRoles() {
		User u1 = UserMock.createDocuSignAdministrator(false);
		User u2 = UserMock.createDocuSignUser(false);
		User u3 = UserMock.createDocuSignSender(false);
		User u4 = UserMock.createDocuSignGenerator(false);
		User u5 = UserMock.createDocuSignNegotiator(false);
		User u6 = UserMock.createClmAdministrator(false);
		User u7 = UserMock.createClmUser(false);
		User u8 = UserMock.createClmViewer(false);
		Set<Id> uIds = new Set<Id> { u1.Id, u2.Id, u3.Id, u4.Id, u5.Id, u6.Id, u7.Id, u8.Id };

		System.runAs(u1) {
			Permissions.assignPermissionSets(
				new Set<Id> { u2.Id },
				new Set<String> { Permissions.DOCUSIGN_SENDER, Permissions.DOCUSIGN_GENERATOR, Permissions.DOCUSIGN_NEGOTIATOR });
		}

		Test.startTest();
		Map<Id, Map<String, String>> result = Permissions.getUserRoles(uIds);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(8, result.size());
		System.assertEquals(uIds, result.keySet());
		System.assertNotEquals(null, result.get(u1.Id));
		System.assertEquals(1, result.get(u1.Id).size());
		System.assertEquals(ESignatureProduct.ROLE_ADMINISTRATOR, result.get(u1.Id).get(Product.ESIGNATURE));
		System.assertNotEquals(null, result.get(u2.Id));
		System.assertEquals(3, result.get(u2.Id).size());
		System.assertEquals(ESignatureProduct.ROLE_USER, result.get(u2.Id).get(Product.ESIGNATURE));
		System.assertEquals(GenProduct.ROLE_GENERATOR, result.get(u2.Id).get(Product.GEN));
		System.assertEquals(NegotiateProduct.ROLE_NEGOTIATOR, result.get(u2.Id).get(Product.NEGOTIATE));
		System.assertNotEquals(null, result.get(u3.Id));
		System.assertEquals(1, result.get(u3.Id).size());
		System.assertEquals(ESignatureProduct.ROLE_SENDER, result.get(u3.Id).get(Product.ESIGNATURE));
		System.assertNotEquals(null, result.get(u4.Id));
		System.assertEquals(1, result.get(u4.Id).size());
		System.assertEquals(GenProduct.ROLE_GENERATOR, result.get(u4.Id).get(Product.GEN));
		System.assertNotEquals(null, result.get(u5.Id));
		System.assertEquals(1, result.get(u5.Id).size());
		System.assertEquals(NegotiateProduct.ROLE_NEGOTIATOR, result.get(u5.Id).get(Product.NEGOTIATE));
		System.assertNotEquals(null, result.get(u6.Id));
		System.assertEquals(2, result.get(u6.Id).size());
		System.assertEquals(ESignatureProduct.ROLE_ADMINISTRATOR, result.get(u6.Id).get(Product.ESIGNATURE));
		System.assertEquals(ClmProduct.ROLE_ADMINISTRATOR, result.get(u6.Id).get(Product.CLM));
		System.assertNotEquals(null, result.get(u7.Id));
		System.assertEquals(1, result.get(u7.Id).size());
		System.assertEquals(ClmProduct.ROLE_USER, result.get(u7.Id).get(Product.CLM));
		System.assertNotEquals(null, result.get(u8.Id));
		System.assertEquals(1, result.get(u8.Id).size());
		System.assertEquals(ClmProduct.ROLE_VIEWER, result.get(u8.Id).get(Product.CLM));
	}

	@IsTest
	static void test_isRoleSuperseded() {
		Test.startTest();
		System.assert(Permissions.isRoleSuperseded(null, null, null));
		System.assert(!Permissions.isRoleSuperseded(null, ESignatureProduct.ROLE_SENDER, ESignatureProduct.ROLE_USER));
		System.assert(!Permissions.isRoleSuperseded(Product.ESIGNATURE, ESignatureProduct.ROLE_SENDER, null));
		System.assert(!Permissions.isRoleSuperseded(Product.ESIGNATURE, ESignatureProduct.ROLE_SENDER, ESignatureProduct.ROLE_SENDER));
		System.assert(Permissions.isRoleSuperseded(Product.ESIGNATURE, null, ESignatureProduct.ROLE_SENDER));
		System.assert(Permissions.isRoleSuperseded(Product.ESIGNATURE, ESignatureProduct.ROLE_SENDER, ESignatureProduct.ROLE_USER));
		System.assert(Permissions.isRoleSuperseded(Product.ESIGNATURE, ESignatureProduct.ROLE_SENDER, ESignatureProduct.ROLE_ADMINISTRATOR));
		System.assert(Permissions.isRoleSuperseded(Product.ESIGNATURE, ESignatureProduct.ROLE_USER, ESignatureProduct.ROLE_ADMINISTRATOR));
		System.assert(!Permissions.isRoleSuperseded(Product.ESIGNATURE, ESignatureProduct.ROLE_ADMINISTRATOR, ESignatureProduct.ROLE_USER));
		System.assert(!Permissions.isRoleSuperseded(Product.ESIGNATURE, ESignatureProduct.ROLE_ADMINISTRATOR, ESignatureProduct.ROLE_SENDER));
		System.assert(!Permissions.isRoleSuperseded(Product.ESIGNATURE, ESignatureProduct.ROLE_USER, ESignatureProduct.ROLE_SENDER));
		System.assert(Permissions.isRoleSuperseded(Product.CLM, ClmProduct.ROLE_VIEWER, ClmProduct.ROLE_USER));
		System.assert(Permissions.isRoleSuperseded(Product.CLM, ClmProduct.ROLE_VIEWER, ClmProduct.ROLE_ADMINISTRATOR));
		System.assert(Permissions.isRoleSuperseded(Product.CLM, ClmProduct.ROLE_USER, ClmProduct.ROLE_ADMINISTRATOR));
		System.assert(!Permissions.isRoleSuperseded(Product.CLM, ClmProduct.ROLE_ADMINISTRATOR, ClmProduct.ROLE_USER));
		System.assert(!Permissions.isRoleSuperseded(Product.CLM, ClmProduct.ROLE_ADMINISTRATOR, ClmProduct.ROLE_VIEWER));
		System.assert(!Permissions.isRoleSuperseded(Product.CLM, ClmProduct.ROLE_USER, ClmProduct.ROLE_VIEWER));
		Test.stopTest();
	}

	@IsTest
	static void test_isImpersonating() {
		Test.startTest();
		Permissions.isImpersonating = true;
		System.assertEquals(true, Permissions.isImpersonating());
		Permissions.isImpersonating = false;
		System.assertEquals(false, Permissions.isImpersonating());
		Test.stopTest();
	}

	@IsTest
	static void test_isImpersonationAllowed() {
		Boolean expected;
		try {
			expected = FeatureManagement.checkPackageBooleanValue('AllowImpersonation');
		} catch (Exception ex) {
			expected = false;
		}

		Test.startTest();
		System.assertEquals(expected, Permissions.isImpersonationAllowed());
		Test.stopTest();
	}

	@IsTest
	static void test_verifyNotImpersonating() {
		Permissions.isImpersonating = true;

		Test.startTest();
		Permissions.allowImpersonation = true;
		Permissions.verifyNotImpersonating();
		Permissions.allowImpersonation = false;
		try {
			Permissions.verifyNotImpersonating();
			throw new AssertException('Expected failure');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.UnauthorizedImpersonation, ex.getMessage());
		}

		Test.stopTest();
	}

	@IsTest
	static void test_getFlsResults_lookups() {
		DescribeSObjectResult oppDesc = Opportunity.getSObjectType().getDescribe();
		DescribeSObjectResult acctDesc = Schema.Account.getSObjectType().getDescribe();

		Test.startTest();
		Permissions.FlsResults result1 = Permissions.getFlsResults(
			Permissions.FlsAccess.Queryable,
			'Opportunity',
			oppDesc,
			new List<String> { 'Name', 'Account', 'Owner' },
			oppDesc.fields.getMap());
		Permissions.FlsResults result2 = Permissions.getFlsResults(
			Permissions.FlsAccess.Queryable,
			'Account',
			acctDesc,
			new List<String> { 'Name', 'Parent', 'MasterRecord', 'Owner' },
			acctDesc.fields.getMap());
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1.isAuthorized);

		System.assertNotEquals(null, result2);
		System.assert(result2.isAuthorized);
	}
}
