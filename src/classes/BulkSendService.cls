/**
 * Operations related to sending DocuSign envelopes in bulk. Bulk send lists may be created, updated, and deleted. These
 * may be reused with multiple draft envelopes. Only one <code>SIGNER</code> recipient per envelope copy is currently
 * supported.
 * <p>
 * To use automatic anchor tags for the bulk envelope recipient, set the placeholder recipient role to
 * <code>dfsle.RecipientService.getDefaultRoles()[0]</code>, assuming it exists.
 * <p>
 * A typical flow is as follows:
 * <pre>
 * // Construct bulk list from a group
 * dfsle.BulkList myList = new dfsle.BulkList(
 * 	null, // Salesforce list ID. Assigned upon creation.
 * 	null, // DocuSign list ID. Assigned upon creation.
 * 	new List&lt;dfsle.Envelope&gt; { ... }, // Envelope copies.
 * 	new dfsle.Entity(mySalesforceGroupId));
 *
 * // Create the bulk send list.
 * myList = dfsle.BulkSendService.createLists(new List&lt;BulkList&gt; { myBulkList })[0];
 *
 * // Create a draft envelope with at least one dummy recipient.
 * dfsle.Envelope myEnvelope = dfsle.BulkSendService.getDraftEnvelope(
 * 		new List<dfsle.Document> {...}, // Documents
 * 		new dfsle.Entity(mySalesforceSourceId)); // Salesforce source entity
 *
 * // Send the envelope to your bulk send list.
 * dfsle.BulkList.Result myResult = dfsle.BulkSendService.sendEnvelope(myList.id, myEnvelope);
 *
 * // Check for and resolve any errors in the result.
 * if (myResult.success) {
 * 	// Get batch job status (will only call DocuSign API at most once per minute)
 * 	dfsle.BulkList.Status myStatus = dfsle.BulkSendService.getStatus(new Set&lt;Id&gt; { myResult.bulkStatusId });
 * }
 * </pre>
 */
