@IsTest
private class GenServiceTest {

	@IsTest
	static void test_Database_queryRecentRecordIds() {
		Lead l1 = TestUtils.createLead();
		Lead l2 = TestUtils.createLead();

		Test.startTest();
		List<Id> result = GenService.DB.queryRecentRecordIds(Lead.getSObjectType(), 2);
		Test.stopTest();

		System.assertEquals(2, Collection.size(result));
		System.assertEquals(new Set<Id> { l1.Id, l2.Id }, new Set<Id>(result));
	}

	@IsTest
	static void test_clone_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.clone(null);
				throw new AssertException('Expected clone to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_clone_undefined_id() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			try {
				GenService.clone(null);
				throw new AssertException('Expected clone to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_clone_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			GenTemplate__c t = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(t.Id);
			ContentVersion cv2 = TestUtils.createGenFile(t.Id);

			Test.startTest();
			Gen.Template result = GenService.clone(t.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertNotEquals(t.Id, result.id);
			System.assertEquals(String.format(Label.GenTemplateCopyName_2, new List<String> {
				t.Name, '1'
			}), result.name);
			System.assertEquals(t.SourceObject__c, result.sourceObject);
			System.assertNotEquals(null, result.objectMappings);
			System.assertNotEquals(null, result.signerMappings);
			System.assertEquals(t.UseAllTemplates__c, result.useAllTemplates);
			System.assertEquals(t.UseCurrentRecord__c, result.useCurrentRecord);
			System.assertEquals(t.HasPreviewedDocuments__c, result.hasPreviewedDocuments);
			System.assertEquals(t.StepsCompleted__c, result.stepsCompleted);
			System.assertEquals(t.IsSample__c, result.isSample);
			System.assertEquals(2, Collection.size(result.generated));
			for (Gen.File f : result.generated) {
				System.assertNotEquals(null, f.id);
				ContentVersion cv = null;
				if (f.title == cv1.Title) {
					cv = cv1;
				} else if (f.title == cv2.Title) {
					cv = cv2;
				} else {
					throw new AssertException('Unexpected content version in cloned template: ' + f.title);
				}
				System.assertNotEquals(cv.Id, f.id);
				System.assertEquals(cv.Title, f.title);
				System.assertEquals(cv.FileExtension, f.extension);
				System.assertEquals(cv.ContentSize, f.size);
				System.assertEquals(cv.GeneratedFileFormat__c, f.generatedFormat);
				System.assertEquals(cv.GeneratedFileName__c, f.generatedName);
				System.assertEquals(cv.GeneratedFileSuffix__c, f.generatedSuffix);
				Gen.Rule testRule = (Gen.Rule)JSON.deserialize(cv.Rule__c, Gen.Rule.class);
				System.assertEquals(testRule.name, f.rule.name);
				System.assertEquals(testRule.ruleType, f.rule.ruleType);
				System.assertEquals(testRule.conditions.size(), f.rule.conditions.size());
			}
			System.assertEquals(2, Collection.size([SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :result.id LIMIT 10]));
		}
	}

	@IsTest
	static void test_createBlankTemplate_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.createBlankTemplate();
				throw new AssertException('Expected createBlankTemplate to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createBlankTemplate_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			Gen.Template result = GenService.createBlankTemplate();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(Label.Untitled, result.name);
			System.assertEquals(null, result.sourceObject);
			System.assertEquals(null, result.objectMappings);
			System.assert(Collection.isEmpty(result.signerMappings));
			System.assert(result.useAllTemplates);
			System.assert(result.useCurrentRecord);
			System.assert(!result.hasPreviewedDocuments);
			System.assertEquals(0, result.stepsCompleted);
			System.assert(Collection.isEmpty(result.generated));
			GenTemplate__c gt = [
				SELECT Id, Name, SourceObject__c, ObjectMappings__c, SignerMappings__c, UseAllTemplates__c,
					UseCurrentRecord__c, HasPreviewedDocuments__c, StepsCompleted__c, IsSample__c
				FROM GenTemplate__c
				WHERE Id = :result.id
				LIMIT 1
			];
			System.assertEquals(result.name, gt.Name);
			System.assertEquals(result.sourceObject, gt.SourceObject__c);
			System.assertEquals(null, gt.ObjectMappings__c);
			System.assertEquals(null, gt.SignerMappings__c);
			System.assertEquals(result.useAllTemplates, gt.UseAllTemplates__c);
			System.assertEquals(result.useCurrentRecord, gt.UseCurrentRecord__c);
			System.assertEquals(result.hasPreviewedDocuments, gt.HasPreviewedDocuments__c);
			System.assertEquals(result.stepsCompleted, gt.StepsCompleted__c);
		}
	}

