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
			DescribeFieldResult dfr = Permissions.describeField(OBJECT_NAME, FIELD_NAME, fieldMap.get(FIELD_NAME));
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
			DescribeFieldResult dfr = Permissions.describeField(OBJECT_NAME, FIELD_NAME, fieldMap.get(FIELD_NAME));
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
			r1 = Permissions.isQueryable(OBJECT_TYPE, null);
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
				Permissions.verifyIsQueryable(OBJECT_TYPE, null);
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

	@IsTest
	static void test_isFilterable_unauthorized() {
		// No good way to test this. Would need to toggle Shield/PE on standard fields.
	}

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

	@IsTest
	static void test_verifyIsFilterable_unauthorized() {
		// No good way to test this. Would need to toggle Shield/PE on standard fields.
	}

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

	@IsTest
	static void test_isUnencrypted_unauthorized() {
		// No good way to test this. Would need to toggle Shield/PE on standard fields.
	}

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

	@IsTest
	static void test_verifyIsUnencrypted_unauthorized() {
		// No good way to test this. Would need to toggle Shield/PE on standard fields.
	}

	@IsTest
	static void test_getDocuSignAdministratorPermissionSetId() {
		Id id = [
			SELECT Id
			FROM PermissionSet
			WHERE Name = :Permissions.DOCUSIGN_ADMINISTRATOR
			LIMIT 1
		].Id;

		Test.startTest();
		System.assertEquals(id, Permissions.getDocuSignAdministratorPermissionSetId());
		Test.stopTest();
	}

	@IsTest
	static void test_getDocuSignUserPermissionSetId() {
		Id id = [
			SELECT Id
			FROM PermissionSet
			WHERE Name = :Permissions.DOCUSIGN_USER
			LIMIT 1
		].Id;

		Test.startTest();
		System.assertEquals(id, Permissions.getDocuSignUserPermissionSetId());
		Test.stopTest();
	}

	@IsTest
	static void test_assignDocuSignUserPermissionSet() {
		final User testUser = UserMock.createUser();

		Test.startTest();
		// Verify the user doesn't have the permission set before assigning
		System.assert(!Permissions.isDocuSignUser(testUser.Id));
		// Assign docusign user permission set to user
		System.assert(Permissions.assignDocuSignUserPermissionSet(new Set<Id> { testUser.Id }));
		// Verify the user havs the permission set before assigning
		System.assert(Permissions.isDocuSignUser(testUser.Id));
		// Make sure it handles invalid inputs
		System.assert(!Permissions.assignDocuSignUserPermissionSet(null));
		Test.stopTest();
	}

	@IsTest
	static void test_assignDocuSignAdministratorPermissionSet() {
		final User testUser = UserMock.createUser();

		Test.startTest();
		// Verify the user doesn't have the permission set before assigning
		System.assert(!Permissions.isDocuSignAdministrator(testUser.Id));
		// Assign docusign user permission set to user
		System.assert(Permissions.assignDocuSignAdministratorPermissionSet(new Set<Id> { testUser.Id }));
		// Verify the user havs the permission set before assigning
		System.assert(Permissions.isDocuSignAdministrator(testUser.Id));
		// Make sure it handles invalid inputs
		System.assert(!Permissions.assignDocuSignAdministratorPermissionSet(null));
		Test.stopTest();
	}

	@IsTest
	static void test_removeDocuSignPermissionSets() {
		User dsUser = UserMock.createDocuSignUser(false);
		User dsAdmin = UserMock.createDocuSignAdministrator(false);
		User nonDocuSignUser = UserMock.createUser();

		System.assert(Permissions.isDocuSignUser(dsUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsUser.Id));
		System.assert(Permissions.isDocuSignUser(dsAdmin.Id));
		System.assert(Permissions.isDocuSignAdministrator(dsAdmin.Id));
		System.assert(!Permissions.isDocuSignUser(nonDocuSignUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(nonDocuSignUser.Id));

		Test.startTest();
		Boolean result = Permissions.removeDocuSignPermissionSets(new Set<Id> { dsUser.Id, dsAdmin.Id, nonDocuSignUser.Id });
		Test.stopTest();

		System.assert(result);
		System.assert(!Permissions.isDocuSignUser(dsUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsUser.Id));
		System.assert(!Permissions.isDocuSignUser(dsAdmin.Id));
		System.assert(!Permissions.isDocuSignAdministrator(dsAdmin.Id));
		System.assert(!Permissions.isDocuSignUser(nonDocuSignUser.Id));
		System.assert(!Permissions.isDocuSignAdministrator(nonDocuSignUser.Id));
	}

	@IsTest
	static void test_isDocuSignUser() {
		// Create 3 users: 1) no DocuSign permission set, 2) user DocuSign permission set, 3) admin DocuSign permission set
		// Verify only users #2 and #3 are DocuSign users
		final User nonDocuSignUser = UserMock.createUser();
		final User dsUser = UserMock.createDocuSignUser(false);
		final User dsAdmin = UserMock.createDocuSignAdministrator(false);

		Test.startTest();
		System.assert(!Permissions.isDocuSignUser(null));
		System.assert(!Permissions.isDocuSignUser(nonDocuSignUser.Id));
		System.assert(Permissions.isDocuSignUser(dsUser.Id));
		System.assert(Permissions.isDocuSignUser(dsAdmin.Id));
		Permissions.verifyIsDocuSignUser(dsUser.Id);
		Permissions.verifyIsDocuSignUser(dsAdmin.Id);
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
	static void testIsDocuSignAdministrator() {
		// Create 3 users: 1) no DocuSign permission set, 2) user DocuSign permission set, 3) admin DocuSign permission set
		// Verify only user #3 is admin
		final User nonDocuSignUser = UserMock.createUser();
		final User dsUser = UserMock.createUser();
		final User dsAdmin = UserMock.createUser();

		Test.startTest();
		// Assign permission sets.
		Permissions.assignDocuSignUserPermissionSet(new Set<Id> { dsUser.Id });
		Permissions.assignDocuSignAdministratorPermissionSet(new Set<Id> { dsAdmin.Id });

		System.assert(!Permissions.isDocuSignAdministrator(null));
		System.assert(!Permissions.isDocuSignAdministrator(nonDocuSignUser.Id));
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
}
