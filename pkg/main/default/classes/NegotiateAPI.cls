public with sharing class NegotiateAPI extends DocuSignAPI {
// TODO: move common logic between GEN and Negotiate to parent class
	public static final String PATH_FOLDER = 'folders';
	public static final String PATH_DOCUMENTS = 'documents';
	public static final String PATH_AGREEMENT_IN_EOS_FOLDER = 'salesforcecontentdocumentimporttasks';
	public static final String PATH_AGREEMENT_VERSIONS = 'versions';
	public static final String PATH_WORKFLOWS = 'workflows';
	public static final String PATH_HISTORY_ITEMS = 'historyitems';
	public static final String PATH_TOKEN_REGISTRATIONS = 'tokenregistrations';
	public static final String PATH_WORK_ITEMS = 'workitems';
	public static final String PATH_EMAILS = 'emails';
	public static final String PATH_LOCK = 'lock';
	public static final String PATH_REVIEWS = 'reviews';
	public static final String PATH_MEMBERS = 'members';
	public static final String APPROVE = 'Approve';
	public static final String REJECT = 'Reject';
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
	private static Map<String, APIEmail> getExternalReviewTemplateEmails(final String documentName, final String customEmailBody, final String customEmailSubject) {
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
					'RequiresAllToComplete' => XMLSerializer.fromPrimitive(true, 'RequiresAllToComplete'),
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
	private static Map<String, APIEmail> getApprovalTemplateEmails(final String documentName, final String customEmailBody, final String customEmailSubject) {
		return new Map<String, APIEmail> {
			'Email' => new APIEmail(
				String.format(Label.ReviewAgreementSubject, new List<String> { documentName }),
				Label.ReviewAgreementBodyText,
				Label.ReviewAgreementButtonText,
				String.format(Label.ReviewAgreementHeaderTitleText, new List<String> { documentName })
			),
			'ApprovalEmail' => new APIEmail(
				String.format(Label.ApprovalEmailSubject, new List<String> { documentName }),
				Label.ApprovalEmailBodyText,
				Label.ApprovalEmailButtonText,
				String.format(Label.ApprovalEmailHeaderTitleText, new List<String> { documentName })
			),
			'ApprovalOnBehalfEmail' => new APIEmail(
				String.format(Label.ApprovalOnBehalfEmailSubject, new List<String> { documentName }),
				Label.ApprovalOnBehalfEmailBodyText,
				Label.ApprovalOnBehalfEmailButtonText,
				String.format(Label.ApprovalOnBehalfEmailHeaderTitleText, new List<String> { documentName })
			),
			'RejectOnBehalfEmail' => new APIEmail(
				String.format(Label.RejectOnBehalfEmailSubject, new List<String> { documentName }),
				Label.RejectOnBehalfEmailBodyText,
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
				Label.ApprovalRejectEmailBodyText,
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
			this.buttonText = buttonText; //Custom Label
			this.headerTitleText = headerTitle; //Custom Label
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
				if (StringUtils.isValidEmail(rec.email) && !String.isBlank(rec.name)) results.add(new APIReviewer(rec.email, rec.name));
				else throw new APIException('Invalid Reviewer email');
			}
			return results;
		} catch (Exception ex) {
			throw new APIException('Invalid Reviewers: ' + ex.getMessage());
		}
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
		public String updatedBy;
		public Datetime createdDate;
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
			status = result.status;
			count += 1;
		}

		return result;
	}

	public String getDocumentURL(final UUID documentId) {
		if (documentId == null) return null;
		return getBaseUrl().toExternalForm() + PATH_DOCUMENTS + '/' + documentId.value;
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

// get Agreement by id
	public Agreement getAgreement(final UUID agreementId) {

		final RestAPI.Response response = get(
			getBaseUrl(),
			new List<Object> {
				PATH_DOCUMENTS, agreementId
			},
			QueryString.empty,
			getDefaultHeaders(),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to get Agreement  - ' + agreementId + ': ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIAgreement)Json.deserialize(response.body, APIAgreement.class)).convertAPIAgreement();

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
	public UUID sendForApproval(final String agreementName, final Id sourceId, final List<UUID> documentsIds, final List<Recipient> approvers, final String subject, final String message, final Boolean isSequential) {

		RestAPI.Response response = post(
			getBaseUrl(),
			new List<String> {
				PATH_WORKFLOWS
			},
			QueryString.empty,
			getDefaultHeaders(),
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
			getBaseUrl(),
			new List<String> {
				PATH_WORKFLOWS
			},
			QueryString.empty,
			getDefaultHeaders(),
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

		while (status != 'Waiting' && status != 'Failed' && count < 10) {

			final RestAPI.Response response = get(
				getBaseUrl(),
				new List<Object> {
					PATH_WORKFLOWS, taskId
				},
				QueryString.empty,
				getDefaultHeaders(),
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
	private class APIHistoryItems {
		public List<APIHistoryItem> items;
		public String next;

	}

	@TestVisible
	private class APIHistoryItem {
		public APIData data;
		public String userEmail;
		public String actionType;
		public Datetime createdDate;

		public AgreementHistoryItem convertAPIHistoryItem() {

			AgreementHistoryItem.Actor actor = null;

			if (this.data.actor != null &&
				(this.actionType.equals(AgreementHistoryItem.ExternalReviewCompletedDocumentAndComments)
					|| this.actionType.equals(AgreementHistoryItem.ExternalReviewCompletedCheckoutCancelled)
					|| this.actionType.equals(AgreementHistoryItem.ExternalReviewCompletedDocumentCheckin))) {

				Contact resolvedContact = resolveSalesforceContact(this.data.actor.emailAddress);
				//for action types where external review has been completed the actor should map to Salesforce contact
				//once DocumentCheckIn action item type provides the correct actor we will update the if condition to include DocumentCheckIn action Item check as well
				if (resolvedContact != null) {
					actor = new AgreementHistoryItem.Actor(
						(resolvedContact != null && resolvedContact.Name != null) ? resolvedContact.Name : '',
						this.data.actor.emailAddress,
						(resolvedContact != null && resolvedContact.Id != null) ? Salesforce.baseUrl.toExternalForm() + '/' + resolvedContact.Id : '');
				}
				//if a Salesforce contact is not being resolved correctly that means that the External review has been completed by the internal Salesforce Admin user
				//in this case Resolve the actor to a Salesforce user
				else {
					actor = new AgreementHistoryItem.Actor(
						this.data.actor.fullName,
						this.data.actor.emailAddress,
						resolveSalesforceUser(this.data.actor.emailAddress) != null ? resolveSalesforceUser(this.data.actor.emailAddress) : '');
				}

			}
			//for all other action types actor will be mapped to a Salesforce user
			else if (this.data.actor != null) {
				actor = new AgreementHistoryItem.Actor(
					this.data.actor.fullName,
					this.data.actor.emailAddress,
					resolveSalesforceUser(this.data.actor.emailAddress) != null ? resolveSalesforceUser(this.data.actor.emailAddress) : '');
			} else {
				actor = new AgreementHistoryItem.Actor(
					'',
					'',
					'');
			}

			List<AgreementHistoryItem.Actor> recipients = new List<AgreementHistoryItem.Actor>();

			if (this.data.reviewer != null) {
				Contact resolvedContact = resolveSalesforceContact(this.data.reviewer.emailAddress);
				recipients.add(new AgreementHistoryItem.Actor(
					(resolvedContact != null && resolvedContact.Name != null) ? resolvedContact.Name : '',
					this.data.reviewer.emailAddress,
					(resolvedContact != null && resolvedContact.Id != null) ? Salesforce.baseUrl.toExternalForm() + '/' + resolvedContact.Id : ''));
			}

			if (this.data.approvers != null && !this.data.approvers.isEmpty()) {
				for (ApiActor a : this.data.approvers) {
					recipients.add(new AgreementHistoryItem.Actor(
						a.fullName,
						a.emailAddress,
						resolveSalesforceUser(a.emailAddress) != null ? resolveSalesforceUser(a.emailAddress) : ''));
				}
			}

			return new AgreementHistoryItem(
				this.actionType,
				UserInfo.getUserEmail(),
				this.createdDate,
				this.data.emailSubject,
				this.data.emailMessage,
				this.data.documentName,
				this.data.versionNumber != null ? this.data.versionNumber : null,
				this.data.documentOldName != null ? this.data.documentOldName : null,
				this.data.documentName,
				actor,
				recipients);
		}

		@TestVisible
		private String resolveSalesforceUser(final String userEmail) {
			String result;
			try {
				List<User> userList = new List<User>();
				userList = [SELECT Id FROM User WHERE email = :userEmail and isActive = true LIMIT 1];
				if (!userList.isEmpty()) {
					result = Salesforce.baseUrl.toExternalForm() + '/' + userList[0].Id;
				}
			} catch (Exception ex) {
				LoggerService.getInstance().error('Failed to resolve salesforce user in history items ' + ex.getMessage());
			}
			return result;
		}

		@TestVisible
		private Contact resolveSalesforceContact(final String contactEmail) {
			Contact result;
			try {
				List<Contact> contactList = new List<Contact>();
				contactList = [SELECT Id, Name, Email FROM Contact WHERE email = :contactEmail LIMIT 1];
				if (!contactList.isEmpty()) {
					result = contactList[0];
				}
			} catch (Exception ex) {
				LoggerService.getInstance().error('Failed to resolve salesforce contact in history items ' + ex.getMessage());
			}
			return result;
		}
	}

	@TestVisible
	private class APIActor {
		public String fullName;
		public String emailAddress;
	}

	@TestVisible
	private class APIUser {
		public String Email;
		public String FirstName;
		public String LastName;
		public String href;
	}

	@TestVisible
	private class APIData {
		public String documentName;
		public String documentOldName;
		public String versionNumber;
		public String documentUid;
		public Datetime dueDate;
		public String emailSubject;
		public String emailMessage;
		public APIActor actor;
		public APIActor reviewer;
		public List<APIActor> approvers;
		public APIUser user;
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

// limited access token

	private class APILimitedAccessToken {
		public String accessToken;
		public String expiresIn;
		public String APIBaseUrl;
		public String APIUploadBaseUrl;
		public String APIDownloadBaseUrl;

		public NegotiateService.LimitedAccessToken toExternalForm() {
			return new NegotiateService.LimitedAccessToken(accessToken, APIBaseUrl, APIUploadBaseUrl, APIDownloadBaseUrl);
		}
	}

	public NegotiateService.LimitedAccessToken generateLimitedAccessToken(final UUID objectId, final String accessToken) {
		final RestAPI.Response response = post(
			getBaseUrl(),
			new List<String> {
				PATH_TOKEN_REGISTRATIONS
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'objectId' => objectId.value,
				'accessToken' => accessToken
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to generate limited access token: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APILimitedAccessToken)JSON.deserialize(response.body, APILimitedAccessToken.class)).toExternalForm();
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
					PATH_DOCUMENTS, documentId, PATH_WORK_ITEMS
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
				PATH_MEMBERS, memberId
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

	// resend approval request and resend external review request

	@TestVisible
	private class APIHref {
		public String href;

		public APIHref(final String href) {
			this.href = href;
		}
	}

	public Boolean resendRequest(final String documentHref, final String resendEmailType) {

		final RestAPI.Response response = post(
			getBaseUrl(),
			new List<String> {
				PATH_EMAILS
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'Document' => new APIHref(documentHref),
				'ResendEmailType' => resendEmailType
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to resend request: ' + response.error);
			throw new APIException(response.error);
		}

		return response.statusCode == 200 ;
	}

	// Cancel Approval or External Review

	public Boolean cancelApprovalOrExternalReview(final UUID documentId) {

		final RestAPI.Response response = del(
			getBaseUrl(),
			new List<Object> {
				PATH_DOCUMENTS, documentId, PATH_LOCK
			},
			QueryString.empty,
			getDefaultHeaders(),
			'',
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to cancel Approval or External Review for document - ' + documentId + ': ' + response.error);
			throw new APIException(response.error);
		}

		return response.statusCode == 200 ;
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
			getBaseUrl(),
			new List<String> {
				PATH_WORK_ITEMS, workItemsId.value
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'Selected' => new APISelected(comment, itemResponse)
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to resend request: ' + response.error);
			throw new APIException(response.error);
		}

		return response.statusCode == 200 ;
	}

	// externalReview complete on behalf

	@TestVisible
	private class APIUploadDocuments {

		public List<APIHref> Items;

		public APIUploadDocuments(final String href) {
			this.Items = new List<APIHref> { new APIHref(href) };
		}
	}

	public Boolean externalReviewCompleteOnBehalf(final String comments, final Url newVersionUrl, final UUID externalReviewId) {
		// add else part

		final RestAPI.Response response = put(
			getBaseUrl(),
			new List<Object> {
				PATH_REVIEWS, externalReviewId
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'Comments' => comments,
				'UploadedDocuments' => new APIUploadDocuments(newVersionUrl.toExternalForm())
			}),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed external review on Behalf for externalReviewId: ' + externalReviewId + ': ' + response.error);
			throw new APIException(response.error);
		}

		return response.statusCode == 200 ;
	}

	// get document reviews
	public UUID getDocumentReview(final UUID documentId) {

		final RestAPI.Response response = get(
			getBaseUrl(),
			new List<Object> {
				PATH_DOCUMENTS, documentId, PATH_REVIEWS
			},
			QueryString.empty,
			getDefaultHeaders(),
			RestAPI.defaultTimeout);
		if (response.hasError) {
			this.log.error('Failed to get reviews for Agreement - ' + documentId + ': ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return UUID.parse(((String)body.get('Href')).substringAfterLast('/'));

	}

}

