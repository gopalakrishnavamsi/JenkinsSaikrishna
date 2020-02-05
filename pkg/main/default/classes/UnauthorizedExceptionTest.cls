@IsTest(IsParallel = true)
private class UnauthorizedExceptionTest {

	@IsTest
	static void test_notDocuSignAdministrator() {
		Test.startTest();
		final UnauthorizedException ex = UnauthorizedException.notDocuSignAdministrator();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.DocuSignAdministrator, ex.requirement);
	}

	@IsTest
	static void test_notDocuSignUser() {
		Test.startTest();
		final UnauthorizedException ex = UnauthorizedException.notDocuSignUser();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.DocuSignUser, ex.requirement);
	}

	@IsTest
	static void test_notDocuSignSender() {
		Test.startTest();
		final UnauthorizedException ex = UnauthorizedException.notDocuSignSender();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.MustBeDocuSignSender, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.DocuSignSender, ex.requirement);
	}

	@IsTest
	static void test_notDocuSignGenerator() {
		Test.startTest();
		final UnauthorizedException ex = UnauthorizedException.notDocuSignGenerator();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.DocuSignGenerator, ex.requirement);
	}

	@IsTest
	static void test_notDocuSignNegotiator() {
		Test.startTest();
		final UnauthorizedException ex = UnauthorizedException.notDocuSignNegotiator();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.DocuSignNegotiator, ex.requirement);
	}

	@IsTest
	static void test_notClmAdministrator() {
		Test.startTest();
		UnauthorizedException ex = UnauthorizedException.notClmAdministrator();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.MustBeClmAdministrator, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.ClmAdministrator, ex.requirement);
	}

	@IsTest
	static void test_notClmUser() {
		Test.startTest();
		UnauthorizedException ex = UnauthorizedException.notClmUser();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.MustBeClmUser, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.ClmUser, ex.requirement);
	}

	@IsTest
	static void test_notClmViewer() {
		Test.startTest();
		UnauthorizedException ex = UnauthorizedException.notClmViewer();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.MustBeClmViewer, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.ClmViewer, ex.requirement);
	}

	@IsTest
	static void test_notSalesforceAdministrator() {
		Test.startTest();
		final UnauthorizedException ex = UnauthorizedException.notSalesforceAdministrator();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.MustBeAdministrator, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.SalesforceAdministrator, ex.requirement);
	}

	@IsTest
	static void test_notEnvelopeOwner() {
		Test.startTest();
		final UnauthorizedException ex = UnauthorizedException.notEnvelopeOwner();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.EnvelopeOwner, ex.requirement);
	}

	@IsTest
	static void test_mayRequireActivation() {
		Test.startTest();
		final UnauthorizedException ex = UnauthorizedException.mayRequireActivation();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.MustBeActivated, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.DocuSignUser, ex.requirement);
	}

	@IsTest
	static void test_accountNotConfigured() {
		Test.startTest();
		final UnauthorizedException ex = UnauthorizedException.accountNotConfigured();
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
		System.assertEquals(UserInfo.getUserId(), ex.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.ConfigureAccount, ex.requirement);
	}

	@IsTest
	static void test_results() {
		Test.startTest();
		UnauthorizedException ex1 = new UnauthorizedException('', null);
		UnauthorizedException ex2 = new UnauthorizedException('Message1', null);
		UnauthorizedException ex3 = new UnauthorizedException('Message1', new ValidationResult(new List<String> { 'Message2', 'Message3' }));
		UnauthorizedException ex4 = new UnauthorizedException(new Permissions.FlsResults(
			Permissions.FlsAccess.Queryable,
			false,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.OK),
			new List<Permissions.FlsResult> {
				new Permissions.FlsResult('Test1', Permissions.FlsStatus.OK),
				new Permissions.FlsResult('Test2', Permissions.FlsStatus.NotFound)
			}).getErrorMessage());
		Test.stopTest();

		System.assertEquals('', ex1.getMessage());
		System.assertEquals('Message1', ex2.getMessage());
		System.assertEquals('Message1\nMessage2\nMessage3', ex3.getMessage());
		System.assertEquals(String.format(Label.CannotQueryFields_2, new List<String> {
			'Unit', 'Test2 (NotFound)'
		}), ex4.getMessage());
	}

	@IsTest
	static void test_impersonation() {
		Test.startTest();
		UnauthorizedException result = UnauthorizedException.impersonation();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(Label.UnauthorizedImpersonation, result.getMessage());
		System.assertEquals(UserInfo.getUserId(), result.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.OriginalUser, result.requirement);
	}

	@IsTest
	static void test_requirement() {
		Test.startTest();
		UnauthorizedException result = new UnauthorizedException(
			'test',
			UnauthorizedException.AccessRequirement.SecurityPermission);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals('test', result.getMessage());
		System.assertEquals(UserInfo.getUserId(), result.userId);
		System.assertEquals(UnauthorizedException.AccessRequirement.SecurityPermission, result.requirement);

	}
}