	@IsTest
	static void test_getTemplate_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.getTemplate(null);
				throw new AssertException('Expected getTemplate to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplate_undefined_id() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Test.startTest();
			try {
				GenService.getTemplate(null);
				throw new AssertException('Expected getTemplate to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplate_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(gt.Id);
			ContentVersion cv2 = TestUtils.createGenFile(gt.Id);

			Test.startTest();
			Gen.Template result = GenService.getTemplate(gt.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(gt.Id, result.id);
			System.assertEquals(gt.Name, result.name);
			System.assertEquals(gt.SourceObject__c, result.sourceObject);
			System.assertEquals(gt.UseAllTemplates__c, result.useAllTemplates);
			System.assertEquals(gt.UseCurrentRecord__c, result.useCurrentRecord);
			System.assertEquals(gt.HasPreviewedDocuments__c, result.hasPreviewedDocuments);
			System.assertEquals(gt.IsSample__c, result.isSample);
			System.assertEquals(2, Collection.size(result.generated));

			Boolean foundCV1 = false, foundCV2 = false;
			for (Gen.File f : result.generated) {
				System.assertNotEquals(null, f);
				if (f.id == cv1.Id) {
					foundCV1 = true;
					System.assertEquals(cv1.Title, f.title);
					System.assertEquals(cv1.FileExtension, f.extension);
					System.assertEquals(cv1.ContentSize, f.size);
					System.assertEquals(cv1.GeneratedFileFormat__c, f.generatedFormat);
					System.assertEquals(cv1.GeneratedFileName__c, f.generatedName);
					System.assertEquals(cv1.GeneratedFileSuffix__c, f.generatedSuffix);
					Gen.Rule testRule = (Gen.Rule)JSON.deserialize(cv1.Rule__c, Gen.Rule.class);
					System.assertEquals(testRule.name, f.rule.name);
					System.assertEquals(testRule.ruleType, f.rule.ruleType);
					System.assertEquals(testRule.conditions.size(), f.rule.conditions.size());
				} else if (f.id == cv2.Id) {
					foundCV2 = true;
					System.assertEquals(cv2.Title, f.title);
					System.assertEquals(cv2.FileExtension, f.extension);
					System.assertEquals(cv2.ContentSize, f.size);
					System.assertEquals(cv2.GeneratedFileFormat__c, f.generatedFormat);
					System.assertEquals(cv2.GeneratedFileName__c, f.generatedName);
					System.assertEquals(cv2.GeneratedFileSuffix__c, f.generatedSuffix);
					Gen.Rule testRule = (Gen.Rule)JSON.deserialize(cv2.Rule__c, Gen.Rule.class);
					System.assertEquals(testRule.name, f.rule.name);
					System.assertEquals(testRule.ruleType, f.rule.ruleType);
					System.assertEquals(testRule.conditions.size(), f.rule.conditions.size());
				} else {
					throw new AssertException('Unexpected generated file: ' + f.generatedName);
				}
			}
			System.assert(foundCV1 && foundCV2);
		}
	}

	@IsTest
	static void test_checkDocumentRule_matches_true() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(gt.Id);
			Schema.Account acc = TestUtils.createAccount();

			Test.startTest();
			Gen.Template result = GenService.getTemplate(gt.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, Collection.size(result.generated));
			System.assertNotEquals(null, result.generated.get(0).rule);
			System.assertEquals(true, GenService.checkDocumentRule(acc.Id, 'Account', result.generated.get(0).rule));
		}
	}

