public with sharing class NegotiateAPI extends DocuSignAPI {
// TODO: move common logic between GEN and Negotiate to parent class
	public static final String PATH_FOLDER = 'folders';
	public static final String PATH_DOCUMENTS = 'documents';
	public static final String PATH_AGREEMENT_IN_EOS_FOLDER = 'salesforcecontentdocumentimporttasks';
	public static final String PATH_AGREEMENT_VERSIONS = 'versions';
	public static final String PATH_WORKFLOWS = 'workflows';
	public static final String PATH_HISTORY_ITEMS = 'historyitems';
	public static final Long SCM_OFFSET = 20;

	private static NegotiateAPI self = null;
	private static NegotiateAPI historySelf = null;

	private NegotiateAPI(final Url baseUrl,
		final String apiVersion,
		final UUID accountId) {
		super (new Url (baseUrl, String.format('{0}/{1}/',
			new List<String> {
				apiVersion,
				String.valueOf(accountId)
			})));
	}

	public static NegotiateAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			String negotiateUrl = c.environment.scmApiBaseUrl.toExternalForm().subString(0, c.environment.scmApiBaseUrl.toExternalForm().indexOf(c.environment.scmApiBaseUrl.getPath()) + 1);
			self = new NegotiateAPI(new Url(negotiateUrl), 'v2', c.account.id);
		}
		return self;
	}

	public static NegotiateAPI getHistoryAPIInstance() {
		if (historySelf == null) {
			Credentials c = Credentials.getInstance();
			historySelf = new NegotiateAPI(c.environment.scmApiBaseUrl, 'v1', c.account.id);
		}
		return historySelf;
	}



	public class Error extends APIError {
		public UUID referenceId { get; private set; }

		public Error(
			final Integer code,
			final UUID referenceId,
			final String description) {

			super(code, description);

			this.referenceId = referenceId;
		}

		override public String toString() {
			return String.format(Label.ApiError_3, new List<String> {
				String.valueOf(this.code),
				this.description,
				String.valueOf(this.referenceId)
			});
		}
	}

	@TestVisible
	override protected virtual APIError getError(final HttpResponse response) {
		APIError e = APIError.none;
		Integer statusCode = response.getStatusCode();
		if (statusCode >= 400) {
			String body = response.getBody();
			try {
				Map<String, Object> error = (Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(body))
					.get('Error');
				e = new NegotiateAPI.Error(
					error.containsKey('ErrorCode') ? (Integer)error.get('ErrorCode') : statusCode,
					UUID.tryParse((String)error.get('ReferenceId')),
					error.containsKey('UserMessage') ? (String)error.get('UserMessage') : response.getStatus());
				this.log.warn('Negotiate API error: ' + e);
			} catch (Exception ex) {
				this.log.exception(ex, 'Failed to parse Negotiate API error. Response body:\n' + body);
				e = new APIError(statusCode, response.getStatus());
			}
		}
		return e;
	}

	@TestVisible
	private class EosInfo {

		public String name ;
		public Id objectId;
		public String objectType ;

		EosInfo(final String objectName, final Id objectId, final String objectType) {
			this.name = objectName;
			this.objectId = objectId;
			this.objectType = objectType;
		}
	}

	@TestVisible
	private class APIExternalReview {

		public List<UUID> documents { get; private set; }
		public List<APIReviewer> reviewers { get; private set; }
		public APIEmail email { get; private set; }
		public Integer expiresInNumberOfDays { get; private set; }

		public APIExternalReview(final Integer expiresInNumberOfDays, final List<UUID> documentsIds, final List<String> reviewerIds, final String subject, final String message) {
			this.documents = documentsIds;
			this.reviewers = NegotiateAPI.getAPIReviewers(reviewerIds);
			this.email = new APIEmail(subject, message);
			this.expiresInNumberOfDays = expiresInNumberOfDays;
		}

		public String toXML() {
		   return XMLSerializer.toXMLForm(
		        new Set<String>{ 'Documents', 'Reviewers', 'Email', 'ExpiresInNumberOfDays' }, 
		        new Map<String, Object> {
		            'Documents' => XMLSerializer.fromIteratable(new Set<String>{ 'Id' }, this.documents ,'Documents', 'Document'),
		            'Reviewers' => XMLSerializer.fromIteratable(new Set<String> { 'Uid' }, this.reviewers, 'Reviewers', 'Reviewer'),
		            'Email' => XMLSerializer.fromObject(new Set<String>{ 'Subject', 'Message' }, this.email, 'Email'),
		            'ExpiresInNumberOfDays' => XMLSerializer.fromPrimitive(this.expiresInNumberOfDays, 'ExpiresInNumberOfDays')
		        },
		        'ExternalReview'
		    );
		}
	}

	@TestVisible
	private class APIApproval {

		public List<UUID> documents { get; private set; }
		public List<APIApprover> approvers { get; private set; }
		public APIEmail email { get; private set; }

		public APIApproval(final List<UUID> documentsIds, final List<String> approverIds, final String subject, final String message) {
			this.documents = documentsIds;
			this.approvers = NegotiateAPI.getAPIApprovers(approverIds);
			this.email = new APIEmail(subject, message);
		}

		public String toXML() {
		   return XMLSerializer.toXMLForm(
		        new Set<String>{ 'Documents', 'Reviewers', 'Email', 'CheckoutDocument', 'AssignTasksInOrder' }, 
		        new Map<String, Object> {
		            'Documents' => XMLSerializer.fromIteratable(new Set<String>{ 'Id' }, this.documents ,'Documents', 'Document'),
		            'Approvers' => XMLSerializer.fromIteratable(new Set<String> { 'Uid' }, this.approvers, 'Approvers', 'Approver'),
		            'Email' => XMLSerializer.fromObject(new Set<String>{ 'Subject', 'Message' }, this.email, 'Email'),
		            'CheckoutDocument' => XMLSerializer.fromPrimitive(true, 'CheckoutDocument'),
		            'AssignTasksInOrder' => XMLSerializer.fromPrimitive(true, 'AssignTasksInOrder')
		        },
		        'Approval'
		    );		    
		}
	}

    //Todo: uid for now is an email address, this will most likely change in the future.
	@TestVisible
	private class APIApprover {
		public String uid { get; private set; }

		public APIApprover(final String email) {
			this.uid = email;
		}
	}

    //Todo: uid for now is an email address, this will most likely change in the future.
	@TestVisible
	private class APIReviewer {
		public String uid { get; private set; }

		public APIReviewer(final String email) {
			this.uid = email;
		}
	}

	private class APIEmail {

		public String subject { get; private set; }
		public String message { get; private set; }

		public APIEmail(final String subject, final String message) {
			this.subject = subject;
			this.message = message;
		}
	}

	private static List<APIApprover> getAPIApprovers(final List<String> approverIds) {
		List<APIApprover> approvers = new List<APIApprover>();
		for (String approver : approverIds) {
			approvers.add(new APIApprover(approver));
		}
		return approvers;
	}

	private static List<APIReviewer> getAPIReviewers(final List<String> reviewerIds) {
		List<APIReviewer> reviewers = new List<APIReviewer>();
		for (String reviewer : reviewerIds) {
			reviewers.add(new APIReviewer(reviewer));
		}
		return reviewers;
	}

