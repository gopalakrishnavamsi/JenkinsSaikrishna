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
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {
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
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {
			GenTemplate__c t = TestUtils.createGenTemplate(Contact.getSObjectType());
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
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {
			Test.startTest();
			Gen.Template result = GenService.createBlankTemplate();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(Label.Untitled, result.name);
			System.assertEquals(null, result.sourceObject);
			System.assert(Collection.isEmpty(result.objectMappings));
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
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
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
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
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
				} else if (f.id == cv2.Id) {
					foundCV2 = true;
					System.assertEquals(cv2.Title, f.title);
					System.assertEquals(cv2.FileExtension, f.extension);
					System.assertEquals(cv2.ContentSize, f.size);
					System.assertEquals(cv2.GeneratedFileFormat__c, f.generatedFormat);
					System.assertEquals(cv2.GeneratedFileName__c, f.generatedName);
					System.assertEquals(cv2.GeneratedFileSuffix__c, f.generatedSuffix);
				} else {
					throw new AssertException('Unexpected generated file: ' + f.generatedName);
				}
			}
			System.assert(foundCV1 && foundCV2);
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
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
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
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			GenTemplate__c gtt = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			gtt.Name = TestUtils.randomString(12);
			gtt.SourceObject__c = 'Opportunity';
			gtt.UseCurrentRecord__c = false;
			gtt.UseAllTemplates__c = false;
			ContentVersion cv1 = TestUtils.createGenFile(gtt.Id);
			cv1.GeneratedFileName__c = TestUtils.randomString(20);
			ContentVersion cv2 = TestUtils.createGenFile(gtt.Id);
			cv2.GeneratedFileSuffix__c = 'name_date';
			cv2.GeneratedFileFormat__c = 'PDF';
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
				} else if (f.id == cv2.Id) {
					foundCV2 = true;
					System.assertEquals(cv2.Title, f.title);
					System.assertEquals(cv2.FileExtension, f.extension);
					System.assertEquals(cv2.ContentSize, f.size);
					System.assertEquals(cv2.GeneratedFileFormat__c, f.generatedFormat);
					System.assertEquals(cv2.GeneratedFileName__c, f.generatedName);
					System.assertEquals(cv2.GeneratedFileSuffix__c, f.generatedSuffix);
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
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRecentRecords_undefined_type() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
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
		System.runAs(UserMock.createDocuSignGenerator(false)) {
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
			try {
				GenService.getMergeData(null, null);
				throw new AssertException('Expected getMergeData to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeData_undefined_argument() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Test.startTest();
			try {
				GenService.getMergeData(null, null);
				throw new AssertException('Expected getMergeData to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.getMergeData(UserInfo.getUserId(), null);
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

			Test.startTest();
			SObject result = GenService.getMergeData(o.Id, q);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(o.Id, result.Id);
			System.assertEquals(o.Name, (String)result.get('Name'));
			List<OpportunityContactRole> ocrs = (List<OpportunityContactRole>)result.getSObjects('OpportunityContactRoles');
			System.assertEquals(2, Collection.size(ocrs));
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
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			System.assertEquals(null, GenService.getOutputFileName(null, null, null));
			Gen.File f = new Gen.File(null, 'a', 'b', 3, 'docx', 'a', 'name', null);
			System.assertEquals('a', GenService.getOutputFileName(f, null, null));
			System.assertEquals('a_' + UserInfo.getName(), GenService.getOutputFileName(f,
				new Entity(UserInfo.getUserId(), UserInfo.getName(), null), null));
		}
	}

	@IsTest
	static void test_getOutputFileName_date() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			System.assertEquals(null, GenService.getOutputFileName(null, null, null));
			Gen.File f = new Gen.File(null, 'a', 'b', 3, 'docx', 'a', 'date', null);
			Datetime dt = Datetime.now();
			System.assertEquals('a_' + dt.format('YYYY-MM-dd'), GenService.getOutputFileName(f, null, dt));
		}
	}

	@IsTest
	static void test_getOutputFileName_name_date() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			System.assertEquals(null, GenService.getOutputFileName(null, null, null));
			Gen.File f = new Gen.File(null, 'a', 'b', 3, 'docx', 'a', 'name_date', null);
			Datetime dt = Datetime.now();
			System.assertEquals('a_' + dt.format('YYYY-MM-dd'), GenService.getOutputFileName(f, null, dt));
			System.assertEquals('a_' + UserInfo.getName() + '_' + dt.format('YYYY-MM-dd'), GenService.getOutputFileName(f,
				new Entity(UserInfo.getUserId(), UserInfo.getName(), null), dt));
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.queueDocumentGeneration(null, null, null, null, null);
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
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
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
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
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
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
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
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
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
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
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
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
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
	static void test_checkMultiCurrency_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.checkMultiCurrency();
				throw new AssertException('Expected failure');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_checkMultiCurrency_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Test.startTest();
			Boolean result = GenService.checkMultiCurrency();
			Test.stopTest();

			System.assertEquals(UserInfo.isMultiCurrencyOrganization(), result);
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
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveFile_undefined_argument() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
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
		System.runAs(UserMock.createDocuSignGenerator(false)) {
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
		System.runAs(UserMock.createDocuSignGenerator(false)) {
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
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteContentDocument_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
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
	static void test_getEntityRecords_search() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			List<Schema.Account> testAccounts = new List<Schema.Account>();
			for (Integer i = 0; i <= 25; i++) {
				testAccounts.add(TestUtils.createAccount());
			}
			Test.startTest();
			Map<String, Object> testQuery = GenService.getRelatedEntityRecords(Schema.Account.getSObjectType(), 'UNIT TEST', 0);
			Map<String, Object> testQuery2 = GenService.getRelatedEntityRecords(Schema.Account.getSObjectType(), 'UNIT TEST', 1);
			List<Schema.Account> results = (List<Schema.Account>)testQuery.get('results');
			List<Schema.Account> results2 = (List<Schema.Account>)testQuery2.get('results');
			Test.stopTest();
			System.assertEquals((Integer)testQuery.get('totalRecords'), 26);
			System.assertEquals(results.size(), 25, results.size());
			System.assertEquals(results2.size(), 1, results.size());
		}
	}

	@IsTest
	static void test_getEntityRecords() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			for (Integer i = 0; i <= 25; i++) {
				TestUtils.createAccount();
			}
			Test.startTest();
			List<Schema.Account> testQuery = GenService.getRelatedEntityRecords(Schema.Account.getSObjectType());
			Test.stopTest();
			System.assertNotEquals(testQuery, null, testQuery);
			System.assertEquals(testQuery.size(), 25);
		}
	}

	@IsTest
	static void test_convertFields_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Quantity', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('UnitPrice', 'val', 'String'));

			Test.startTest();
			List<String> result = GenService.convertFields(onlineEditorFields);
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

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Quantity', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('UnitPrice', 'val', 'String'));

			Test.startTest();
			List<String> result = GenService.convertFields(onlineEditorFields);
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

		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Quantity', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('UnitPrice', 'val', 'String'));

			OnlineEditor.Query onlineEditorQuery = new OnlineEditor.Query('Account', '', onlineEditorFields, new List<OnlineEditor.Query>());

			Test.startTest();
			Gen.Query result = GenService.convertQuery(onlineEditorQuery);
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

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			OnlineEditorFields.add(new onlineEditor.Field('Id', 'val', 'String'));
			OnlineEditorFields.add(new onlineEditor.Field('Quantity', 'val', 'String'));
			OnlineEditorFields.add(new onlineEditor.Field('UnitPrice', 'val', 'String'));

			OnlineEditor.Query onlineEditorQuery = new OnlineEditor.Query('Account', '', onlineEditorFields, new List<OnlineEditor.Query>());

			Test.startTest();
			Gen.Query result = GenService.convertQuery(onlineEditorQuery);
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

		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Quantity', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('UnitPrice', 'val', 'String'));

			List<OnlineEditor.Field> onlineEditorFieldsChild = new List<OnlineEditor.Field>();
			onlineEditorFieldsChild.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild.add(new OnlineEditor.Field('Name', 'val', 'String'));
			onlineEditorFieldsChild.add(new OnlineEditor.Field('BillingCity', 'val', 'String'));

			OnlineEditor.Query onlineEditorQueryChild = new OnlineEditor.Query('Opportunity', 'Opportunities', onlineEditorFieldsChild, new List<OnlineEditor.Query>());
			OnlineEditor.Query onlineEditorQuery = new OnlineEditor.Query('Account', '', onlineEditorFields, new List<OnlineEditor.Query> { onlineEditorQueryChild });

			Test.startTest();
			Gen.Query result = GenService.convertQuery(onlineEditorQuery);
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

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Quantity', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('UnitPrice', 'val', 'String'));

			List<OnlineEditor.Field> onlineEditorFieldsChild = new List<OnlineEditor.Field>();
			onlineEditorFieldsChild.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild.add(new OnlineEditor.Field('Name', 'val', 'String'));
			onlineEditorFieldsChild.add(new OnlineEditor.Field('BillingCity', 'val', 'String'));

			OnlineEditor.Query onlineEditorQueryChild = new OnlineEditor.Query('Opportunity', 'Opportunities', onlineEditorFieldsChild, new List<OnlineEditor.Query>());
			OnlineEditor.Query onlineEditorQuery = new OnlineEditor.Query('Account', '', onlineEditorFields, new List<OnlineEditor.Query> { onlineEditorQueryChild });

			Test.startTest();
			Gen.Query result = GenService.convertQuery(onlineEditorQuery);
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

		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Name', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('UnitPrice', 'val', 'String'));

			List<OnlineEditor.Field> onlineEditorFieldsChild1 = new List<OnlineEditor.Field>();
			onlineEditorFieldsChild1.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild1.add(new OnlineEditor.Field('Quantity', 'val', 'String'));

			List<OnlineEditor.Field> onlineEditorFieldsChild2 = new List<OnlineEditor.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('UnitPrice', 'val', 'String'));

			OnlineEditor.Query onlineEditorQueryChild1 = new OnlineEditor.Query('OpportunityLineItem', 'OpportunityLineItems', onlineEditorFieldsChild1, new List<OnlineEditor.Query>());
			OnlineEditor.Query onlineEditorQueryChild2 = new OnlineEditor.Query('OpportunityLineItem', 'OpportunityLineItems', onlineEditorFieldsChild2, new List<OnlineEditor.Query>());
			OnlineEditor.Query onlineEditorQueryOpp = new OnlineEditor.Query('Opportunity', '', onlineEditorFields, new List<OnlineEditor.Query> { onlineEditorQueryChild1, onlineEditorQueryChild2 });
			OnlineEditor.Query onlineEditorQuery = new OnlineEditor.Query('Account', '', onlineEditorFields, new List<OnlineEditor.Query> { onlineEditorQueryOpp });

			Test.startTest();
			Gen.Query result = GenService.convertQuery(onlineEditorQuery);
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
			System.assert(Collection.isNotEmpty(result.children[0].children));
			System.assertEquals(onlineEditorQuery.children[0].children[0].type, result.children[0].children[0].type);
			System.assertEquals(onlineEditorQuery.children[0].children[0].relationship, result.children[0].children[0].relationship);
			System.assertEquals(onlineEditorQuery.children[0].children[0].fields[0].name, result.children[0].children[0].fields[0]);
			System.assertEquals(onlineEditorQuery.children[0].children[0].fields[1].name, result.children[0].children[0].fields[1]);

		}
	}

	@IsTest
	static void test_convertQuery3_viewer_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignGenerator(true)) {

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Name', 'val', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('UnitPrice', 'val', 'String'));

			List<OnlineEditor.Field> onlineEditorFieldsChild1 = new List<OnlineEditor.Field>();
			onlineEditorFieldsChild1.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild1.add(new OnlineEditor.Field('Quantity', 'val', 'String'));

			List<OnlineEditor.Field> onlineEditorFieldsChild2 = new List<OnlineEditor.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Id', 'val', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('UnitPrice', 'val', 'String'));

			OnlineEditor.Query onlineEditorQueryChild1 = new OnlineEditor.Query('OpportunityLineItem', 'OpportunityLineItems', onlineEditorFieldsChild1, new List<OnlineEditor.Query>());
			OnlineEditor.Query onlineEditorQueryChild2 = new OnlineEditor.Query('OpportunityLineItem', 'OpportunityLineItems', onlineEditorFieldsChild2, new List<OnlineEditor.Query>());
			OnlineEditor.Query onlineEditorQueryOpp = new OnlineEditor.Query('Opportunity', '', onlineEditorFields, new List<OnlineEditor.Query> { onlineEditorQueryChild1, onlineEditorQueryChild2 });
			OnlineEditor.Query onlineEditorQuery = new OnlineEditor.Query('Account', '', onlineEditorFields, new List<OnlineEditor.Query> { onlineEditorQueryOpp });

			Test.startTest();
			Gen.Query result = GenService.convertQuery(onlineEditorQuery);
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
			System.assert(Collection.isNotEmpty(result.children[0].children));
			System.assertEquals(onlineEditorQuery.children[0].children[0].type, result.children[0].children[0].type);
			System.assertEquals(onlineEditorQuery.children[0].children[0].relationship, result.children[0].children[0].relationship);
			System.assertEquals(onlineEditorQuery.children[0].children[0].fields[0].name, result.children[0].children[0].fields[0]);
			System.assertEquals(onlineEditorQuery.children[0].children[0].fields[1].name, result.children[0].children[0].fields[1]);

		}
	}

	@IsTest
	static void test_getMergeData_success2() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			OpportunityContactRole ocr1 = TestUtils.createOpportunityContactRole(o.Id, c1.Id);
			OpportunityContactRole ocr2 = TestUtils.createOpportunityContactRole(o.Id, c2.Id);

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Name', '', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Account.Name', '', 'String'));

			List<OnlineEditor.Field> onlineEditorFieldsChild2 = new List<OnlineEditor.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Contact.Name', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Contact.Email', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Role', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Id', '', 'String'));

			OnlineEditor.Query q = new OnlineEditor.Query('Opportunity', null, onlineEditorFields, new List<OnlineEditor.Query> {
				new OnlineEditor.Query('OpportunityContactRole', 'OpportunityContactRoles', onlineEditorFieldsChild2, null)
			});

			Test.startTest();
			OnlineEditor.Query result = GenService.getOnlineEditorMergeData(o.Id, q);
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
			OpportunityContactRole ocr1 = TestUtils.createOpportunityContactRole(o.Id, c1.Id);
			OpportunityContactRole ocr2 = TestUtils.createOpportunityContactRole(o.Id, c2.Id);

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Name', '', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Account.Name', '', 'String'));

			List<OnlineEditor.Field> onlineEditorFieldsChild2 = new List<OnlineEditor.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Contact.Name', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Contact.Email', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Role', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Id', '', 'String'));

			OnlineEditor.Query q = new OnlineEditor.Query('Opportunity', null, onlineEditorFields, new List<OnlineEditor.Query> {
				new OnlineEditor.Query('OpportunityContactRole', 'OpportunityContactRoles', onlineEditorFieldsChild2, null)
			});

			Test.startTest();
			OnlineEditor.Query result = GenService.getOnlineEditorMergeData(o.Id, q);
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
			List<OnlineEditor.Field> fields = new List<OnlineEditor.Field>();
			Fields.add(new OnlineEditor.Field('Name', '', 'String'));
			Fields.add(new OnlineEditor.Field('IsDeleted', '', 'Boolean'));
			Fields.add(new OnlineEditor.Field('BillingAddress', '', 'String'));
			Fields.add(new OnlineEditor.Field('CreatedDate', '', 'String'));

			List<OnlineEditor.Field> childFields = new List<OnlineEditor.Field>();
			childFields.add(new OnlineEditor.Field('Name', '', 'String'));

			OnlineEditor.Query queryChild = new OnlineEditor.Query('Opportunity', 'Opportunities', childFields, new List<OnlineEditor.Query>());
			OnlineEditor.Query query = new OnlineEditor.Query('Account', '', fields, new List<OnlineEditor.Query> { queryChild });

			Schema.Account testAccount = new Schema.Account(
				Name = 'Unit Test Gen ConvertData Account',
				BillingStreet = '123 Street',
				BillingCity = 'Fake City',
				BillingState = 'WA',
				BillingCountry = 'USA',
				BillingPostalCode = '98055'
			);
			insert testAccount;

			TestUtils.createOpportunity(testAccount.id);

			Schema.Account instertedAccount = (Schema.Account)Collection.head([SELECT Id, BillingAddress, CreatedDate FROM Account WHERE ID = :testAccount.id LIMIT 1]);

			Test.startTest();
			OnlineEditor.Query result = GenService.convertData(query, GenService.getMergeData(testAccount.id, GenService.convertQuery(query)));
			System.assertNotEquals(null, result);
			System.assertEquals(query.type, result.type);
			System.assertEquals(query.relationship, result.relationship);
			System.assertEquals(query.fields[0].type, result.fields[0].type);
			System.assertEquals(query.fields[0].name, result.fields[0].name);
			System.assertEquals(testAccount.Name, result.fields[0].value);
			System.assertEquals(query.fields[1].type, result.fields[1].type);
			System.assertEquals(query.fields[1].name, result.fields[1].name);
			System.assertEquals('false', result.fields[1].value, result.fields[1].value);
			System.assertEquals(GenService.formatAddress(instertedAccount.BillingAddress), result.fields[2].value);
			System.assertEquals(instertedAccount.CreatedDate.format(), result.fields[3].value);
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
			Schema.Account instertedAccount = (Schema.Account)Collection.head([SELECT ID, BillingAddress FROM Account WHERE ID = :a.id LIMIT 1]);
			System.assertEquals(
				String.join(new List<String> { instertedAccount.BillingAddress.getStreet(), instertedAccount.BillingAddress.getCity(), instertedAccount.BillingAddress.getState() + ' ' + instertedAccount.BillingAddress.getPostalCode(), instertedAccount.BillingAddress.getCountry() }, ', '),
				GenService.formatAddress(instertedAccount.BillingAddress)
			);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveAttachments() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			Schema.Account testAccount = TestUtils.createAccount();
			Opportunity testOpportunity = TestUtils.createOpportunity(testAccount.id);
			GenTemplate__c genTemplate = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			genTemplate.Name = TestUtils.randomString(12);
			genTemplate.SourceObject__c = 'Opportunity';
			genTemplate.FileName__c = TestUtils.randomString(100);
			genTemplate.FileSuffix__c = 'Main Data Source Name';
			update genTemplate;

			String htmlData = '<h1>Hello World</h1>';

			Test.startTest();
			Id fileId = GenService.saveAttachments(testOpportunity.id, htmlData, genTemplate.id);
			System.assertNotEquals(fileId, null);
			ContentVersion cv = (ContentVersion)Collection.head([SELECT Id, Title FROM ContentVersion WHERE Id = :fileId]);
			Test.stopTest();
			System.assertEquals(cv.Title.length(), 80);
			System.assertEquals(cv.Title.substringAfterLast('.'), 'html');
		}
	}

	@IsTest
	static void test_getFileName_mainDataSourceSuffix() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			System.assert(GenService.getFileName('One', 'Main Data Source Name', 'Account').contains('Account'));
		}
	}

	@IsTest
	static void test_getFileName_dateSuffix() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			System.assertEquals(false, GenService.getFileName('One', 'Date', 'Account').contains('Account'));
		}
	}

	@IsTest
	static void test_getFileName_mainDataSourceAndDateSuffix() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			System.assert(GenService.getFileName('One', 'Main Data Source Name and Date', 'Account').contains('Account'));
			System.assert(GenService.getFileName('One', 'Main Data Source Name and Date', 'Account').contains('One'));
		}
	}

	@IsTest
	static void test_getFileName_blankFileName() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			System.assertEquals(true, GenService.getFileName(null, null, 'Account').contains(Label.Untitled));
			System.assertEquals(false, GenService.getFileName(null, null, 'Account').contains('Account'));
		}
	}

	@IsTest
	static void test_getFileName_emptySuffix() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			System.assertEquals('One.html', GenService.getFileName('One', null, 'Account'));
		}
	}

}