	@IsTest
	static void test_saveTemplate_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.saveTemplate(null);
				throw new AssertException('Expected saveTemplate to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveTemplate_undefined_template() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				GenService.saveTemplate(null);
				throw new AssertException('Expected saveTemplate to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveTemplate_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c gtt = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			gtt.Name = TestUtils.randomString(12);
			gtt.SourceObject__c = 'Opportunity';
			gtt.UseCurrentRecord__c = false;
			gtt.UseAllTemplates__c = false;
			ContentVersion cv1 = TestUtils.createGenFile(gtt.Id);
			cv1.GeneratedFileName__c = TestUtils.randomString(20);
			cv1.Rule__c = '{"name":"CV1 Rule","ruleType":"any","conditions":[{"fieldName":"BillingState","matchType":"equals","matchValue":"California"},{"fieldName":"BillingState","matchType":"equals","matchValue":"Washington"}]}';
			ContentVersion cv2 = TestUtils.createGenFile(gtt.Id);
			cv2.GeneratedFileSuffix__c = 'name_date';
			cv2.GeneratedFileFormat__c = 'PDF';
			cv2.Rule__c = '{"name":"CV2 Rule","ruleType":"any","conditions":[{"fieldName":"Name","matchType":"equals","matchValue":"UnitTest"},{"fieldName":"Name","matchType":"equals","matchValue":"California"}]}';
			Gen.Template gt = GenService.DB.convert(gtt, new List<Gen.File> {
				GenService.DB.convert(cv1),
				GenService.DB.convert(cv2)
			});

			Test.startTest();
			Gen.Template result = GenService.saveTemplate(gt);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(gt.id, result.id);
			System.assertEquals(gt.name, result.name);
			System.assertEquals(gt.sourceObject, result.sourceObject);
			System.assertEquals(gt.useAllTemplates, result.useAllTemplates);
			System.assertEquals(gt.useCurrentRecord, result.useCurrentRecord);
			System.assertEquals(gt.hasPreviewedDocuments, result.hasPreviewedDocuments);
			System.assertEquals(gt.isSample, result.isSample);
			System.assertEquals(2, Collection.size(result.generated));

			Boolean foundCV1 = false, foundCV2 = false;
			for (Gen.File f : result.generated) {
				System.assertNotEquals(null, f);
				if (f.id == cv1.Id) {
					foundCV1 = true;
					System.assertEquals(cv1.Title, f.title);
					System.assertEquals(cv1.FileExtension, f.extension);
					System.assertEquals(cv1.ContentSize, f.size);
					System.assertEquals(cv1.GeneratedFileFormat__c, f.generatedFormat);
					System.assertEquals(cv1.GeneratedFileName__c, f.generatedName);
					System.assertEquals(cv1.GeneratedFileSuffix__c, f.generatedSuffix);
					Gen.Rule testRule = (Gen.Rule)JSON.deserialize(cv1.Rule__c, Gen.Rule.class);
					System.assertEquals(testRule.name, f.rule.name);
					System.assertEquals(testRule.ruleType, f.rule.ruleType);
					System.assertEquals(testRule.conditions.size(), f.rule.conditions.size());
				} else if (f.id == cv2.Id) {
					foundCV2 = true;
					System.assertEquals(cv2.Title, f.title);
					System.assertEquals(cv2.FileExtension, f.extension);
					System.assertEquals(cv2.ContentSize, f.size);
					System.assertEquals(cv2.GeneratedFileFormat__c, f.generatedFormat);
					System.assertEquals(cv2.GeneratedFileName__c, f.generatedName);
					System.assertEquals(cv2.GeneratedFileSuffix__c, f.generatedSuffix);
					Gen.Rule testRule = (Gen.Rule)JSON.deserialize(cv2.Rule__c, Gen.Rule.class);
					System.assertEquals(testRule.name, f.rule.name);
					System.assertEquals(testRule.ruleType, f.rule.ruleType);
					System.assertEquals(testRule.conditions.size(), f.rule.conditions.size());
				} else {
					throw new AssertException('Unexpected generated file: ' + f.generatedName);
				}
			}
			System.assert(foundCV1 && foundCV2);
		}
	}

	@IsTest
	static void test_getRecentRecords_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.getRecentRecordIds(null, 0);
				throw new AssertException('Expected getRecentRecordIds to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRecentRecords_undefined_type() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				GenService.getRecentRecordIds(null, 0);
				throw new AssertException('Expected getRecentRecordIds to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRecentRecords_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Lead l1 = TestUtils.createLead();
			Lead l2 = TestUtils.createLead();

			Test.startTest();
			List<Id> result = GenService.getRecentRecordIds(Lead.getSObjectType(), 2);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertEquals(new Set<Id> { l2.Id, l1.Id }, new Set<Id>(result));
		}
	}

