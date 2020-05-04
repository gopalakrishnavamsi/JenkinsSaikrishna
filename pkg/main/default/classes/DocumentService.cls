/**
 * This class is the entry point for DocuSign eSignature envelope document management. It provides methods to retrieve
 * Salesforce source documents.
 */
global with sharing class DocumentService {

	@TestVisible
	private static final DocumentService.Database DB = new DocumentService.Database();
	private static final SObjectType TYPE_DOCUMENT = Document__c.getSObjectType();
	@TestVisible
	private static final Document.Folder PERSONAL_FOLDER = new Document.Folder(UserInfo.getUserId(), Label.MyPersonalContent);
	@TestVisible
	private static final Set<String> VALID_EXTENSIONS = new Set<String> {
		'adf' /* Online Editor format */, 'as', 'asl', 'asp', 'doc', 'docm', 'docx', 'dot',
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

	@TestVisible
	private static String getFileExtension(final String name) {
		String extension = null;
		if (String.isNotBlank(name)) {
			Integer i = name.lastIndexOf('.');
			if (i > -1) {
				extension = name.substring(i + 1);
			}
		}
		return extension;
	}

	/**
	 * Converts a list of <code>dfsle__Document__c</code> objects to their domain object form.
	 * <p>
	 * <em>This method is intended for DocuSign internal use only.</em>
	 *
	 * @param docs The documents to convert.
	 *
	 * @return The converted documents.
	 */
	public static List<Document> convert(final List<Document__c> docs) {
		List<Document> result = new List<Document>();
		if (docs != null) {
			for (Document__c d : docs) {
				result.add(DB.convert(d));
			}
		}
		return result;
	}

	/**
	 * Validates a list of DocuSign envelope documents. They are checked for the following:
	 * <ul>
	 *     <li>At least one document is defined.</li>
	 *     <li>Non-DocuSign template documents are of a supported type.</li>
	 * </ul>
	 * <p>
	 * <em>This method is intended for DocuSign internal use only.</em>
	 *
	 * @param documents The documents to validate.
	 *
	 * @return The result of the validation.
	 */
	public static ValidationResult validate(final List<Document> documents) {
		if (Collection.isEmpty(documents)) {
			return new ValidationResult(Label.AtLeastOneDocumentIsRequired);
		}

		ValidationResult result = new ValidationResult();
		for (Document d : documents) {
			result.add(validate(d));
		}

		return result;
	}

	public static Boolean isValidFileType(final String extension) {
		return String.isNotBlank(extension) && VALID_EXTENSIONS.contains(extension);
	}

	@TestVisible
	private static ValidationResult validate(final Document doc) {
		if (doc == null) return new ValidationResult(Label.UndefinedDocument);

		ValidationResult result = new ValidationResult();
		if (doc.type != Document.TYPE_TEMPLATE && !VALID_EXTENSIONS.contains(doc.extension)) {
			result.add(Label.InvalidFileType);
		}
		return result;
	}

	private class Database {

		@TestVisible
		private Document convert(final Document__c doc) {
			if (doc == null) return null;

			return new Document(
				doc.Id,
				doc.Type__c,
				Integer.valueOf(doc.Sequence__c),
				doc.Name,
				String.isNotBlank(doc.Extension__c) ? doc.Extension__c : getFileExtension(doc.Name),
				Integer.valueOf(doc.Size__c),
				doc.LastModified__c,
				doc.SourceId__c,
				doc.ReadOnly__c == true,
				doc.Required__c == true);
		}

		@TestVisible
		private Document__c convert(
			final Document doc,
			final Id envelopeId,
			final Integer sequence) {

			if (doc == null) return null;

			return new Document__c(
				Id = doc.id,
				Envelope__c = envelopeId,
				Type__c = doc.type,
				Sequence__c = sequence,
				Name = doc.name,
				Extension__c = doc.extension,
				Size__c = doc.size,
				SourceId__c = doc.sourceId,
				LastModified__c = doc.lastModified,
				ReadOnly__c = doc.readOnly == true,
				Required__c = doc.required == true);
		}

		@TestVisible
		private Integer queryMaxSequence(final Id envelopeId) {
			Integer sequence = 0;
			List<AggregateResult> maxSequence = [
				SELECT MAX(Sequence__c) maxSequence
				FROM Document__c
				WHERE Envelope__c = :envelopeId
			];
			if (Collection.isNotEmpty(maxSequence)) {
				Object obj = maxSequence[0].get('maxSequence');
				sequence = obj == null ? 0 : Integer.valueOf(obj);
			}
			return sequence;
		}

		@TestVisible
		private List<Document__c> queryDocumentsInternal(final Id envelopeId) {
			Permissions.verifyIsQueryable(TYPE_DOCUMENT, new List<String> {
				'Id',
				'Name',
				Application.namespacePrefix + 'Extension__c',
				Application.namespacePrefix + 'LastModified__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'Size__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});

			return [
				SELECT Id,
					Envelope__c,
					Type__c,
					Sequence__c,
					Name,
					Extension__c,
					Size__c,
					SourceId__c,
					LastModified__c,
					ReadOnly__c,
					Required__c
				FROM Document__c
				WHERE Envelope__c = :envelopeId
				ORDER BY Sequence__c
			];
		}

		public List<Document> queryDocuments(final Id envelopeId) {
			return convert(queryDocumentsInternal(envelopeId));
		}

		public List<Document> insertDocuments(
			final Id envelopeId,
			final List<Document> documents) {

			Permissions.verifyIsCreateable(TYPE_DOCUMENT, new List<String> {
				'Name',
				Application.namespacePrefix + 'Extension__c',
				Application.namespacePrefix + 'LastModified__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'Size__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});

			List<Document> result = new List<Document>();
			if (documents != null) {
				List<Document__c> ds = new List<Document__c>();
				Integer sequence = queryMaxSequence(envelopeId);
				for (Document d : documents) {
					ds.add(convert(d, envelopeId, ++sequence));
				}
				insert ds;

				result.addAll(convert(ds));
			}
			return result;
		}

		public Map<Id, List<Document>> insertDocuments(final Map<Id, List<Document>> documents) {
			Permissions.verifyIsCreateable(TYPE_DOCUMENT, new List<String> {
				'Name',
				Application.namespacePrefix + 'Extension__c',
				Application.namespacePrefix + 'LastModified__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'Size__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});

			Map<Id, List<Document>> result = new Map<Id, List<Document>>();
			if (Collection.isNotEmpty(documents)) {
				List<Document__c> ds = new List<Document__c>();
				for (Id eId : documents.keySet()) {
					List<Document> docs = documents.get(eId);
					if (Collection.isNotEmpty(docs)) {
						Integer sequence = 0;
						for (Document d : docs) {
							ds.add(convert(d, eId, ++sequence));
						}
					}
				}
				insert ds;

				for (Document__c d : ds) {
					if (d == null || d.Envelope__c == null) continue;

					if (result.containsKey(d.Envelope__c)) {
						result.get(d.Envelope__c).add(convert(d));
					} else {
						result.put(d.Envelope__c, new List<Document> { convert(d) });
					}
				}
			}
			return result;
		}

		public List<Document> upsertDocuments(final Id envelopeId, final List<Document> documents) {
			List<String> fields = new List<String> {
				'Name',
				Application.namespacePrefix + 'Extension__c',
				Application.namespacePrefix + 'LastModified__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'Size__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			};
			Permissions.verifyIsCreateable(TYPE_DOCUMENT, fields);
			Permissions.verifyIsUpdateable(TYPE_DOCUMENT, fields);

			List<Document> updatedDocuments = new List<Document>();
			if (documents != null) {
				final List<Document__c> envDocs = new List<Document__c>();
				Integer sequence = 1;
				for (Document d : documents) {
					envDocs.add(convert(d, envelopeId, sequence++));
				}
				upsert envDocs;
				updatedDocuments.addAll(convert(envDocs));
			}
			return updatedDocuments;
		}

		public Boolean deleteDocuments(final Set<Id> documentIds) {
			Permissions.verifyIsDeletable(TYPE_DOCUMENT);

			Boolean result = false;
			if (Collection.isNotEmpty(documentIds)) {
				List<Document__c> envDocs = new List<Document__c>();
				for (Id id : documentIds) {
					envDocs.add(new Document__c(Id = id));
				}
				delete envDocs;
				result = true;
			}
			return result;
		}
	}

	/**
	 * Retrieves a list of Salesforce source documents by IDs.
	 * <p>
	 * By default, the Salesforce <code>Document</code> and <code>ContentVersion</code> types are supported. More types
	 * may be supported via plugins.
	 *
	 * @param type The Salesforce object type.
	 * @param sObjectIds The Salesforce object IDs.
	 *
	 * @return A list of envelope documents.
	 */
	global static List<Document> getDocuments(final SObjectType type, final Set<Id> sObjectIds) {
		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Document> result = null;
		for (DocumentResolver dr : DOCUMENT_RESOLVERS) {
			if (dr.canResolveDocuments(type)) {
				result = dr.getDocuments(type, sObjectIds);
				break;
			}
		}
		return result;
	}

	/**
	 * Retrieves a list of Salesforce source documents by linked entity IDs.
	 * <p>
	 * For example, to pull in all of an Opportunity's Notes and Attachments related list:
	 * <pre>
	 * List<dfsle.Document> docs = dfsle.DocumentService.getLinkedDocuments(
	 * 		ContentVersion.getSObjectType(),
	 * 		new Set<Id> { myOpportunity.Id },
	 * 		false);
	 * </pre>
	 * <p>
	 * By default, only <code>ContentVersion</code> types are supported. More types may be supported via plugins.
	 *
	 * @param type The Salesforce object type.
	 * @param linkedEntityIds The Salesforce parent IDs.
	 * @param getLastUpdatedOnly Whether to retrieve only the last updated linked document.
	 *
	 * @return A list of DocuSign envelope documents.
	 */
	// TODO: Deprecate in favor of new version.
	global static List<Document> getLinkedDocuments(
		final SObjectType type,
		final Set<Id> linkedEntityIds,
		final Boolean getLastUpdatedOnly) {

		return getLinkedDocuments(
			type,
			linkedEntityIds,
			getLastUpdatedOnly ? new Query.Filter(null, null, 1) : null);
	}

	/**
	 * Retrieves a list of Salesforce source documents by linked entity IDs.
	 * <p>
	 * For example, to pull in all of an Opportunity's Notes and Attachments related list:
	 * <pre>
	 * List<dfsle.Document> docs = dfsle.DocumentService.getLinkedDocuments(
	 * 		ContentVersion.getSObjectType(),
	 * 		new Set<Id> { myOpportunity.Id },
	 * 		null);
	 * </pre>
	 * <p>
	 * By default, only the <code>ContentDocument</code> and <code>ContentVersion</code> types are supported. More types
	 * may be supported via plugins.
	 *
	 * @param type The Salesforce object type.
	 * @param linkedEntityIds The Salesforce parent IDs.
	 * @param filter Optional query filter to apply.
	 *
	 * @return A list of DocuSign envelope documents.
	 */
	public static List<Document> getLinkedDocuments(
		final SObjectType type,
		final Set<Id> linkedEntityIds,
		final Query.Filter filter) {

		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Document> result = null;
		for (DocumentResolver dr : DOCUMENT_RESOLVERS) {
			if (dr.canResolveDocuments(type)) {
				result = dr.getLinkedDocuments(type, linkedEntityIds, filter);
				break;
			}
		}
		return result == null ? new List<Document>() : result;
	}

	/**
	 * Retrieves a list of Salesforce source documents folders by object type. The current user's personal folder, and
	 * the documents contained within, is always returned as the first element in the list. The returned folder IDs
	 * may be used in subsequent calls to <code>dfsle.DocumentService.getFolderDocuments</code>.
	 * <p>
	 * By default, the Salesforce <code>Document</code> and <code>ContentVersion</code> types are supported. More types
	 * may be supported via plugins.
	 *
	 * @param type The Salesforce object type.
	 *
	 * @return A list of document folders.
	 * @see dfsle.DocumentService.getFolderDocuments
	 */
	global static Document.Folders getDocumentFolders(final SObjectType type) {
		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Document.Folder> folders = new List<Document.Folder> {
			PERSONAL_FOLDER
		};
		List<Document> personalDocuments = null;
		for (DocumentResolver dr : DOCUMENT_RESOLVERS) {
			if (dr.canResolveDocuments(type)) {
				List<Document.Folder> fs = dr.getDocumentFolders(type);
				if (fs != null) {
					folders.addAll(fs);
					personalDocuments = getFolderDocuments(type, new Set<Id> { PERSONAL_FOLDER.id });
					break;
				}
			}
		}
		return new Document.Folders(folders, personalDocuments);
	}

	/**
	 * Retrieves a list of Salesforce source documents by folder IDs. The folder IDs may be retrieved by calling
	 * <code>dfsle.DocumentService.getDocumentFolders</code> first.
	 * <p>
	 * By default, the Salesforce <code>Document</code> and <code>ContentVersion</code> types are supported. More types
	 * may be supported via plugins.
	 *
	 * @param type The Salesforce object type.
	 * @param folderIds The folder IDs.
	 *
	 * @return A list of documents contained within the target folders.
	 * @see dfsle.DocumentService.getDocumentFolders
	 */
	global static List<Document> getFolderDocuments(final SObjectType type, final Set<Id> folderIds) {
		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Document> result = null;
		for (DocumentResolver dr : DOCUMENT_RESOLVERS) {
			if (dr.canResolveDocuments(type)) {
				result = dr.getFolderDocuments(type, folderIds);
				break;
			}
		}
		return result;
	}

	/**
	 * Retrieves a list of a DocuSign envelope's documents.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelopeId The envelope ID.
	 *
	 * @return A list of documents contained within the envelope.
	 */
	global static List<Document> getEnvelopeDocuments(final Id envelopeId) {
		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);

		Permissions.verifyIsOwner(envelopeId);

		return DB.queryDocuments(envelopeId);
	}

	/**
	 * Adds one or more documents to a DocuSign envelope.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelopeId The envelope ID.
	 * @param documents The documents to add.
	 *
	 * @return The updated envelope documents.
	 */
	public static List<Document> addEnvelopeDocuments(
		final Id envelopeId,
		final List<Document> documents) {

		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);
		if (Collection.isEmpty(documents)) throw new DocuSignException(Label.UndefinedDocument);

		Permissions.verifyIsOwner(envelopeId);

		return DB.insertDocuments(envelopeId, documents);
	}

	/**
	 * Adds documents to one or more DocuSign envelopes. This method is called during envelope bulk insert.
	 *
	 * @param documents A map of envelope IDs to documents.
	 *
	 * @return The added map of envelope IDs to documents.
	 */
	public static Map<Id, List<Document>> addEnvelopeDocuments(final Map<Id, List<Document>> documents) {
		if (Collection.isEmpty(documents)) return new Map<Id, List<Document>>();

		Permissions.verifyIsOwner(documents.keySet());

		return DB.insertDocuments(documents);
	}

	/**
	 * Updates a DocuSign envelope's documents. Documents may be deleted or upserted by this method.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelopeId The envelope ID.
	 * @param originalDocuments The original list of documents.
	 * @param updatedDocuments The new list of documents.
	 *
	 * @return The updated envelope documents.
	 */
	public static List<Document> updateEnvelopeDocuments(
		final Id envelopeId,
		final List<Document> originalDocuments,
		final List<Document> updatedDocuments) {

		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);

		Permissions.verifyIsOwner(envelopeId);

		// Create two sets of IDs: original and updated.
		Set<Id> originalIds = new Set<Id>();
		if (originalDocuments != null) {
			for (Document d : originalDocuments) {
				originalIds.add(d.id);
			}
		}

		Set<Id> updatedIds = new Set<Id>();
		if (updatedDocuments != null) {
			for (Document d : updatedDocuments) {
				if (d.id != null) updatedIds.add(d.id);
			}
		}

		DB.deleteDocuments(Collection.difference(originalIds, updatedIds));
		return DB.upsertDocuments(envelopeId, updatedDocuments);
	}

	/**
	 * Retrieves a list of DocuSign envelope documents by <code>ContentVersion</code> IDs.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 * <p>
	 * <em>This method is intended for DocuSign internal use only.</em>
	 *
	 * @param fileIds The file IDs.
	 *
	 * @return A list of envelope documents.
	 */
	public static List<Document> resolveFiles(final Set<Id> fileIds) {
		Permissions.verifyIsDocuSignUser();

		return getDocuments(ContentVersion.getSObjectType(), fileIds);
	}

	/**
	 * Retrieves a list of DocuSign envelope documents by DocuSign template IDs. This method may invoke multiple
	 * callouts depending on the number of templates being resolved.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 * <p>
	 * <em>This method is intended for DocuSign internal use only.</em>
	 *
	 * @param templateIds The template IDs.
	 *
	 * @return A list of envelope documents.
	 */
	public static List<Document> resolveTemplates(final Set<UUID> templateIds) {
		Permissions.verifyIsDocuSignUser();

		List<Document> templates = new List<Document>();
		if (templateIds != null) {
			EnvelopeAPI api = EnvelopeAPI.getInstance();
			try {
				for (UUID templateId : templateIds) {
					templates.add(Document.fromTemplate(api.getTemplate(templateId)));
				}
			} finally {
				Credentials.save();
			}
		}
		return templates;
	}

	/**
	 * Retrieves a list of DocuSign envelope documents by linked entity IDs. Only the <code>ContentVersion</code> type
	 * is supported.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 * <p>
	 * <em>This method is intended for DocuSign internal use only.</em>
	 *
	 * @param linkedEntityIds The linked entity IDs.
	 * @param getLastUpdatedOnly Whether to retrieve only the last updated linked document.
	 *
	 * @return A list of envelope documents.
	 */
	public static List<Document> resolveLinkedFiles(final Set<Id> linkedEntityIds, final Boolean getLastUpdatedOnly) {
		Permissions.verifyIsDocuSignUser();

		if (Collection.isEmpty(linkedEntityIds)) throw new DocuSignException(Label.InvalidSource);

		return getLinkedDocuments(ContentVersion.getSObjectType(), linkedEntityIds, getLastUpdatedOnly);
	}
}
