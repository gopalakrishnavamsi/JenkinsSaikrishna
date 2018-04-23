public with sharing class DocumentService {

	@TestVisible
	private static final DocumentService.Database DB = new DocumentService.Database();
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

	public static List<Document> convert(final List<Document__c> docs) {
		List<Document> result = new List<Document>();
		if (docs != null) {
			for (Document__c d : docs) {
				result.add(DB.convert(d));
			}
		}
		return result;
	}

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
				doc.SourceId__c);
		}

		@TestVisible
		private Document__c convert(final Document doc, final Id envelopeId, final Integer sequence) {
			if (doc == null) return null;

			return new Document__c(
				Id = doc.id,
				Envelope__c = envelopeId,
				Type__c = doc.type,
				Sequence__c = sequence,
				Name = doc.name,
				Extension__c = doc.extension,
				Size__c = doc.size,
				SourceId__c = doc.sourceId);
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
			Permissions.verifyIsQueryable('Document__c', new List<String> {
				'Id', 'Type__c', 'Sequence__c', 'Name', 'Extension__c', 'Size__c', 'SourceId__c'
			});

			return [
				SELECT Id,
					Envelope__c,
					Type__c,
					Sequence__c,
					Name,
					Extension__c,
					Size__c,
					SourceId__c
				FROM Document__c
				WHERE Envelope__c = :envelopeId
				ORDER BY Sequence__c
			];
		}

		public List<Document> queryDocuments(final Id envelopeId) {
			return convert(queryDocumentsInternal(envelopeId));
		}

		public List<Document> insertDocuments(final Id envelopeId, final List<Document> documents) {
			Permissions.verifyIsCreateable('Document__c', new List<String> {
				'Type__c', 'Sequence__c', 'Name', 'Extension__c', 'Size__c', 'SourceId__c'
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

		public List<Document> upsertDocuments(final Id envelopeId, final List<Document> documents) {
			Permissions.verifyIsCreateable('Document__c', new List<String> {
				'Type__c', 'Sequence__c', 'Name', 'Extension__c', 'Size__c', 'SourceId__c'
			});
			Permissions.verifyIsUpdateable('Document__c', new List<String> {
				'Type__c', 'Sequence__c', 'Name', 'Extension__c', 'Size__c', 'SourceId__c'
			});

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
			Permissions.verifyIsDeletable('Document__c');

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

		public List<Document> updateDocumentSequence(final Id envelopeId) {
			Permissions.verifyIsUpdateable('Document__c', new List<String> { 'Sequence__c' });

			Boolean reordered = false;
			Decimal sequence = 1;
			List<Document__c> documents = queryDocumentsInternal(envelopeId);
			for (Document__c d : documents) {
				if (d.Sequence__c != sequence) {
					d.Sequence__c = sequence;
					reordered = true;
				}
				++sequence;
			}

			if (reordered) {
				update documents;
			}

			return convert(documents);
		}

		public List<Document> updateDocumentSequence(final Id envelopeId, final Map<Id, Integer> newSequence) {
			Permissions.verifyIsUpdateable('Document__c', new List<String> { 'Sequence__c' });

			if (newSequence != null && !newSequence.isEmpty()) {
				List<Document__c> docs = new List<Document__c>();
				for (Id id : newSequence.keySet()) {
					docs.add(new Document__c(
						Id = id,
						Sequence__c = newSequence.get(id)));
				}
				update docs;
			}

			return queryDocuments(envelopeId);
		}
	}

	public static List<Document> getDocuments(final String sObjectType, final Set<Id> sObjectIds) {
		Permissions.verifyIsDocuSignUser();

		List<Document> result = null;
		for (DocumentResolver dr : DOCUMENT_RESOLVERS) {
			if (dr.canResolveDocuments(sObjectType)) {
				result = dr.getDocuments(sObjectType, sObjectIds);
				break;
			}
		}
		return result;
	}

	public static List<Document> getLinkedDocuments(final String sObjectType, final Set<Id> linkedEntityIds) {
		Permissions.verifyIsDocuSignUser();

		List<Document> result = null;
		for (DocumentResolver dr : DOCUMENT_RESOLVERS) {
			if (dr.canResolveDocuments(sObjectType)) {
				result = dr.getLinkedDocuments(sObjectType, linkedEntityIds);
				break;
			}
		}
		return result;
	}

	public static Document.Folders getDocumentFolders(final String sObjectType) {
		Permissions.verifyIsDocuSignUser();

		List<Document.Folder> folders = new List<Document.Folder> {
			PERSONAL_FOLDER
		};
		List<Document> personalDocuments = null;
		for (DocumentResolver dr : DOCUMENT_RESOLVERS) {
			if (dr.canResolveDocuments(sObjectType)) {
				List<Document.Folder> fs = dr.getDocumentFolders(sObjectType);
				if (fs != null) {
					folders.addAll(fs);
					personalDocuments = getFolderDocuments(sObjectType, new Set<Id> { PERSONAL_FOLDER.id });
					break;
				}
			}
		}
		return new Document.Folders(folders, personalDocuments);
	}

	public static List<Document> getFolderDocuments(final String sObjectType, final Set<Id> folderIds) {
		Permissions.verifyIsDocuSignUser();

		List<Document> result = null;
		for (DocumentResolver dr : DOCUMENT_RESOLVERS) {
			if (dr.canResolveDocuments(sObjectType)) {
				result = dr.getFolderDocuments(sObjectType, folderIds);
				break;
			}
		}
		return result;
	}

	public static List<Document> getEnvelopeDocuments(final Id envelopeId) {
		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);

		Permissions.verifyIsOwner(envelopeId);

		return DB.queryDocuments(envelopeId);
	}

	public static List<Document> addEnvelopeDocuments(final Id envelopeId, final List<Document> documents) {
		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);
		if (Collection.isEmpty(documents)) throw new DocuSignException(Label.UndefinedDocument);

		Permissions.verifyIsOwner(envelopeId);

		return DB.insertDocuments(envelopeId, documents);
	}

	public static List<Document> removeEnvelopeDocuments(final Id envelopeId, final Set<Id> documentIds) {
		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);
		if (Collection.isEmpty(documentIds)) throw new DocuSignException(Label.UndefinedDocument);

		Permissions.verifyIsOwner(envelopeId);

		DB.deleteDocuments(documentIds);
		return DB.updateDocumentSequence(envelopeId);
	}

	public static List<Document> reorderEnvelopeDocuments(final Id envelopeId, final Map<Id, Integer> newSequence) {
		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);
		if (newSequence == null || newSequence.isEmpty()) throw new DocuSignException(Label.UndefinedDocument);

		Permissions.verifyIsOwner(envelopeId);

		return DB.updateDocumentSequence(envelopeId, newSequence);
	}

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

	public static List<Document> resolveFiles(final Set<Id> fileIds) {
		Permissions.verifyIsDocuSignUser();

		return getDocuments('ContentVersion', fileIds);
	}

	public static List<Document> resolveTemplates(final Set<UUID> templateIds) {
		Permissions.verifyIsDocuSignUser();

		List<Document> templates = new List<Document>();
		if (templateIds != null) {
			TemplateAPI client = TemplateAPI.getInstance();
			for (UUID templateId : templateIds) {
				templates.add(client.getTemplate(templateId).toDocument());
			}
		}
		return templates;
	}

	public static List<Document> resolveLinkedFiles(final Set<Id> linkedEntityIds) {
		Permissions.verifyIsDocuSignUser();

		if (Collection.isEmpty(linkedEntityIds)) throw new DocuSignException(Label.InvalidSource);

		return getLinkedDocuments('ContentVersion', linkedEntityIds);
	}
}