global with sharing class BulkSendService {

	@TestVisible
	private static final BulkSendService.Database DB = new BulkSendService.Database();
	private static final SObjectType BULK_LIST_TYPE = BulkList__c.getSObjectType();
	private static final SObjectType BULK_STATUS_TYPE = BulkStatus__c.getSObjectType();
	@TestVisible
	private static final Long STATUS_POLL_INTERVAL_MS = 60000; // 1 min * 60 sec * 1000 ms

	@TestVisible
	private class Database {

		@TestVisible
		private BulkList__c convert(final BulkList bl) {
			if (bl == null) return null;

			return new BulkList__c(
				Id = bl.id,
				DocuSignId__c = String.valueOf(bl.docuSignId),
				Name = bl.name,
				SourceId__c = bl.source == null ? null : bl.source.id);
		}

		@TestVisible
		private List<BulkList__c> convert(final List<BulkList> bls) {
			if (bls == null) return null;

			List<BulkList__c> result = new List<BulkList__c>();
			for (BulkList bl : bls) {
				result.add(convert(bl));
			}

			return result;
		}

		@TestVisible
		private BulkList convert(final BulkList__c bl) {
			if (bl == null) return null;

			return new BulkList(
				bl.Id,
				UUID.tryParse(bl.DocuSignId__c),
				bl.Name,
				null,
				bl.SourceId__c == null ? null : new Entity(bl.SourceId__c));
		}

		@TestVisible
		private List<BulkList> convert(final List<BulkList__c> bls) {
			if (bls == null) return null;

			List<BulkList> result = new List<BulkList>();
			for (BulkList__c bl : bls) {
				result.add(convert(bl));
			}

			return result;
		}

		@TestVisible
		private BulkStatus__c convert(final BulkList.Status bs) {
			if (bs == null) return null;

			return new BulkStatus__c(
				Id = bs.id,
				DocuSignId__c = String.valueOf(bs.docuSignId),
				SourceId__c = bs.source == null ? null : bs.source.id,
				BatchSize__c = bs.batchSize,
				QueuedEnvelopes__c = bs.queuedEnvelopes,
				SentEnvelopes__c = bs.sentEnvelopes,
				FailedEnvelopes__c = bs.failedEnvelopes,
				Submitted__c = bs.submitted,
				LastStatusUpdate__c = bs.lastStatusUpdate);
		}

		@TestVisible
		private List<BulkStatus__c> convert(final List<BulkList.Status> bss) {
			if (bss == null) return null;

			List<BulkStatus__c> result = new List<BulkStatus__c>();
			for (BulkList.Status bs : bss) {
				result.add(convert(bs));
			}

			return result;
		}

		@TestVisible
		private BulkList.Status convert(final BulkStatus__c bs) {
			if (bs == null) return null;

			return new BulkList.Status(
				bs.Id,
				UUID.tryParse(bs.DocuSignId__c),
				bs.SourceId__c == null ? null : new Entity(bs.SourceId__c),
				Integer.valueOf(bs.BatchSize__c),
				Integer.valueOf(bs.QueuedEnvelopes__c),
				Integer.valueOf(bs.SentEnvelopes__c),
				Integer.valueOf(bs.FailedEnvelopes__c),
				null,
				bs.Submitted__c,
				bs.LastStatusUpdate__c);
		}

		@TestVisible
		private List<BulkList.Status> convert(final List<BulkStatus__c> bss) {
			if (bss == null) return null;

			List<BulkList.Status> result = new List<BulkList.Status>();
			for (BulkStatus__c bs : bss) {
				result.add(convert(bs));
			}

			return result;
		}

		public List<BulkList> createLists(final List<BulkList> bulkLists) {
			Permissions.verifyIsCreateable(BULK_LIST_TYPE, new List<String> { 'Name', 'DocuSignId__c', 'SourceId__c' });

			if (Collection.isEmpty(bulkLists)) return new List<BulkList>();

			List<BulkList__c> bls = convert(bulkLists);
			insert bls;

			return convert(bls);
		}

		public List<BulkList> queryLists(final Set<Id> bulkListIds) {
			Permissions.verifyIsQueryable(BULK_LIST_TYPE, new List<String> { 'Name', 'DocuSignId__c', 'SourceId__c' });

			if (Collection.isEmpty(bulkListIds)) return new List<BulkList>();

			return convert([
				SELECT Name, DocuSignId__c, SourceId__c
				FROM BulkList__c
				WHERE Id IN :bulkListIds
			]);
		}

		public List<BulkList> queryLists(final String name, final Integer maximumRecords) {
			Permissions.verifyIsQueryable(BULK_LIST_TYPE, new List<String> { 'Name', 'DocuSignId__c', 'SourceId__c' });

			Integer l = maximumRecords > 0 ? maximumRecords : 100;
			if (String.isNotBlank(name)) {
				String n = name + '%';
				return convert([
					SELECT Name, DocuSignId__c, SourceId__c
					FROM BulkList__c
					WHERE Name LIKE :n
					ORDER BY Name ASC
					LIMIT :l
				]);
			} else {
				return convert([
					SELECT Name, DocuSignId__c, SourceId__c
					FROM BulkList__c
					ORDER BY Name ASC
					LIMIT :l
				]);
			}
		}

		public List<BulkList> updateLists(final List<BulkList> bulkLists) {
			Permissions.verifyIsUpdateable(BULK_LIST_TYPE, new List<String> { 'Name', 'DocuSignId__c', 'SourceId__c' });

			if (Collection.isEmpty(bulkLists)) return new List<BulkList>();

			update convert(bulkLists);

			return bulkLists;
		}

		public Boolean deleteLists(final Set<Id> bulkListIds) {
			Permissions.verifyIsDeletable(BULK_LIST_TYPE);

			if (Collection.isEmpty(bulkListIds)) return false;

			List<BulkList__c> bls = new List<BulkList__c>();
			for (Id blId : bulkListIds) {
				bls.add(new BulkList__c(Id = blId));
			}
			delete bls;

			return true;
		}

		public List<BulkList.Status> createStatus(final List<BulkList.Status> status) {
			Permissions.verifyIsCreateable(BULK_STATUS_TYPE, new List<String> {
				'DocuSignId__c', 'SourceId__c', 'BatchSize__c', 'QueuedEnvelopes__c', 'SentEnvelopes__c',
				'FailedEnvelopes__c', 'Submitted__c', 'LastStatusUpdate__c'
			});

			if (Collection.isEmpty(status)) return new List<BulkList.Status>();

			List<BulkStatus__c> bss = convert(status);
			insert bss;

			return convert(bss);
		}

		public List<BulkList.Status> queryStatus(final Set<Id> bulkStatusIds) {
			Permissions.verifyIsQueryable(BULK_STATUS_TYPE, new List<String> {
				'DocuSignId__c', 'SourceId__c', 'BatchSize__c', 'QueuedEnvelopes__c', 'SentEnvelopes__c',
				'FailedEnvelopes__c', 'Submitted__c', 'LastStatusUpdate__c'
			});

			if (Collection.isEmpty(bulkStatusIds)) return new List<BulkList.Status>();

			return convert([
				SELECT
					Id, DocuSignId__c, SourceId__c, BatchSize__c, QueuedEnvelopes__c, SentEnvelopes__c,
					FailedEnvelopes__c, Submitted__c, LastStatusUpdate__c
				FROM BulkStatus__c
				WHERE Id IN :bulkStatusIds
			]);
		}

		public List<BulkList.Status> updateStatus(final List<BulkList.Status> status) {
			Permissions.verifyIsUpdateable(BULK_STATUS_TYPE, new List<String> {
				'DocuSignId__c', 'SourceId__c', 'BatchSize__c', 'QueuedEnvelopes__c', 'SentEnvelopes__c',
				'FailedEnvelopes__c', 'Submitted__c', 'LastStatusUpdate__c'
			});

			if (Collection.isEmpty(status)) return new List<BulkList.Status>();

			update convert(status);

			return status;
		}
	}

	/**
	 * Creates one or more bulk send lists in Salesforce and DocuSign. The lists must have at least one member. Each
	 * list may be used for multiple envelopes. Currently bulk envelope copies are restricted to exactly one recipient
	 * each.
	 *
	 * @param bulkLists The bulk send lists to create.
	 *
	 * @return The newly-created bulk send lists.
	 */
	global static List<BulkList> createLists(final List<BulkList> bulkLists) {
		Permissions.verifyIsDocuSignUser();

		if (Collection.isEmpty(bulkLists)) throw new DocuSignException(Label.UndefinedBulkList);

		BulkSendAPI api = BulkSendAPI.getInstance();
		List<BulkList> result = new List<BulkList>();
		for (BulkList bl : bulkLists) {
			result.add(api.createList(bl));
		}

		return DB.createLists(result);
	}

	/**
	 * Searches for bulk send lists partially matching a name.
	 *
	 * @param name The beginning part of the name to match.
	 * @param maximumRecords The maximum number of records to retrieve.
	 *
	 * @return Bulk send lists matching the search criteria.
	 */
	global static List<BulkList> searchLists(final String name, final Integer maximumRecords) {
		Permissions.verifyIsDocuSignUser();

		return DB.queryLists(name, maximumRecords);
	}

	/**
	 * Updates one or more bulk send lists in Salesforce and DocuSign. Currently bulk envelope copies are restricted to
	 * exactly one recipient each.
	 *
	 * @param bulkLists The bulk send lists to update.
	 *
	 * @return The updated bulk send lists.
	 */
	global static List<BulkList> updateLists(final List<BulkList> bulkLists) {
		Permissions.verifyIsDocuSignUser();

		if (Collection.isEmpty(bulkLists)) throw new DocuSignException(Label.UndefinedBulkList);

		BulkSendAPI api = BulkSendAPI.getInstance();
		List<BulkList> result = new List<BulkList>();
		for (BulkList bl : bulkLists) {
			result.add(api.updateList(bl));
		}

		return DB.updateLists(result);
	}

	/**
	 * Deletes one or more bulk send lists in Salesforce and DocuSign.
	 *
	 * @param bulkListIds The IDs of the lists to delete.
	 *
	 * @return The result of the delete operation: <code>true</code> if the lists were deleted, and <code>false</code>
	 * otherwise.
	 */
	global static Boolean deleteLists(final Set<Id> bulkListIds) {
		Permissions.verifyIsDocuSignUser();

		if (Collection.isEmpty(bulkListIds)) throw new DocuSignException(Label.UndefinedId);

		BulkSendAPI api = BulkSendAPI.getInstance();
		List<BulkList> bls = DB.queryLists(bulkListIds);
		Boolean result = Collection.isNotEmpty(bls);
		if (result) {
			for (BulkList bl : bls) {
				if (bl.docuSignId != null) result &= api.deleteList(bl.docuSignId);
			}
			result &= DB.deleteLists(bulkListIds);
		}

		return result;
	}

	/**
	 * Gets a new bulk draft envelope instance with a single bulk recipient placeholder and default email and
	 * notification settings. This may be further customized via the <code>Envelope.withEmail</code> or
	 * <code>Envelope.withNotifications</code> methods.
	 * <p>
	 * Callers must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param documents List of envelope documents. At least one document is required.
	 * @param source Optional Salesforce source object for the envelope.
	 *
	 * @return A new bulk envelope instance.
	 */
	global static Envelope getDraftEnvelope(final List<Document> documents, final Entity source) {
		Permissions.verifyIsDocuSignUser();

		if (Collection.isEmpty(documents)) throw new DocuSignException(Label.AtLeastOneDocumentIsRequired);

		return EnvelopeService.getEmptyEnvelope(source)
			.withDocuments(documents)
			.withRecipients(new List<Recipient> {
				Recipient.newBulkRecipientPlaceholder()
			});
	}

	/**
	 * Sends a draft envelope to a bulk send list. The envelope will be created in DocuSign and Salesforce.
	 * <p>
	 * If previously created, the caller must be the owner of the envelope. Otherwise the caller must be assigned the
	 * <code>DocuSign User</code> permission set.
	 *
	 * @param bulkListId The bulk send list Salesforce ID.
	 * @param envelope The draft envelope.
	 *
	 * @return The result of the bulk send operation.
	 */
	global static BulkList.Result sendEnvelope(final Id bulkListId, final Envelope envelope) {
		Boolean dsEnvelopeCreated = envelope != null && !UUID.isEmpty(envelope.docuSignId);
		Boolean sfdcEnvelopeCreated = envelope != null && envelope.id != null;
		if (sfdcEnvelopeCreated) {
			Permissions.verifyIsOwner(envelope.id);
		} else {
			Permissions.verifyIsDocuSignUser();
		}

		if (bulkListId == null) throw new DocuSignException(Label.UndefinedBulkList);

		ValidationResult vr = EnvelopeService.validate(envelope, true);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		List<BulkList> bls = DB.queryLists(new Set<Id> { bulkListId });
		if (Collection.size(bls) != 1) throw new DocuSignException(Label.BulkListNotFound);

		UUID docuSignId = dsEnvelopeCreated
			? envelope.docuSignId
			: EnvelopeAPI.getInstance().createEnvelope(envelope, EnvelopeSettings.getOptions(false));

		BulkSendAPI api = BulkSendAPI.getInstance();
		BulkList.Result result = api.sendEnvelope(bls[0].docuSignId, docuSignId);
		if (result.success) {
			List<BulkList.Status> status = DB.createStatus(new List<BulkList.Status> {
				api.getStatus(result.batchId).withSource(envelope.source)
			});
			if (Collection.isNotEmpty(status)) {
				result = result.withBulkStatusId(status[0].id);
			}
			// TODO: Create envelope and status records for each bulk copy?
			if (!sfdcEnvelopeCreated) {
				EnvelopeService.saveEnvelope(envelope.withDocuSignId(docuSignId), null);
			}
		}

		return result;
	}

	/**
	 * Retrieves status for one or more bulk send jobs.
	 *
	 * @param bulkStatusIds The list of status IDs.
	 *
	 * @return A list of bulk send job statuses.
	 */
	global static List<BulkList.Status> getStatus(final Set<Id> bulkStatusIds) {
		Permissions.verifyIsDocuSignUser();

		if (Collection.isEmpty(bulkStatusIds)) throw new DocuSignException(Label.UndefinedId);

		List<BulkList.Status> result = new List<BulkList.Status>();
		List<BulkList.Status> toUpdate = new List<BulkList.Status>();
		BulkSendAPI api = BulkSendAPI.getInstance();
		Long now = Datetime.now().getTime();
		for (BulkList.Status bs : DB.queryStatus(bulkStatusIds)) {
			Long elapsedMs = bs.lastStatusUpdate == null ? STATUS_POLL_INTERVAL_MS : now - bs.lastStatusUpdate.getTime();
			if (!bs.isFinal && elapsedMs >= STATUS_POLL_INTERVAL_MS) {
				toUpdate.add(api.getStatus(bs.docuSignId).withId(bs.id).withSource(bs.source));
			} else {
				result.add(bs);
			}
		}

		if (Collection.isNotEmpty(toUpdate)) {
			result.addAll(DB.updateStatus(toUpdate));
		}

		return result;
	}
}
