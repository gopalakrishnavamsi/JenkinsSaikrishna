public with sharing class EnvelopeConfigurationController extends Controller {

	public String objectHomeUrl { get; private set; }
	public Id envelopeConfigId { get; set; }

	public class LayoutParameters {
		public String decButtonApiName { get; private set; }
		public String decButtonLabel { get; private set; }
		public String decTemplateId { get; private set; }
	}

	public EnvelopeConfigurationController() {
		this.objectHomeUrl = '/' + EnvelopeConfiguration__c.getSObjectType().getDescribe().getKeyPrefix() + '/o';
	}

	//noinspection ApexUnusedDeclaration
	public EnvelopeConfigurationController(final ApexPages.StandardController c) {
		this();
	}

	@TestVisible
	private static String queryEntityPhone(final Id entityId) {
		if (entityId == null) return null;
		SObjectType objectType = entityId.getSobjectType();
		if (!RecipientService.canResolveRecipientType(objectType))  return null;
		Query phoneQuery = Query.newQuery(
			String.valueOf(objectType), 
			new List<String>{ 'Id', 'MobilePhone' },
			null
		);
		Query.Result queryResult = phoneQuery.execute(entityId);
		return (String) queryResult.result.get('MobilePhone');
	}

	@TestVisible
	private static EnvelopeConfiguration parseUpdates(final String envelopeConfigurationJSON, final Boolean attachSourceFiles) {
		Map<String, Object> untypedConfig = (Map<String, Object>)JSON.deserializeUntyped(envelopeConfigurationJSON);
		List<Recipient> recipients = parseRecipients((List<Object>)untypedConfig.get('recipients'));
		List<Document> documents = parseDocuments((List<Object>)untypedConfig.get('documents'), attachSourceFiles);
		EnvelopeConfiguration configuration = (EnvelopeConfiguration)JSON.deserialize(envelopeConfigurationJSON, EnvelopeConfiguration.class);
		return configuration.withRecipients(recipients).withDocuments(documents);
	}

	@TestVisible
	private static List<Document> parseDocuments(final List<Object> documentsNode, final Boolean attachSourceFiles) {
		List<Document> results = new List<Document>();
		if (Collection.isEmpty(documentsNode)) return results;

		for (Object node : documentsNode) {
			Map<String, Object> nodeMap = (Map<String, Object>)node;
			if (nodeMap.containsKey('type')) {
				String type = (String)nodeMap.get('type');
				if (type == EnvelopeConfiguration.DOCUMENT_TYPE_SOURCE_FILES && attachSourceFiles) {
					results.add((EnvelopeConfiguration.SourceFiles)JSON.deserialize(JSON.serialize((Object)nodeMap), EnvelopeConfiguration.SourceFiles.class));
				} else if (type == EnvelopeConfiguration.DOCUMENT_TYPE_TEMPLATE_DOCUMENT) {
					results.add((EnvelopeConfiguration.TemplateDocument)JSON.deserialize(JSON.serialize((Object)nodeMap), EnvelopeConfiguration.TemplateDocument.class));
				}
			} else {
				results.add((Document)JSON.deserialize(JSON.serialize((Object)nodeMap), Document.class));
			}
		}
		return results;
	}

	@TestVisible
	private static List<Recipient> parseRecipients(final List<Object> recipientsNode) {
		List<Recipient> results = new List<Recipient>();
		if (Collection.isEmpty(recipientsNode)) return results;

		for (Object node : recipientsNode) {
			Map<String, Object> nodeMap = (Map<String, Object>)node;
			if (nodeMap.containsKey('relationship')) {
				Query.Relationship relationship = (Query.Relationship)JSON.deserialize(JSON.serialize((Object)nodeMap.get('relationship')), Query.Relationship.class);
				if (relationship != null && relationship.isLookup) {
					results.add((EnvelopeConfiguration.LookupRecipient)JSON.deserialize(JSON.serialize((Object)nodeMap), EnvelopeConfiguration.LookupRecipient.class));
				} else if (relationship != null && !relationship.isLookup) {
					results.add((EnvelopeConfiguration.RelatedRecipients)JSON.deserialize(JSON.serialize((Object)nodeMap), EnvelopeConfiguration.RelatedRecipients.class));
				} else {
					results.add((Recipient)JSON.deserialize(JSON.serialize((Object)nodeMap), Recipient.class));
				}
			} else {
				results.add((Recipient)JSON.deserialize(JSON.serialize((Object)nodeMap), Recipient.class));
			}
		}
		return results;
	}

	@AuraEnabled
	public static EnvelopeConfiguration createEnvelopeConfiguration(final String envelopeConfigurationJSON) {
		try {
			return EnvelopeConfigurationService.createEnvelopeConfiguration(parseUpdates(envelopeConfigurationJSON, false));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to create envelope configuration.');
		}
	}

	@AuraEnabled
	public static EnvelopeConfiguration updateEnvelopeConfiguration(
		final String envelopeConfigurationJSON,
		final Boolean attachSourceFiles,
		final List<Id> contentDocumentIdsToDelete) {
		try {
			EnvelopeConfiguration ec = EnvelopeConfigurationService.updateEnvelopeConfiguration(parseUpdates(envelopeConfigurationJSON, attachSourceFiles));
			if (Collection.isNotEmpty(contentDocumentIdsToDelete)) {
				EnvelopeConfigurationService.deleteContentDocuments(contentDocumentIdsToDelete);
			}
			return parseEnvelopeConfiguration(ec);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to update envelope configuration.');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static EnvelopeConfiguration getEnvelopeConfiguration(final Id recordId) {
		try {
			EnvelopeConfiguration ec = EnvelopeConfigurationService.getEnvelopeConfiguration(recordId);
			return parseEnvelopeConfiguration(ec);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get envelope configuration.');
		}
	}

	private static EnvelopeConfiguration parseEnvelopeConfiguration(final EnvelopeConfiguration ec) {
		List<Id> contentDocumentIds = new List<Id>();
		for (Document doc : filterDocuments(ec, EnvelopeConfiguration.DOCUMENT_TYPE_TEMPLATE_DOCUMENT)) {
			contentDocumentIds.add(doc.sourceId);
		}
		if (Collection.isEmpty(contentDocumentIds)) {
			return ec;
		}
		List<Document> updatedDocuments = getDocumentsWithFileSize(ec, contentDocumentIds);
		return ec.withDocuments(updatedDocuments);
	}

	private static List<Document> filterDocuments(final EnvelopeConfiguration ec, final String type) {
		List<Document> documents = new List<Document>();
		for (Document doc : ec.documents) {
			if (doc.type == type) {
				documents.add(doc);
			}
		}
		return documents;
	}

	private static List<Document> getDocumentsWithFileSize(final EnvelopeConfiguration ec, final List<Id> contentDocumentIds) {
		Map<Id, ContentDocument> contentDocumentIdToFileSize =
			new Map<Id, ContentDocument>([
				SELECT Id, ContentSize
				FROM ContentDocument
				WHERE Id IN:contentDocumentIds
			]);
		List<Document> updatedDocs = new List<Document>();
		for (Document doc : ec.documents) {
			if (contentDocumentIdToFileSize.containsKey(doc.sourceId)) {
				document d = new document(
					doc.id,
					doc.type,
					doc.sequence,
					doc.name,
					doc.extension,
					contentDocumentIdToFileSize.get(doc.sourceId).ContentSize,
					doc.lastModified,
					doc.sourceId,
					doc.readOnly,
					doc.required);
				updatedDocs.add(d);
			} else {
				updatedDocs.add(doc);
			}
		}
		return updatedDocs;
	}

	@AuraEnabled
	public static List<Query.Relationship> getChildRelationships(final String sourceObject) {
		try {
			SObjectType objectType = Schema.getGlobalDescribe().get(sourceObject);
			return MetadataService.getChildRelationships(objectType);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get child relationships.');
		}
	}

	@AuraEnabled
	public static List<Query.Relationship> getLookupFields(final String sourceObject) {
		try {
			SObjectType objectType = Schema.getGlobalDescribe().get(sourceObject);
			return MetadataService.getLookups(objectType);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get lookup fields.');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static List<MergeField> getMergeFields(final String sObjectType) {
		try {
			return MetadataService.getFields(Salesforce.getSObjectType(sObjectType), 1);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to retrieve merge fields.');
		}
	}

	@AuraEnabled
	public static List<SigningGroup> getSigningGroups() {
		try {
			return RecipientService.getSigningGroups();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to signing groups.');
		}
	}

	@AuraEnabled
	public static Boolean deleteEnvelopeConfiguration(final Id envelopeConfigurationId) {
		try {
			return EnvelopeConfigurationService.deleteEnvelopeConfiguration(envelopeConfigurationId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to delete envelope configuration.');
		}
	}

	@AuraEnabled
	public static String getEntityPhone(final String entityId) {
		try {
			return queryEntityPhone((Id) entityId);
		} catch(Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get entity phone number.');
		}
	}

	public PageReference redirectToNewConfigUrl() {
		PageReference pg = Page.EnvelopeConfigurationNavigator;
		if (String.isNotBlank(this.envelopeConfigId)) {
			pg.getParameters().put('id', this.envelopeConfigId);
		}
		pg.setRedirect(true);
		return pg;
	}
}
