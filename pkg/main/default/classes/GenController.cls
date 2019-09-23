public with sharing class GenController extends Controller {

	public GenController() {
	}

	public GenController(final ApexPages.StandardController c) {
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
		final String xmlPayload, // FIXME: Generate XML in service class. The callout payload must be opaque to clients.
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
			return EnvelopeService.getSendingDeepLink(sourceId, fileIdsInCommaSeparated).toExternalForm();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get deep link');
		}
	}

	@AuraEnabled
	public static boolean isEsignEnabled() {
		try {
			return AccountProducts.isEsignEnabled();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to check esign Products on account.');
		}
	}
}