// Create EOS folder in SpringCM Space
	public UUID createEOSFolder(final String objectName, final Id objectId, final String objectType) {

		final RestAPI.Response response = post(
			getBaseUrl(),
			new List<String> {
				PATH_FOLDER
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'EosInfo' => new EosInfo(objectName, objectId, objectType)
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to create EOS folder: ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return UUID.parse(((String)body.get('Href')).substringAfterLast('/'));
	}

	@TestVisible
	private class APIAgreements {

		public List<APIAgreement> items;
		public String next;
	}

	@TestVisible
	private class APIAgreement {
		public String name;
		public Datetime createdDate;
		public String status;
		public String href;
		public Long pdfFileSize;
		public String version;

		public Agreement convertAPIAgreement() {
			return new Agreement(
				UUID.parse(this.href.substringAfterLast('/')),
				this.name,
				this.createdDate,
				this.createdDate,
				AgreementStatus.NEW_AGREEMENT,
				new Url(this.href),
				this.pdfFileSize,
				this.version);
		}
	}

	@TestVisible
	private class APIFolder {
		public String href;

		APIFolder(final String href) {
			this.href = href;
		}
	}

//Create Agreement in EOS folder
	public UUID createAgreementInEOSFolder(final Id sfContentVersionId, final UUID folderId, final String documentName) {

		final RestAPI.Response response = post(
			getBaseUrl(),
			new List<String> {
				PATH_AGREEMENT_IN_EOS_FOLDER
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'SfContentVersionId' => sfContentVersionId,
				'Folder' => new APIFolder(getBaseUrl() + '/' + PATH_FOLDER + '/' + String.valueOf(folderId)),
				'Name' => documentName
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to create Agreement in EOS folder: ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return UUID.parse(((String)body.get('Href')).substringAfterLast('/'));
	}

	@TestVisible
	public class TaskStatus {
		@AuraEnabled
		public String message;
		@AuraEnabled
		public String status;
	}

//Get status of created Agreement in Folder
	public NegotiateAPI.TaskStatus getAgreementInEOSFolderStatus(final UUID taskId) {
		String status = '';
		Long count = 0;
		NegotiateAPI.TaskStatus result = new NegotiateAPI.TaskStatus();

			while (status != 'Success' && count < 10) {

			final RestAPI.Response response = get(
				getBaseUrl(),
				new List<Object> {
					PATH_AGREEMENT_IN_EOS_FOLDER, taskId
				},
				QueryString.empty,
				getDefaultHeaders(),
				RestAPI.defaultTimeout);
			if (response.hasError) {
				this.log.error('Failed to get status of newly Agreement in EOSfolder for - ' + taskId + ': ' + response.error);
				throw new APIException(response.error);
			}

			result = (NegotiateAPI.TaskStatus)JSON.deserialize(response.body, NegotiateAPI.TaskStatus.class);
			count += 1;
		}

		return result;
	}

//Get All Agreements from an EOS folder
	public List<Agreement> getAgreements(final UUID folderId) {
		List<Agreement> agreements = new List<Agreement>();
		Map<String, String> queryStrings = new Map<String, String>();
		queryStrings.put('limit', String.valueOf(SCM_OFFSET));
		Long offset = -SCM_OFFSET;
		String next = '';

		while (next != null) {
			offset += SCM_OFFSET;
			queryStrings.put('offset', String.valueOf(offset));

			final RestAPI.Response response = get(
				getBaseUrl(),
				new List<Object> {
					PATH_FOLDER, folderId, PATH_DOCUMENTS
				},
				new QueryString(queryStrings),
				getDefaultHeaders(),
				RestAPI.defaultTimeout);
			if (response.hasError) {
				this.log.error('Failed to get Agreements from folderId - ' + folderId + ': ' + response.error);
				throw new APIException(response.error);
			}

			APIAgreements result = (APIAgreements)JSON.deserialize(response.body, APIAgreements.class);
			for (APIAgreement a : result.items) {
				if (a != null) {
					agreements.add(a.convertAPIAgreement());
				}
			}
			next = result.next;
		}

		return agreements;
	}

// Rename Agreement

	public Boolean renameAgreement(final UUID documentId, final String documentName) {

		final RestAPI.Response response = put(
			getBaseUrl(),
			new List<Object> {
				PATH_DOCUMENTS, documentId
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'Name' => documentName
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to rename Agreement: ' + documentId + ': ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return body.get('Name') == documentName;
	}

// Delete Agreement

	public Boolean deleteAgreement(final UUID documentId) {

		final RestAPI.Response response = del(
			getBaseUrl(),
			new List<Object> {
				PATH_DOCUMENTS, documentId
			},
			QueryString.empty,
			getDefaultHeaders(),
			'',
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to delete Agreement - ' + documentId + ': ' + response.error);
			throw new APIException(response.error);
		}

		return response.statusCode == 200 ;
	}

// Get all the versions of the Agreement
	public List<Agreement> getAgreementVersions(final UUID documentId) {
		List<Agreement> agreements = new List<Agreement>();
		Map<String, String> queryStrings = new Map<String, String>();
		queryStrings.put('limit', String.valueOf(SCM_OFFSET));
		Long offset = -SCM_OFFSET;
		String next = '';

		while (next != null) {
			offset += SCM_OFFSET;
			queryStrings.put('offset', String.valueOf(offset));

			final RestAPI.Response response = get(
				getBaseUrl(),
				new List<Object> {
					PATH_DOCUMENTS, documentId, PATH_AGREEMENT_VERSIONS
				},
				new QueryString(queryStrings),
				getDefaultHeaders(),
				RestAPI.defaultTimeout);
			if (response.hasError && response.statusCode == 404) {
				this.log.error('Empty Agreement versions for Agreement - ' + documentId + ': ' + response.error);
				return agreements;
			} else if (response.hasError) {
				this.log.error('Failed to get versions of Agreement - ' + documentId + ': ' + response.error);
				throw new APIException(response.error);
			}

			APIAgreements result = (APIAgreements)JSON.deserialize(response.body, APIAgreements.class);
			for (APIAgreement a : result.items) {
				agreements.add(a.convertAPIAgreement());
			}
			next = result.next;
		}

		return agreements;
	}

// Send for Approval
	public UUID sendForApproval(final List<UUID> documentsIds, final List<String> approverIds, final String subject, final String message) {

		RestAPI.Response response = post(
			getBaseUrl(),
			new List<String> {
				PATH_WORKFLOWS
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'Name' => 'Negotiate_Approval_Template',
				'Params' => new APIApproval(documentsIds, approverIds, subject, message).toXML()
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to Send for Approval - ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return UUID.parse(((String)body.get('Href')).substringAfterLast('/'));
	}

// Send for External Review
	public UUID sendForExternalReview(final List<UUID> documentsIds, final List<String> reviewerIds, final String subject, final String message, final Integer expiresInNumberOfDays) {
		
		RestAPI.Response response = post(
			getBaseUrl(),
			new List<String> {
				PATH_WORKFLOWS
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'Name' => 'Negotiate_ExternalReview_Template',
				'Params' => new APIExternalReview(expiresInNumberOfDays, documentsIds, reviewerIds, subject, message).toXML()
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to Send for External Review - ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return UUID.parse(((String)body.get('Href')).substringAfterLast('/'));
	}

	@TestVisible
	private class APIHistoryItems {
		public List<APIHistoryItem> items;
		public String next;

	}

	@TestVisible
	private class APIHistoryItem {
		public APIData data;
		public String userEmail;
		public AgreementHistoryItem.Action action;
		public Datetime createdDate;

		public AgreementHistoryItem convertAPIHistoryItem() {

			AgreementHistoryItem.Actor actor = null;

			if(this.data.actor != null) {
				actor = new AgreementHistoryItem.Actor(
					this.data.actor.fullName,
					this.data.actor.emailAddress,
					'');
			}

			List<AgreementHistoryItem.Actor> recipients = new List<AgreementHistoryItem.Actor>();

			if (this.data.reviewer != null) {
				recipients.add(new AgreementHistoryItem.Actor(
					this.data.reviewer.fullName,
					this.data.reviewer.emailAddress, ''));
			}

			if(this.data.approvers != null && !this.data.approvers.isEmpty()) {
				for (ApiActor a : this.data.approvers) {
					recipients.add(new AgreementHistoryItem.Actor(
						a.fullName,
						a.emailAddress, ''));
				}
			}

			return new AgreementHistoryItem(
				this.action,
				this.userEmail,
				this.createdDate,
				this.data.emailSubject,
				this.data.emailMessage,
				this.data.documentName,
				actor,
				recipients);
		}
	}

	@TestVisible
	private class APIActor {
		public String fullName;
		public String emailAddress;
	}

// User, do we need it ?
	@TestVisible
	private class APIData {
		public String documentName;
		public Datetime dueDate;
		public String emailSubject;
		public String emailMessage;
		public APIActor actor;
		public APIActor reviewer;
		public List<APIActor> approvers;
	}

//Get historyItems
	public List<AgreementHistoryItem> getHistoryItems(final UUID documentId) {
		List<AgreementHistoryItem> historyItems = new List<AgreementHistoryItem>();
		Map<String, String> queryStrings = new Map<String, String>();
		queryStrings.put('limit', String.valueOf(SCM_OFFSET));
		Long offset = -SCM_OFFSET;
		String next = '';

		while (next != null) {
			offset += SCM_OFFSET;
			queryStrings.put('offset', String.valueOf(offset));

			final RestAPI.Response response = get(
				getBaseUrl(),
				new List<Object> {
					PATH_HISTORY_ITEMS, documentId
				},
				new QueryString(queryStrings),
				getDefaultHeaders(),
				RestAPI.defaultTimeout);
			if (response.hasError) {
				this.log.error('Failed to get history items for documentId - ' +
					documentId + response.error);
				throw new APIException(response.error);
			}
			APIHistoryItems result = (APIHistoryItems)JSON.deserialize(response.body, APIHistoryItems.class);
			for (APIHistoryItem a : result.items) {
				if (a != null) {
					historyItems.add(a.convertAPIHistoryItem());
				}
			}
			next = result.next;
		}
// catch some errors here
		return historyItems;
	}
}
