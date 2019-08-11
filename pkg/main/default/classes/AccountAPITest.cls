@IsTest
private class AccountAPITest {

	@IsTest
	static void test_getConsoleViewUrl_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			Url u = client.getConsoleViewUrl();
			Test.stopTest();

			System.assertNotEquals(null, u);
		}
	}

	@IsTest
	static void test_getConsoleViewUrl_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getConsoleViewUrl();
				throw new AssertException('Expected getConsoleView call to fail');
			} catch (APIException ex2) {
				ex = ex2;

			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}

	@IsTest
	static void test_getCustomFields_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			List<CustomField> cfs = client.getCustomFields();
			Test.stopTest();

			System.assertNotEquals(null, cfs);
			System.assertEquals(3, cfs.size());
			System.assertEquals('text', cfs[0].type);
			System.assert(cfs[0].isText);
			System.assert(!cfs[0].isList);
			System.assertEquals('textField1', cfs[0].name);
			System.assertEquals('textValue1', cfs[0].value);
			System.assert(!cfs[0].required);
			System.assert(cfs[0].show);
			System.assertEquals('list', cfs[2].type);
			System.assert(!cfs[2].isText);
			System.assert(cfs[2].isList);
			System.assertEquals('listField2', cfs[2].name);
			System.assertEquals('listField2Item2', cfs[2].value);
			System.assertEquals(new List<String> { 'listField2Item1', 'listField2Item2', 'listField2Item3' }, cfs[2].items);
			System.assert(cfs[2].required);
			System.assert(cfs[2].show);
		}
	}

	@IsTest
	static void test_getCustomFields_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();
			APIException ex;

			Test.startTest();
			try {
				client.getCustomFields();
				throw new AssertException('Expected getCustomFields to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}

	@IsTest
	static void test_getDocumentCustomFields_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			List<DocumentCustomField> customTabs = client.getDocumentCustomFields();
			Test.stopTest();

			System.assertNotEquals(null, customTabs);
			System.assertEquals(3, customTabs.size());

			System.assertNotEquals(null, customTabs[0]);
			System.assertNotEquals(null, customTabs[0].id);
			System.assertEquals('Field 1', customTabs[0].label);
			System.assertEquals('text', customTabs[0].type);
			System.assertEquals(null, customTabs[0].mergeField);
			System.assertEquals(new List<String> {
				'one', 'two'
			}, customTabs[0].items);
			System.assertEquals('', customTabs[0].initialValue);
			System.assertNotEquals(null, customTabs[0].options);
			System.assert(!customTabs[0].options.required);
			System.assert(!customTabs[0].options.readOnly);
			System.assert(!customTabs[0].options.shared);
			System.assert(customTabs[0].options.editable);
			System.assert(!customTabs[0].options.includeInEmail);
			System.assertNotEquals(null, customTabs[0].formatting);
			System.assertNotEquals(null, customTabs[0].formatting.font);
			System.assertEquals('default', customTabs[0].formatting.font.family);
			System.assertEquals('default', customTabs[0].formatting.font.color);
			System.assertEquals('default', customTabs[0].formatting.font.size);
			System.assert(!customTabs[0].formatting.font.bold);
			System.assert(!customTabs[0].formatting.font.italic);
			System.assert(!customTabs[0].formatting.font.underline);
			System.assert(!customTabs[0].formatting.masked);
			System.assert(!customTabs[0].formatting.fixedSize);
			System.assertNotEquals(null, customTabs[0].validation);
			System.assertEquals(null, customTabs[0].validation.maximumCharacters);
			System.assertEquals('', customTabs[0].validation.regularExpression);
			System.assertEquals('', customTabs[0].validation.errorMessage);
			System.assertEquals('Field 1 name', customTabs[0].tooltip);
			System.assertEquals('Field 1 anchor', customTabs[0].autoPlaceText);
			System.assertNotEquals(null, customTabs[0].lastModified);

			System.assertNotEquals(null, customTabs[1]);
			System.assertNotEquals(null, customTabs[1].id);
			System.assertEquals('Field 2', customTabs[1].label);
			System.assertEquals('email', customTabs[1].type);
			System.assertNotEquals(null, customTabs[1].mergeField);
			System.assertEquals('Opportunity.Id', customTabs[1].mergeField.path);
			System.assert(!customTabs[1].mergeField.writeBack);
			System.assert(!customTabs[1].mergeField.editable);
			System.assertEquals(new List<String>(), customTabs[1].items);
			System.assertEquals('Field 2 value', customTabs[1].initialValue);
			System.assertNotEquals(null, customTabs[1].options);
			System.assert(customTabs[1].options.required);
			System.assert(customTabs[1].options.readOnly);
			System.assert(customTabs[1].options.shared);
			System.assert(customTabs[1].options.editable);
			System.assert(!customTabs[1].options.includeInEmail);
			System.assertNotEquals(null, customTabs[1].formatting);
			System.assertNotEquals(null, customTabs[1].formatting.font);
			System.assertEquals('tahoma', customTabs[1].formatting.font.family);
			System.assertEquals('brightBlue', customTabs[1].formatting.font.color);
			System.assertEquals('size24', customTabs[1].formatting.font.size);
			System.assert(customTabs[1].formatting.font.bold);
			System.assert(customTabs[1].formatting.font.italic);
			System.assert(customTabs[1].formatting.font.underline);
			System.assert(customTabs[1].formatting.masked);
			System.assert(customTabs[1].formatting.fixedSize);
			System.assertNotEquals(null, customTabs[1].validation);
			System.assertEquals(50, customTabs[1].validation.maximumCharacters);
			System.assertEquals('w+', customTabs[1].validation.regularExpression);
			System.assertEquals('You fail', customTabs[1].validation.errorMessage);
			System.assertEquals('Field 2 name', customTabs[1].tooltip);
			System.assertEquals('', customTabs[1].autoPlaceText);
			System.assertNotEquals(null, customTabs[1].lastModified);

			System.assertNotEquals(null, customTabs[2]);
			System.assertNotEquals(null, customTabs[2].id);
			System.assertEquals('Field 3', customTabs[2].label);
			System.assertEquals('something', customTabs[2].type);
			System.assertNotEquals(null, customTabs[2].mergeField);
			System.assertEquals('Account.Name', customTabs[2].mergeField.path);
			System.assert(customTabs[2].mergeField.writeBack);
			System.assert(customTabs[2].mergeField.editable);
			System.assertEquals(new List<String>(), customTabs[2].items);
			System.assertEquals('', customTabs[2].initialValue);
			System.assertNotEquals(null, customTabs[2].options);
			System.assert(!customTabs[2].options.required);
			System.assert(!customTabs[2].options.readOnly);
			System.assert(!customTabs[2].options.shared);
			System.assert(customTabs[2].options.editable);
			System.assert(!customTabs[2].options.includeInEmail);
			System.assertNotEquals(null, customTabs[2].formatting);
			System.assertNotEquals(null, customTabs[2].formatting.font);
			System.assertEquals('helvetica', customTabs[2].formatting.font.family);
			System.assertEquals('gold', customTabs[2].formatting.font.color);
			System.assertEquals('size11', customTabs[2].formatting.font.size);
			System.assert(customTabs[2].formatting.font.bold);
			System.assert(!customTabs[2].formatting.font.italic);
			System.assert(!customTabs[2].formatting.font.underline);
			System.assert(!customTabs[2].formatting.masked);
			System.assert(!customTabs[2].formatting.fixedSize);
			System.assertNotEquals(null, customTabs[2].validation);
			System.assertEquals(null, customTabs[2].validation.maximumCharacters);
			System.assertEquals('', customTabs[2].validation.regularExpression);
			System.assertEquals('', customTabs[2].validation.errorMessage);
			System.assertEquals('Field 3 name', customTabs[2].tooltip);
			System.assertNotEquals(null, customTabs[2].lastModified);
		}
	}

	@IsTest
	static void test_getDocumentCustomFields_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.getDocumentCustomFields();
				throw new AssertException('Expected getDocumentCustomFields to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}

	@IsTest
	static void test_saveDocumentCustomField_success_create() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			UUID u = client.saveDocumentCustomField(new DocumentCustomField(
				null,
				'',
				'text',
				null,
				null,
				'',
				new DocumentCustomField.Options(),
				new DocumentCustomField.Formatting(),
				new DocumentCustomField.Validation(),
				'',
				'',
				null));
			Test.stopTest();

			System.assertNotEquals(null, u);
		}
	}

	@IsTest
	static void test_saveDocumentCustomField_success_update() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();
			UUID id = UUID.randomUUID();

			Test.startTest();
			UUID u = client.saveDocumentCustomField(new DocumentCustomField(
				id,
				'',
				'text',
				new DocumentCustomField.MergeField(
					'Account.Id',
					false,
					false),
				null,
				'',
				new DocumentCustomField.Options(),
				new DocumentCustomField.Formatting(),
				new DocumentCustomField.Validation(),
				'',
				'',
				null));
			Test.stopTest();

			System.assertEquals(id, u);
		}
	}

	@IsTest
	static void test_saveDocumentCustomField_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.saveDocumentCustomField(new DocumentCustomField(
					UUID.randomUUID(),
					'',
					'text',
					null,
					null,
					'',
					new DocumentCustomField.Options(),
					new DocumentCustomField.Formatting(),
					new DocumentCustomField.Validation(),
					'',
					'',
					null));
				throw new AssertException('Expected saveDocumentCustomField to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}

	@IsTest
	static void test_deleteDocumentCustomField_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();

			Test.startTest();
			Boolean result = client.deleteDocumentCustomField(UUID.randomUUID());
			Test.stopTest();

			System.assert(result);
		}
	}

	@IsTest
	static void test_deleteDocumentCustomField_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignAdministrator()) {
			AccountAPI client = AccountAPI.getInstance();
			APIException ex = null;

			Test.startTest();
			try {
				client.deleteDocumentCustomField(UUID.randomUUID());
				throw new AssertException('Expected deleteDocumentCustomField to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertNotEquals(null, ex.error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
		}
	}
}
