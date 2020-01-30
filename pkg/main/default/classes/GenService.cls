public with sharing class GenService {

	@TestVisible
	private static final GenService.Database DB = new GenService.Database();
	private static final SObjectType CONTENT_VERSION_TYPE = ContentVersion.getSObjectType();
	private static final SObjectType CONTENT_DOCUMENT_LINK_TYPE = ContentDocumentLink.getSObjectType();
	private static final SObjectType CONTENT_DOCUMENT_TYPE = ContentDocument.getSObjectType();
	private static final String ADMIN = 'admin';
	private static final String TEMPLATES_HTML = 'templates_html';

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
				Description__c = template.description,
				TemplateType__c = template.templateType,
				SourceObject__c = template.sourceObject,
				ObjectMappings__c = Collection.isEmpty(template.objectMappings)
					? null : JSON.serialize(template.objectMappings),
				SignerMappings__c = Collection.isEmpty(template.signerMappings)
					? null : JSON.serialize(template.signerMappings),
				UseAllTemplates__c = template.useAllTemplates == true,
				UseCurrentRecord__c = template.useCurrentRecord == true,
				HasPreviewedDocuments__c = template.hasPreviewedDocuments == true,
				StepsCompleted__c = template.stepsCompleted,
				IsSample__c = template.isSample == true,
				TemplateId__c = UUID.toString(template.springTemplateId),
				FileName__c = String.isNotBlank(template.filename) ? template.filename : '',
				FileSuffix__c = String.isNotBlank(template.fileSuffix) ? template.fileSuffix : '');
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
				template.TemplateType__c,
				template.Description__c,
				String.isBlank(objMapJson) ? null : (List<Gen.ObjectMappings>)JSON.deserialize(objMapJson, List<Gen.ObjectMappings>.class),
				String.isBlank(signMapJson) ? null : (List<Gen.SignerFieldMappings>)JSON.deserialize(signMapJson, List<Gen.SignerFieldMappings>.class),
				template.UseAllTemplates__c == true,
				template.UseCurrentRecord__c == true,
				template.HasPreviewedDocuments__c == true,
				Integer.valueOf(template.StepsCompleted__c),
				template.IsSample__c == true,
				generatedFiles,
				UUID.tryParse(template.TemplateId__c),
				String.isNotBlank(template.FileName__c) ? template.FileName__c : '',
				String.isNotBlank(template.FileSuffix__c) ? template.FileSuffix__c : '');
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
				'UseCurrentRecord__c', 'HasPreviewedDocuments__c', 'StepsCompleted__c', 'IsSample__c', 'Description__c',
				'TemplateType__c', 'TemplateId__c', 'FileName__c', 'FileSuffix__c'
			});

			return convert((GenTemplate__c)Collection.head([
				SELECT Id, Name, SourceObject__c, ObjectMappings__c, SignerMappings__c, UseAllTemplates__c,
					UseCurrentRecord__c, HasPreviewedDocuments__c, StepsCompleted__c, IsSample__c, Description__c,
					TemplateType__c, TemplateId__c, FileName__c, FileSuffix__c
				FROM GenTemplate__c
				WHERE Id = :templateId
				LIMIT 1
			]), queryGeneratedFiles(templateId));
		}

		public List<Gen.GenTemplateDisplay> queryTemplates() {
			Permissions.verifyIsQueryable(GenTemplate__c.getSObjectType(), new List<String> {
				'Id', 'Name', 'SourceObject__c', 'LastModifiedDate', 'TemplateType__c'
			});
			List<Gen.GenTemplateDisplay> templatesList = new List<Gen.GenTemplateDisplay>();
			for (GenTemplate__c template : [
				SELECT Id, Name, SourceObject__c, LastModifiedDate, TemplateType__c
				FROM GenTemplate__c
				ORDER BY LastModifiedDate DESC
				LIMIT 50000
			]) {
				templatesList.add(new Gen.GenTemplateDisplay(
					template.Id,
					template.Name,
					template.SourceObject__c,
					template.TemplateType__c,
					template.LastModifiedDate));
			}
			return templatesList;
		}

		@TestVisible
		private Boolean deleteTemplate(final Id templateId) {
			Permissions.verifyIsQueryable(GenTemplate__c.getSObjectType(), new List<String> { 'Id' });
			Permissions.verifyIsDeletable(GenTemplate__c.getSObjectType());

			Boolean result = false;
			if (templateId != null) {
				GenTemplate__c genTemplate = (GenTemplate__c)Collection.head([SELECT Id FROM GenTemplate__c WHERE Id = :templateId LIMIT 1]);
				delete genTemplate;
				result = true;
			}
			return result;
		}

		@TestVisible
		private UUID getTemplateFolderId() {
			UUID templateFolderId;
			OnlineEditorRoot__c onlineEditorRootFolderSettings = OnlineEditorRoot__c.getOrgDefaults();
			if (onlineEditorRootFolderSettings.FolderId__c != null) {
				templateFolderId = UUID.parse(onlineEditorRootFolderSettings.FolderId__c);
			} else {
				UUID rootFolder = NegotiateAPI.getInstance().getRootFolder();
				UUID adminFolder = NegotiateAPI.getInstance().createFolder(ADMIN, rootFolder);
				templateFolderId = NegotiateAPI.getInstance().createFolder(TEMPLATES_HTML, adminFolder);
				onlineEditorRootFolderSettings.FolderId__c = templateFolderId.toString();
				upsert onlineEditorRootFolderSettings;
			}
			return templateFolderId;
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

		private List<SObject> getEntityRecords(final SObjectType objectType, final String nameField) {
			Schema.DescribeSObjectResult objectDescription = objectType.getDescribe();
			List<String> objectFields = new List<String> { 'Id', nameField };
			Permissions.verifyIsQueryable(
				objectType,
				objectFields
			);

			String queryTemplate = 'SELECT {0} FROM {1} LIMIT 25';

			return System.Database.query(
				String.format(
					queryTemplate,
					new List<String> {
						String.join(objectFields, ','),
						objectDescription.getName()
					}
				)
			);
		}

		private String getObjectNameField(final SObjectType objectType) {
			if (objectType == null) return null;

			Map<String, Schema.SObjectField> fieldsMap = objectType.getDescribe().fields.getMap();
			if (fieldsMap.containsKey('Name')) {
				return 'Name';
			} else {
				for (String fieldName : fieldsMap.keySet()) {
					if (fieldsMap.containsKey(fieldName) && fieldsMap.get(fieldName).getDescribe().isNameField()) return fieldsMap.get(fieldName).getDescribe().getName();
				}
			}
			return null;
		}

		private Map<String, Object> getEntityRecords(final SObjectType objectType, final String searchValue, final String filterBy, final String orderBy, final Integer recordsPerPage, final Integer pageIndex) {

			if (pageIndex == null || pageIndex < 0 || filterBy == null || searchValue == null) throw new DocuSignException(Label.InvalidGenQuery);

			Schema.DescribeSObjectResult objectDescription = objectType.getDescribe();
			List<String> objectFields = new List<String> { 'Id', filterBy };
			Permissions.verifyIsQueryable(
				objectType,
				objectFields
			);

			String query = null;
			String queryFormattedSearchValue = '%' + searchValue + '%';
			Integer entityRecordCount = System.Database.countQuery(
				String.format(
					'SELECT count() FROM {0} WHERE {1} LIKE :queryFormattedSearchValue ',
					new List<String> {
						objectDescription.getName(),
						filterBy
					}
				)
			);

			Integer totalPageIndexes = entityRecordCount <= recordsPerPage ? 0 : (Integer)Math.floor(entityRecordCount / recordsPerPage);
			Integer queryOffSet = totalPageIndexes < pageIndex ? 0 : pageIndex * recordsPerPage;

			if (totalPageIndexes > 0) {
				query = String.format(
					'SELECT {0} FROM {1} WHERE {2} LIKE :queryFormattedSearchValue ORDER BY {3} LIMIT {4} OFFSET {5}',
					new List<String> {
						String.join(objectFields, ','),
						objectDescription.getName(),
						filterBy,
						orderBy,
						String.valueOf(recordsPerPage),
						String.valueOf(queryOffSet)
					}
				);
			} else if (pageIndex == 0) {
				query = String.format(
					'SELECT {0} FROM {1} WHERE {2} LIKE :queryFormattedSearchValue ORDER BY {3}',
					new List<String> {
						String.join(objectFields, ','),
						objectDescription.getName(),
						filterBy,
						orderBy
					}
				);
			}

			return new Map<String, Object> {
				'pageIndex' => pageIndex,
				'results' => query == null ? new List<SObject>() : System.Database.query(query),
				'filterBy' => filterBy,
				'totalRecords' => entityRecordCount,
				'totalPages' => totalPageIndexes + 1
			};
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
				'UseCurrentRecord__c', 'HasPreviewedDocuments__c', 'StepsCompleted__c', 'IsSample__c', 'Description__c', 'TemplateType__c',
				'FileName__c', 'FileSuffix__c'
			});
			Permissions.verifyIsCreateable(GenTemplate__c.getSObjectType(), new List<String> {
				'Name', 'SourceObject__c', 'ObjectMappings__c', 'SignerMappings__c', 'UseAllTemplates__c',
				'UseCurrentRecord__c', 'HasPreviewedDocuments__c', 'StepsCompleted__c', 'IsSample__c', 'Description__c', 'TemplateType__c',
				'FileName__c', 'FileSuffix__c'
			});

			GenTemplate__c original = (GenTemplate__c)Collection.head([
				SELECT Id, Name, SourceObject__c, ObjectMappings__c, SignerMappings__c, UseAllTemplates__c,
					UseCurrentRecord__c, HasPreviewedDocuments__c, StepsCompleted__c, IsSample__c, Description__c, TemplateType__c,
					FileName__c, FileSuffix__c
				FROM GenTemplate__c
				WHERE Id = :templateId
				LIMIT 1
			]);
			if (original == null) throw new DocuSignException(Label.GenTemplateNotFound);

			GenTemplate__c clone = original.clone(false, true);
			clone.Name = getCopyName(clone.Name);
			clone.TemplateId__c = null;
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
				'UseCurrentRecord__c', 'HasPreviewedDocuments__c', 'StepsCompleted__c', 'IsSample__c', 'Description__c', 'TemplateType__c',
				'TemplateId__c', 'FileName__c', 'FileSuffix__c'
			});

			if (template == null) return null;

			GenTemplate__c t = convert(template);
			insert t;

			return convert(t, null);
		}

		public Gen.Template updateTemplate(final Gen.Template template) {
			Permissions.verifyIsUpdateable(GenTemplate__c.getSObjectType(), new List<String> {
				'Name', 'SourceObject__c', 'ObjectMappings__c', 'SignerMappings__c', 'UseAllTemplates__c',
				'UseCurrentRecord__c', 'HasPreviewedDocuments__c', 'StepsCompleted__c', 'IsSample__c', 'Description__c',
				'TemplateId__c', 'FileName__c', 'FileSuffix__c'

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
				String parentSobject = toks[0];
				type = Salesforce.isValidSObject(parentSobject)
					? Salesforce.getSObjectType(parentSobject)
					: Salesforce.getParentSobjectType(baseType, getValidReferencePath(parentSobject));
				fieldName = toks[1];
			}

			if (accessMap.containsKey(type)) {
				accessMap.get(type).add(fieldName);
			} else {
				accessMap.put(type, new List<String> { fieldName });
			}

			return accessMap;
		}

		private String getValidReferencePath(String name) {
			return name.endsWith('__r') ?
				name.replace('__r', '__c') : name + 'Id';
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

			if (Collection.isNotEmpty(query.fields)) q += String.join(query.fields, ', '); else q += 'Id ';

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
			null,
			null,
			true,
			true,
			false,
			0,
			false,
			null,
			UUID.empty,
			'',
			''));
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
		return template.id != null ? DB.updateTemplate(template) : DB.insertTemplate(template) ;
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
		final String xmlPayload,
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
		return Salesforce.checkIfMultiCurrencyIsEnabled();
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

	public static List<SObject> getRelatedEntityRecords(final SObjectType objectType) {
		Permissions.verifyIsDocuSignGenerator();
		return DB.getEntityRecords(objectType, DB.getObjectNameField(objectType));
	}

	public static Map<String, Object> getRelatedEntityRecords(final SObjectType objectType, final String searchValue, final Integer pageIndex) {
		return DB.getEntityRecords(objectType, searchValue, DB.getObjectNameField(objectType), 'LastModifiedDate', 25, pageIndex);
	}

	public static Url getNewGenTemplateUrl() {
		Permissions.verifyIsDocuSignAdministrator();
		Permissions.verifyIsCreateable(GenTemplate__c.getSObjectType(), new List<String> {
			'Name',
			Application.namespacePrefix + 'SourceObject__c',
			Application.namespacePrefix + 'ObjectMappings__c',
			Application.namespacePrefix + 'SignerMappings__c',
			Application.namespacePrefix + 'UseAllTemplates__c',
			Application.namespacePrefix + 'UseCurrentRecord__c',
			Application.namespacePrefix + 'HasPreviewedDocuments__c',
			Application.namespacePrefix + 'StepsCompleted__c',
			Application.namespacePrefix + 'IsSample__c',
			Application.namespacePrefix + 'Description__c',
			Application.namespacePrefix + 'TemplateType__c'
		});
		PageReference genTemplatePage = Page.GenTemplate;
		return new Url(Salesforce.baseUrl, genTemplatePage.getUrl());
	}

	public static Map<String, String> getGenTemplateValues() {
		Permissions.verifyIsDocuSignAdministrator();
		Permissions.verifyIsDocuSignGenerator();
		return MetadataService.picklistValues(Application.namespacePrefix + 'GenTemplate__c', Application.namespacePrefix + 'TemplateType__C');
	}

	public static Url getTemplateUrl(final Gen.Template template, final Boolean isFromSetupWizard) {
		Permissions.verifyIsDocuSignAdministrator();
		Permissions.verifyIsCreateable(GenTemplate__c.getSObjectType(), new List<String> {
			'Name',
			Application.namespacePrefix + 'SourceObject__c',
			Application.namespacePrefix + 'ObjectMappings__c',
			Application.namespacePrefix + 'SignerMappings__c',
			Application.namespacePrefix + 'UseAllTemplates__c',
			Application.namespacePrefix + 'UseCurrentRecord__c',
			Application.namespacePrefix + 'HasPreviewedDocuments__c',
			Application.namespacePrefix + 'StepsCompleted__c',
			Application.namespacePrefix + 'IsSample__c',
			Application.namespacePrefix + 'Description__c',
			Application.namespacePrefix + 'TemplateType__c',
			Application.namespacePrefix + 'TemplateId__c'
		});
		PageReference templatePage = template.templateType.equals(Gen.ONLINE_EDITOR_TYPE) ? Page.OnlineEditorGenTemplate : Page.GenTemplate;
		templatePage.getParameters().put('id', template.id);
		templatePage.getParameters().put('isFromSetupWizard', String.valueOf(isFromSetupWizard));
		return new Url(Salesforce.baseUrl, templatePage.getUrl());
	}

	//onlineEditorService start

	public static Negotiate.LimitedAccessToken generateUploadToken(UUID templateFolderId) {
		Permissions.verifyIsDocuSignGenerator();
		return ScmTokenAPI.getInstance().generateLimitedAccessToken(templateFolderId, AuthService.getContentAccessToken());
	}

	public static UUID getTemplateFolderId() {
		Permissions.verifyIsDocuSignGenerator();
		return DB.getTemplateFolderId();
	}

	public static Boolean deleteTemplate(final Id templateId) {
		Permissions.verifyIsDocuSignGenerator();
		return DB.deleteTemplate(templateId);
	}

	public static String getOnlineEditorTemplateId(final Id templateId) {
		Permissions.verifyIsDocuSignGenerator();
		return UUID.toString(DB.queryTemplate(templateId).springTemplateId);
	}

	public static Id saveAttachments(final Id recordId, final String htmlData, final Id salesforceOnlineEditorTemplateId) {
		Permissions.verifyIsDocuSignGenerator();

		Permissions.verifyIsQueryable(ContentVersion.getSObjectType(), new List<String> {
			'Id', 'ContentDocumentId'
		});
		Permissions.verifyIsCreateable(ContentVersion.getSObjectType(), new List<String> {
			'Title', 'PathOnClient', 'VersionData'
		});
		Permissions.verifyIsCreateable(ContentDocumentLink.getSObjectType(), new List<String> {
			'ContentDocumentId', 'LinkedEntityId', 'ShareType'
		});

		Gen.Template genTemplate = DB.queryTemplate(salesforceOnlineEditorTemplateId);

		ContentVersion attachment = new ContentVersion();
		attachment.VersionData = Blob.valueOf(htmlData);
		attachment.Title = getFileName(genTemplate.fileName, genTemplate.fileSuffix, genTemplate.sourceObject);
		attachment.PathOnClient = getFileName(genTemplate.fileName, genTemplate.fileSuffix, genTemplate.sourceObject);
		insert attachment;

		ContentDocumentLink attachmentLink = new ContentDocumentLink();
		attachmentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :attachment.Id].ContentDocumentId;
		attachmentLink.LinkedEntityId = recordId;
		attachmentLink.ShareType = 'V';
		insert attachmentLink;

		return attachment.Id;
	}

	public static OnlineEditor.Query getOnlineEditorMergeData(
		final Id sourceId,
		final OnlineEditor.Query onlineEditorQuery) {

		Permissions.verifyIsDocuSignGenerator();

		if (sourceId == null || onlineEditorQuery == null) throw new DocuSignException(Label.UndefinedArgument);

		Gen.Query genQuery = convertQuery(onlineEditorQuery);

		SObject result = GenService.getMergeData(sourceId, genQuery);
		return convertData(onlineEditorQuery, result);
	}

	@TestVisible
	private static String formatAddress(final Address location) {
		return location == null ? null : String.join(new List<String> { location.getStreet(), location.getCity(), location.getState() + ' ' + location.getPostalCode(), location.getCountry() }, ', ');
	}

	@TestVisible
	private static SObject fieldLookUp(List<String> fieldNames, SObject data) {
		if (data == null || Collection.isEmpty(fieldNames)) {
			return null;
		}
		SObject result = data.getSObject((String)Collection.head(fieldNames));
		if (fieldNames.size() == 2) {
			return result;
		}
		return fieldLookUp((List<String>)Collection.tail(fieldNames), result);
	}

	public static OnlineEditor.Query convertData(final OnlineEditor.Query onlineEditorQuery, SObject data) {
		Permissions.verifyIsDocuSignGenerator();

		List<OnlineEditor.Query> childQueries = new List<OnlineEditor.Query>();
		List<OnlineEditor.Field > fields = new List<OnlineEditor.Field >();
		for (OnlineEditor.Field f : onlineEditorQuery.fields) {
			Object fieldValue;
			String value = '';
			if (f.name.contains('.')) {
				List<String> fieldNames = f.name.split('\\.');
				SObject fieldLookup = fieldLookUp(fieldNames, data);
				fieldValue = fieldLookup != null ? fieldLookup.get((String)Collection.last(fieldNames)) : null;
				if (fieldValue != null) {
					if (fieldValue instanceof Datetime) {
						Datetime dt = (Datetime)fieldValue;
						value = dt.format();
					} else if (fieldValue instanceof Address) {
						value = GenService.formatAddress((Address)fieldValue);
					} else {
						value = String.valueOf(fieldValue);
					}
				}
			} else {
				fieldValue = data.get(f.name);
				if (fieldValue != null) {
					if (fieldValue instanceof Datetime) {
						Datetime dt = (Datetime)fieldValue;
						value = dt.format();
					} else if (fieldValue instanceof Address) {
						value = GenService.formatAddress((Address)fieldValue);
					} else {
						value = String.valueOf(fieldValue);
					}
				}
			}
			fields.add(new OnlineEditor.Field(f.name, value, f.type));
		}
		if (Collection.isNotEmpty(onlineEditorQuery.children)) {
			for (OnlineEditor.Query child : onlineEditorQuery.children) {
				List<SObject> tempData = data.getSObjects(child.relationship);
				if (Collection.isNotEmpty(tempData)) {
					for (SObject childData : tempData) {
						childQueries.add(convertData(child, childData));
					}
				} else {
					childQueries.add(child);
				}
			}
		}
		return new OnlineEditor.Query(onlineEditorQuery.type, onlineEditorQuery.relationship, fields, childQueries);
	}

	public static Gen.Query convertQuery(final OnlineEditor.Query onlineEditorQuery) {
		Permissions.verifyIsDocuSignGenerator();

		List<String> genFields = new List<String>();
		List<Gen.Query> listGenQuery = new List<Gen.Query>();

		if (Collection.isNotEmpty(onlineEditorQuery.fields)) {
			genFields = convertFields(onlineEditorQuery.fields);
		}

		if (Collection.isNotEmpty(onlineEditorQuery.children)) {
			for (OnlineEditor.Query child : onlineEditorQuery.children) {
				listGenQuery.add(convertQuery(child));
			}
		}

		Gen.Query result = new Gen.Query(
			onlineEditorQuery.type,
			onlineEditorQuery.relationship,
			genFields,
			listGenQuery);

		return result;
	}

	@TestVisible
	private static List<String> convertFields(final List<OnlineEditor.Field> fields) {
		Permissions.verifyIsDocuSignGenerator();

		List<String> genFields = new List<String>();
		for (OnlineEditor.Field f : fields) {
			genFields.add(f.name);
		}
		return genFields;
	}

	@TestVisible
	private static String getFileName(final String fileName, final String fileSuffix, final String dataSource) {
		String formattedFileName;
		if (fileSuffix == 'Main Data Source Name') {
			formattedFileName = String.format('{0} {1}', new List<String> { fileName, dataSource });
		} else if (fileSuffix == 'Date') {
			formattedFileName = String.format('{0} {1}', new List<String> { fileName, StringUtils.formatDatetime(Datetime.now()) });
		} else if (fileSuffix == 'Main Data Source Name and Date') {
			formattedFileName = String.format('{0} {1} {2}', new List<String> { fileName, dataSource, StringUtils.formatDatetime(Datetime.now()) });
		} else if (String.isBlank(fileName)) {
			formattedFileName = Label.Untitled;
		} else {
			formattedFileName = fileName;
		}

		formattedFileName = formattedFileName.length() > 75 ? formattedFileName.substring(0, 75) + '.html' : formattedFileName + '.html';
		return formattedFileName;
	}
}
