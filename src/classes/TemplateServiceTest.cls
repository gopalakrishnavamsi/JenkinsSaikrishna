@IsTest
private class TemplateServiceTest {

	@IsTest
	static void test_getTemplates_unauthorized() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				TemplateService.getTemplates();
				throw new AssertException('Expected getTemplates to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplates_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			List<Template> result = TemplateService.getTemplates();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(4, result.size());
		}
	}

	@IsTest
	static void test_getTemplate_unauthorized() {
		System.runAs(TestUtils.createUser()) {
			Test.startTest();
			try {
				TemplateService.getTemplate(UUID.randomUUID());
				throw new AssertException('Expected getTemplate to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplate_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			Template result = TemplateService.getTemplate(UUID.randomUUID());
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}
}
