@IsTest
private class OnlineEditorControllerTest {

	@IsTest
	static void test_convertFields_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator(true)) {

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Quantity', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('UnitPrice', 'val', 'String'));

			Test.startTest();
			List<String> result = OnlineEditorController.convertFields(onlineEditorFields);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
			System.assertEquals(onlineEditorFields[0].name, result[0]);
			System.assertEquals(onlineEditorFields[1].name, result[1]);
			System.assertEquals(onlineEditorFields[2].name, result[2]);
		}
	}

	@IsTest
	static void test_convertFields_viewer_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator(true)) {

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Quantity', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('UnitPrice', 'val', 'String'));

			Test.startTest();
			List<String> result = OnlineEditorController.convertFields(onlineEditorFields);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
			System.assertEquals(onlineEditorFields[0].name, result[0]);
			System.assertEquals(onlineEditorFields[1].name, result[1]);
			System.assertEquals(onlineEditorFields[2].name, result[2]);
		}
	}

	@IsTest
	static void test_convertQuery_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator(true)) {

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Quantity', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('UnitPrice', 'val', 'String'));

			OnlineEditorController.Query onlineEditorQuery = new OnlineEditorController.Query('Account', '', onlineEditorFields, new List<OnlineEditorController.Query>());

			Test.startTest();
			Gen.Query result = OnlineEditorController.convertQuery(onlineEditorQuery);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(onlineEditorQuery.type, result.type);
			System.assertEquals(onlineEditorQuery.relationship, result.relationship);
			System.assertEquals(onlineEditorQuery.fields[0].name, result.fields[0]);
			System.assertEquals(onlineEditorQuery.fields[1].name, result.fields[1]);
			System.assertEquals(onlineEditorQuery.fields[2].name, result.fields[2]);
			System.assert(Collection.isEmpty(result.children));
		}
	}

	@IsTest
	static void test_convertQuery_viewer_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator(true)) {

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Quantity', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('UnitPrice', 'val', 'String'));

			OnlineEditorController.Query onlineEditorQuery = new OnlineEditorController.Query('Account', '', onlineEditorFields, new List<OnlineEditorController.Query>());

			Test.startTest();
			Gen.Query result = OnlineEditorController.convertQuery(onlineEditorQuery);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(onlineEditorQuery.type, result.type);
			System.assertEquals(onlineEditorQuery.relationship, result.relationship);
			System.assertEquals(onlineEditorQuery.fields[0].name, result.fields[0]);
			System.assertEquals(onlineEditorQuery.fields[1].name, result.fields[1]);
			System.assertEquals(onlineEditorQuery.fields[2].name, result.fields[2]);
			System.assert(Collection.isEmpty(result.children));
		}
	}

	@IsTest
	static void test_convertQuery2_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator(true)) {

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Quantity', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('UnitPrice', 'val', 'String'));

			List<OnlineEditorController.Field> onlineEditorFieldsChild = new List<OnlineEditorController.Field>();
			onlineEditorFieldsChild.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild.add(new OnlineEditorController.Field('Name', 'val', 'String'));
			onlineEditorFieldsChild.add(new OnlineEditorController.Field('BillingCity', 'val', 'String'));

			OnlineEditorController.Query onlineEditorQueryChild = new OnlineEditorController.Query('Opportunity', 'Opportunities', onlineEditorFieldsChild, new List<OnlineEditorController.Query>());
			OnlineEditorController.Query onlineEditorQuery = new OnlineEditorController.Query('Account', '', onlineEditorFields, new List<OnlineEditorController.Query> { onlineEditorQueryChild });

			Test.startTest();
			Gen.Query result = OnlineEditorController.convertQuery(onlineEditorQuery);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(onlineEditorQuery.type, result.type);
			System.assertEquals(onlineEditorQuery.relationship, result.relationship);
			System.assertEquals(onlineEditorQuery.fields[0].name, result.fields[0]);
			System.assertEquals(onlineEditorQuery.fields[1].name, result.fields[1]);
			System.assertEquals(onlineEditorQuery.fields[2].name, result.fields[2]);
			System.assert(Collection.isNotEmpty(result.children));
			System.assertEquals(onlineEditorQuery.children[0].type, result.children[0].type);
			System.assertEquals(onlineEditorQuery.children[0].relationship, result.children[0].relationship);
			System.assertEquals(onlineEditorQuery.children[0].fields[0].name, result.children[0].fields[0]);
			System.assertEquals(onlineEditorQuery.children[0].fields[1].name, result.children[0].fields[1]);
			System.assertEquals(onlineEditorQuery.children[0].fields[2].name, result.children[0].fields[2]);
			System.assert(Collection.isEmpty(result.children[0].children));
		}
	}

	@IsTest
	static void test_convertQuery2_viewer_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator(true)) {

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Quantity', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('UnitPrice', 'val', 'String'));

			List<OnlineEditorController.Field> onlineEditorFieldsChild = new List<OnlineEditorController.Field>();
			onlineEditorFieldsChild.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild.add(new OnlineEditorController.Field('Name', 'val', 'String'));
			onlineEditorFieldsChild.add(new OnlineEditorController.Field('BillingCity', 'val', 'String'));

			OnlineEditorController.Query onlineEditorQueryChild = new OnlineEditorController.Query('Opportunity', 'Opportunities', onlineEditorFieldsChild, new List<OnlineEditorController.Query>());
			OnlineEditorController.Query onlineEditorQuery = new OnlineEditorController.Query('Account', '', onlineEditorFields, new List<OnlineEditorController.Query> { onlineEditorQueryChild });

			Test.startTest();
			Gen.Query result = OnlineEditorController.convertQuery(onlineEditorQuery);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(onlineEditorQuery.type, result.type);
			System.assertEquals(onlineEditorQuery.relationship, result.relationship);
			System.assertEquals(onlineEditorQuery.fields[0].name, result.fields[0]);
			System.assertEquals(onlineEditorQuery.fields[1].name, result.fields[1]);
			System.assertEquals(onlineEditorQuery.fields[2].name, result.fields[2]);
			System.assert(Collection.isNotEmpty(result.children));
			System.assertEquals(onlineEditorQuery.children[0].type, result.children[0].type);
			System.assertEquals(onlineEditorQuery.children[0].relationship, result.children[0].relationship);
			System.assertEquals(onlineEditorQuery.children[0].fields[0].name, result.children[0].fields[0]);
			System.assertEquals(onlineEditorQuery.children[0].fields[1].name, result.children[0].fields[1]);
			System.assertEquals(onlineEditorQuery.children[0].fields[2].name, result.children[0].fields[2]);
			System.assert(Collection.isEmpty(result.children[0].children));
		}
	}

	@IsTest
	static void test_convertQuery3_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator(true)) {

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Name', 'val', 'String'));

			List<OnlineEditorController.Field> onlineEditorFieldsChild1 = new List<OnlineEditorController.Field>();
			onlineEditorFieldsChild1.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild1.add(new OnlineEditorController.Field('Name', 'val', 'String'));

			List<OnlineEditorController.Field> onlineEditorFieldsChild2 = new List<OnlineEditorController.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Name', 'val', 'String'));

			OnlineEditorController.Query onlineEditorQueryChild1 = new OnlineEditorController.Query('Opportunity', 'Opportunities', onlineEditorFieldsChild1, new List<OnlineEditorController.Query>());
			OnlineEditorController.Query onlineEditorQueryChild2 = new OnlineEditorController.Query('Contact', 'Contacts', onlineEditorFieldsChild2, new List<OnlineEditorController.Query>());
			OnlineEditorController.Query onlineEditorQuery = new OnlineEditorController.Query('Account', '', onlineEditorFields, new List<OnlineEditorController.Query> { onlineEditorQueryChild1, onlineEditorQueryChild2 });

			Test.startTest();
			Gen.Query result = OnlineEditorController.convertQuery(onlineEditorQuery);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(onlineEditorQuery.type, result.type);
			System.assertEquals(onlineEditorQuery.relationship, result.relationship);
			System.assertEquals(onlineEditorQuery.fields[0].name, result.fields[0]);
			System.assertEquals(onlineEditorQuery.fields[1].name, result.fields[1]);
			System.assert(Collection.isNotEmpty(result.children));
			System.assertEquals(onlineEditorQuery.children[0].type, result.children[0].type);
			System.assertEquals(onlineEditorQuery.children[0].relationship, result.children[0].relationship);
			System.assertEquals(onlineEditorQuery.children[0].fields[0].name, result.children[0].fields[0]);
			System.assertEquals(onlineEditorQuery.children[0].fields[1].name, result.children[0].fields[1]);
		}
	}

	@IsTest
	static void test_convertQuery3_viewer_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator(true)) {

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Name', 'val', 'String'));

			List<OnlineEditorController.Field> onlineEditorFieldsChild1 = new List<OnlineEditorController.Field>();
			onlineEditorFieldsChild1.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild1.add(new OnlineEditorController.Field('Name', 'val', 'String'));

			List<OnlineEditorController.Field> onlineEditorFieldsChild2 = new List<OnlineEditorController.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Name', 'val', 'String'));

			OnlineEditorController.Query onlineEditorQueryChild1 = new OnlineEditorController.Query('Opportunity', 'Opportunities', onlineEditorFieldsChild1, new List<OnlineEditorController.Query>());
			OnlineEditorController.Query onlineEditorQueryChild2 = new OnlineEditorController.Query('Contact', 'Contacts', onlineEditorFieldsChild2, new List<OnlineEditorController.Query>());
			OnlineEditorController.Query onlineEditorQuery = new OnlineEditorController.Query('Account', '', onlineEditorFields, new List<OnlineEditorController.Query> { onlineEditorQueryChild1, onlineEditorQueryChild2 });

			Test.startTest();
			Gen.Query result = OnlineEditorController.convertQuery(onlineEditorQuery);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(onlineEditorQuery.type, result.type);
			System.assertEquals(onlineEditorQuery.relationship, result.relationship);
			System.assertEquals(onlineEditorQuery.fields[0].name, result.fields[0]);
			System.assertEquals(onlineEditorQuery.fields[1].name, result.fields[1]);
			System.assert(Collection.isNotEmpty(result.children));
			System.assertEquals(onlineEditorQuery.children[0].type, result.children[0].type);
			System.assertEquals(onlineEditorQuery.children[0].relationship, result.children[0].relationship);
			System.assertEquals(onlineEditorQuery.children[0].fields[0].name, result.children[0].fields[0]);
			System.assertEquals(onlineEditorQuery.children[0].fields[1].name, result.children[0].fields[1]);
		}
	}

	@IsTest
	static void test_getMergeData_success2() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			TestUtils.createOpportunityContactRole(o.Id, c1.Id);
			TestUtils.createOpportunityContactRole(o.Id, c2.Id);

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Name', '', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Account.Name', '', 'String'));

			List<OnlineEditorController.Field> onlineEditorFieldsChild2 = new List<OnlineEditorController.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Contact.Name', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Contact.Email', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Role', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Id', '', 'String'));

			OnlineEditorController.Query q = new OnlineEditorController.Query('Opportunity', null, onlineEditorFields, new List<OnlineEditorController.Query> {
				new OnlineEditorController.Query('OpportunityContactRole', 'OpportunityContactRoles', onlineEditorFieldsChild2, null)
			});

			Test.startTest();
			OnlineEditorController.Query result = OnlineEditorController.getMergeData(o.Id, JSON.serialize(q));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(q.type, result.type);
			System.assertEquals(q.relationship, result.relationship);
			System.assertEquals(q.fields[0].type, result.fields[0].type);
			System.assertEquals(q.fields[0].name, result.fields[0].name);
			System.assertEquals(o.Name, result.fields[0].value);
			System.assertEquals(q.fields[1].type, result.fields[1].type);
			System.assertEquals(q.fields[1].name, result.fields[1].name);
			System.assertEquals(a.Name, result.fields[1].value);
			System.assertEquals(q.children[0].type, result.children[0].type);
			System.assertEquals(q.children[0].relationship, result.children[0].relationship);
			System.assertEquals(q.children[0].fields[0].type, result.children[0].fields[0].type);
			System.assertEquals(q.children[0].fields[0].name, result.children[0].fields[0].name);
			System.assertEquals(q.children[0].children, result.children[0].children);

		}
	}

	@IsTest
	static void test_convertData() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			List<OnlineEditorController.Field> fields = new List<OnlineEditorController.Field>();
			fields.add(new OnlineEditorController.Field('Name', '', 'String'));
			fields.add(new OnlineEditorController.Field('IsDeleted', '', 'Boolean'));
			fields.add(new OnlineEditorController.Field('BillingAddress', '', 'String'));
			fields.add(new OnlineEditorController.Field('CreatedDate', '', 'String'));

			List<OnlineEditorController.Field> childFields = new List<OnlineEditorController.Field>();
			childFields.add(new OnlineEditorController.Field('Name', '', 'String'));

			OnlineEditorController.Query queryChild = new OnlineEditorController.Query('Opportunity', 'Opportunities', childFields, new List<OnlineEditorController.Query>());
			OnlineEditorController.Query query = new OnlineEditorController.Query('Account', '', fields, new List<OnlineEditorController.Query> { queryChild });

			Schema.Account testAccount = new Schema.Account(
				Name = 'Unit Test Gen ConvertData Account',
				BillingStreet = '123 Street',
				BillingCity = 'Fake City',
				BillingState = 'WA',
				BillingCountry = 'USA',
				BillingPostalCode = '98055'
			);
			insert testAccount;

			TestUtils.createOpportunity(testAccount.Id);

			Schema.Account insertedAccount = (Schema.Account)Collection.head([SELECT Id, BillingAddress, CreatedDate FROM Account WHERE Id = :testAccount.Id LIMIT 1]);

			SObject mergeData = GenService.getMergeData(testAccount.Id, OnlineEditorController.convertQuery(query));

			Test.startTest();
			OnlineEditorController.Query result = OnlineEditorController.convertData(query, mergeData);
			System.assertNotEquals(null, result);
			System.assertEquals(query.type, result.type);
			System.assertEquals(query.relationship, result.relationship);
			System.assertEquals(query.fields[0].type, result.fields[0].type);
			System.assertEquals(query.fields[0].name, result.fields[0].name);
			System.assertEquals(testAccount.Name, result.fields[0].value);
			System.assertEquals(query.fields[1].type, result.fields[1].type);
			System.assertEquals(query.fields[1].name, result.fields[1].name);
			System.assertEquals('false', result.fields[1].value, result.fields[1].value);
			System.assertEquals(OnlineEditorController.formatAddress(insertedAccount.BillingAddress), result.fields[2].value);
			System.assertEquals(insertedAccount.CreatedDate.format(), result.fields[3].value);
			System.assertEquals(query.children[0].type, result.children[0].type);
			System.assertEquals(query.children[0].relationship, result.children[0].relationship);
			System.assertEquals(query.children[0].fields[0].type, result.children[0].fields[0].type);
			System.assertEquals(query.children[0].fields[0].name, result.children[0].fields[0].name);
			System.assertEquals(query.children[0].children, result.children[0].children);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_formatAddress() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Test.startTest();
			Schema.Account a = new Schema.Account(Name = 'UNIT TEST test_formatAddress', BillingStreet = '123 Street', BillingCity = 'Fake City', BillingState = 'WA', BillingCountry = 'USA', BillingPostalCode = '98055');
			insert a;
			Schema.Account insertedAccount = (Schema.Account)Collection.head([SELECT Id, BillingAddress FROM Account WHERE Id = :a.Id LIMIT 1]);
			Address addr = insertedAccount.BillingAddress;
			System.assertEquals(
				String.join(new List<String> { addr.Street, addr.City, addr.State + ' ' + addr.PostalCode, addr.Country }, ', '),
				OnlineEditorController.formatAddress(insertedAccount.BillingAddress)
			);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveAttachments() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Schema.Account testAccount = TestUtils.createAccount();
			Opportunity testOpportunity = TestUtils.createOpportunity(testAccount.Id);
			GenTemplate__c genTemplate = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			genTemplate.Name = TestUtils.randomString(12);
			genTemplate.SourceObject__c = 'Opportunity';
			genTemplate.FileName__c = TestUtils.randomString(100);
			genTemplate.FileSuffix__c = 'Main Data Source Name';
			update genTemplate;

			String htmlData = '<h1>Hello World</h1>';

			Test.startTest();
			Id fileId = OnlineEditorController.saveAttachments(testOpportunity.Id, htmlData, genTemplate.Id);
			System.assertNotEquals(fileId, null);
			ContentVersion cv = (ContentVersion)Collection.head([SELECT Id, Title FROM ContentVersion WHERE Id = :fileId]);
			Test.stopTest();
			System.assertEquals(cv.Title.length(), 80);
			System.assertEquals(cv.Title.substringAfterLast('.'), 'html');
		}
	}

	@IsTest
	static void test_getFileName_mainDataSourceSuffix() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			System.assert(OnlineEditorController.getFileName('One', 'Main Data Source Name', 'Account').contains('Account'));
		}
	}

	@IsTest
	static void test_getFileName_dateSuffix() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			System.assertEquals(false, OnlineEditorController.getFileName('One', 'Date', 'Account').contains('Account'));
		}
	}

	@IsTest
	static void test_getFileName_mainDataSourceAndDateSuffix() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			System.assert(OnlineEditorController.getFileName('One', 'Main Data Source Name and Date', 'Account').contains('Account'));
			System.assert(OnlineEditorController.getFileName('One', 'Main Data Source Name and Date', 'Account').contains('One'));
		}
	}

	@IsTest
	static void test_getFileName_blankFileName() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			System.assertEquals(true, OnlineEditorController.getFileName(null, null, 'Account').contains(Label.Untitled));
			System.assertEquals(false, OnlineEditorController.getFileName(null, null, 'Account').contains('Account'));
		}
	}

	@IsTest
	static void test_getFileName_emptySuffix() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			System.assertEquals('One.html', OnlineEditorController.getFileName('One', null, 'Account'));
		}
	}

	@IsTest
	static void test_generateUploadToken_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			Test.startTest();
			LimitedAccessToken limitedAccessToken = OnlineEditorController.generateUploadToken(OnlineEditorRoot__c.getOrgDefaults().FolderId__c);
			Test.stopTest();
			System.assertNotEquals(null, limitedAccessToken);
		}
	}

	@IsTest
	static void test_generateUploadToken_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				OnlineEditorController.generateUploadToken(UUID.randomUUID().toString());
				throw new AssertException('Expected to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_generateDownloadToken_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			Test.startTest();
			LimitedAccessToken limitedAccessToken = OnlineEditorController.generateDownloadToken(OnlineEditorRoot__c.getOrgDefaults().FolderId__c);
			Test.stopTest();
			System.assertNotEquals(null, limitedAccessToken);
		}
	}

	@IsTest
	static void test_generateDownloadToken_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				OnlineEditorController.generateDownloadToken(UUID.randomUUID().toString());
				throw new AssertException('Expected to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEntityRecords_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			for (Integer i = 0; i <= 24; i++) {
				TestUtils.createAccount();
			}
			Schema.Account uniqueAccount = TestUtils.createAccount();
			uniqueAccount.name = 'UNIT TEST getEntityRecords';
			update uniqueAccount;

			Test.startTest();
			Map<String, Object> testQuery = OnlineEditorController.getEntityRecords('Account', 0, '');
			Map<String, Object> testQuery2 = OnlineEditorController.getEntityRecords('Account', 0, uniqueAccount.name);
			List<Schema.Account> results = (List<Schema.Account>)testQuery.get('results');
			List<Schema.Account> results2 = (List<Schema.Account>)testQuery2.get('results');
			Test.stopTest();
			System.assertEquals((Integer)testQuery.get('totalRecords'), 26);
			System.assertEquals(results.size(), 25, results.size());
			System.assertEquals(results2.size(), 1, results2.size());
		}
	}

	@IsTest
	static void test_getEntityRecords_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				OnlineEditorController.getEntityRecords('Account', 0, '');
				throw new AssertException('Expected to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplateFolderId_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			String testTemplateFolderId;
			testTemplateFolderId = OnlineEditorController.getTemplateFolderId();
			System.assertNotEquals(null, testTemplateFolderId);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_constructors() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			System.assertNotEquals(null, new OnlineEditorController());
			System.assertNotEquals(null, new OnlineEditorController(null));
		}
	}

	@IsTest
	static void test_constructor_nonSetupWizard_Edit() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			GenTemplate__c testGenTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = 'Online Editor');
			insert testGenTemplate;
			Test.startTest();
			PageReference genTemplateNavigatorPageReference = Page.GenTemplateNavigator;
			Test.setCurrentPageReference(genTemplateNavigatorPageReference);
			genTemplateNavigatorPageReference.getParameters().put('templateId', testGenTemplate.Id);
			genTemplateNavigatorPageReference.getParameters().put('isFromSetupWizard', 'false');
			genTemplateNavigatorPageReference.getParameters().put('isEdit', 'true');
			OnlineEditorController testController = new OnlineEditorController();
			System.assertNotEquals(null, testController);
			System.assertEquals(true, testController.editMode);
			System.assertEquals(null, testController.errorMessage);
			System.assertNotEquals(null, testController.templateJson);
			System.assertEquals([SELECT Id, Name FROM GenTemplate__c LIMIT 1].Name, testController.templateName);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_constructor_setupWizard_New() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Test.startTest();
			PageReference genTemplateNavigatorPageReference = Page.GenTemplateNavigator;
			Test.setCurrentPageReference(genTemplateNavigatorPageReference);
			genTemplateNavigatorPageReference.getParameters().put('isFromSetupWizard', 'true');
			genTemplateNavigatorPageReference.getParameters().put('isEdit', 'false');
			OnlineEditorController testController = new OnlineEditorController();
			System.assertNotEquals(null, testController);
			System.assertEquals(false, testController.editMode);
			System.assertEquals(false, testController.editMode);
			System.assertEquals(Layout.ACTION_NAME_ONLINEEDITOR, testController.layoutActionName);
			System.assertEquals(Layout.ACTION_TYPE_ONLINEEDITOR, testController.layoutActionType);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_constructor_unauthorized() {
		System.runAs(UserMock.createRestrictedUser()) {
			Test.startTest();
			OnlineEditorController controller = new OnlineEditorController();
			System.assertEquals(Label.MustBeAdministratorOrGenerator, controller.errorMessage);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplateFolderId_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				OnlineEditorController.getTemplateFolderId();
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteTemplate_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.TYPE_ONLINE, SourceObject__c = 'Account');
			insert testTemplate;
			Test.startTest();
			System.assertEquals(1, [SELECT COUNT() FROM GenTemplate__c]);
			OnlineEditorController.deleteTemplate(testTemplate.Id);
			Test.stopTest();
			System.assertEquals(0, [SELECT COUNT() FROM GenTemplate__c]);
		}
	}

	@IsTest
	static void test_deleteTemplate_unauthorized() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.TYPE_ONLINE, SourceObject__c = 'Account');
			insert testTemplate;
			Test.startTest();
			try {
				OnlineEditorController.deleteTemplate(testTemplate.Id);
				throw new AssertException('Expected to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLayouts_success() {
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			List<Layout> testLayouts = new List<Layout>();
			Test.startTest();
			testLayouts = OnlineEditorController.getLayouts('Contact');
			Test.stopTest();
			System.assert(Collection.isNotEmpty(testLayouts));
		}
	}

	@IsTest
	static void test_getLayouts_unauthorized() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Test.startTest();
			try {
				OnlineEditorController.getLayouts('Account');
				throw new AssertException('Expected to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateLayouts_success() {
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.TYPE_ONLINE, SourceObject__c = 'Account');
			insert testTemplate;
			Layout l1 = new Layout(
				Contact.getSObjectType(),
				UserInfo.getOrganizationId(),
				'ns',
				'n1',
				new List<Layout.Action> {
					new Layout.Action(
						Layout.ACTION_TYPE_ONLINEEDITOR,
						Layout.ACTION_NAME_ONLINEEDITOR,
						'testLabel')
				});
			Layout l2 = new Layout(
				Contact.getSObjectType(),
				UserInfo.getOrganizationId(),
				'ns',
				'n2',
				new List<Layout.Action> {
					new Layout.Action(
						Layout.ACTION_TYPE_ONLINEEDITOR,
						Layout.ACTION_NAME_ONLINEEDITOR,
						'testLabel')
				});

			Test.startTest();
			String layoutJSONString = JSON.serialize(new List<Layout> { l1, l2 });
			String parameters = '{"genButtonApiName":"testOnlineEditorbutton","genButtonLabel":"testOnlineEditorlabel", "genTemplateId":"' + testTemplate.Id + '"}';
			List<Layout> result = OnlineEditorController.updateLayouts(
				'Contact',
				layoutJSONString,
				parameters);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
		}
	}

	@IsTest
	static void test_updateLayouts_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				OnlineEditorController.updateLayouts('Account', null, null);
				throw new AssertException('Expected to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSpringTemplateIdInUUIDFormat_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			UUID testUUID;
			Test.startTest();
			testUUID = OnlineEditorController.getSpringTemplateIdInUUIDFormat(UUID.randomUUID().toString());
			Test.stopTest();
			System.assertNotEquals(null, testUUID);
		}
	}

	@IsTest
	static void test_updateTemplate_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.TYPE_ONLINE, SourceObject__c = 'Account');
			insert testTemplate;
			System.assertNotEquals(null, testTemplate.Id);
			System.assertEquals('TestTemplate', [SELECT Id, Name FROM GenTemplate__c LIMIT 1].Name);
			System.assertEquals(Gen.TYPE_ONLINE, [SELECT Id, TemplateType__c FROM GenTemplate__c LIMIT 1].TemplateType__c);
			System.assertEquals('Account', [SELECT Id, SourceObject__c FROM GenTemplate__c LIMIT 1].SourceObject__c);
			Gen.Template testTemplateInstance = new Gen.Template(testTemplate.Id, 'UpdatedGenTemplate', 'Contact', Gen.TYPE_ONLINE, null, null, null, null, null, null, null, null, null, null, null, null);
			Test.startTest();
			testTemplateInstance = OnlineEditorController.updateTemplate(JSON.serialize(testTemplateInstance));
			Test.stopTest();
			System.assertNotEquals(null, testTemplateInstance);
			System.assertEquals('UpdatedGenTemplate', [SELECT Id, Name FROM GenTemplate__c LIMIT 1].Name);
			System.assertEquals('Contact', [SELECT Id, SourceObject__c FROM GenTemplate__c LIMIT 1].SourceObject__c);
		}
	}

	@IsTest
	static void test_updateTemplate_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Gen.Template testGenTemplate = new Gen.Template(null, 'TestGenTemplate', 'Account', Gen.TYPE_ONLINE, null, null, null, null, null, null, null, null, null, null, null, null);
			Test.startTest();
			try {
				OnlineEditorController.updateTemplate(JSON.serialize(testGenTemplate));
				throw new AssertException('Expected to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveAttachments_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Contact testContact = new Contact(FirstName = 'testContact', LastName = 'test', Email = 'unittest@test.com');
			insert testContact;
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.TYPE_ONLINE, SourceObject__c = 'Contact', FileName__c = 'Main', FileSuffix__c = 'Main Data Source');
			insert testTemplate;
			Id testAttachmentId;
			Test.startTest();
			testAttachmentId = OnlineEditorController.saveAttachments(testContact.Id, 'Test HTML data', testTemplate.Id);
			Test.stopTest();
			System.assertNotEquals(null, testAttachmentId);
		}
	}

	@IsTest
	static void test_saveAttachments_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Contact testContact = new Contact(FirstName = 'testContact', LastName = 'test', Email = 'unittest@test.com');
			insert testContact;
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.TYPE_ONLINE);
			insert testTemplate;
			Test.startTest();
			try {
				OnlineEditorController.saveAttachments(UserInfo.getUserId(), 'test', UserInfo.getUserId());
				throw new AssertException('Expected to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeData_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			TestUtils.createOpportunityContactRole(o.Id, c1.Id);
			TestUtils.createOpportunityContactRole(o.Id, c2.Id);

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Name', '', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Account.Name', '', 'String'));

			List<OnlineEditorController.Field> onlineEditorFieldsChild2 = new List<OnlineEditorController.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Contact.Name', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Contact.Email', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Role', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Id', '', 'String'));

			OnlineEditorController.Query q = new OnlineEditorController.Query('Opportunity', null, onlineEditorFields, new List<OnlineEditorController.Query> {
				new OnlineEditorController.Query('OpportunityContactRole', 'OpportunityContactRoles', onlineEditorFieldsChild2, null)
			});

			Test.startTest();
			OnlineEditorController.Query result = OnlineEditorController.getMergeData(o.Id, JSON.serialize(q));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(q.type, result.type);
			System.assertEquals(q.relationship, result.relationship);
			System.assertEquals(q.fields[0].type, result.fields[0].type);
			System.assertEquals(q.fields[0].name, result.fields[0].name);
			System.assertEquals(o.Name, result.fields[0].value);
			System.assertEquals(q.fields[1].type, result.fields[1].type);
			System.assertEquals(q.fields[1].name, result.fields[1].name);
			System.assertEquals(a.Name, result.fields[1].value);
			System.assertEquals(q.children[0].type, result.children[0].type);
			System.assertEquals(q.children[0].relationship, result.children[0].relationship);
			System.assertEquals(q.children[0].fields[0].type, result.children[0].fields[0].type);
			System.assertEquals(q.children[0].fields[0].name, result.children[0].fields[0].name);
			System.assertEquals(q.children[0].children, result.children[0].children);
		}
	}

	@IsTest
	static void test_getMergeData_viewer_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			TestUtils.createOpportunityContactRole(o.Id, c2.Id);
			TestUtils.createOpportunityContactRole(o.Id, c1.Id);

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Name', '', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Account.Name', '', 'String'));

			List<OnlineEditorController.Field> onlineEditorFieldsChild2 = new List<OnlineEditorController.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Contact.Name', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Contact.Email', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Role', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Id', '', 'String'));

			OnlineEditorController.Query q = new OnlineEditorController.Query('Opportunity', null, onlineEditorFields, new List<OnlineEditorController.Query> {
				new OnlineEditorController.Query('OpportunityContactRole', 'OpportunityContactRoles', onlineEditorFieldsChild2, null)
			});

			Test.startTest();
			OnlineEditorController.Query result = OnlineEditorController.getMergeData(o.Id, JSON.serialize(q));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(q.type, result.type);
			System.assertEquals(q.relationship, result.relationship);
			System.assertEquals(q.fields[0].type, result.fields[0].type);
			System.assertEquals(q.fields[0].name, result.fields[0].name);
			System.assertEquals(o.Name, result.fields[0].value);
			System.assertEquals(q.fields[1].type, result.fields[1].type);
			System.assertEquals(q.fields[1].name, result.fields[1].name);
			System.assertEquals(a.Name, result.fields[1].value);
			System.assertEquals(q.children[0].type, result.children[0].type);
			System.assertEquals(q.children[0].relationship, result.children[0].relationship);
			System.assertEquals(q.children[0].fields[0].type, result.children[0].fields[0].type);
			System.assertEquals(q.children[0].fields[0].name, result.children[0].fields[0].name);
			System.assertEquals(q.children[0].children, result.children[0].children);

		}
	}

	@IsTest
	static void test_getMergeData_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			TestUtils.createOpportunityContactRole(o.Id, c1.Id);
			TestUtils.createOpportunityContactRole(o.Id, c2.Id);

			List<OnlineEditorController.Field> onlineEditorFields = new List<OnlineEditorController.Field>();
			onlineEditorFields.add(new OnlineEditorController.Field('Name', '', 'String'));
			onlineEditorFields.add(new OnlineEditorController.Field('Account.Name', '', 'String'));

			List<OnlineEditorController.Field> onlineEditorFieldsChild2 = new List<OnlineEditorController.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Contact.Name', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Contact.Email', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Role', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditorController.Field('Id', '', 'String'));

			OnlineEditorController.Query q = new OnlineEditorController.Query('Opportunity', null, onlineEditorFields, new List<OnlineEditorController.Query> {
				new OnlineEditorController.Query('OpportunityContactRole', 'OpportunityContactRoles', onlineEditorFieldsChild2, null)
			});
			OnlineEditorController.Query result;
			Test.startTest();
			try {
				result = OnlineEditorController.getMergeData(o.Id, JSON.serialize(q));
			} catch(UnauthorizedException ex) {
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeData_emptyQuery() {
		System.runAs(UserMock.createDocuSignGenerator()) {
			Schema.Account a = TestUtils.createAccount();
			OnlineEditorController.Query q = new OnlineEditorController.Query(null, null, null, null);
			OnlineEditorController.Query result;
			Exception ex;
			Test.startTest();
			try {
				result = OnlineEditorController.getMergeData(a.Id, JSON.serialize(q));
			} catch(Exception error) {
				ex = error;
			}
			Test.stopTest();
			System.assertEquals(ex, null);
			System.assertNotEquals(result, null);
			System.assertEquals(result.isEmpty(), true);
			System.assertEquals(q.isEmpty(), true);
		}
	}	

	@IsTest
	static void test_getUserProperties_failure() {
		System.runAs(UserMock.createDocuSignSender(false)) {
			Test.startTest();
			try {
				OnlineEditorController.getUserProperties();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getUserProperties_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			UserEventsController.UserProperties result = OnlineEditorController.getUserProperties();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}
}
