@IsTest
private class TemplateAPITest {

	@IsTest
	static void test_getTemplate_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			final TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			final Template t = client.getTemplate(UUID.randomUUID());
			Test.stopTest();

			System.assertNotEquals(null, t);
			System.assertEquals(TestUtils.ID1, t.id);
			System.assertEquals('Unit test', t.name);
			System.assertNotEquals(null, t.customFields);
			System.assertEquals(3, t.customFields.size());
			System.assertEquals('textField1', t.customFields[0].name);
			System.assertEquals('textValue1', t.customFields[0].value);
			System.assert(!t.customFields[0].required);
			System.assert(t.customFields[0].show);
			System.assertEquals('listField2', t.customFields[2].name);
			System.assertEquals('listValue2', t.customFields[2].value);
			System.assertEquals(new List<String> { 'listField2Item1', 'listField2Item2', 'listField2Item3' }, t.customFields[2].items);
			System.assert(t.customFields[2].required);
			System.assert(t.customFields[2].show);
		}
	}

	@IsTest
	static void test_getTemplate_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			final TemplateAPI client = TemplateAPI.getInstance();
			APIException ex;

			Test.startTest();
			try {
				client.getTemplate(UUID.randomUUID());
				throw new AssertException('Expected getTemplate to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(404, ex.error.code);
		}
	}

	@IsTest
	static void test_getTemplates_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			final TemplateAPI client = TemplateAPI.getInstance();

			Test.startTest();
			final List<Template> templates = client.getTemplates();
			Test.stopTest();

			System.assertNotEquals(null, templates);
			System.assertEquals(4, templates.size());

			System.assertEquals(TestUtils.ID1, templates[0].id);
			System.assertEquals('Template 1', templates[0].name);
			System.assert(Collection.isEmpty(templates[0].customFields));

			System.assertEquals(TestUtils.ID2, templates[1].id);
			System.assertEquals('Template 2', templates[1].name);
			System.assert(Collection.isEmpty(templates[1].customFields));

			System.assertEquals(TestUtils.ID3, templates[2].id);
			System.assertEquals('Template 3', templates[2].name);
			System.assert(Collection.isEmpty(templates[2].customFields));

			System.assertEquals(TestUtils.ID4, templates[3].id);
			System.assertEquals('Template 4', templates[3].name);
			System.assert(Collection.isEmpty(templates[3].customFields));
		}
	}

	@IsTest
	static void test_getTemplates_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			final TemplateAPI client = TemplateAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getTemplates();
				throw new AssertException('Expected getTemplates to fail');
			} catch (APIException ex1) {
				ex = ex1;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(400, ex.error.code);
		}
	}
}
