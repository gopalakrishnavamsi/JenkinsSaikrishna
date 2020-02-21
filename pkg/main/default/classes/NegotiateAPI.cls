public with sharing class NegotiateAPI extends ScmAPI {

	public static final String FULL_SUBSCRIBER = 'FullSubscriber';
	public static final String VIEW_EDIT_DELETE = 'ViewEditDelete';
	public static final String APPROVE = 'Approve';
	public static final String REJECT = 'Reject';
	public static final Long SCM_OFFSET = 20;
	public static final String SCM_SORT_PROPERTY = 'UpdatedDate';
	public static final String SCM_SORT_DIRECTION = 'desc';
	public static final Integer API_RETRY_LIMIT = 25;

	private static final String APPROVAL_COMMENTS_PLACEHOLDER = '&lt;%#ApproveComments%&gt;';
	private static NegotiateAPI self = null;
	private UUID accountId = null;

	private NegotiateAPI(
		final Url baseUrl,
		final UUID accountId) {
		super(baseUrl);
		this.accountId = accountId;
	}

	public static NegotiateAPI getInstance() {
		if (self == null) {
			Url baseUrl = AccountProducts.getInstance().getScmApiBaseUrl();
			if (baseUrl == null) throw new DocuSignException(Label.NegotiateNotConfigured);
			self = new NegotiateAPI(baseUrl, Credentials.getInstance().account.id);
		}
		return self;
	}

	@TestVisible
	private class EosInfo {

		public String name;
		public Id objectId;
		public String objectType;

		EosInfo(final String objectName, final Id objectId, final String objectType) {
			this.name = objectName;
			this.objectId = objectId;
			this.objectType = objectType;
		}
	}

	@TestVisible
	private class APIExternalReview {

		public String name { get; private set; }
		public Id sourceId { get; private set; }
		public List<UUID> documents { get; private set; }
		public List<APIReviewer> reviewers { get; private set; }
		public APIEmail email { get; private set; }
		public Integer expiresInNumberOfDays { get; private set; }

		public APIExternalReview(final String name, final Id sourceId, final Integer expiresInNumberOfDays, final List<UUID> documentsIds, final List<APIReviewer> reviewers, final String subject, final String body) {
			this.name = name;
			this.sourceId = sourceId;
			this.documents = documentsIds;
			this.reviewers = reviewers;
			this.email = new APIEmail(subject, body);
			this.expiresInNumberOfDays = expiresInNumberOfDays;
		}

		public String toXML() {
			Map<String, APIEmail> templateEmails = getExternalReviewTemplateEmails(this.name, this.email.subject, this.email.bodyText);
			return XMLSerializer.toXMLForm(
				new Set<String> { 'Documents', 'ExpiresInNumberOfDays', 'Reviewers', 'Email', 'DocumentUrl', 'FailureEmail', 'ExpiredReview', 'ReviewCompleted', 'CanceledReviewEmail' },
				new Map<String, Object> {
					'Documents' => XMLSerializer.fromIteratable(new Set<String> { 'id' }, this.documents, 'Documents', 'Document', false),
					'ExpiresInNumberOfDays' => XMLSerializer.fromPrimitive(this.expiresInNumberOfDays, 'ExpiresInNumberOfDays'),
					'Reviewers' => XMLSerializer.fromIteratable(new Set<String> { 'email', 'name' }, this.reviewers, 'Reviewers', 'Reviewer', false),
					'Email' => XMLSerializer.fromObject(new Set<String> { 'subject', 'body' }, this.email, 'Email', false),
					'DocumentUrl' => XMLSerializer.fromPrimitive(getDocumentDeepLink(this.sourceId, this.documents[0]), 'DocumentUrl'),
					'FailureEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('FailureEmail'), 'FailureEmail', false),
					'ExpiredReview' => XMLSerializer.toXMLForm(
						new Set<String> { 'SenderEmail', 'ReviewerEmail' },
						new Map<String, Object> {
							'SenderEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('ExpiredReview:SenderEmail'), 'SenderEmail', false),
							'ReviewerEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('ExpiredReview:ReviewerEmail'), 'ReviewerEmail', false)
						},
						'ExpiredReview'
					),
					'ReviewCompleted' => XMLSerializer.toXMLForm(
						new Set<String> { 'SenderEmail', 'ReviewerEmail', 'OnBehalfOf' },
						new Map<String, Object> {
							'SenderEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('ReviewCompleted:SenderEmail'), 'SenderEmail', false),
							'ReviewerEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('ReviewCompleted:SenderEmail'), 'ReviewerEmail', false),
							'OnBehalfOf' => XMLSerializer.toXMLForm(
								new Set<String> { 'SenderEmail', 'ReviewerEmail' },
								new Map<String, Object> {
									'SenderEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('OnBehalfOfEmail'), 'SenderEmail', false),
									'ReviewerEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('OnBehalfOfEmail'), 'ReviewerEmail', false)
								},
								'OnBehalfOf'
							)
						},
						'ReviewCompleted'
					),
					'CanceledReviewEmail' => XMLSerializer.fromObject(new Set<String> { 'subject', 'bodyText', 'headerTitleText' }, templateEmails.get('CanceledReviewEmail'), 'CanceledReviewEmail', false)
				},
				'ExternalReview'
			);
		}
	}

	@TestVisible
	private static Map<String, APIEmail> getExternalReviewTemplateEmails(
		final String documentName,
		final String customEmailSubject,
		final String customEmailBody) {

		return new Map<String, APIEmail> {
			'FailureEmail' => new APIEmail(
				String.format(Label.ExternalReviewFailureEmailSubject_1, new List<String> { documentName }),
				Label.ExternalReviewFailureEmailBody,
				Label.ViewDocumentButton,
				Label.ExternalReviewFailureEmailHeader
			),
			'ExpiredReview:SenderEmail' => new APIEmail(
				Label.ExpiredReviewSenderEmailSubject,
				String.format(Label.ExpiredReviewSenderEmailBody_1, new List<String> { documentName }),
				Label.OpenAgreementButton,
				String.format(Label.ExpiredReviewHeader_1, new List<String> { documentName })
			),
			'ExpiredReview:ReviewerEmail' => new APIEmail(
				Label.ExpiredReviewReviewerEmailSubject,
				String.format(Label.ExpiredReviewReviewerEmailBody_1, new List<String> { documentName }),
				Label.OpenAgreementButton,
				String.format(Label.ExpiredReviewHeader_1, new List<String> { documentName })
			),
			'ReviewCompleted:SenderEmail' => new APIEmail(
				String.format(Label.CompletedReviewEmailSubject_1, new List<String> { documentName }),
				String.format(Label.CompletedReviewEmailBody_1, new List<String> { documentName }),
				Label.OpenAgreementButton,
				Label.CompletedReviewEmailHeader
			),
			'ReviewCompleted:ReviewerEmail' => new APIEmail(
				String.format(Label.CompletedReviewEmailSubject_1, new List<String> { documentName }),
				String.format(Label.CompletedReviewEmailBody_1, new List<String> { documentName }),
				Label.OpenAgreementButton,
				Label.CompletedReviewEmailHeader
			),
			'OnBehalfOfEmail' => new APIEmail(
				customEmailSubject,
				customEmailBody,
				Label.OpenAgreementButton,
				Label.CompletedReviewEmailHeader
			),
			'CanceledReviewEmail' => new APIEmail(
				String.format(Label.CanceledReviewEmailSubject_1, new List<String> { documentName }),
				String.format(Label.CanceledReviewEmailBody_1, new List<String> { documentName }),
				Label.OpenAgreementButton,
				String.format(Label.CanceledReviewEmailHeader_1, new List<String> { documentName })
			)
		};
	}

	@TestVisible
	private class APIApproval {

		public String name { get; private set; }
		public Id sourceId { get; private set; }
		public List<UUID> documents { get; private set; }
		public List<APIApprover> approvers { get; private set; }
		public APIEmail email { get; private set; }
		public Boolean isSequential { get; private set; }

		public APIApproval(final String name, final Id sourceId, final List<UUID> documentsIds, final List<APIApprover> approvers, final String subject, final String message, final Boolean isSequential) {
			this.name = name;
			this.sourceId = sourceId;
			this.documents = documentsIds;
			this.approvers = approvers;
			this.email = new APIEmail(subject, message);
			this.isSequential = isSequential;
		}

		public String toXML() {
			Map<String, APIEmail> templateEmails = getApprovalTemplateEmails(this.name, this.email.subject, this.email.bodyText);
			return XMLSerializer.toXMLForm(
				new Set<String> { 'AssignTasksInOrder', 'CheckoutDocument', 'RequiresAllToApprove', 'RequiresAllToComplete', 'Approvers', 'Documents', 'Email', 'ApprovalEmail', 'ApprovalOnBehalfEmail', 'RejectOnBehalfEmail', 'CancelEmail', 'RejectEmail', 'FailureEmail', 'DocumentUrl' },
				new Map<String, Object> {
					'AssignTasksInOrder' => isSequential == true ? XMLSerializer.fromPrimitive(true, 'AssignTasksInOrder') : XMLSerializer.fromPrimitive(false, 'AssignTasksInOrder'),
					'CheckoutDocument' => XMLSerializer.fromPrimitive(true, 'CheckoutDocument'),
					'RequiresAllToApprove' => XMLSerializer.fromPrimitive(true, 'RequiresAllToApprove'),
					'RequiresAllToComplete' => XMLSerializer.fromPrimitive(false, 'RequiresAllToComplete'),
					'Approvers' => XMLSerializer.fromIteratable(new Set<String> { 'email' }, this.approvers, 'Approvers', 'Approver', false),
					'Documents' => XMLSerializer.fromIteratable(new Set<String> { 'id' }, this.documents, 'Documents', 'Document', false),
					'Email' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('Email'), 'Email', false),
					'ApprovalEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('ApprovalEmail'), 'ApprovalEmail', false),
					'ApprovalOnBehalfEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('ApprovalOnBehalfEmail'), 'ApprovalOnBehalfEmail', false),
					'RejectOnBehalfEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('RejectOnBehalfEmail'), 'RejectOnBehalfEmail', false),
					'CancelEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('CancelEmail'), 'CancelEmail', false),
					'RejectEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('RejectOnBehalfEmail'), 'RejectOnBehalfEmail', false),
					'FailureEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('RejectEmail'), 'RejectEmail', false),
					'DocumentUrl' => XMLSerializer.fromPrimitive(getDocumentDeepLink(this.sourceId, this.documents[0]), 'DocumentUrl')
				},
				'Approval'
			);
		}
	}

	@TestVisible
	private static Map<String, APIEmail> getApprovalTemplateEmails(
		final String documentName,
		final String customEmailSubject,
		final String customEmailBody) {

		return new Map<String, APIEmail> {
			'Email' => new APIEmail(
				String.format(customEmailSubject, new List<String> { documentName }),
				customEmailBody,
				Label.ReviewAgreementButtonText,
				String.format(Label.ReviewAgreementHeaderTitleText, new List<String> { documentName })
			),
			'ApprovalEmail' => new APIEmail(
				String.format(Label.ApprovalEmailSubject, new List<String> { documentName }),
				APPROVAL_COMMENTS_PLACEHOLDER,
				Label.ApprovalEmailButtonText,
				String.format(Label.ApprovalEmailHeaderTitleText, new List<String> { documentName })
			),
			'ApprovalOnBehalfEmail' => new APIEmail(
				String.format(Label.ApprovalOnBehalfEmailSubject, new List<String> { documentName }),
				APPROVAL_COMMENTS_PLACEHOLDER,
				Label.ApprovalOnBehalfEmailButtonText,
				String.format(Label.ApprovalOnBehalfEmailHeaderTitleText, new List<String> { documentName })
			),
			'RejectOnBehalfEmail' => new APIEmail(
				String.format(Label.RejectOnBehalfEmailSubject, new List<String> { documentName }),
				APPROVAL_COMMENTS_PLACEHOLDER,
				Label.RejectOnBehalfEmailButtonText,
				String.format(Label.RejectOnBehalfEmailHeaderTitleText, new List<String> { documentName })
			),
			'CancelEmail' => new APIEmail(
				String.format(Label.ApprovalCancelEmailSubject, new List<String> { documentName }),
				String.format(Label.ApprovalCancelEmailBodyText, new List<String> { documentName }),
				'',
				Label.ApprovalCancelEmailHeaderTitleText
			),
			'RejectEmail' => new APIEmail(
				String.format(Label.ApprovalRejectEmailSubject, new List<String> { documentName }),
				APPROVAL_COMMENTS_PLACEHOLDER,
				Label.ApprovalRejectEmailButtonText,
				String.format(Label.ApprovalRejectEmailHeaderTitleText, new List<String> { documentName })
			),
			'FailureEmail' => new APIEmail(
				Label.ApprovalFailureEmailSubject,
				Label.ApprovalFailureEmailBodyText,
				Label.ApprovalFailureEmailButtonText,
				Label.ApprovalFailureEmailHeaderTitleText
			)
		};
	}

	//Todo: uid for now is an email address, this will most likely change in the future.
	@TestVisible
	private class APIApprover {
		public String email { get; private set; }
		public String name { get; private set; }

		public APIApprover(final String email, final String name) {
			this.email = email;
			this.name = name;
		}
	}

	//Todo: uid for now is an email address, this will most likely change in the future.
	@TestVisible
	private class APIReviewer {
		public String email { get; private set; }
		public String name { get; private set; }

		public APIReviewer(final String email, final String name) {
			this.email = email;
			this.name = name;
		}
	}

	@TestVisible
	private class APIEmail {

		public String subject { get; private set; }
		public String bodyText { get; private set; }
		public String buttonText { get; private set; }
		public String headerTitleText { get; private set; }
		public String body {
			get {
				return this.bodyText;
			}
		}

		public APIEmail(final String subject, final String body) {
			this.subject = subject;
			this.bodyText = body;
		}

		public APIEmail(final String subject, final String body, final String buttonText, final String headerTitle) {
			this.subject = subject;
			this.bodyText = body;
			this.buttonText = buttonText;//Custom Label
			this.headerTitleText = headerTitle;//Custom Label
		}
	}

	private static List<APIApprover> getAPIApprovers(final List<Recipient> approvers) {
		try {
			List<APIApprover> results = new List<APIApprover>();
			for (Recipient rec : approvers) {
				if (StringUtils.isValidEmail(rec.email) && !String.isBlank(rec.name)) results.add(new APIApprover(rec.email, rec.name)); else throw new APIException('Invalid Approver email');
			}
			return results;
		} catch (Exception ex) {
			throw new APIException('Invalid Approvers: ' + ex.getMessage());
		}
	}

	@TestVisible
	private static List<APIReviewer> getAPIReviewers(final List<Recipient> approvers) {
		try {
			List<APIReviewer> results = new List<APIReviewer>();
			for (Recipient rec : approvers) {
				if (StringUtils.isValidEmail(rec.email) && !String.isBlank(rec.name)) results.add(new APIReviewer(rec.email, rec.name)); else throw new APIException('Invalid Reviewer email');
			}
			return results;
		} catch (Exception ex) {
			throw new APIException('Invalid Reviewers: ' + ex.getMessage());
		}
	}

	// Create EOS folder in SpringCM Space
	public UUID createEOSFolder(
		final String objectName,
		final Id objectId,
		final String objectType) {

		RestAPI.Response response = this.post(
			new List<Object> { 'v2', accountId, 'folders' },
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
		public String updatedBy;
		public Datetime createdDate;
		public Datetime contentCreatedDate;
		public String status;
		public String href;
		public Long pdfFileSize;
		public String version;

		public Agreement convertAPIAgreement() {
			return new Agreement(
				UUID.parse(this.href.substringAfterLast('/')),
				this.name,
				this.updatedBy,
				this.createdDate,
				this.createdDate,
				this.contentCreatedDate,
				AgreementStatus.NEW_AGREEMENT,
				this.href,
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

	@TestVisible
	private class APIRoles {
		public String item;
		public String accessType;

		APIRoles(final String item, final String accessType) {
			this.item = item;
			this.accessType = accessType;
		}
	}

	@TestVisible
	private class APISecurity {
		public List<APIRoles> roles;

		APISecurity(final List<APIRoles> roles) {
			this.roles = roles;
		}
	}

	@TestVisible
	private class APIDocument {
		public String href;

		APIDocument(final String href) {
			this.href = href;
		}
	}

	//Create Agreement in EOS folder
	public UUID createAgreementInEOSFolder(
		final Id sfContentVersionId,
		final UUID folderId,
		final String documentName) {
		RestAPI.Response response = this.post(
			new List<Object> { 'v2', accountId, 'salesforcecontentdocumentimporttasks' },
			JSON.serialize(new Map<String, Object> {
				'SfContentVersionId' => sfContentVersionId,
				'Folder' => new APIFolder(getBaseUrl() + '/folders/' + String.valueOf(folderId)),
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

	//Add Agreement to Salesforce Files
	public UUID exportAgreementToSalesforce(
		final Id sourceId,
		final UUID documentId) {

		RestAPI.Response response = this.post(
			new List<Object> { 'v2', accountId, 'salesforcecontentdocumentexporttasks' },
			JSON.serialize(new Map<String, Object> {
				'SfObjectId' => sourceId,
				'Document' => new APIDocument(getBaseUrl() + '/documents/' + String.valueOf(documentId))
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to export Agreement to Salesforce: ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return UUID.parse(((String)body.get('Href')).substringAfterLast('/'));
	}

	//Generate Task UUID for comparing two agreement versions
	//originalDocumentHref -> the url for the current version of the agreement
	//compareVersionHref -> the url for the version of the agreement which is to be compared with the current version of the agreement
	public UUID compareAgreements(
		final String originalDocumentHref,
		final String compareVersionHref) {

		RestAPI.Response response = this.post(
			new List<Object> { 'v2', accountId, 'documentcomparetasks' },
			JSON.serialize(new Map<String, Object> {
				'OriginalDocument' => new APIDocument(originalDocumentHref),
				'RevisedDocument' => new APIDocument(compareVersionHref)
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to trigger document comparison: ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return UUID.parse(((String)body.get('Href')).substringAfterLast('/'));
	}

	@TestVisible
	private class APIHref {
		public String href;

		APIHref(final String href) {
			this.href = href;
		}
	}

	// FIXME: Leaky abstraction. This should not be directly exposed to the caller.
	public class TaskStatus {
		@AuraEnabled
		public String message;
		@AuraEnabled
		public String status;
		public APIHref document;
		@AuraEnabled
		public UUID agreementId {
			get {
				if (this.document == null) return null;
				return UUID.parse((this.document.href).substringAfterLast('/'));
			}
		}
	}

	//Get status of created Agreement in Folder
	public NegotiateAPI.TaskStatus getAgreementInEOSFolderStatus(final UUID taskId) {
		String status = '';
		Long count = 0;
		NegotiateAPI.TaskStatus result = new NegotiateAPI.TaskStatus();

		while (status != 'Success' && count < API_RETRY_LIMIT) {
			RestAPI.Response response = this.get(
				new List<Object> { 'v2', accountId, 'salesforcecontentdocumentimporttasks', taskId },
				RestAPI.defaultTimeout);
			if (response.hasError) {
				this.log.error('Failed to get status of newly Agreement in EOSfolder for - ' + taskId + ': ' + response.error);
				throw new APIException(response.error);
			}
			result = (NegotiateAPI.TaskStatus)JSON.deserialize(response.body, NegotiateAPI.TaskStatus.class);
			status = result.status;
			count += 1;
		}

		return result;
	}

	public NegotiateAPI.TaskStatus getCompareAgreementsStatus(final UUID taskId) {
		String status = '';
		Long count = 0;
		NegotiateAPI.TaskStatus result = new NegotiateAPI.TaskStatus();

		while (status != 'Success' && count < API_RETRY_LIMIT) {
			final RestAPI.Response response = this.get(
				new List<Object> {
					'v2', accountId, 'documentcomparetasks', taskId
				},
				RestAPI.defaultTimeout);
			if (response.hasError) {
				this.log.error('Failed to get status of comparison of Agreements - ' + taskId + ': ' + response.error);
				throw new APIException(response.error);
			}
			result = (NegotiateAPI.TaskStatus)JSON.deserialize(response.body, NegotiateAPI.TaskStatus.class);
			status = result.status;
			count += 1;
		}

		return result;
	}

	public NegotiateAPI.TaskStatus getExportAgreementToSalesforceStatus(final UUID taskId) {
		String status = '';
		Long count = 0;
		NegotiateAPI.TaskStatus result = new NegotiateAPI.TaskStatus();

		while (status != 'Success' && count < API_RETRY_LIMIT) {

			final RestAPI.Response response = this.get(
				new List<Object> {
					'v2', accountId, 'salesforcecontentdocumentexporttasks', taskId
				},
				RestAPI.defaultTimeout);
			if (response.hasError) {
				this.log.error('Failed to get status of newly exported Agreement to Salesforce - ' + taskId + ': ' + response.error);
				throw new APIException(response.error);
			}
			result = (NegotiateAPI.TaskStatus)JSON.deserialize(response.body, NegotiateAPI.TaskStatus.class);
			status = result.status;
			count += 1;
		}

		return result;
	}

	public static String getDocumentDeepLink(final Id sourceId, final UUID documentId) {
		if (sourceId == null || documentId == null) return null;
		try {
			PageReference previewPath = Page.AgreementPreview;
			previewPath.getParameters().put('sourceId', EncodingUtil.urlEncode(sourceId, StringUtils.ENCODING));
			previewPath.getParameters().put('agreementId', EncodingUtil.urlEncode(documentId.value, StringUtils.ENCODING));

			return new Url(Salesforce.baseUrl, previewPath.getUrl()).toExternalForm().replace('&', '&amp;');
		} catch (Exception ex) {
			throw new APIException('Failed to generate Document deep link: ' + ex.getMessage());
		}
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
			queryStrings.put('SortProperty', SCM_SORT_PROPERTY);
			queryStrings.put('SortDirection', SCM_SORT_DIRECTION);
			final RestAPI.Response response = get(
				new List<Object> {
					'v2', accountId, 'folders', folderId, 'documents'
				},
				new QueryString(queryStrings),
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

	public Agreement getAgreement(final UUID agreementId) {

		final RestAPI.Response response = get(
			new List<Object> {
				'v2', accountId, 'documents', agreementId
			},
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to get Agreement  - ' + agreementId + ': ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIAgreement)JSON.deserialize(response.body, APIAgreement.class)).convertAPIAgreement();

	}

	public Boolean renameAgreement(final UUID documentId, final String documentName) {

		final RestAPI.Response response = put(
			new List<Object> {
				'v2', accountId, 'documents' , documentId
			},
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

	public Boolean deleteAgreement(final UUID documentId) {

		final RestAPI.Response response = del(
			new List<Object> {
				'v2', accountId, 'documents', documentId
			},
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to delete Agreement - ' + documentId + ': ' + response.error);
			throw new APIException(response.error);
		}

		return response.statusCode == 200;
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
				new List<Object> {
					'v2', accountId, 'documents', documentId, 'versions'
				},
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
	public UUID sendForApproval(final String agreementName, final Id sourceId, final List<UUID> documentsIds, final List<Recipient> approvers, final String subject, final String message, final Boolean isSequential) {

		RestAPI.Response response = post(
			new List<Object> {
				'v2', accountId, 'workflows'
			},
			JSON.serialize(new Map<String, Object> {
				'Name' => 'Negotiate_Approval_Template',
				'Params' => new APIApproval(agreementName, sourceId, documentsIds, getAPIApprovers(approvers), subject, message, isSequential).toXML()
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
	public UUID sendForExternalReview(final String agreementName, final Id sourceId, final List<UUID> documentsIds, final List<Recipient> reviewers, final String subject, final String body, final Integer expiresInNumberOfDays) {
		RestAPI.Response response = post(
			new List<Object> {
				'v2', accountId, 'workflows'
			},
			JSON.serialize(new Map<String, Object> {
				'Name' => 'Negotiate_ExternalReview_Template',
				'Params' => new APIExternalReview(agreementName, sourceId, expiresInNumberOfDays, documentsIds, getAPIReviewers(reviewers), subject, body).toXML()
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to Send for External Review - ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> responsebody = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return UUID.parse(((String)responsebody.get('Href')).substringAfterLast('/'));
	}

	public NegotiateAPI.TaskStatus getWorkFlowStatus(final UUID taskId) {
		String status = '';
		Long count = 0;
		NegotiateAPI.TaskStatus result = new NegotiateAPI.TaskStatus();

		while (status != 'Waiting' && status != 'Failed' && count < API_RETRY_LIMIT) {

			final RestAPI.Response response = get(
				new List<Object> {
					'v2', accountId, 'workflows', taskId
				},
				RestAPI.defaultTimeout);
			if (response.hasError) {
				this.log.error('Failed to get status of Workflow Item - ' + taskId + ': ' + response.error);
				throw new APIException(response.error);
			}

			result = (NegotiateAPI.TaskStatus)JSON.deserialize(response.body, NegotiateAPI.TaskStatus.class);
			status = result.status;
			count += 1;
		}

		return result;
	}

	@TestVisible
	private class APIUser {
		public String Email;
		public String FirstName;
		public String LastName;
		public String href;
	}

	// workItems to get Assignee for PreviewWidget
	@TestVisible
	private class APIWorkItems {
		public List<APIWorkItem> items;
		public String next;
	}

	@TestVisible
	private class APIMemberDetails {
		public String email;
		public String firstName;
		public String lastName;
	}

	@TestVisible
	private class APIWorkItem {
		public APIUser assignee;
		public String href;

		AgreementApprovalWorkItem convertAPIWorkItem() {
			NegotiateAPI.APIMemberDetails memberResult = (NegotiateAPI.APIMemberDetails)JSON.deserialize(NegotiateAPI.getInstance().resolveApproverDetails(UUID.parse(this.assignee.href.substringAfterLast('/'))), NegotiateAPI.APIMemberDetails.class);
			return new AgreementApprovalWorkItem(memberResult.firstName, memberResult.lastName, memberResult.email, this.href);
		}
	}

	public List<AgreementApprovalWorkItem> getApprovalWorkItems(final UUID documentId) {

		List<AgreementApprovalWorkItem> workItems = new List<AgreementApprovalWorkItem>();
		Map<String, String> queryStrings = new Map<String, String>();
		queryStrings.put('limit', String.valueOf(SCM_OFFSET));
		Long offset = -SCM_OFFSET;
		String next = '';

		while (next != null) {
			offset += SCM_OFFSET;
			queryStrings.put('offset', String.valueOf(offset));
			queryStrings.put('expand', 'Assignee');

			final RestAPI.Response response = get(
				getBaseUrl(),
				new List<Object> {
					'v2', accountId, 'documents', documentId, 'workitems'
				},
				new QueryString(queryStrings),
				getDefaultHeaders(),
				RestAPI.defaultTimeout);
			if (response.hasError) {
				this.log.error('Failed to get history items for documentId - ' +
					documentId + response.error);
				throw new APIException(response.error);
			}

			APIWorkItems result = (APIWorkItems)JSON.deserialize(response.body, APIWorkItems.class);
			for (APIWorkItem a : result.items) {
				if (a != null) {
					workItems.add(a.convertAPIWorkItem());
				}
			}
			next = result.next;
		}
		return workItems;
	}

	public String resolveApproverDetails(final UUID memberId) {

		final RestAPI.Response response = get(
			getBaseUrl(),
			new List<Object> {
				'v2', accountId, 'members', memberId
			},
			QueryString.empty,
			getDefaultHeaders(),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to get memberId  - ' + memberId + ': ' + response.error);
			throw new APIException(response.error);
		}
		return response.body;
	}

	// Cancel Approval or External Review
	public Boolean cancelApprovalOrExternalReview(final UUID documentId) {

		final RestAPI.Response response = del(
			new List<Object> {
				'v2', accountId, 'documents', documentId, 'lock'
			},
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to cancel Approval or External Review for document - ' + documentId + ': ' + response.error);
			throw new APIException(response.error);
		}

		return response.statusCode == 200;
	}

	// approveOnBehalf and recipientResponse
	@TestVisible
	private class APISelected {

		public String Comment;
		public List<String> Items;

		public APISelected(final String comment, final String item) {
			this.Comment = comment;
			this.Items = new List<String> { item };
		}
	}

	public Boolean approveOnBehalfOrRecipientResponse(final String comment, final String itemResponse, final UUID workItemsId) {

		final RestAPI.Response response = put(
			new List<Object> {
				'v2', accountId, 'workitems', workItemsId.value
			},
			JSON.serialize(new Map<String, Object> {
				'Selected' => new APISelected(comment, itemResponse)
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to resend request: ' + response.error);
			throw new APIException(response.error);
		}

		return response.statusCode == 200;
	}

	// externalReview complete on behalf
	@TestVisible
	private class APIUploadDocuments {

		public List<APIExternalReviewOnBehalfOfHref> Items;
		public Integer Total;
		public APIUploadDocuments(final String href) {
			this.Items = new List<APIExternalReviewOnBehalfOfHref> { new APIExternalReviewOnBehalfOfHref(href) };
			this.Total = this.Items != null ? this.Items.size() : 0;
		}
	}

	private class APIExternalReviewOnBehalfOfHref {
		public String Href;

		public APIExternalReviewOnBehalfOfHref(final String href) {
			this.Href = href;
		}
	}

	public Boolean externalReviewCompleteOnBehalf(final String comments, final Url newVersionUrl, final UUID externalReviewId) {
		Map<String, Object> requestParameters = new Map<String, Object>();
		requestParameters.put('Comment', comments);

		if (newVersionUrl != null) {
			requestParameters.put('UploadedDocuments', new APIUploadDocuments(newVersionUrl.toExternalForm()));
		}
		final RestAPI.Response response = put(
			getBaseUrl(),
			new List<Object> {
				'v2', accountId, 'reviews', externalReviewId
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(requestParameters),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed external review on Behalf for externalReviewId: ' + externalReviewId + ': ' + response.error);
			throw new APIException(response.error);
		}

		return response.statusCode == 200;
	}

	// get document reviews
	public UUID getDocumentReview(final UUID documentId) {

		final RestAPI.Response response = get(
			new List<Object> {
				'v2', accountId, 'documents', documentId, 'reviews'
			},
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to get reviews for Agreement - ' + documentId + ': ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return UUID.parse(((String)body.get('Href')).substringAfterLast('/'));
	}

	// Create Folder

	public UUID createFolder(final String folderName, final UUID parentFolder) {

		final RestAPI.Response response = post(
			getBaseUrl(),
			new List<Object> {
				'v2', accountId, 'folders'
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'Name' => folderName,
				'ParentFolder' => new APIFolder(getBaseUrl() + '/folders/' + String.valueOf(parentFolder))
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to create folder: ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return UUID.parse(((String)body.get('Href')).substringAfterLast('/'));
	}

	// Get template_html folder for an account
	public UUID getTemplateHtmlFolder() {

		Map<String, String> queryStrings = new Map<String, String>();
		queryStrings.put('templateType', 'html');

		final RestAPI.Response response = get(
			getBaseUrl(),
			new List<Object> {
				'negotiate', 'api', 'v1', accountId ,'templates', 'root'
			},
			new QueryString(queryStrings),
			getDefaultHeaders(),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to get template html folder : ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return UUID.parse((String)body.get('id'));
	}

	//Get the href for root level folder on the account
	public Url getRootLevelFolderUrl() {
		Map<String, String> queryStrings = new Map<String, String>();
		queryStrings.put('SystemFolder', 'other sources');

		final RestAPI.Response response = get(
			new List<Object> {
				'v2', accountId, 'folders', 'type'
			},
			new QueryString(queryStrings),
			RestAPI.defaultTimeout);

		if (response.hasError) {
			this.log.error('Failed get the href for root level folder on the account - ' + response.error);
			throw new APIException(response.error);
		}

		APIHref result = (APIHref)JSON.deserialize(response.body, APIHref.class);
		if (String.isNotBlank(result.href)) {
			return new Url(result.href);
		} else {
			return null;
		}
	}

	//Set the correct AccessType to move or delete documents on the root folder
	//This call returns the Url of the asynchronous task that is queued in SpringCM for execution
	//Currently there is no need to monitoring the task and checking for status
	public void triggerChangeSecurityTask(final Url rootLevelFolderUrl) {
		if (rootLevelFolderUrl != null) {
			List<APIRoles> roles = new List<APIRoles>();
			roles.add(new APIRoles(FULL_SUBSCRIBER, VIEW_EDIT_DELETE));

			RestAPI.Response response = this.post(
				new List<Object> { 'v2', accountId, 'changesecuritytasks' },
				JSON.serialize(new Map<String, Object> {
					'Folder' => new APIHref(rootLevelFolderUrl.toExternalForm()),
					'Security' => new APISecurity(roles)
				}),
				RestAPI.defaultTimeout);

			if (response.hasError) {
				this.log.error('Failed to trigger change security task: ' + response.error);
				throw new APIException(response.error);
			}
		}
	}
}