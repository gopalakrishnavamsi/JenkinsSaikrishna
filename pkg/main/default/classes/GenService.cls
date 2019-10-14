public with sharing class GenService {

	@TestVisible
	private static final GenService.Database DB = new GenService.Database();
	private static final SObjectType CONTENT_VERSION_TYPE = ContentVersion.getSObjectType();
	private static final SObjectType CONTENT_DOCUMENT_LINK_TYPE = ContentDocumentLink.getSObjectType();
	private static final SObjectType CONTENT_DOCUMENT_TYPE = ContentDocument.getSObjectType();

	private class Database {

		@TestVisible
		private ContentVersion convert(final Gen.File file) {
			if (file == null) return null;

			return new ContentVersion(
				Id = file.id,
				GeneratedFileFormat__c = file.generatedFormat,
				GeneratedFileName__c = file.generatedName,
				GeneratedFileSuffix__c = file.generatedSuffix);
		}

		@TestVisible
		private List<ContentVersion> convert(final List<Gen.File> files) {
			List<ContentVersion> result = new List<ContentVersion>();
			if (files != null) {
				for (Gen.File f : files) {
					result.add(convert(f));
				}
			}
			return result;
		}

		@TestVisible
		private GenTemplate__c convert(final Gen.Template template) {
			if (template == null) return null;

			return new GenTemplate__c(
				Id = template.id,
				Name = template.name,
				SourceObject__c = template.sourceObject,
				ObjectMappings__c = Collection.isEmpty(template.objectMappings)
					? null : JSON.serialize(template.objectMappings),
				SignerMappings__c = Collection.isEmpty(template.signerMappings)
					? null : JSON.serialize(template.signerMappings),
				UseAllTemplates__c = template.useAllTemplates == true,
				UseCurrentRecord__c = template.useCurrentRecord == true,
				HasPreviewedDocuments__c = template.hasPreviewedDocuments == true,
				StepsCompleted__c = template.stepsCompleted,
				IsSample__c = template.isSample == true);
		}

		@TestVisible
		private Gen.File convert(final ContentVersion cv) {
			if (cv == null) return null;

			return new Gen.File(
				cv.Id,
				cv.Title,
				cv.FileExtension,
				cv.ContentSize,
				cv.GeneratedFileFormat__c,
				cv.GeneratedFileName__c,
				cv.GeneratedFileSuffix__c,
				cv.ContentDocumentId);
		}

		@TestVisible
		private List<Gen.File> convert(final List<ContentVersion> cvs) {
			List<Gen.File> result = new List<Gen.File>();
			if (Collection.isNotEmpty(cvs)) {
				for (ContentVersion cv : cvs) {
					if (cv != null) result.add(convert(cv));
				}
			}
			return result;
		}

		@TestVisible
		private Gen.Template convert(final GenTemplate__c template, final List<Gen.File> generatedFiles) {
			if (template == null) return null;

			String objMapJson = template.ObjectMappings__c;
			String signMapJson = template.SignerMappings__c;
			return new Gen.Template(
				template.Id,
				template.Name,
				template.SourceObject__c,
				String.isBlank(objMapJson) ? null : (List<Gen.ObjectMappings>)JSON.deserialize(objMapJson, List<Gen.ObjectMappings>.class),
				String.isBlank(signMapJson) ? null : (List<Gen.SignerFieldMappings>)JSON.deserialize(signMapJson, List<Gen.SignerFieldMappings>.class),
				template.UseAllTemplates__c == true,
				template.UseCurrentRecord__c == true,
				template.HasPreviewedDocuments__c == true,
				Integer.valueOf(template.StepsCompleted__c),
				template.IsSample__c == true,
				generatedFiles);
		}

		private List<Gen.File> queryGeneratedFiles(final Id templateId) {
			Permissions.verifyIsQueryable(ContentVersion.getSObjectType(), new List<String> {
				'Id', 'Title', 'FileExtension', 'ContentSize',
				'GeneratedFileFormat__c', 'GeneratedFileName__c', 'GeneratedFileSuffix__c', 'ContentDocumentId'
			});

			return convert([
				SELECT Id, Title, ContentSize, FileExtension,
					GeneratedFileFormat__c, GeneratedFileName__c, GeneratedFileSuffix__c, ContentDocumentId
				FROM ContentVersion
				WHERE ContentDocumentId IN :(queryLinkedDocumentIds(templateId))
				AND IsLatest = TRUE
				ORDER BY CreatedDate ASC
			]);
		}

		public Gen.Template queryTemplate(final Id templateId) {
			Permissions.verifyIsQueryable(GenTemplate__c.getSObjectType(), new List<String> {
				'Id', 'Name', 'SourceObject__c', 'ObjectMappings__c', 'SignerMappings__c', 'UseAllTemplates__c',
				'UseCurrentRecord__c', 'HasPreviewedDocuments__c', 'StepsCompleted__c', 'IsSample__c'
			});

			return convert((GenTemplate__c)Collection.head([
				SELECT Id, Name, SourceObject__c, ObjectMappings__c, SignerMappings__c, UseAllTemplates__c,
					UseCurrentRecord__c, HasPreviewedDocuments__c, StepsCompleted__c, IsSample__c
				FROM GenTemplate__c
				WHERE Id = :templateId
				LIMIT 1
			]), queryGeneratedFiles(templateId));
		}

		public List<Gen.GenTemplateDisplay> queryTemplates() {
			Permissions.verifyIsQueryable(GenTemplate__c.getSObjectType(), new List<String> {
				'Id', 'Name', 'SourceObject__c', 'LastModifiedDate'
			});
			List<Gen.GenTemplateDisplay> templatesList = new List<Gen.GenTemplateDisplay>();
			for (GenTemplate__c template : [SELECT Id, Name, SourceObject__c, LastModifiedDate 
											FROM GenTemplate__c ORDER BY LastModifiedDate desc LIMIT 50000]) {
				templatesList.add(new Gen.GenTemplateDisplay(
										template.Id, 
										template.Name, 
										template.SourceObject__c,
										template.LastModifiedDate));										
			}
			return templatesList;
		}

		private String getCopyName(final String name) {
			Integer count = [
				SELECT COUNT()
				FROM GenTemplate__c
				WHERE Name LIKE :(name + '%')
			];
			return String.format(Label.GenTemplateCopyName_2, new List<String> { name, String.valueOf(count) });
		}

		private Set<Id> queryLinkedDocumentIds(final Id linkedEntityId) {
			Permissions.verifyIsQueryable(ContentDocumentLink.getSObjectType(), new List<String> {
				'ContentDocumentId'
			});

			Set<Id> result = new Set<Id>();
			for (ContentDocumentLink cdl : [
				SELECT ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :linkedEntityId
			]) {
				result.add(cdl.ContentDocumentId);
			}
			return result;
		}

		private List<ContentVersion> cloneContentVersions(final Id templateId) {
			Permissions.verifyIsQueryable(ContentVersion.getSObjectType(), new List<String> {
				'Id', 'Title', 'Description', 'PathOnClient', 'VersionData',
				Application.namespacePrefix + 'GeneratedFileFormat__c',
				Application.namespacePrefix + 'GeneratedFileName__c',
				Application.namespacePrefix + 'GeneratedFileSuffix__c'
			});
			Permissions.verifyIsCreateable(ContentVersion.getSObjectType(), new List<String> {
				'Title', 'Description', 'PathOnClient', 'VersionData',
				Application.namespacePrefix + 'GeneratedFileFormat__c',
				Application.namespacePrefix + 'GeneratedFileName__c',
				Application.namespacePrefix + 'GeneratedFileSuffix__c'
			});

			List<ContentVersion> cvs = new List<ContentVersion>();
			for (ContentVersion cv : [
				SELECT Id, Title, Description, PathOnClient, VersionData,
					GeneratedFileFormat__c, GeneratedFileName__c, GeneratedFileSuffix__c
				FROM ContentVersion
				WHERE IsLatest = TRUE
				AND ContentDocumentId IN :(queryLinkedDocumentIds(templateId))
			]) {
				// Can't use clone because ContentBodyId and VersionData are exclusive,
				// but ContentBodyId is always queried even if we don't specify it.
				cvs.add(new ContentVersion(
					Title = cv.Title,
					Description = cv.Description,
					PathOnClient = cv.PathOnClient,
					VersionData = cv.VersionData,
					GeneratedFileFormat__c = cv.GeneratedFileFormat__c,
					GeneratedFileName__c = cv.GeneratedFileName__c,
					GeneratedFileSuffix__c = cv.GeneratedFileSuffix__c));
			}
			insert cvs;
			return [
				SELECT Id, Title, FileExtension, ContentSize,
					GeneratedFileFormat__c, GeneratedFileName__c, GeneratedFileSuffix__c, ContentDocumentId
				FROM ContentVersion
				WHERE Id IN :cvs
			];
		}

		private List<ContentDocumentLink> createContentDocumentLinks(
			final Id linkedEntityId,
			final List<ContentVersion> contentVersions) {

			Permissions.verifyIsCreateable(ContentDocumentLink.getSObjectType(), new List<String> {
				'ContentDocumentId', 'LinkedEntityId', 'ShareType'
			});

			List<ContentDocumentLink> result = new List<ContentDocumentLink>();
			for (ContentVersion cv : [
				SELECT Id, ContentDocumentId
				FROM ContentVersion
				WHERE Id IN :contentVersions
			]) {
				result.add(new ContentDocumentLink(
					ContentDocumentId = cv.ContentDocumentId,
					LinkedEntityId = linkedEntityId,
					ShareType = 'V'));
			}
			insert result;
			return result;
		}

		public Gen.Template cloneTemplate(final Id templateId) {
			Permissions.verifyIsQueryable(GenTemplate__c.getSObjectType(), new List<String> {
				'Id', 'Name', 'SourceObject__c', 'ObjectMappings__c', 'SignerMappings__c', 'UseAllTemplates__c',
				'UseCurrentRecord__c', 'HasPreviewedDocuments__c', 'StepsCompleted__c', 'IsSample__c'
			});
			Permissions.verifyIsCreateable(GenTemplate__c.getSObjectType(), new List<String> {
				'Name', 'SourceObject__c', 'ObjectMappings__c', 'SignerMappings__c', 'UseAllTemplates__c',
				'UseCurrentRecord__c', 'HasPreviewedDocuments__c', 'StepsCompleted__c', 'IsSample__c'
			});

			GenTemplate__c original = (GenTemplate__c)Collection.head([
				SELECT Id, Name, SourceObject__c, ObjectMappings__c, SignerMappings__c, UseAllTemplates__c,
					UseCurrentRecord__c, HasPreviewedDocuments__c, StepsCompleted__c, IsSample__c
				FROM GenTemplate__c
				WHERE Id = :templateId
				LIMIT 1
			]);
			if (original == null) throw new DocuSignException(Label.GenTemplateNotFound);

			GenTemplate__c clone = original.clone(false, true);
			clone.Name = getCopyName(clone.Name);
			insert clone;

			List<ContentVersion> cvs = cloneContentVersions(templateId);
			createContentDocumentLinks(
				clone.Id,
				cvs);

			return convert(clone, convert(cvs));
		}

		public Gen.Template insertTemplate(final Gen.Template template) {
			Permissions.verifyIsCreateable(GenTemplate__c.getSObjectType(), new List<String> {
				'Name', 'SourceObject__c', 'ObjectMappings__c', 'SignerMappings__c', 'UseAllTemplates__c',
				'UseCurrentRecord__c', 'HasPreviewedDocuments__c', 'StepsCompleted__c', 'IsSample__c'
			});

			if (template == null) return null;

			GenTemplate__c t = convert(template);
			insert t;

			return convert(t, null);
		}

		public Gen.Template updateTemplate(final Gen.Template template) {
			Permissions.verifyIsUpdateable(GenTemplate__c.getSObjectType(), new List<String> {
				'Name', 'SourceObject__c', 'ObjectMappings__c', 'SignerMappings__c', 'UseAllTemplates__c',
				'UseCurrentRecord__c', 'HasPreviewedDocuments__c', 'StepsCompleted__c', 'IsSample__c'
			});
			Permissions.verifyIsUpdateable(ContentVersion.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'GeneratedFileFormat__c',
				Application.namespacePrefix + 'GeneratedFileName__c',
				Application.namespacePrefix + 'GeneratedFileSuffix__c'
			});

			if (template == null) return null;

			update convert(template.generated);
			update convert(template);

			return template;
		}

		public List<Gen.File> queryFiles(final List<Id> contentDocumentIds) {
			Permissions.verifyIsQueryable(ContentVersion.getSObjectType(), new List<String> {
				'Id', 'Title', 'FileExtension', 'ContentSize', 'ContentDocumentId',
				Application.namespacePrefix + 'GeneratedFileFormat__c',
				Application.namespacePrefix + 'GeneratedFileName__c',
				Application.namespacePrefix + 'GeneratedFileSuffix__c'
			});

			return convert([
				SELECT Id, Title, FileExtension, ContentSize,
					GeneratedFileName__c, GeneratedFileFormat__c, GeneratedFileSuffix__c, ContentDocumentId
				FROM ContentVersion
				WHERE ContentDocumentId IN :contentDocumentIds
				AND IsLatest = TRUE
				ORDER BY CreatedDate ASC
			]);
		}

		private Map<SObjectType, List<String>> addAccessCheck(
			final SObjectType baseType,
			final String field,
			final Map<SObjectType, List<String>> accessMap) {

			if (String.isBlank(field) || accessMap == null) return accessMap;

			SObjectType type = baseType;
			String fieldName = field;
			if (field.contains('.')) {
				List<String> toks = field.split('\\.');
				if (toks.size() > MergeField.MAX_DEPTH) throw new DocuSignException(Label.MaxObjectDepthExceeded);
				type = Salesforce.getSObjectType(toks[0]);
				fieldName = toks[1];
			}

			if (accessMap.containsKey(type)) {
				accessMap.get(type).add(fieldName);
			} else {
				accessMap.put(type, new List<String> { fieldName });
			}

			return accessMap;
		}

		private String buildChildQuery(
			final Gen.Query childQuery,
			final Map<SObjectType, List<String>> accessMap) {

			SObjectType type = Salesforce.getSObjectType(childQuery.type);
			accessMap.put(type, new List<String>());
			for (String field : childQuery.fields) {
				addAccessCheck(type, field, accessMap);
			}

			return String.format('(SELECT {0} FROM {1})', new List<String> {
				String.join(childQuery.fields, ', '),
				childQuery.relationship
			});
		}

		public SObject querySource(
			final Id sourceId,
			final Gen.Query query) {

			SObjectType type = sourceId.getSobjectType();
			Map<SObjectType, List<String>> accessMap = new Map<SObjectType, List<String>> {
				type => new List<String>()
			};
			List<String> childQueries = new List<String>();
			String q = 'SELECT ';
			for (String field : query.fields) {
				if (String.isNotBlank(field)) addAccessCheck(type, field, accessMap);
			}

			for (Gen.Query childQuery : query.children) {
				if (Gen.isValidChildQuery(childQuery)) childQueries.add(buildChildQuery(childQuery, accessMap));
			}

			for (SObjectType t : accessMap.keySet()) {
				Permissions.verifyIsQueryable(t, accessMap.get(t));
			}

			q += String.join(query.fields, ', ');
			if (Collection.isNotEmpty(childQueries)) {
				q += ', ' + String.join(childQueries, ', ');
			}
			q += String.format(' FROM {0} WHERE Id = :sourceId', new List<String> { String.valueOf(type) });
			return System.Database.query(q);
		}

		public List<Gen.File> queryFiles(final Set<Id> contentVersionIds) {
			Permissions.verifyIsQueryable(ContentVersion.getSObjectType(), new List<String> {
				'Id', 'Title', 'FileExtension', 'ContentSize', 'ContentDocumentId',
				Application.namespacePrefix + 'GeneratedFileFormat__c',
				Application.namespacePrefix + 'GeneratedFileName__c',
				Application.namespacePrefix + 'GeneratedFileSuffix__c'
			});

			return convert([
				SELECT Id, Title, FileExtension, ContentSize,
					GeneratedFileFormat__c, GeneratedFileName__c, GeneratedFileSuffix__c,ContentDocumentId
				FROM ContentVersion
				WHERE Id IN :contentVersionIds
			]);
		}

		public List<Id> queryRecentRecordIds(
			final SObjectType type,
			final Integer maximumRecords) {

			Permissions.verifyIsQueryable(type, new List<String> { 'Id' });

			List<SObject> records = [
				SELECT Id
				FROM RecentlyViewed
				WHERE Type = :String.valueOf(type)
				ORDER BY LastViewedDate DESC
				LIMIT :maximumRecords
			];
			if (Collection.isEmpty(records)) {
				records = System.Database.query(String.format(
					'SELECT Id FROM {0} ORDER BY CreatedDate DESC LIMIT :maximumRecords', new List<String> {
						String.valueOf(type)
					}));
			}

			List<Id> result = new List<Id>();
			for (SObject record : records) {
				result.add(record.Id);
			}
			return result;
		}

		public ContentVersion createGenFile(
			final Id linkedEntityId,
			final String title,
			final String base64Data) {

			Permissions.verifyIsCreateable(CONTENT_VERSION_TYPE, new List<String> {
				'ContentDocumentId', 'Title', 'VersionData', 'IsMajorVersion', 'GeneratedFileFormat__c', 'GeneratedFileSuffix__c', 'GeneratedFileName__c'
			});
			Permissions.verifyIsQueryable(CONTENT_VERSION_TYPE, new List<String> {
				'ContentDocumentId', 'Title', 'PathOnClient', 'FileExtension', 'VersionData', 'ContentSize',
				'LastModifiedDate', 'GeneratedFileFormat__c', 'GeneratedFileSuffix__c', 'GeneratedFileName__c'
			});
			Permissions.verifyIsCreateable(CONTENT_DOCUMENT_LINK_TYPE, new List<String> {
				'ContentDocumentId', 'LinkedEntityId', 'ShareType'
			});

			ContentVersion cv = new ContentVersion(
				PathOnClient = title,
				VersionData = EncodingUtil.base64Decode(base64Data),
				IsMajorVersion = false,
				GeneratedFileFormat__c = 'Word',
				GeneratedFileSuffix__c = 'name');
			insert cv;

			cv = [
				SELECT ContentDocumentId, Title, PathOnClient, FileExtension, VersionData, ContentSize, LastModifiedDate, GeneratedFileFormat__c, GeneratedFileSuffix__c, GeneratedFileName__c
				FROM ContentVersion
				WHERE Id = :cv.Id
				LIMIT 1
			];

			cv.GeneratedFileName__c = cv.Title;
			update cv;

			insert new ContentDocumentLink(
				ContentDocumentId = cv.ContentDocumentId,
				LinkedEntityId = linkedEntityId,
				ShareType = 'I'); // Types are: V - Viewer, C - Collaborator, and I - Inferred

			return cv;
		}

		public ContentVersion updateGenFile(
			final Id contentVersionId,
			final String base64Data) {

			Permissions.verifyIsQueryable(CONTENT_VERSION_TYPE, new List<String> {
				'ContentDocumentId', 'Title', 'PathOnClient', 'FileExtension', 'VersionData', 'ContentSize',
				'LastModifiedDate', 'GeneratedFileFormat__c', 'GeneratedFileSuffix__c', 'GeneratedFileName__c'
			});
			Permissions.verifyIsUpdateable(CONTENT_VERSION_TYPE, new List<String> { 'VersionData' });

			ContentVersion cv = [
				SELECT VersionData
				FROM ContentVersion
				WHERE Id = :contentVersionId
				LIMIT 1
			];
			cv.VersionData = EncodingUtil.base64Decode(EncodingUtil.base64Encode(cv.VersionData) + base64Data);
			update cv;

			return [
				SELECT ContentDocumentId, Title, PathOnClient, FileExtension, VersionData, ContentSize, LastModifiedDate, GeneratedFileFormat__c, GeneratedFileSuffix__c, GeneratedFileName__c
				FROM ContentVersion
				WHERE Id = :contentVersionId
				LIMIT 1
			];
		}

		public Boolean deleteContentDocument(final Id contentVersionId) {
			Permissions.verifyIsDeletable(CONTENT_DOCUMENT_TYPE);

			Boolean result = false;
			if (contentVersionId != null) {
				ContentVersion contentVersionInstance = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId];
				ContentDocument contentDocumentInstance = [SELECT Id FROM ContentDocument WHERE Id = :contentVersionInstance.ContentDocumentId];
				delete contentDocumentInstance;
				result = true;
			}
			return result;
		}

	}

	public static Gen.Template clone(final Id templateId) {
		Permissions.verifyIsDocuSignAdministrator();
		Permissions.verifyIsDocuSignGenerator();
		if (templateId == null) throw new DocuSignException(Label.UndefinedId);

		return DB.cloneTemplate(templateId);
	}

	public static Gen.Template createBlankTemplate() {
		Permissions.verifyIsDocuSignAdministrator();
		Permissions.verifyIsDocuSignGenerator();
		return DB.insertTemplate(new Gen.Template(
			null,
			Label.Untitled,
			null,
			null,
			null,
			true,
			true,
			false,
			0,
			false,
			null));
	}

	public static Gen.Template getTemplate(final Id templateId) {
		Permissions.verifyIsDocuSignGenerator();
		if (templateId == null) throw new DocuSignException(Label.UndefinedId);

		return DB.queryTemplate(templateId);
	}

	public static Gen.Template saveTemplate(final Gen.Template template) {
		Permissions.verifyIsDocuSignAdministrator();
		Permissions.verifyIsDocuSignGenerator();
		if (template == null) throw new DocuSignException(Label.UndefinedArgument);

		return DB.updateTemplate(template);
	}

	public static List<Id> getRecentRecordIds(
		final SObjectType type,
		final Integer maximumRecords) {

		Permissions.verifyIsDocuSignGenerator();

		if (type == null) throw new DocuSignException(Label.UndefinedArgument);

		return DB.queryRecentRecordIds(type, maximumRecords);
	}

	public static SObject getMergeData(
		final Id sourceId,
		final Gen.Query query) {

		Permissions.verifyIsDocuSignGenerator();

		if (sourceId == null || query == null) throw new DocuSignException(Label.UndefinedArgument);
		if (!Gen.isValidQuery(query)) throw new DocuSignException(Label.InvalidGenQuery);

		return DB.querySource(sourceId, query);
	}

	@TestVisible
	private static String getOutputFileName(
		final Gen.File file,
		final Entity source,
		final Datetime timestamp) {

		if (file == null) return null;

		String result = file.generatedName;
		switch on file.generatedSuffix {
			when 'name' {
				if (source != null) result += '_' + source.name;
			} when 'date' {
				result += '_' + (timestamp == null ? Datetime.now() : timestamp).format('YYYY-MM-dd');
			} when 'name_date' {
				if (source != null) {
					result += '_' + source.name + '_'
						+ (timestamp == null ? Datetime.now() : timestamp).format('YYYY-MM-dd');
				} else {
					result += '_' + (timestamp == null ? Datetime.now() : timestamp).format('YYYY-MM-dd');
				}
			}
		}
		return result;
	}

	public static List<Gen.Job> queueDocumentGeneration(
		final Id templateId,
		final Id sourceId,
		final String xmlPayload, // FIXME: Generate XML in service class. The callout payload must be opaque to clients.
		final Boolean isPreview,
		final List<Id> contentDocumentIds) {

		Permissions.verifyIsDocuSignGenerator();

		if (templateId == null
			|| sourceId == null
			|| String.isBlank(xmlPayload)
			|| Collection.isEmpty(contentDocumentIds)) {

			throw new DocuSignException(Label.UndefinedArgument);
		}

		List<Gen.Job> result = new List<Gen.Job>();
		Entity source = Entity.resolve(sourceId);
		GenAPI client = GenAPI.getInstance();
		for (Gen.File file : DB.queryFiles(contentDocumentIds)) {
			try {
				result.add(client.queueDocumentGeneration(
					file.id,
					isPreview ? null : source.id, // if we're preview we want to attach the user not a starting record
					xmlPayload,
					file.generatedFormat,
					getOutputFileName(file, source, Datetime.now())).withFile(file));
			} catch (Exception ex) {
				LoggerService.getInstance().exception(ex, 'Failed to queue document generation');
				result.add(new Gen.Job(
					null,
					file.id,
					Label.Failure,
					ex.getMessage() + ' ' + file.title).withFile(file));
			}
		}
		return result;
	}

	public static List<Gen.Job> getJobStatus(final List<UUID> jobIds) {
		Permissions.verifyIsDocuSignGenerator();

		if (Collection.isEmpty(jobIds)) throw new DocuSignException(Label.UndefinedArgument);

		List<Gen.Job> result = new List<Gen.Job>();
		Map<Id, Gen.Job> successfulJobs = new Map<Id, Gen.Job>();
		GenAPI client = GenAPI.getInstance();
		for (UUID jobId : jobIds) {
			try {
				Gen.Job job = client.getJobStatus(jobId);
				if (job.success) {
					successfulJobs.put(job.fileId, job);
				}
				result.add(job);
			} catch (Exception ex) {
				result.add(new Gen.Job(
					jobId,
					null,
					Label.Unknown,
					ex.getMessage()));
			}
		}

		for (Gen.File file : DB.queryFiles(successfulJobs.keySet())) {
			successfulJobs.get(file.id).withFile(file);
		}

		return result;
	}

	public static Boolean checkMultiCurrency() {
		Permissions.verifyIsDocuSignGenerator();
		Boolean isMultiCurrencyOrganization = UserInfo.isMultiCurrencyOrganization() ? true : false;
		return isMultiCurrencyOrganization;
	}

	/**
	 * Saves all or part of a file.
	 *
	 * @param contentVersionId The ID of the file record to update. If <code>null</code>, the record will be created.
	 * @param linkedEntityId The ID of the Salesforce object linked to the file.
	 * @param title The file name.
	 * @param base64Data Base64-encoded file bytes. This will be appended to an existing file's data if updating.
	 *
	 * @return The created or updated file.
	 */
	public static Gen.File saveFile(
		final Id contentVersionId,
		final Id linkedEntityId,
		final String title,
		final String base64Data) {

		Permissions.verifyIsDocuSignGenerator();

		if (linkedEntityId == null
			|| String.isBlank(title)
			|| String.isBlank(base64Data)) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		Gen.File resultFile = null;
		ContentVersion result = null;

		if (contentVersionId == null) {
			result = DB.createGenFile(linkedEntityId, title, base64Data);
		} else {
			result = DB.updateGenFile(contentVersionId, base64Data);
		}

		if (result != null) {
			resultFile = DB.convert(result);
		}
		return resultFile;
	}

	/**
	 * Deletes a Salesforce File. The ContentDocument is deleted from Salesforce.
	 *
	 * @param contentVersionId The ID of the ContentVersion. This will be used to fetch the ContentDocument to be deleted.
	 *
	 * @return Boolean
	 */
	public static Boolean deleteContentDocument(final Id contentVersionId) {
		Permissions.verifyIsDocuSignGenerator();
		return DB.deleteContentDocument(contentVersionId);
	}

	public static List<Gen.GenTemplateDisplay> queryGenTemplatesForDisplay() {
		Permissions.verifyIsDocuSignAdministrator();
		return DB.queryTemplates();
	}

	public static Url getNewGenTemplateUrl() {
		Permissions.verifyIsDocuSignAdministrator();
		Permissions.verifyIsCreateable(GenTemplate__c.getSObjectType(), new List<String> {
				'Name', 
				Application.namespacePrefix + 'SourceObject__c', 
				Application.namespacePrefix +'ObjectMappings__c', 
				Application.namespacePrefix +'SignerMappings__c', 
				Application.namespacePrefix +'UseAllTemplates__c',
				Application.namespacePrefix +'UseCurrentRecord__c', 
				Application.namespacePrefix +'HasPreviewedDocuments__c', 
				Application.namespacePrefix +'StepsCompleted__c', 
				Application.namespacePrefix +'IsSample__c'
			});
		PageReference genTemplatePage = Page.GenTemplate;
		return new Url(Salesforce.baseUrl, genTemplatePage.getUrl());
	}
}
