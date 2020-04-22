public with sharing class GenController extends Controller {

	public Id templateId { get; set; }
	public String errorMessage { get; private set; }
	public String objectHomeUrl { get; private set; }

	public GenController() {
		this.objectHomeUrl = '/' + GenTemplate__c.getSObjectType().getDescribe().getKeyPrefix() + '/o';
	}

	//noinspection ApexUnusedDeclaration
	public GenController(final ApexPages.StandardController c) {
		this();
	}

	public PageReference redirectOnEdit() {
		PageReference redirectPage = null;
		try {
			Permissions.verifyIsDocuSignAdministrator();
			QueryString params = QueryString.fromCurrentPage();
			this.templateId = params.getId('templateId', params.getId('id', null));
			if (this.templateId != null) {
				Gen.Template template = GenService.getTemplate(this.templateId);
				Boolean editMode = template.templateType != Gen.TYPE_ONLINE || template.springTemplateId != null;
				redirectPage = GenService.getTemplatePage(template, false);
				redirectPage.getParameters().put('isEdit', String.valueOf(editMode));
				redirectPage.setRedirect(true);
			}
		} catch (Exception ex) {
			this.errorMessage = ex.getMessage();
			LoggerService.getInstance().exception(ex, 'Failed to redirect to Gen template page');
		}
		return redirectPage;
	}

	public PageReference redirectOnNewTemplate() {
		PageReference redirectPage;
		try {
			Permissions.verifyIsDocuSignAdministrator();
			if (this.templateId != null) {
				Gen.Template template = GenService.getTemplate(this.templateId);
				redirectPage = GenService.getTemplatePage(template, false);
				redirectPage.getParameters().put('isEdit', 'false');
				redirectPage.setRedirect(true);
			}
		} catch (Exception ex) {
			this.errorMessage = ex.getMessage();
			LoggerService.getInstance().exception(ex, 'Failed to redirect to Gen template page');
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
	public static List<MergeField> getMergeFields(
		final String sObjectType,
		final Integer depth) {

		try {
			return MetadataService.getFields(Salesforce.getSObjectType(sObjectType), depth > 0 ? depth : 1);
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
			Permissions.verifyIsDocuSignAdministratorOrGenerator();

			return UserInfo.isMultiCurrencyOrganization();
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
	public static Query.Result getMergeData(
		final Id sourceId,
		final String queryJson) {

		try {
			return GenService.getMergeData(sourceId, (Query)JSON.deserialize(queryJson, Query.class));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get object merge data.');
		}
	}

	@AuraEnabled
	public static Boolean validateChildRelationshipField(
		final String fieldJSON,
		final Integer depth) {
		
		try {
			return GenService.validateChildRelationshipField((Gen.Field) JSON.deserialize(fieldJSON, Gen.Field.class), depth);
		} catch(Exception ex) {
			throw Controller.wrapException(ex, 'Add error here.');
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
	public static String getSendingDeepLink(
		final Id sourceId,
		final List<String> files) {

		try {
			PageReference pg = FileService.getSendingDeepLink(sourceId, files);
			return pg == null ? null : pg.getUrl();
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
			return GenService.getTemplateTypes();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get Template Types.');
		}
	}

	@AuraEnabled
	public static Boolean deleteTemplate(final Id templateId) {
		try {
			return GenService.deleteTemplate(templateId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to delete template.');
		}
	}

	@AuraEnabled
	public static UUID getTempEOSFolderId(final Id sourceId) {
		try {
			return GenService.getTempEOSFolderId(sourceId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to fetch Eos Folder');
		}
	}

	@AuraEnabled
	public static LimitedAccessToken generateLimitedAccessToken(final String entityId) {
		try {
			return GenService.generateLimitedAccessToken(UUID.parse(entityId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to generate Limited Access Token');
		}
	}

	@AuraEnabled
	public static void convertHtmlDocumentToWord(final String documentId) {
		try {
			GenService.convertHtmlDocumentToWord(UUID.parse(documentId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to convert html document to word');
		}
	}

	@AuraEnabled
	public static void deleteDocument(final String documentId) {
		try {
			GenService.deleteScmDocument(UUID.parse(documentId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to delete document');
		}
	}

	@AuraEnabled
	public static String getFileName(final Id templateId, final String recordName) {
		try {
			Gen.Template template = GenService.getTemplate(templateId);
			return getFileName(template.fileName, template.fileSuffix, recordName);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get  file name');
		}
	}

	@TestVisible
	private static String getFileName(final String fileName, final String fileSuffix, final String recordName) {
		String formattedFileName;
		if (fileSuffix == 'Main Data Source Name') {
			formattedFileName = String.format('{0} {1}', new List<String> { fileName, recordName });
		} else if (fileSuffix == 'Date') {
			formattedFileName = String.format('{0} {1}', new List<String> { fileName, Datetime.now().format() });
		} else if (fileSuffix == 'Main Data Source Name and Date') {
			formattedFileName = String.format('{0} {1} {2}', new List<String> { fileName, recordName, Datetime.now().format() });
		} else if (String.isBlank(fileName)) {
			formattedFileName = Label.Untitled;
		} else {
			formattedFileName = fileName;
		}
		formattedFileName = StringUtils.replaceSpecialCharacter(formattedFileName.trim(), '_');
		return formattedFileName.length() > 75 ? formattedFileName.substring(0, 75) : formattedFileName;
	}
}
