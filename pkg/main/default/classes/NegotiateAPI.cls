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
					'DocumentUrl' => XMLSerializer.fromPrimitive(getDocumentDeepLink(this.sourceId, this.documents[0]), 'DocumentUrl'),
					'Reviewers' => XMLSerializer.fromIteratable(new Set<String> { 'email', 'name' }, this.reviewers, 'Reviewers', 'Reviewer', false),
					'ExpiresInNumberOfDays' => XMLSerializer.fromPrimitive(this.expiresInNumberOfDays, 'ExpiresInNumberOfDays'),					
					'Email' => XMLSerializer.fromObject(new Set<String> { 'subject', 'body' }, this.email, 'Email', false),
					'FailureEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('FailureEmail'), 'FailureEmail', false),
					'ExpiredReview' => XMLSerializer.toXMLForm(
						new Set<String> { 'SenderEmail', 'ReviewerEmail' },
						new Map<String, Object> {
							'SenderEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('ExpiredReview:SenderEmail'), 'SenderEmail', false),
							'ReviewerEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('ExpiredReview:ReviewerEmail'), 'ReviewerEmail', false)
						},
						'ExpiredReview'
					),
					'ReviewCompleted' => XMLSerializer.toXMLForm(
						new Set<String> { 'SenderEmail', 'ReviewerEmail', 'OnBehalfOf' },
						new Map<String, Object> {
							'SenderEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('ReviewCompleted:SenderEmail'), 'SenderEmail', false),
							'ReviewerEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('ReviewCompleted:SenderEmail'), 'ReviewerEmail', false),
							'OnBehalfOf' => XMLSerializer.toXMLForm(
								new Set<String> { 'SenderEmail', 'ReviewerEmail' },
								new Map<String, Object> {
									'SenderEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('OnBehalfOfEmail'), 'SenderEmail', false),
									'ReviewerEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('OnBehalfOfEmail'), 'ReviewerEmail', false)										
								},
								'OnBehalfOf'
							)
						},
						'ReviewCompleted'
					),
					'CanceledReviewEmail' => XMLSerializer.fromObject(new Set<String> { 'subject', 'bodyText', 'headerTitleText' },  templateEmails.get('CanceledReviewEmail'), 'CanceledReviewEmail', false)
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
				String.format(Label.ExpiredReviewHeader_1	, new List<String> { documentName })
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

		public APIApproval(final String name, final Id sourceId, final List<UUID> documentsIds, final List<APIApprover> approvers, final String subject, final String message) {
			this.name = name;
			this.sourceId = sourceId;
			this.documents = documentsIds;
			this.approvers = approvers;
			this.email = new APIEmail(subject, message);
		}

		public String toXML() {
			Map<String, APIEmail> templateEmails = getApprovalTemplateEmails(this.name, this.email.subject, this.email.bodyText);
			return XMLSerializer.toXMLForm(
				new Set<String> { 'Documents', 'ExpiresInNumberOfDays', 'Approvers', 'Email', 'DocumentUrl', 'FailureEmail', 'ExpiredApproval', 'ApprovalCompleted', 'CanceledApprovalEmail' },
				new Map<String, Object> {
					'Documents' => XMLSerializer.fromIteratable(new Set<String> { 'id' }, this.documents, 'Documents', 'Document', false),
					'DocumentUrl' => XMLSerializer.fromPrimitive(getDocumentDeepLink(this.sourceId, this.documents[0]), 'DocumentUrl'),					
					'Approvers' => XMLSerializer.fromIteratable(new Set<String> { 'email' }, this.approvers, 'Approvers', 'Approver', false),					
					'Email' => XMLSerializer.fromObject(new Set<String> { 'subject', 'body' }, this.email, 'Email', false),
					'FailureEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' }, templateEmails.get('FailureEmail'), 'Email', false),
					'ExpiredApproval' => XMLSerializer.toXMLForm(
						new Set<String> { 'SenderEmail', 'ApproverEmail' },
						new Map<String, Object> {
							'SenderEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('ExpiredApproval:SenderEmail'), 'SenderEmail', false),
							'ApproverEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('ExpiredApproval:ApproverEmail'), 'ApproverEmail', false)
						},
						'ExpiredApproval'
					),
					'ApprovalCompleted' => XMLSerializer.toXMLForm(
						new Set<String> { 'SenderEmail', 'ApproverEmail' },
						new Map<String, Object> {
							'SenderEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('ApprovalCompleted:SenderEmail'), 'SenderEmail', false),
							'ApproverEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('ApprovalCompleted:SenderEmail'), 'ApproverEmail', false),
							'OnBehalfOf' => XMLSerializer.toXMLForm(
								new Set<String> { 'SenderEmail', 'ApproverEmail' },
								new Map<String, Object> {
									'SenderEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('OnBehalfOfEmail'), 'SenderEmail', false),
									'ApproverEmail' =>  XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('OnBehalfOfEmail'), 'ApproverEmail', false)										
								},
								'OnBehalfOf'
							)
						},
						'ExpiredApproval'
					),
					'CanceledApprovalEmail' => XMLSerializer.fromObject(new Set<String> { 'buttonText', 'headerTitleText', 'bodyText', 'subject' },  templateEmails.get('CanceledApprovalEmail'), 'CanceledApprovalEmail', false)					
				},
				'Approval'
			);
		}
	}

	@TestVisible
	private static Map<String, APIEmail> getApprovalTemplateEmails(final String documentName, final String customEmailBody, final String customEmailSubject) {
		return new Map<String, APIEmail> {
			'FailureEmail' => new APIEmail(
				String.format(Label.ApprovalFailureEmailSubject_1, new List<String> { documentName }),
				Label.ApprovalFailureEmailBody,
				Label.ViewDocumentButton,
				Label.ApprovalFailureEmailHeader
			),
			'ExpiredApproval:SenderEmail' => new APIEmail(
				Label.ExpiredApprovalSenderEmailSubject,
				String.format(Label.ExpiredApprovalSenderEmailBody_1, new List<String> { documentName }),
				Label.OpenAgreementButton,
				String.format(Label.ExpiredApprovalHeader_1, new List<String> { documentName })
			),
			'ExpiredApproval:ApproverEmail' => new APIEmail(
				Label.ExpiredApprovalApproverEmailSubject,
				String.format(Label.ExpiredApprovalApproverEmailBody_1, new List<String> { documentName }),
				Label.OpenAgreementButton,
				String.format(Label.ExpiredApprovalHeader_1	, new List<String> { documentName })
			),
			'ApprovalCompleted:SenderEmail' => new APIEmail(
				String.format(Label.CompletedApprovalEmailSubject_1, new List<String> { documentName }),
				String.format(Label.CompletedApprovalEmailBody_1, new List<String> { documentName }),
				Label.OpenAgreementButton,
				Label.CompletedApprovalEmailHeader
			), 
			'ApprovalCompleted:ApproverEmail' => new APIEmail(
				String.format(Label.CompletedApprovalEmailSubject_1, new List<String> { documentName }),
				String.format(Label.CompletedApprovalEmailBody_1, new List<String> { documentName }),
				Label.OpenAgreementButton,
				Label.CompletedApprovalEmailHeader
			),
			'OnBehalfOfEmail' => new APIEmail(
				customEmailSubject,
				customEmailBody,
				Label.OpenAgreementButton,
				Label.CompletedApprovalEmailHeader
			),
			'CanceledApprovalEmail' => new APIEmail(
				String.format(Label.CanceledApprovalEmailSubject_1, new List<String> { documentName }),
				String.format(Label.CanceledApprovalEmailBody_1, new List<String> { documentName }),
				Label.OpenAgreementButton,
				Label.CanceledApprovalEmailHeader_1
			)
		};
	}	

	//Todo: uid for now is an email address, this will most likely change in the future.
	@TestVisible
	private class APIApprover {
		public String name { get; private set; }
		public String email { get; private set; }

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
				if (StringUtils.isValidEmail(rec.email) && !String.isBlank(rec.name)) results.add(new APIApprover(rec.name, rec.email));
				else throw new APIException('Invalid Approver email');
			}
			return results;
		} catch(Exception ex) {
			throw new APIException('Invalid Approvers: ' + ex.getMessage());
		}		
	}

	@TestVisible
	private static List<APIReviewer> getAPIReviewers(final List<Recipient> approvers) {
		try {
			List<APIReviewer> results = new List<APIReviewer>();
			for (Recipient rec : approvers) {
				if (StringUtils.isValidEmail(rec.email) && !String.isBlank(rec.name)) results.add(new APIReviewer(rec.name, rec.email));
				else throw new APIException('Invalid Reviewer email');
			}
			return results;
		} catch(Exception ex) {
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
			status = result.status;
			count += 1;
		}

		return result;
	}

	public String getDocumentURL(final UUID documentId) {
		if (documentId == null) return null;
		return getBaseUrl().toExternalForm() + PATH_DOCUMENTS + '/' + documentId.value;
	}

	public static String getDocumentDeepLink(final String sourceId, final UUID documentId) {
		String previewPath = NegotiateService.getAgreementPreviewLink(sourceId, documentId.value);
		if (previewPath == null) return null;
		return new Url(Salesforce.baseUrl, previewPath).toExternalForm().replace('&', '&amp;');
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
	public UUID sendForApproval(final String agreementName, final Id sourceId, final List<UUID> documentsIds, final List<Recipient> approvers, final String subject, final String message) {

		RestAPI.Response response = post(
			getBaseUrl(),
			new List<String> {
				PATH_WORKFLOWS
			},
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'Name' => 'Negotiate_Approval_Template',
				'Params' => new APIApproval(agreementName, sourceId, documentsIds, getAPIApprovers(approvers), subject, message).toXML()
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

			if (this.data.actor != null) {
				actor = new AgreementHistoryItem.Actor(
					this.data.actor.fullName,
					this.data.actor.emailAddress,
					'https://salesforce.com'); //TODO implement account URL logic
			} else {
				actor = new AgreementHistoryItem.Actor(
					'',
					'',
					'https://salesforce.com');
			}

			List<AgreementHistoryItem.Actor> recipients = new List<AgreementHistoryItem.Actor>();

			if (this.data.reviewer != null) {
				recipients.add(new AgreementHistoryItem.Actor(
					this.data.reviewer.fullName,
					this.data.reviewer.emailAddress, ''));
			}

			if (this.data.approvers != null && !this.data.approvers.isEmpty()) {
				for (ApiActor a : this.data.approvers) {
					recipients.add(new AgreementHistoryItem.Actor(
						a.fullName,
						a.emailAddress, ''));
				}
			}

			return new AgreementHistoryItem(
				this.actionType,
				this.userEmail,
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
	}

	@TestVisible
	private class APIActor {
		public String fullName;
		public String emailAddress;
	}

	@TestVisible
	private class APIUser {
		public String userName;
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
	private class APIWorkItem {
		// from assignee use firstName and lastName. Do not use url on Asignee for AprrovalUsers.
		public APIUser assignee;
		public String href;

		AgreementHistoryItem.Actor convertAPIWorkItem() {
			String name = this.assignee.FirstName + ' ' + this.assignee.LastName;
			return new AgreementHistoryItem.Actor(name, null, this.href);
		}
	}

	public List<AgreementHistoryItem.Actor> getApprovalUsers(final UUID documentId) {

		List<AgreementHistoryItem.Actor> workItems = new List<AgreementHistoryItem.Actor>();
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
}

