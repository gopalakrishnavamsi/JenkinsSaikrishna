public with sharing class EnvelopeConfigurationController extends Controller {

	public String objectHomeUrl { get; private set; }
	public Id envelopeConfigId { get; set; }

	public EnvelopeConfigurationController() {
		this.objectHomeUrl = '/' + EnvelopeConfiguration__c.getSObjectType().getDescribe().getKeyPrefix() + '/o';
	}

	//noinspection ApexUnusedDeclaration
	public EnvelopeConfigurationController(final ApexPages.StandardController c) {
		this();
	}

	@TestVisible
	private static EnvelopeConfiguration parseUpdates(final String envelopeConfigurationJSON, final Boolean attachSourceFiles) {
		Map<String, Object> untypedConfig = (Map<String, Object>) JSON.deserializeUntyped(envelopeConfigurationJSON);
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
			Map<String,Object> nodeMap = (Map<String, Object>) node;
			if (nodeMap.containsKey('type')) {
				String type = (String) nodeMap.get('type');
				if (type == EnvelopeConfiguration.DOCUMENT_TYPE_SOURCE_FILES && attachSourceFiles) {
					results.add((EnvelopeConfiguration.SourceFiles) JSON.deserialize(JSON.serialize((Object) nodeMap), EnvelopeConfiguration.SourceFiles.class));
				} else if (type == EnvelopeConfiguration.DOCUMENT_TYPE_TEMPLATE_DOCUMENT) {
					results.add((EnvelopeConfiguration.TemplateDocument) JSON.deserialize(JSON.serialize((Object) nodeMap), EnvelopeConfiguration.TemplateDocument.class));
				}
			}  else {
				results.add((Document) JSON.deserialize(JSON.serialize((Object) nodeMap), Document.class));
			}
		}
		return results;
	}

	@TestVisible
	private static List<Recipient> parseRecipients(final List<Object> recipientsNode) {
		List<Recipient> results = new List<Recipient>();
		if (Collection.isEmpty(recipientsNode)) return results;

		for (Object node : recipientsNode) {
			Map<String,Object> nodeMap = (Map<String, Object>) node;
			if (nodeMap.containsKey('relationship')) {
				Query.Relationship relationship = (Query.Relationship) JSON.deserialize(JSON.serialize((Object) nodeMap.get('relationship')), Query.Relationship.class);
				if (relationship != null && relationship.isLookup) {
					results.add((EnvelopeConfiguration.LookupRecipient) JSON.deserialize(JSON.serialize((Object) nodeMap), EnvelopeConfiguration.LookupRecipient.class));
				} else if (relationship != null && !relationship.isLookup) {
					results.add((EnvelopeConfiguration.RelatedRecipients) JSON.deserialize(JSON.serialize((Object) nodeMap), EnvelopeConfiguration.RelatedRecipients.class));
				} else {
					results.add((Recipient) JSON.deserialize(JSON.serialize((Object) nodeMap), Recipient.class));
				}
			}  else {
				results.add((Recipient) JSON.deserialize(JSON.serialize((Object) nodeMap), Recipient.class));
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
	public static EnvelopeConfiguration updateEnvelopeConfiguration(final String envelopeConfigurationJSON, final Boolean attachSourceFiles) {
		try {
			return EnvelopeConfigurationService.updateEnvelopeConfiguration(parseUpdates(envelopeConfigurationJSON, attachSourceFiles));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to update envelope configuration.');
		}
	}

	@AuraEnabled
	public static Boolean deleteContentDocument(final Id contentDocumentId) {
		try {
			return EnvelopeConfigurationService.deleteContentDocument(contentDocumentId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to delete content document');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static EnvelopeConfiguration getEnvelopeConfiguration(final Id recordId) {
		try {
			return EnvelopeConfigurationService.getEnvelopeConfiguration(recordId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get envelope configuration.');
		}
	}

 	@AuraEnabled
	public static List<Query.Relationship> getChildRelationships(final String sourceObject) {
		try {
			SObjectType objectType = Schema.getGlobalDescribe().get(sourceObject);
			return MetadataService.getChildRelationships(objectType);
		} catch(Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get child relationships.');
		}		
	}
	
	@AuraEnabled
	public static List<Query.Relationship> getLookupFields(final String sourceObject) {
		try {
			SObjectType objectType = Schema.getGlobalDescribe().get(sourceObject);
			return MetadataService.getLookups(objectType);
		} catch(Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get lookup fields.');
		}
	}
	
	@AuraEnabled
	public static List<SigningGroup> getSigningGroups(){
		try  {
			return RecipientService.getSigningGroups();
		} catch(Exception ex) {
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

	public PageReference redirectToNewConfigUrl() {
		PageReference pg = Page.EnvelopeConfigurationNavigator;
		if (String.isNotBlank(this.envelopeConfigId)) {
			pg.getParameters().put('id', this.envelopeConfigId);
		}
		pg.setRedirect(true);
		return pg;
	}
}
