public with sharing class GenController extends Controller {

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

	public GenController() {
		onlineEditorInit();
	}

	public GenController(final ApexPages.StandardController c) {
		this();
	}

	public PageReference redirectOnEdit() {
		PageReference redirectPage;
		QueryString params = QueryString.fromCurrentPage();
		Id templateId = params.getId('id', params.getId('templateId', null));
		if (templateId != null) {
			Gen.Template template = GenService.getTemplate(templateId);
			Boolean editMode = template.templateType.equals(Gen.ONLINE_EDITOR_TYPE) ? template.springTemplateId != null : true;
			redirectPage = new PageReference(GenService.getTemplateUrl(template, false).toExternalForm());
			redirectPage.getParameters().put('isEdit', String.valueOf(editMode));
			redirectPage.setRedirect(true);
		}
		return redirectPage;
	}

	public PageReference redirectOnNewTemplate() {
		PageReference redirectPage;
		QueryString params = QueryString.fromCurrentPage();
		Id templateId = params.getId('id', params.getId('templateId', null));
		if (templateId != null) {
			Gen.Template template = GenService.getTemplate(templateId);
			redirectPage = new PageReference(GenService.getTemplateUrl(template, false).toExternalForm());
			redirectPage.getParameters().put('isEdit', 'false');
			redirectPage.setRedirect(true);
		}
		return redirectPage;
	}

	@RemoteAction
	public static Gen.Template clone(final Id templateId) {
		try {
			return GenService.clone(templateId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to clone Gen template.');
		}
	}

	public void onlineEditorInit() {
		try {
			Permissions.verifyIsDocuSignGenerator();
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

	public class Configuration {
		@AuraEnabled
		public Gen.Template template { get; private set; }
		@AuraEnabled
		public List<MergeObject> commonObjects { get; private set; }
		@AuraEnabled
		public List<MergeObject> allObjects { get; private set; }
		@AuraEnabled
		public Boolean isMultiCurrencyOrganization { get; private set; }

		private Configuration(
			final Gen.Template template,
			final List<MergeObject> commonObjects,
			final List<MergeObject> allObjects,
			final Boolean isMultiCurrencyOrganization) {

			this.template = template;
			this.commonObjects = commonObjects == null ? new List<MergeObject>() : commonObjects;
			this.allObjects = allObjects == null ? new List<MergeObject>() : allObjects;
			this.isMultiCurrencyOrganization = isMultiCurrencyOrganization;
		}
	}

	@AuraEnabled
	public static Configuration getConfiguration(final Id templateId) {
		try {
			return new Configuration(
				templateId == null
					? GenService.createBlankTemplate()
					: GenService.getTemplate(templateId),
				MetadataService.getCommonObjects(),
				MetadataService.getObjects(),
				UserInfo.isMultiCurrencyOrganization());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to retrieve Gen template configuration.');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static List<MergeField> getMergeFields(final String sObjectType, final Boolean isChild) {
		try {
			return MetadataService.getFields(Salesforce.getSObjectType(sObjectType), isChild);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to retrieve merge fields.');
		}
	}

	@AuraEnabled
	public static Gen.Template saveTemplate(final String templateJson) {
		try {
			return GenService.saveTemplate((Gen.Template)JSON.deserialize(templateJson, Gen.Template.class));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to save Gen template.');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static Gen.Template getTemplate(final Id templateId) {
		try {
			return GenService.getTemplate(templateId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to retrieve Gen template.');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static Boolean checkMultiCurrency() {
		try {
			return GenService.checkMultiCurrency();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to check multi currency');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static Id getLatestRecordId(final String sObjectType) {
		try {
			return (Id)Collection.head(GenService.getRecentRecordIds(Salesforce.getSObjectType(sObjectType), 1));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get latest record ID for ' + sObjectType);
		}
	}

	@AuraEnabled(Cacheable = true)
	public static SObject getMergeData(final Id sourceId, final String queryJson) {
		try {
			return GenService.getMergeData(sourceId, (Gen.Query)JSON.deserialize(queryJson, Gen.Query.class));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get object merge data.');
		}
	}

	@AuraEnabled
	public static Gen.File saveChunk(
		final Id contentVersionId,
		final Id linkedEntityId,
		final String fileName,
		final String base64Data) {

		try {
			return GenService.saveFile(contentVersionId, linkedEntityId, fileName, base64Data);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to save file chunk');
		}
	}

	@AuraEnabled
	public static Boolean deleteContentDocument(final Id contentVersionId) {
		try {
			return GenService.deleteContentDocument(contentVersionId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to delete content document');
		}
	}

	@AuraEnabled
	public static List<Gen.Job> queueDocumentGeneration(
		final Id templateId,
		final Id sourceId,
		final String xmlPayload,
		final Boolean isPreview,
		final List<Id> contentDocumentIds) {

		try {
			return GenService.queueDocumentGeneration(templateId, sourceId, xmlPayload, isPreview, contentDocumentIds);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to generate documents.');
		}
	}

	@AuraEnabled
	public static List<Gen.Job> getJobStatus(final List<String> jobIds) {
		try {
			List<UUID> jobIdsList = new List<UUID>();
			if (!Collection.isEmpty(jobIds)) {
				for (String stringJobId : jobIds) {
					jobIdsList.add(UUID.parse(stringJobId));
				}
			}
			return GenService.getJobStatus(jobIdsList);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get job status.');
		}
	}

	@AuraEnabled
	public static String getSendingDeepLink(final Id sourceId, final String fileIdsInCommaSeparated) {
		try {
			return FileService.getSendingDeepLink(sourceId, fileIdsInCommaSeparated).toExternalForm();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get deep link');
		}
	}

	@AuraEnabled
	public static NegotiateAPI.TaskStatus createAgreementInEOSFolder(final Id sfContentVersionId, final Id sourceObjectId, final String documentName) {
		try {
			return NegotiateService.createAgreementInEOSFolder(sfContentVersionId, sourceObjectId, documentName);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to create Agreement Folder');
		}
	}

	@AuraEnabled
	public static Agreement getAgreement(final String agreementId) {
		try {
			return NegotiateService.getAgreement(UUID.parse(agreementId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get Agreement.');
		}
	}

	@AuraEnabled
	public static Map<String, String> getTemplateTypes() {
		try {
			return GenService.getGenTemplateValues();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get Template Types.');
		}
	}

	@AuraEnabled
	public static String prepareCancelUrl() {
		try {
			Permissions.verifyIsDocuSignGenerator();
			return new Url(
				Salesforce.baseUrl,
				'/' + GenTemplate__c.getSObjectType().getDescribe().getKeyPrefix() + '/o')
				.toExternalForm();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to Prepare Cancel Url.');
		}
	}

	@RemoteAction
	public static Negotiate.LimitedAccessToken generateUploadToken(String templateFolderId) {
		try {
			return GenService.generateUploadToken(UUID.parse(templateFolderId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to execute generateUploadToken.');
		}

	}

	@RemoteAction
	public static List<SObject> getEntityRecords(final String sourceObject) {
		try {
			return GenService.getRelatedEntityRecords(Salesforce.getSObjectType(sourceObject));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to execute getEntityRecords.');
		}

	}

	@RemoteAction
	public static String getTemplateFolderId() {
		try {
			return GenService.getTemplateFolderId().toString();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to execute getTemplateFolderId.');
		}
	}

	@RemoteAction
	public static Boolean deleteTemplate(final Id templateId) {
		try {
			return GenService.deleteTemplate(templateId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to execute deleteTemplate.');
		}
	}

	@RemoteAction
	public static List<Layout> getLayouts(final String sObjectType) {
		try {
			Permissions.verifyIsDocuSignGenerator();
			return MetadataController.getLayouts(sObjectType);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to execute getLayouts.');
		}
	}

	@RemoteAction
	public static MergeFieldsResult getMergeFields(final String sObjectType) {
		try {
			Permissions.verifyIsDocuSignGenerator();
			OnlineEditorMergeObject obj = MetadataService.getObjectsRecursively(Salesforce.getSObjectType(sObjectType));
			return new MergeFieldsResult(new List<OnlineEditorMergeObject> { obj }, MetadataService.getFieldsRecursively(obj));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to execute getMergeFields.');
		}
	}

	@RemoteAction
	public static List<Layout> updateLayouts(
		final String sObjectType,
		final String layoutsJson,
		final String parameters) {

		try {
			Permissions.verifyIsDocuSignGenerator();
			return MetadataService.updateLayouts(
				Salesforce.getSObjectType(sObjectType),
				(List<Layout>)JSON.deserialize(layoutsJson, List<Layout>.class), parameters);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to execute updateLayouts.');
		}
	}

	@RemoteAction
	public static UUID getSpringTemplateIdInUUIDFormat(final String springTemplateId) {
		try {
			Permissions.verifyIsDocuSignGenerator();
			return UUID.parse(springTemplateId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to getSpringTemplateIdInUUIDFormat.');
		}
	}

	@RemoteAction
	public static Gen.Template updateTemplate(final String templateJson) {
		try {
			return GenService.saveTemplate((Gen.Template)JSON.deserialize(templateJson, Gen.Template.class));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to save Gen template.');
		}
	}

	@RemoteAction
	public static Negotiate.LimitedAccessToken generateDownloadToken(final String scmFileId) {
		try {
			return NegotiateService.generateDownloadToken(UUID.parse(scmFileId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to execute generateDownloadToken.');
		}
	}

	@RemoteAction
	public static Id saveAttachments(final String recordId, final String htmlData, String salesforceOnlineEditorTemplateId) {
		try {
			return GenService.saveAttachments((Id)recordId, htmlData, (Id)salesforceOnlineEditorTemplateId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to execute saveAttachments.');
		}
	}

	@RemoteAction
	public static OnlineEditor.Query getOnlineEditorMergeData(final String sourceId, final String queryJson) {
		try {
			OnlineEditor.Query onlineEditorQuery = (OnlineEditor.Query)JSON.deserialize(queryJson, OnlineEditor.Query.class);
			if (sourceId == null || onlineEditorQuery == null) throw new DocuSignException(Label.UndefinedArgument);
			Gen.Query genQuery = GenService.convertQuery(onlineEditorQuery);
			SObject result = GenService.getMergeData(sourceId, genQuery);
			return GenService.convertData(onlineEditorQuery, result);
		} catch (Exception ex) {
			return new OnlineEditor.Query('', '', null, null);
		}
	}
}
