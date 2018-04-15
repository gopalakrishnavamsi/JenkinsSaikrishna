public with sharing class DocumentService {

	@TestVisible
	private static final Document.Folder PERSONAL_FOLDER = new Document.Folder(UserInfo.getUserId(), Label.MyPersonalContent);
	@TestVisible
	private static final Set<String> VALID_EXTENSIONS = new Set<String> {
		'as', 'asl', 'asp', 'doc', 'docm', 'docx', 'dot',
		'dotm', 'dotx', 'htm', 'html', 'pdf', 'pdx', 'rtf', 'txt', 'wpd', 'wps', 'wpt', 'dwg', 'dxf', 'emz', 'svg', 'svgz',
		'vdx', 'vsd', 'vss', 'vst', 'bmp', 'cdr', 'dcx', 'gif', 'ico', 'jpg', 'jpeg', 'pct', 'pic', 'png', 'rgb', 'sam',
		'tga', 'tif', 'tiff', 'wpg', 'dps', 'dpt', 'pot', 'potx', 'pps', 'ppt', 'pptm', 'pptx', 'csv', 'et', 'ett', 'xls',
		'xlsm', 'xlsx', 'xlt'
	};
	private static final List<DocumentResolver> DOCUMENT_RESOLVERS = new List<DocumentResolver>();

	static {
		String rs = AccountSettings__c.getOrgDefaults().DocumentResolvers__c;
		if (String.isNotBlank(rs)) {
			for (String r : rs.split(',')) {
				try {
					DOCUMENT_RESOLVERS.add((DocumentResolver)Type.forName(r.trim()).newInstance());
				} catch (Exception ex) {
					LoggerService.getInstance().exception(ex, 'Invalid document resolver: ' + r.trim());
					throw new DocuSignException(String.format(Label.InvalidDocumentResolver_1, new List<String> {
						r.trim()
					}));
				}
			}
		}
	}

	public static List<Document> getDocuments(final String sObjectType, final Set<Id> sObjectIds) {
		List<Document> result = null;
		for (DocumentResolver dr : DOCUMENT_RESOLVERS) {
			if (dr.canResolveDocument(sObjectType)) {
				result = dr.getDocuments(sObjectType, sObjectIds);
				break;
			}
		}
		return result;
	}

	public static Document.Folders getDocumentFolders(final String sObjectType) {
		List<Document.Folder> result = new List<Document.Folder> {
			PERSONAL_FOLDER
		};
		for (DocumentResolver dr : DOCUMENT_RESOLVERS) {
			if (dr.canResolveDocument(sObjectType)) {
				List<Document.Folders> fs = dr.getDocumentFolders(sObjectType);
				if (fs != null) {
					result.addAll(fs);
					break;
				}
			}
		}
		return new Document.Folders(result, getFolderDocuments(sObjectType, new Set<Id> { PERSONAL_FOLDER.id }));
	}

	public static List<Document> getFolderDocuments(final String sObjectType, final Set<Id> folderIds) {
		List<Document> result = null;
		for (DocumentResolver dr : DOCUMENT_RESOLVERS) {
			if (dr.canResolveDocument(sObjectType)) {
				result = dr.getFolderDocuments(sObjectType, folderIds);
				break;
			}
		}
		return result;
	}

	/**
	 * Gets a list of available attachments
	 * @salesforceObjectId - salesforce object id used for envelope creation
     */
	public static List<DocuSign.Document> getChatterFeedItems(final Set<Id> parentIds) {
		return CHATTER_DB.queryChatterFeedItems(parentIds, 1);
	}

	/**
	 * Adds document to the specified envelopeId
	 */
	public static List<DocuSign.Document> addEnvelopeDocuments(final Id envelopeId, final List<DocuSign.Document> documents) {
		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);
		if (Collection.isEmpty(documents)) throw new DocuSignException(Label.UndefinedDocument);

		return DB.insertEnvelopeDocuments(envelopeId, documents);
	}

	/**
	 * Removes a document from database based from UI info
	 * @envelopeId - envelope id
	 * @documentId - document id
	 */
	public static List<DocuSign.Document> removeEnvelopeDocuments(final Id envelopeId, final Set<Id> documentIds) {
		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);
		if (Collection.isEmpty(documentIds)) throw new DocuSignException(Label.UndefinedDocument);

		DB.deleteEnvelopeDocuments(documentIds);
		return DB.updateEnvelopeDocumentOrder(envelopeId);
	}

	/**
	 * Reorders documents
	 * @envelopeId - id of the envelope
	 * @documents - list of documents in desired order
	 */
	public static List<DocuSign.Document> reorderEnvelopeDocuments(final Id envelopeId, final Map<Id, Integer> newSequence) {
		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);
		if (newSequence == null || newSequence.isEmpty()) throw new DocuSignException(Label.UndefinedDocument);

		return DB.updateEnvelopeDocumentOrder(envelopeId, newSequence);
	}

	public static List<DocuSign.Document> updateEnvelopeDocuments(
		final Id envelopeId,
		final List<DocuSign.Document> originalDocuments,
		final List<DocuSign.Document> updatedDocuments) {

		// Create two sets of IDs: original and updated.
		Set<Id> originalIds = new Set<Id>();
		if (originalDocuments != null) {
			for (DocuSign.Document d : originalDocuments) {
				originalIds.add(d.id);
			}
		}

		Set<Id> updatedIds = new Set<Id>();
		if (updatedDocuments != null) {
			for (DocuSign.Document d : updatedDocuments) {
				if (d.id != null) updatedIds.add(d.id);
			}
		}

		DB.deleteEnvelopeDocuments(Collection.difference(originalIds, updatedIds));
		return DB.upsertEnvelopeDocuments(envelopeId, updatedDocuments);
	}

	public static List<DocuSign.Document> getEnvelopeDocuments(final Id envelopeId) {
		return DB.queryEnvelopeDocuments(envelopeId);
	}
}
