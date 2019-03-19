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
	public static List<MergeField> getMergeFields(final String sObjectType) {
		try {
			return MetadataService.getFields(Salesforce.getSObjectType(sObjectType));
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
	public static List<Gen.Job> getJobStatus(final List<UUID> jobIds) {
		try {
			return GenService.getJobStatus(jobIds);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get job status.');
		}
	}
}