	@IsTest
	static void test_getMergeData_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			Gen.Query q = null;
			try {
				GenService.getMergeData(null, q);
				throw new AssertException('Expected getMergeData to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeData_undefined_argument() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Gen.Query q = null;
			Test.startTest();
			try {
				GenService.getMergeData(null, q);
				throw new AssertException('Expected getMergeData to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.getMergeData(UserInfo.getUserId(), q);
				throw new AssertException('Expected getMergeData to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeData_invalid_query() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Test.startTest();
			try {
				GenService.getMergeData(UserInfo.getUserId(), new Gen.Query(null, null, null, null));
				throw new AssertException('Expected getMergeData to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidGenQuery, ex.getMessage());
			}
			try {
				GenService.getMergeData(UserInfo.getUserId(), new Gen.Query('Lead', null, new List<String>(), null));
				throw new AssertException('Expected getMergeData to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidGenQuery, ex.getMessage());
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
			OpportunityContactRole ocr1 = TestUtils.createOpportunityContactRole(o.Id, c1.Id);
			OpportunityContactRole ocr2 = TestUtils.createOpportunityContactRole(o.Id, c2.Id);
			Gen.Query q = new Gen.Query('Opportunity', null, new List<String> { 'Name' }, new List<Gen.Query> {
				new Gen.Query('OpportunityContactRole', 'OpportunityContactRoles', new List<String> {
					'Contact.Name', 'Contact.Email', 'Role'
				}, null)
			});

			Gen.Query childOnlyQuery = new Gen.Query('Opportunity', null, new List<String>(), new List<Gen.Query> {
				new Gen.Query('OpportunityContactRole', 'OpportunityContactRoles', new List<String> {
					'Contact.Name', 'Contact.Email', 'Role'
				}, null)
			});

			Test.startTest();
			SObject result = GenService.getMergeData(o.Id, q);
			SObject result2 = GenService.getMergeData(o.Id, childOnlyQuery);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(o.Id, result.Id);
			System.assertEquals(o.Id, result2.Id);
			System.assertEquals(o.Name, (String)result.get('Name'));
			List<OpportunityContactRole> ocrs = (List<OpportunityContactRole>)result.getSObjects('OpportunityContactRoles');
			List<OpportunityContactRole> ocrs2 = (List<OpportunityContactRole>)result2.getSObjects('OpportunityContactRoles');
			System.assertEquals(2, Collection.size(ocrs));
			System.assertEquals(2, Collection.size(ocrs2));
			Boolean foundOCR1 = false, foundOCR2 = false;
			for (OpportunityContactRole ocr : ocrs) {
				System.assertNotEquals(null, ocr);
				System.assertNotEquals(null, ocr.Contact);
				if (ocr.Id == ocr1.Id) {
					System.assertEquals(ocr1.Role, ocr.Role);
					System.assertEquals(c1.Id, ocr.Contact.Id);
					System.assertEquals(c1.Name, ocr.Contact.Name);
					System.assertEquals(c1.Email, ocr.Contact.Email);
					foundOCR1 = true;
				} else if (ocr.Id == ocr2.Id) {
					System.assertEquals(ocr2.Role, ocr.Role);
					System.assertEquals(c2.Id, ocr.Contact.Id);
					System.assertEquals(c2.Name, ocr.Contact.Name);
					System.assertEquals(c2.Email, ocr.Contact.Email);
					foundOCR2 = true;
				} else {
					throw new AssertException('Unexpected OpportunityContactRole: ' + ocr.Id);
				}
			}
			System.assert(foundOCR1);
			System.assert(foundOCR2);
		}
	}

	@IsTest
	static void test_getOutputFileName_name() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			System.assertEquals(null, GenService.getOutputFileName(null, null, null));
			Gen.File f = new Gen.File(null, 'a', 'b', 3, 'docx', 'a', 'name', null, null);
			System.assertEquals('a', GenService.getOutputFileName(f, null, null));
			System.assertEquals('a_' + UserInfo.getName(), GenService.getOutputFileName(f,
				new Entity(UserInfo.getUserId(), UserInfo.getName(), null), null));
		}
	}

	@IsTest
	static void test_getOutputFileName_date() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			System.assertEquals(null, GenService.getOutputFileName(null, null, null));
			Gen.File f = new Gen.File(null, 'a', 'b', 3, 'docx', 'a', 'date', null, null);
			Datetime dt = Datetime.now();
			System.assertEquals('a_' + dt.format('YYYY-MM-dd'), GenService.getOutputFileName(f, null, dt));
		}
	}

	@IsTest
	static void test_getOutputFileName_name_date() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			System.assertEquals(null, GenService.getOutputFileName(null, null, null));
			Gen.File f = new Gen.File(null, 'a', 'b', 3, 'docx', 'a', 'name_date', null, null);
			Datetime dt = Datetime.now();
			System.assertEquals('a_' + dt.format('YYYY-MM-dd'), GenService.getOutputFileName(f, null, dt));
			System.assertEquals('a_' + UserInfo.getName() + '_' + dt.format('YYYY-MM-dd'), GenService.getOutputFileName(f,
				new Entity(UserInfo.getUserId(), UserInfo.getName(), null), dt));
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_preview_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.queueDocumentGeneration(null, null, null, true, null);
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_non_preview_unauthorized() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				GenService.queueDocumentGeneration(null, null, null, false, null);
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_undefined_arguments() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Test.startTest();
			try {
				GenService.queueDocumentGeneration(null, UserInfo.getUserId(), '<xml/>', false, new List<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.queueDocumentGeneration(UserInfo.getUserId(), null, '<xml/>', false, new List<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.queueDocumentGeneration(UserInfo.getUserId(), UserInfo.getUserId(), '  ', false, new List<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.queueDocumentGeneration(UserInfo.getUserId(), UserInfo.getUserId(), '<xml/>', false, new List<Id>());
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private class PartialSuccessMock implements HttpCalloutMock {

		private Integer invocations = 0;
		private final Integer failOnInvocation;
		private final ScmAPIMock successMock;
		private final ScmAPIMock failureMock;

		public PartialSuccessMock(final Integer failOnInvocation) {
			this.failOnInvocation = failOnInvocation;
			this.successMock = new ScmAPIMock(true);
			this.failureMock = new ScmAPIMock(false);
		}

		public HttpResponse respond(final HttpRequest request) {
			return ++this.invocations == this.failOnInvocation
				? this.failureMock.getResponse(request)
				: this.successMock.getResponse(request);
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_success_partial() {
		Test.setMock(HttpCalloutMock.class, new PartialSuccessMock(1));
		System.runAs(UserMock.createDocuSignGenerator()) {
			Lead l = TestUtils.createLead();
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(gt.Id);
			ContentVersion cv2 = TestUtils.createGenFile(gt.Id);

			Test.startTest();
			List<Gen.Job> result = GenService.queueDocumentGeneration(gt.Id, l.Id, '<xml/>', true, new List<Id> {
				cv1.ContentDocumentId, cv2.ContentDocumentId
			});
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(null, result[0].id);
			System.assertEquals(cv1.Id, result[0].fileId);
			System.assertEquals(Label.Failure, result[0].status);
			System.assertNotEquals(null, result[0].message);
			System.assert(result[0].message.contains('Test user message'));
			System.assert(!result[0].success);
			System.assertNotEquals(null, result[1]);
			System.assert(UUID.isNotEmpty(result[1].id));
			System.assertEquals(cv2.Id, result[1].fileId);
			System.assertEquals(Label.Queued, result[1].status);
			System.assertEquals(null, result[1].message);
			System.assert(!result[1].success);
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_preview() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator()) {
			Lead l = TestUtils.createLead();
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(gt.Id);
			ContentVersion cv2 = TestUtils.createGenFile(gt.Id);

			Test.startTest();
			List<Gen.Job> result = GenService.queueDocumentGeneration(gt.Id, l.Id, '<xml/>', true, new List<Id> {
				cv1.ContentDocumentId, cv2.ContentDocumentId
			});
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assert(UUID.isNotEmpty(result[0].id));
			System.assertEquals(cv1.Id, result[0].fileId);
			System.assertEquals(Label.Queued, result[0].status);
			System.assertEquals(null, result[0].message);
			System.assert(!result[0].success);
			System.assertNotEquals(null, result[1]);
			System.assert(UUID.isNotEmpty(result[1].id));
			System.assertEquals(cv2.Id, result[1].fileId);
			System.assertEquals(Label.Queued, result[1].status);
			System.assertEquals(null, result[1].message);
			System.assert(!result[1].success);
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_source() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator()) {
			Lead l = TestUtils.createLead();
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(gt.Id);
			ContentVersion cv2 = TestUtils.createGenFile(gt.Id);

			Test.startTest();
			List<Gen.Job> result = GenService.queueDocumentGeneration(gt.Id, l.Id, '<xml/>', false, new List<Id> {
				cv1.ContentDocumentId, cv2.ContentDocumentId
			});
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assert(UUID.isNotEmpty(result[0].id));
			System.assertEquals(cv1.Id, result[0].fileId);
			System.assertEquals(Label.Queued, result[0].status);
			System.assertEquals(null, result[0].message);
			System.assert(!result[0].success);
			System.assertNotEquals(null, result[1]);
			System.assert(UUID.isNotEmpty(result[1].id));
			System.assertEquals(cv2.Id, result[1].fileId);
			System.assertEquals(Label.Queued, result[1].status);
			System.assertEquals(null, result[1].message);
			System.assert(!result[1].success);
		}
	}

	@IsTest
	static void test_getJobStatus_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.getJobStatus(null);
				throw new AssertException('Expected getJobStatus to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getJobStatus_invalid_argument() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Test.startTest();
			try {
				GenService.getJobStatus(null);
				throw new AssertException('Expected getJobStatus to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.getJobStatus(new List<UUID>());
				throw new AssertException('Expected getJobStatus to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getJobStatus_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator()) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			ContentVersion cv = TestUtils.createGenFile(gt.Id);
			UUID jobId1 = UUID.randomUUID();

			Test.startTest();
			List<Gen.Job> result = GenService.getJobStatus(new List<UUID> { jobId1 });
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(jobId1, result[0].id);
			System.assertEquals(cv.Id, result[0].fileId);
			System.assertEquals('Success', result[0].status);
			System.assert(result[0].success);
			System.assertNotEquals(null, result[0].file);
			System.assertEquals(cv.Id, result[0].file.id);
			System.assertEquals(cv.Title, result[0].file.title);
			System.assertEquals(cv.FileExtension, result[0].file.extension);
			System.assertEquals(cv.ContentSize, result[0].file.size);
			System.assertEquals(cv.GeneratedFileFormat__c, result[0].file.generatedFormat);
			System.assertEquals(cv.GeneratedFileName__c, result[0].file.generatedName);
			System.assertEquals(cv.GeneratedFileSuffix__c, result[0].file.generatedSuffix);
		}
	}

	@IsTest
	static void test_getJobStatus_success_partial() {
		Test.setMock(HttpCalloutMock.class, new PartialSuccessMock(1));
		System.runAs(UserMock.createDocuSignGenerator()) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			ContentVersion cv = TestUtils.createGenFile(gt.Id);
			UUID jobId1 = UUID.randomUUID(), jobId2 = UUID.randomUUID();

			Test.startTest();
			List<Gen.Job> result = GenService.getJobStatus(new List<UUID> { jobId1, jobId2 });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(jobId1, result[0].id);
			System.assertEquals(null, result[0].fileId);
			System.assertEquals(Label.Unknown, result[0].status);
			System.assert(!result[0].success);
			System.assert(String.isNotBlank(result[0].message));

			System.assertNotEquals(null, result[1]);
			System.assertEquals(jobId2, result[1].id);
			System.assertEquals(cv.Id, result[1].fileId);
			System.assertEquals('Success', result[1].status);
			System.assert(result[1].success);
			System.assertNotEquals(null, result[1].file);
			System.assertEquals(cv.Id, result[1].file.id);
			System.assertEquals(cv.Title, result[1].file.title);
			System.assertEquals(cv.FileExtension, result[1].file.extension);
			System.assertEquals(cv.ContentSize, result[1].file.size);
			System.assertEquals(cv.GeneratedFileFormat__c, result[1].file.generatedFormat);
			System.assertEquals(cv.GeneratedFileName__c, result[1].file.generatedName);
			System.assertEquals(cv.GeneratedFileSuffix__c, result[1].file.generatedSuffix);
		}
	}

	@IsTest
	static void test_createGenFile_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Schema.Account a = TestUtils.createAccount();
			System.assertNotEquals(null, a.Id);

			Test.startTest();
			ContentVersion testContentVersion = GenService.DB.createGenFile(a.Id, 'Test Title', 'Test Content');
			Test.stopTest();

			System.assertNotEquals(null, testContentVersion);
		}
	}

	@IsTest
	static void test_saveFile_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.saveFile(null, null, null, null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveFile_undefined_argument() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				GenService.saveFile(UserInfo.getUserId(), null, 'title', 'base64data');
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.saveFile(UserInfo.getUserId(), UserInfo.getUserId(), null, 'base64data');
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.saveFile(UserInfo.getUserId(), UserInfo.getUserId(), ' ', 'base64data');
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.saveFile(UserInfo.getUserId(), UserInfo.getUserId(), 'title', null);
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.saveFile(UserInfo.getUserId(), UserInfo.getUserId(), 'title', '\r');
				throw new AssertException('Expected failure');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveFile_create() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Schema.Account a = TestUtils.createAccount();

			Test.startTest();
			Gen.File result = GenService.saveFile(null, a.Id, 'title', EncodingUtil.base64Encode(Blob.valueOf('data')));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals('title', result.title);
			System.assertNotEquals(null, result.contentDocumentId);

			ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE Id = :result.id];
			System.assertNotEquals(null, cv);
			System.assertNotEquals(null, cv.VersionData);
			System.assertEquals(EncodingUtil.base64Encode(Blob.valueOf('data')), EncodingUtil.base64Encode(cv.VersionData));
		}
	}

	@IsTest
	static void test_saveFile_update() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Schema.Account a = TestUtils.createAccount();
			ContentVersion cv = TestUtils.createContentVersion(a.Id);

			Test.startTest();
			Gen.File result = GenService.saveFile(cv.Id, a.Id, 'title', EncodingUtil.base64Encode(Blob.valueOf('data')));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(cv.Id, result.id);
			System.assertNotEquals('title', result.title);
			System.assertEquals(cv.ContentDocumentId, result.contentDocumentId);
		}
	}

	@IsTest
	static void test_deleteContentDocument_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.deleteContentDocument(null);
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteContentDocument_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			ContentVersion cv = TestUtils.createContentVersion();
			System.assertNotEquals(null, cv.ContentDocumentId);

			Test.startTest();
			System.assert(GenService.deleteContentDocument(cv.Id));
			Test.stopTest();

			System.assert(Collection.isEmpty([SELECT Id FROM ContentVersion WHERE Id = :cv.Id]));
			System.assert(Collection.isEmpty([SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId]));
		}
	}

	@IsTest
	static void test_queryGenTemplatesForDisplay_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.queryGenTemplatesForDisplay();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_queryGenTemplatesForDisplay_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate');
			insert testTemplate;
			List<Gen.GenTemplateDisplay> templatesList = new List<Gen.GenTemplateDisplay>();
			Test.startTest();
			templatesList = GenService.queryGenTemplatesForDisplay();
			Test.stopTest();
			System.assertEquals(1, templatesList.size());
			System.assertEquals('TestTemplate', templatesList[0].name);
		}
	}

	@IsTest
	static void test_getNewGenTemplateUrl_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.getNewGenTemplateUrl();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getNewGenTemplateUrl_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			Url gentemplateUrl = GenService.getNewGenTemplateUrl();
			Test.stopTest();
			System.assertNotEquals(null, gentemplateUrl);
			System.assert(gentemplateUrl.toExternalForm().startsWith(Site.getBaseUrl()), true);
		}
	}

	@IsTest
	static void test_getSelfLookup_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Schema.Account a = TestUtils.createAccount();
			Schema.Account b = TestUtils.createAccount();
			a.ParentId = b.Id;
			update a;
			Gen.Query q = new Gen.Query('Account', null, new List<String> { 'Parent.Name' }, null);
			Test.startTest();
			SObject result = GenService.getMergeData(a.Id, q);
			Test.stopTest();
			System.assertNotEquals(null, result);
			System.assertEquals(a.Id, result.Id);
			System.assertEquals(b.Id, (String)result.get('ParentId'));
		}
	}

	@IsTest
	static void test_deleteTemplate_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			gt.TemplateId__c = String.valueOf(ScmAPIMock.DOCUMENT_ID);
			gt.TemplateType__c = Gen.TYPE_ONLINE;
			update gt;
			Test.startTest();
			Boolean isDeleted = GenService.deleteTemplate(gt.Id);
			System.assertEquals(isDeleted, true);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteTemplate_unauthorized() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			gt.TemplateId__c = String.valueOf(ScmAPIMock.DOCUMENT_ID);
			gt.TemplateType__c = Gen.TYPE_ONLINE;
			update gt;
			Test.startTest();
			try {
				GenService.deleteTemplate(gt.Id);
				throw new AssertException('Expected delete template to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplateTypes_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			Map<String, String> templateTypesMap = GenService.getTemplateTypes();
			System.assert(templateTypesMap.keySet().size() == 2);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplateTypes_unauthorized() {
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			Test.startTest();
			try {
				GenService.getTemplateTypes();
				throw new AssertException('Expected fetching template types to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplatePage_word_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c templateRecord = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			templateRecord.TemplateType__c = Gen.TYPE_WORD;
			update templateRecord;
			Gen.Template template = GenService.getTemplate(templateRecord.Id);
			Boolean isFromSetupWizard = true;

			Test.startTest();
			PageReference result = GenService.getTemplatePage(template, isFromSetupWizard);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.getUrl().toLowerCase().contains(Application.namespacePrefix + 'gentemplate'));
			System.assertEquals(templateRecord.Id, (Id)result.getParameters().get('id'));
			System.assertEquals('true', result.getParameters().get('isFromSetupWizard'));
		}
	}

	@IsTest
	static void test_getTemplatePage_onlineEditor_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c templateRecord = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			templateRecord.TemplateType__c = Gen.TYPE_ONLINE;
			update templateRecord;
			Gen.Template template = GenService.getTemplate(templateRecord.Id);
			Boolean isFromSetupWizard = false;

			Test.startTest();
			PageReference result = GenService.getTemplatePage(template, isFromSetupWizard);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.getUrl().toLowerCase().contains(Application.namespacePrefix + 'onlineeditorgentemplate'));
			System.assertEquals(templateRecord.Id, (Id)result.getParameters().get('id'));
			System.assertEquals('false', result.getParameters().get('isFromSetupWizard'));
		}
	}

	@IsTest
	static void test_getTemplatePage_unauthorized() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			GenTemplate__c templateRecord = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			templateRecord.TemplateType__c = Gen.TYPE_ONLINE;
			update templateRecord;
			Gen.Template template = GenService.getTemplate(templateRecord.Id);
			Boolean isFromSetupWizard = false;

			Test.startTest();
			try {
				GenService.getTemplatePage(template, isFromSetupWizard);
				throw new AssertException('Expected fetching template url to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplate_failureOnDelete() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Opportunity.getSObjectType());
			gt.TemplateId__c = String.valueOf(ScmAPIMock.DOCUMENT_ID);
			gt.TemplateType__c = Gen.TYPE_ONLINE;
			update gt;
			Test.startTest();
			try {
				System.assert(GenService.deleteTemplate(gt.Id));
				GenService.getTemplate(gt.Id);
				throw new AssertException('Expected get template to fail');
			} catch (Exception ex) {
				System.assertEquals(Label.GenTemplateNotFound, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeData_success2() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
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
			Query.Result result = GenService.getMergeData(a.Id, q);
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

	@IsTest
	static void test_getTempEOSFolderId_withConfig_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			TestUtils.createAgreementConfiguration(ScmAPIMock.SOURCE_OBJECT_ID, ScmAPIMock.FOLDER_ID.toString(), ScmAPIMock.FOLDER_ID_3.toString());
			Test.startTest();
			UUID eosFolderId = GenService.getTempEOSFolderId(ScmAPIMock.SOURCE_OBJECT_ID);
			System.assert(eosFolderId != null);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTempEOSFolderId_withoutConfig_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			Test.startTest();
			UUID eosFolderId = GenService.getTempEOSFolderId(ScmAPIMock.SOURCE_OBJECT_ID);
			System.assert(eosFolderId != null);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTempEOSFolderId_unauthorized() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser(true)) {
			TestUtils.createAgreementConfiguration(ScmAPIMock.SOURCE_OBJECT_ID, ScmAPIMock.FOLDER_ID.toString(), null);
			Test.startTest();
			try {
				GenService.getTempEOSFolderId(ScmAPIMock.SOURCE_OBJECT_ID);
				throw new AssertException('Expected get EOSFolderId to Fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTempEOSFolderId_without_existing_subFolder_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			TestUtils.createAgreementConfiguration(ScmAPIMock.SOURCE_OBJECT_ID, ScmAPIMock.FOLDER_ID_2.toString(), null);
			Test.startTest();
			UUID eosFolderId = GenService.getTempEOSFolderId(ScmAPIMock.SOURCE_OBJECT_ID);
			System.assert(eosFolderId != null);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_convertHtmlDocumentToWord_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			Test.startTest();
			GenService.convertHtmlDocumentToWord(ScmAPIMock.DOCUMENT_ID);
			system.assert(true);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_convertHtmlDocumentToWord_unauthorized() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser(true)) {
			Test.startTest();
			try {
				GenService.convertHtmlDocumentToWord(ScmAPIMock.DOCUMENT_ID);
				throw new AssertException('Expected convertHtmlDocumentToWord to Fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteScmDocument_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			Test.startTest();
			system.assert(GenService.deleteScmDocument(ScmAPIMock.DOCUMENT_ID));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteScmDocument_unauthorized() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser(true)) {
			Test.startTest();
			try {
				GenService.deleteScmDocument(ScmAPIMock.DOCUMENT_ID);
				throw new AssertException('Expected deleteScmDocument to Fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_generateLimitedAccessToken_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator()) {
			UUID entityId = UUID.randomUUID();

			Test.startTest();
			LimitedAccessToken limitedAccessToken = GenService.generateLimitedAccessToken(entityId);
			Test.stopTest();

			System.assertNotEquals(null, limitedAccessToken);
			System.assert(String.isNotBlank(limitedAccessToken.token));
			System.assert(String.isNotBlank(limitedAccessToken.apiBaseUrl));
			System.assert(String.isNotBlank(limitedAccessToken.apiDownloadBaseUrl));
			System.assert(String.isNotBlank(limitedAccessToken.apiUploadBaseUrl));
			System.assertEquals(entityId, limitedAccessToken.entityId);
		}
	}

	@IsTest
	static void test_generateLimitedAccessToken_unauthorized() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			UUID entityId = UUID.randomUUID();

			Test.startTest();
			try {
				GenService.generateLimitedAccessToken(entityId);
				throw new AssertException('Expected generateLimitedAccessToken to Fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_validateChildRelationshipField() {

		System.runAs(UserMock.createDocuSignAdministrator(true)) {

			String sourceObject = 'Account';

			ValidationException ex1, ex2, ex3, ex4;

			Gen.Field successField = new Gen.Field(
				'CHILD_RELATIONSHIP',
				'Opportunity',
				'Opportunities',
				'Opportunity',
				'Opportunities',
				'AccountId',
				'',
				0,
				true,
				false,
				null,
				null,
				'StageName != \'Closed Won\' ',
				'Name ASC',
				1
			);

			Gen.Field invalidOrderField = new Gen.Field(
				'CHILD_RELATIONSHIP',
				'Opportunity',
				'Opportunities',
				'Opportunity',
				'Opportunities',
				'AccountId',
				'',
				0,
				true,
				false,
				null,
				null,
				'StageName != \'Closed Won\' ',
				'BAD SOQL VALUE',
				1
			);

			Gen.Field invalidFilterField = new Gen.Field(
				'CHILD_RELATIONSHIP',
				'Opportunity',
				'Opportunities',
				'Opportunity',
				'Opportunities',
				'AccountId',
				'',
				0,
				true,
				false,
				null,
				null,
				'BAD SOQL VALUE',
				'Name ASC',
				1
			);

			Gen.Field successDepth3Field = new Gen.Field(
				'CHILD_RELATIONSHIP',
				'OpportunityContactRole',
				'OpportunityContactRoles',
				'OpportunityContactRole',
				'OpportunityContactRoles',
				'OpportunityId',
				'',
				0,
				true,
				false,
				null,
				null,
				'Role != \'Business User\'',
				'Role ASC',
				1
			);

			Test.startTest();
			try {
				GenService.validateChildRelationshipField(successField, 2);
			} catch (ValidationException err) {
				ex1 = err;
			}

			try {
				GenService.validateChildRelationshipField(invalidOrderField, 2);
			} catch (ValidationException err) {
				ex2 = err;
			}

			try {
				GenService.validateChildRelationshipField(invalidFilterField, 2);
			} catch (ValidationException err) {
				ex3 = err;
			}

			try {
				GenService.validateChildRelationshipField(successDepth3Field, 3);
			} catch (ValidationException err) {
				ex4 = err;
			}

			Test.stopTest();

			System.assertEquals(ex1, null);
			System.assertNotEquals(ex2, null);
			System.assert(ex2.getMessage().startsWith(Label.InvalidQuery));
			System.assertNotEquals(ex3, null);
			System.assert(ex2.getMessage().startsWith(Label.InvalidQuery));
			System.assertEquals(ex4, null);

		}

	}
}
