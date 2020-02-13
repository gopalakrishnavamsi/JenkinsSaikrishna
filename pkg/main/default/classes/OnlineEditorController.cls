// This class supports the online editor experience. Anything unique to that should be specified here. Eventually we
// will consolidate the logic between the experiences.
public with sharing class OnlineEditorController extends Controller {

	public String errorMessage { get; private set; }
	public String templateJson { get; private set; }
	public String templateName { get; set; }
	public Boolean editMode { get; private set; }
	public String layoutActionName {
		get {
			return Layout.ACTION_NAME_ONLINEEDITOR;
		}
	}
	public String layoutActionType {
		get {
			return Layout.ACTION_TYPE_ONLINEEDITOR;
		}
	}
	public String docuSignAccountId { get; private set; }
	public String docuSignUserId { get; private set; }
	public String docuSignEnvironment { get; private set; }
	public String templateListUrl { get; private set; }
	//OnlineEditor

	public OnlineEditorController() {
		onlineEditorInit();
	}

	//noinspection ApexUnusedDeclaration
	public OnlineEditorController(final ApexPages.StandardController c) {
		this();
	}

	public class Query {
		@AuraEnabled
		public String type { get; set; }
		@AuraEnabled
		public String relationship { get; set; }
		@AuraEnabled
		public List<OnlineEditorController.Field> fields { get; set; }
		@AuraEnabled
		public List<OnlineEditorController.Query> children { get; set; }

		public Query(
			final String type,
			final String relationship,
			final List<OnlineEditorController.Field> fields,
			final List<OnlineEditorController.Query> children) {

			this.type = type;
			this.relationship = relationship;
			this.fields = fields == null ? new List<OnlineEditorController.Field>() : fields;
			this.children = children == null ? new List<OnlineEditorController.Query>() : children;
		}
	}

	public class Field {
		@AuraEnabled
		public String name { get; set; }
		@AuraEnabled
		public String value { get; set; }
		@AuraEnabled
		public String type { get; set; }

		public Field(
			final String name,
			final String value,
			final String type) {

			this.name = name;
			this.value = value == null ? '' : value;
			this.type = type;
		}
	}

	public class MergeFieldsResult {
		@AuraEnabled
		public OnlineEditorMergeObject[] objects { get; private set; }
		@AuraEnabled
		public Map<String, MergeField[]> fields { get; private set; }

		public MergeFieldsResult(
			final OnlineEditorMergeObject[] objects,
			final Map<String, MergeField[]> fields) {

			this.objects = objects;
			this.fields = fields;
		}
	}

	public void onlineEditorInit() {
		try {
			if (!Permissions.isDocuSignAdministrator() && !Permissions.isDocuSignGenerator()) {
				throw new UnauthorizedException(
					Label.MustBeAdministratorOrGenerator,
					UnauthorizedException.AccessRequirement.SecurityPermission);
			}
			QueryString params = QueryString.fromCurrentPage();
			Id templateId = params.getId('id', params.getId('templateId', null));
			Boolean isEdit = params.getBoolean('isEdit', false);
			Boolean isFromSetupWizard = params.getBoolean('isFromSetupWizard', false);
			this.editMode = templateId != null && isEdit;
			if (templateId != null) {
				Gen.Template template = GenService.getTemplate(templateId) ;
				this.templateJson = JSON.serialize(template);
				this.templateName = template.name;
			}
			// TODO: Need to obfuscate these IDs?
			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			this.docuSignAccountId = settings.AccountId__c;
			this.docuSignUserId = [SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Username__c;
			this.docuSignEnvironment = settings.Environment__c;
			this.templateListUrl = isFromSetupWizard ? new Url(
				Salesforce.baseUrl,
				Page.Setup.getUrl()
			).toExternalForm() : new Url(
				Salesforce.baseUrl,
				'/' + GenTemplate__c.getSObjectType().getDescribe().getKeyPrefix() + '/o'
			).toExternalForm();
		} catch (Exception ex) {
			this.errorMessage = ex.getMessage();
			LoggerService.getInstance().error(ex.getMessage());
			throw Controller.wrapException(ex, 'Failed to invoke constructor.');
		}
	}

	public void verifyDocuSignGenerator() {
		try {
			Permissions.verifyIsDocuSignGenerator();
		} catch (Exception ex) {
			this.errorMessage = ex.getMessage();
			LoggerService.getInstance().exception(ex, 'failed to validate docusign generator');
		}
	}

	@TestVisible
	private static List<String> convertFields(final List<OnlineEditorController.Field> fields) {
		Permissions.verifyIsDocuSignGenerator();

		List<String> genFields = new List<String>();
		for (OnlineEditorController.Field f : fields) {
			genFields.add(f.name);
		}
		return genFields;
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

	// FIXME: Address formatting is locale dependent.
	@TestVisible
	private static String formatAddress(final Address location) {
		return location == null
			? null
			: String.join(new List<String> {
				location.Street, location.City, location.State + ' ' + location.PostalCode, location.Country
			}, ', ');
	}

	@TestVisible
	private static Gen.Query convertQuery(final OnlineEditorController.Query onlineEditorQuery) {
		Permissions.verifyIsDocuSignGenerator();

		List<String> genFields = new List<String>();
		List<Gen.Query> listGenQuery = new List<Gen.Query>();

		if (Collection.isNotEmpty(onlineEditorQuery.fields)) {
			genFields = convertFields(onlineEditorQuery.fields);
		}

		if (Collection.isNotEmpty(onlineEditorQuery.children)) {
			for (OnlineEditorController.Query child : onlineEditorQuery.children) {
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
	private static OnlineEditorController.Query convertData(
		final OnlineEditorController.Query onlineEditorQuery,
		final SObject data) {

		Permissions.verifyIsDocuSignGenerator();

		List<OnlineEditorController.Query> childQueries = new List<OnlineEditorController.Query>();
		List<OnlineEditorController.Field > fields = new List<OnlineEditorController.Field >();
		for (OnlineEditorController.Field f : onlineEditorQuery.fields) {
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
						value = formatAddress((Address)fieldValue);
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
						value = formatAddress((Address)fieldValue);
					} else {
						value = String.valueOf(fieldValue);
					}
				}
			}
			fields.add(new OnlineEditorController.Field(f.name, value, f.type));
		}
		if (Collection.isNotEmpty(onlineEditorQuery.children)) {
			for (OnlineEditorController.Query child : onlineEditorQuery.children) {
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
		return new OnlineEditorController.Query(
			onlineEditorQuery.type,
			onlineEditorQuery.relationship,
			fields,
			childQueries);
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

	private static OnlineEditorMergeObject getObjectsRecursively(final SObjectType type) {
		if (type == null) throw new DocuSignException(Label.UndefinedArgument);
		Permissions.verifyIsDocuSignAdministrator();

		OnlineEditorMergeObject obj = OnlineEditorMergeObject.forType(type.getDescribe());
		Map<String, String[]> resolvedObjects = new Map<String, String[]>();
		String[] path = new List<String>();
		return getObjectsRecursively(obj, 1, resolvedObjects, path);
	}

	private static OnlineEditorMergeObject getObjectsRecursively(
		final OnlineEditorMergeObject obj,
		Integer depth,
		Map<String, String[]> resolvedObjects,
		String[] path) {

		if (!OnlineEditorMergeObject.isValid(obj.describe)) {
			return obj;
		}
		if (depth == 1) {
			obj.children.addAll(getChildRelationships(obj.describe));
		}

		if (!resolvedObjects.containsKey(obj.name)) {
			resolvedObjects.put(obj.name, path);
		}
		path.add(obj.name);
		for (OnlineEditorMergeObject refObject : getReferenceObjects(obj.describe)) {
			if (!resolvedObjects.containsKey(refObject.name)) {
				obj.children.add(getObjectsRecursively(refObject, depth + 1, resolvedObjects, path.clone()));
			} else {
				refObject.childrenPath = resolvedObjects.get(refObject.name);
				obj.children.add(refObject);
			}
		}

		return obj;
	}

	@TestVisible
	private static List<OnlineEditorMergeObject> getReferenceObjects(final DescribeSObjectResult type) {
		List<OnlineEditorMergeObject> result = new List<OnlineEditorMergeObject>();
		for (SObjectField f : type.fields.getMap().values()) {
			DescribeFieldResult field = f.getDescribe();
			if (!field.getReferenceTo().isEmpty() && OnlineEditorMergeObject.isValid(field)) {
				result.add(OnlineEditorMergeObject.forField(field));
			}
		}
		return result;
	}

	@TestVisible
	private static List<OnlineEditorMergeObject> getChildRelationships(final DescribeSObjectResult type) {
		List<OnlineEditorMergeObject> result = new List<OnlineEditorMergeObject>();
		for (Schema.ChildRelationship cr : type.getChildRelationships()) {
			if (MergeField.isValid(cr)) {
				OnlineEditorMergeObject obj = OnlineEditorMergeObject.forChildRelationship(cr);
				result.add(obj);
			}
		}
		return result;
	}

	@TestVisible
	private static List<MergeField> getOnlineEditorFields(final DescribeSObjectResult type) {
		List<MergeField> result = new List<MergeField>();
		for (SObjectField f : type.fields.getMap().values()) {
			DescribeFieldResult field = f.getDescribe();
			if (field.getReferenceTo().isEmpty() && MergeField.isValid(field)) {
				result.add(MergeField.forField(field, null));
			}
		}
		return result;
	}

	@TestVisible
	private static Map<String, MergeField[]> getFieldsRecursively(final OnlineEditorMergeObject obj) {
		Map<String, MergeField[]> fields = new Map<String, MergeField[]>();
		return getFieldsRecursively(obj, fields);
	}

	@TestVisible
	private static Map<String, MergeField[]> getFieldsRecursively(final OnlineEditorMergeObject obj, Map<String, MergeField[]> fields) {
		if (!fields.containsKey(obj.name)) {
			fields.put(obj.name, getOnlineEditorFields(obj.describe));
		}
		for (OnlineEditorMergeObject child : obj.children) {
			getFieldsRecursively(child, fields);
		}
		return fields;
	}

	@RemoteAction
	public static LimitedAccessToken generateUploadToken(String templateFolderId) {
		GenService.verifyIsDocuSignAdministratorOrGenerator();

		return ScmTokenAPI.getInstance().generateLimitedAccessToken(
			UUID.parse(templateFolderId),
			AuthService.getContentAccessToken());
	}

	@RemoteAction
	public static List<SObject> getEntityRecords(final String sourceObject) {
		Permissions.verifyIsDocuSignAdministrator();

		SObjectType type = Salesforce.getSObjectType(sourceObject);
		String nameField = Salesforce.getNameField(type);
		List<String> fields = new List<String> { 'Id', nameField };

		Permissions.verifyIsQueryable(type, fields);

		return System.Database.query(String.format('SELECT {0} FROM {1} LIMIT 25', new List<String> {
			String.join(fields, ','),
			type.getDescribe().getName()
		}));

	}

	@RemoteAction
	public static String getTemplateFolderId() {
		Permissions.verifyIsDocuSignAdministrator();

		String templateFolderId;
		OnlineEditorRoot__c onlineEditorRootFolderSettings = OnlineEditorRoot__c.getOrgDefaults();
		if (onlineEditorRootFolderSettings.FolderId__c != null) {
			templateFolderId = onlineEditorRootFolderSettings.FolderId__c;
		} else {
			NegotiateAPI client = NegotiateAPI.getInstance();
			templateFolderId = String.valueOf(client.getTemplateHtmlFolder());
			onlineEditorRootFolderSettings.FolderId__c = templateFolderId;
			upsert onlineEditorRootFolderSettings;
		}
		return templateFolderId;
	}

	@RemoteAction
	public static Boolean deleteTemplate(final Id templateId) {
		return GenService.deleteTemplate(templateId);
	}

	@RemoteAction
	public static List<Layout> getLayouts(final String sObjectType) {
		Permissions.verifyIsDocuSignAdministrator();

		return MetadataController.getLayouts(sObjectType);
	}

	@RemoteAction
	public static MergeFieldsResult getMergeFields(final String sObjectType) {
		Permissions.verifyIsDocuSignAdministrator();

		OnlineEditorMergeObject obj = getObjectsRecursively(Salesforce.getSObjectType(sObjectType));
		return new MergeFieldsResult(new List<OnlineEditorMergeObject> { obj }, getFieldsRecursively(obj));
	}

	@RemoteAction
	public static List<Layout> updateLayouts(
		final String sObjectType,
		final String layoutsJson,
		final String parameters) {

		Permissions.verifyIsDocuSignAdministrator();

		Gen.LayoutParameters params = (Gen.LayoutParameters)JSON.deserialize(parameters, Gen.LayoutParameters.class);
		Gen.Template template = GenService.getTemplate((Id)params.genTemplateId);

		return MetadataService.updateLayouts(
			Salesforce.getSObjectType(sObjectType),
			(List<Layout>)JSON.deserialize(layoutsJson, List<Layout>.class),
			parameters,
			template.springTemplateId);
	}

	// FIXME: This is a mostly useless function. If the springTemplateId is needed in UUID form on the client, just create it there.
	@RemoteAction
	public static UUID getSpringTemplateIdInUUIDFormat(final String springTemplateId) {
		return UUID.parse(springTemplateId);
	}

	@RemoteAction
	public static Gen.Template updateTemplate(final String templateJson) {
		return GenService.saveTemplate((Gen.Template)JSON.deserialize(templateJson, Gen.Template.class));
	}

	@RemoteAction
	public static LimitedAccessToken generateDownloadToken(final String scmFileId) {
		GenService.verifyIsDocuSignAdministratorOrGenerator();

		return ScmTokenAPI.getInstance().generateLimitedAccessToken(
			UUID.parse(scmFileId),
			AuthService.getContentAccessToken());
	}

	@RemoteAction
	public static Id saveAttachments(
		final Id recordId,
		final String htmlData,
		final Id templateId) {

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

		Gen.Template genTemplate = GenService.getTemplate(templateId);
		String fileName = getFileName(genTemplate.fileName, genTemplate.fileSuffix, genTemplate.sourceObject);
		ContentVersion attachment = new ContentVersion();
		attachment.VersionData = Blob.valueOf(htmlData);
		attachment.Title = fileName;
		attachment.PathOnClient = fileName;
		insert attachment;

		ContentDocumentLink attachmentLink = new ContentDocumentLink();
		attachmentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :attachment.Id].ContentDocumentId;
		attachmentLink.LinkedEntityId = recordId;
		attachmentLink.ShareType = 'V';
		insert attachmentLink;

		return attachment.Id;
	}

	// FIXME: Don't swallow exceptions. This will be a support driver.
	@RemoteAction
	public static OnlineEditorController.Query getMergeData(
		final Id sourceId,
		final String queryJson) {

		try {
			if (sourceId == null || String.isBlank(queryJson) == null) {
				throw new DocuSignException(Label.UndefinedArgument);
			}

			OnlineEditorController.Query onlineEditorQuery = (OnlineEditorController.Query)JSON.deserialize(
				queryJson,
				OnlineEditorController.Query.class);

			// TODO: Chorus should support Word query results
			Gen.Query genQuery = convertQuery(onlineEditorQuery);
			SObject result = GenService.getMergeData(sourceId, genQuery);

			return convertData(onlineEditorQuery, result);
		} catch (Exception ex) {
			LoggerService.getInstance().exception(ex, 'Failed to get online editor merge data');
			return new OnlineEditorController.Query('', '', null, null);
		}
	}
}
