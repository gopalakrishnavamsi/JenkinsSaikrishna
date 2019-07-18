/**
 * Primary interface point for DocuSign Negotiate.
 */
public with sharing class NegotiateService {
	@TestVisible
	private static final NegotiateService.Database DB = new NegotiateService.Database();

	public class NegotiateRecipient {
		public String name { get; private set; }
	}

	private class Database {

		@TestVisible
		private UUID getFolderId(final Id sourceObjectId) {
			Permissions.verifyIsQueryable(AgreementConfiguration__c.getSObjectType(), new List<String> {
				'Id', 'Name', 'FolderId__c', 'SourceObject__c'
			});

			List<AgreementConfiguration__c> agreementConfigurationList = new List<AgreementConfiguration__c>();
			agreementConfigurationList = [SELECT Id, Name, FolderId__c, SourceObject__c FROM AgreementConfiguration__c WHERE SourceObject__c = :sourceObjectId];
			if (!agreementConfigurationList.isEmpty()) {
				return UUID.parse(agreementConfigurationList[0].FolderId__c);
			} else {
				return null;
			}
		}
	}

	public class LimitedAccessToken {
		@AuraEnabled
		public String token { get; private set; }
		@AuraEnabled
		public String apiBaseUrl { get; private set; }
		@AuraEnabled
		public UUID accountId { get; private set; }
		@AuraEnabled
		public UUID entityId { get; private set; }
		@AuraEnabled
		public String apiUploadBaseUrl { get; private set; }
		@AuraEnabled
		public String apiDownloadBaseUrl { get; private set; }

		public LimitedAccessToken(
			final String token,
			final String apiBaseUrl,
			final String apiUploadBaseUrl,
			final String apiDownloadBaseUrl) {

			this.token = token;
			this.apiBaseUrl = apiBaseUrl;
			this.apiUploadBaseUrl = apiUploadBaseUrl != null ? apiUploadBaseUrl.split('/v')[0] : null;
			this.apiDownloadBaseUrl = apiDownloadBaseUrl != null ? apiDownloadBaseUrl.split('/v')[0] : null;
			this.accountId = null;
			this.entityId = null;
		}

		public LimitedAccessToken withAccountId(UUID accountId) {
			this.accountId = accountId;
			return this;
		}

		public LimitedAccessToken withEntityId(UUID entityId) {
			this.entityId = entityId;
			return this;
		}
	}

	@future
	private static void setFolderId(final Id sourceObjectId, final String folderId) {
		Permissions.verifyIsCreateable(AgreementConfiguration__c.getSObjectType(), new List<String> {
			'FolderId__c', 'SourceObject__c'
		});

		AgreementConfiguration__c configuration = new AgreementConfiguration__c();
		configuration.FolderId__c = folderId;
		configuration.SourceObject__c = sourceObjectId;
		insert configuration;

	}

	/**
	 * Fetches the Agreements on the Salesforce Source Object
	 *
	 * @param sourceObjectId The ID of the ContentVersion. This will be used to fetch the ContentDocument to be deleted.
	 *
	 * @return Boolean
	 */

	public static List<Agreement> getAgreements(final Id sourceObjectId) {
		Permissions.verifyIsDocuSignUser(); //TODO check if additional Netgotiate permissions check
		UUID folderId = DB.getFolderId(sourceObjectId);
		List<Agreement> agreements = new List<Agreement>();
		if (folderId == null) {
			String sourceObjectType = sourceObjectId.getSObjectType().getDescribe().getName();
			String sourceObjectName = sourceObjectId; //EOS folder name set as recordID since Name field can vary on all objects.
			folderId = NegotiateAPI.getInstance().createEOSFolder(sourceObjectName, sourceObjectId, sourceObjectType);
			setFolderId(sourceObjectId, folderId.toString());
			return agreements;

		} else {
			agreements = NegotiateAPI.getInstance().getAgreements(folderId);
			for (Agreement agreement : agreements) {
				if (agreement != null) {
					agreement = getAgreementData(agreement);
				}
			}
		}
		return agreements;
	}

	public static Agreement getAgreement(final UUID agreementId) {
		Permissions.verifyIsDocuSignUser(); //TODO check if additional Netgotiate permissions check
		return getAgreementData(NegotiateAPI.getInstance().getAgreement(agreementId));
	}

	private static Agreement getAgreementData(Agreement agreement) {
		// add historyItems
		List<AgreementHistoryItem> agreementHistoryItems = NegotiateAPI.getHistoryAPIInstance().getHistoryItems(agreement.id);
		agreement.withStatus(calculateStatus(agreementHistoryItems)).withHistoryItems(agreementHistoryItems);
		if (agreementHistoryItems != null && !agreementHistoryItems.isEmpty() && agreementHistoryItems.get(0) != null) {
			agreement.withModifiedDate(agreementHistoryItems.get(0).historyDate);
		}
		// add versions
		agreement.withVersions(NegotiateAPI.getInstance().getAgreementVersions(agreement.id));
		return agreement;
	}

	private static String calculateStatus(final List<AgreementHistoryItem> historyItems) {
		if (historyItems == null || historyItems.isEmpty()) {
			return AgreementStatus.SYSTEM_ERROR;
		}
		if (historyItems.get(0).historyItemType == AgreementHistoryItem.WorkflowApproved) {

			List<AgreementHistoryItem> tempHistoryItems = new List<AgreementHistoryItem>();
			Long numberOfApprovers = 0;
			for (AgreementHistoryItem historyItem : historyItems) {
				if (historyItem.historyItemType != null && historyItem.historyItemType == AgreementHistoryItem.ApprovalCheckout) {
					numberOfApprovers = historyItem.recipients.size();
					break;
				} else if (historyItem.historyItemType != null && historyItem.historyItemType == AgreementHistoryItem.WorkflowApproved) {
					tempHistoryItems.add(historyItem);
				}
			}
			if (numberOfApprovers == tempHistoryItems.size()) {
				return AgreementStatus.APPROVED;
			} else {
				return AgreementStatus.PENDING_APPROVAL;
			}
		}
		return statusActionMapping(historyItems.get(0).historyItemType);
	}

	private static String statusActionMapping(final String historyItemType) {

		if (historyItemType.equals(AgreementHistoryItem.DocumentImportFromSalesforce) ||
			historyItemType.equals(AgreementHistoryItem.DocumentAdded) ||
			historyItemType.equals(AgreementHistoryItem.TitleChanged)) {
			return AgreementStatus.NEW_AGREEMENT;
		}

		else if (historyItemType.equals(AgreementHistoryItem.ExternalReviewInitiated)) {
			return AgreementStatus.PENDING_REVIEW;
		}

		else if (historyItemType.equals(AgreementHistoryItem.ExternalReviewCompletedDocumentAndComments) ||
			historyItemType.equals(AgreementHistoryItem.ExternalReviewCompletedCheckoutCancelled) ||
			historyItemType.equals(AgreementHistoryItem.ExternalReviewCompletedDocumentCheckin) ||
			historyItemType.equals(AgreementHistoryItem.ExternalReviewCompletedInternally)) {
			return AgreementStatus.REVIEWED;
		}

		else if (historyItemType.equals(AgreementHistoryItem.ExternalReviewCancelled)) {
			return AgreementStatus.REVIEW_CANCELLED;
		}

		else if (historyItemType.equals(AgreementHistoryItem.ExternalReviewErrored)) {
			return AgreementStatus.SYSTEM_ERROR;
		}

		else if (historyItemType.equals(AgreementHistoryItem.ApprovalCheckout)) {
			return AgreementStatus.PENDING_APPROVAL;
		}

		else if (historyItemType.equals(AgreementHistoryItem.WorkflowApproved)) {
			return AgreementStatus.APPROVED;
		}

		else if (historyItemType.equals(AgreementHistoryItem.WorkflowRejected)) {
			return AgreementStatus.REJECTED;
		}

		else if (historyItemType.equals(AgreementHistoryItem.ApprovalCanceledByUser)) {
			return AgreementStatus.APPROVAL_CANCELLED;
		}

		else if (historyItemType.equals(AgreementHistoryItem.DocumentCheckIn)) {
			return AgreementStatus.NEW_VERSION;
		}

		else if (historyItemType.equals(AgreementHistoryItem.ExternalReviewExpirationNew)) {
			return AgreementStatus.REVIEW_EXPIRED;
		}

		else {
			return AgreementStatus.SYSTEM_ERROR;
		}
	}

	public static NegotiateAPI.TaskStatus createAgreementInEOSFolder(final Id sfContentVersionId, final Id sourceObjectId, final String documentName) {
		Permissions.verifyIsDocuSignUser(); //TODO check if additional Netgotiate permissions check
		UUID folderId = DB.getFolderId(sourceObjectId);
		UUID taskId = NegotiateAPI.getInstance().createAgreementInEOSFolder(sfContentVersionId, folderId, documentName);
		NegotiateAPI.TaskStatus taskStatus = NegotiateAPI.getInstance().getAgreementInEOSFolderStatus(taskId);
		if (taskStatus.status.equals('Success')) {
			taskStatus.message = Label.AgreementImportSuccessful;
		} else if (taskStatus.status.equals('Processing')) {
			taskStatus.message = Label.AgreementImportProcessing;
		} else {
			taskStatus.message = Label.AgreementImportFailed;
		}
		return taskStatus;
	}

	public static String getAgreementPreviewLink(final Id sourceId, final String agreementId, final Boolean isFullUrl) {
		Permissions.verifyIsDocuSignUser();
		if (sourceId == null || agreementId == null) return null;

		UUID agreementUId = UUID.parse(agreementId);
		PageReference agreementView = Page.AgreementPreview;
		agreementView.getParameters().put('sourceId', EncodingUtil.urlEncode(sourceId, StringUtils.ENCODING));
		agreementView.getParameters().put('agreementId', EncodingUtil.urlEncode(agreementUId.value, StringUtils.ENCODING));
		if (isFullUrl) return new Url(Salesforce.baseUrl, agreementView.getUrl()).toExternalForm();
		return agreementView.getUrl();
	}

	public static Boolean renameAgreement(final UUID documentId, final String documentName) {
		Permissions.verifyIsDocuSignUser();
		return NegotiateAPI.getInstance().renameAgreement(documentId, documentName);
	}

	public static Boolean deleteAgreement(final UUID documentId) {
		Permissions.verifyIsDocuSignUser();
		return NegotiateAPI.getInstance().deleteAgreement(documentId);
	}

	public static NegotiateAPI.TaskStatus sendForExternalReview(final String agreementName, final Id sourceId, final List<UUID> documentsIds, final List<Recipient> reviewers, final String subject, final String body, final Integer expiresInNumberOfDays) {
		Permissions.verifyIsDocuSignUser(); //TODO check if additional Netgotiate permissions check
		UUID taskId = NegotiateAPI.getInstance().sendForExternalReview(agreementName, sourceId, documentsIds, reviewers, subject, body, expiresInNumberOfDays);
		NegotiateAPI.TaskStatus taskStatus = NegotiateAPI.getInstance().getWorkFlowStatus(taskId);
		if (taskStatus.status.equals('Waiting')) {
			taskStatus.message = Label.ExternalReviewSuccess;
		} else if (taskStatus.status.equals('Executing')) {
			taskStatus.message = Label.ExternalReviewProcessing;
		} else {
			taskStatus.message = Label.ExternalReviewFailed;
		}
		return taskStatus;
	}

	public static NegotiateAPI.TaskStatus sendForInternalApproval(final String agreementName, final Id sourceId, final List<UUID> documentsIds, final List<Recipient> approvers, final String subject, final String body, final Boolean isSequential) {
		Permissions.verifyIsDocuSignUser(); //TODO check if additional Netgotiate permissions check
		UUID taskId = NegotiateAPI.getInstance().sendForApproval(agreementName, sourceId, documentsIds, approvers, subject, body, isSequential);
		NegotiateAPI.TaskStatus taskStatus = NegotiateAPI.getInstance().getWorkFlowStatus(taskId);
		if (taskStatus.status.equals('Waiting')) {
			taskStatus.message = Label.InternalApprovalSuccess;
		} else if (taskStatus.status.equals('Executing')) {
			taskStatus.message = Label.InternalApprovalProcessing;
		} else {
			taskStatus.message = Label.InternalApprovalFailed;
		}
		return taskStatus;
	}

	public static NegotiateService.LimitedAccessToken generateUploadToken(final Id objectId) {
		Permissions.verifyIsDocuSignUser();
		UUID folderId = DB.getFolderId(objectId);
		NegotiateService.LimitedAccessToken token = NegotiateAPI.getHistoryAPIInstance().generateLimitedAccessToken(folderId, AuthService.getContentAccessToken());
		return token.withEntityId(folderId)
			.withAccountId(Credentials.getInstance().account.id);
	}

	public static NegotiateService.LimitedAccessToken generateDownloadToken(final UUID agreementId) {
		Permissions.verifyIsDocuSignUser();
		NegotiateService.LimitedAccessToken token = NegotiateAPI.getHistoryAPIInstance().generateLimitedAccessToken(agreementId, AuthService.getContentAccessToken());
		return token.withEntityId(agreementId)
			.withAccountId(Credentials.getInstance().account.id);
	}

	public static NegotiateService.LimitedAccessToken generateUploadNewVersionToken(final UUID agreementId) {
		Permissions.verifyIsDocuSignUser();
		NegotiateService.LimitedAccessToken token = NegotiateAPI.getHistoryAPIInstance().generateLimitedAccessToken(agreementId, AuthService.getContentAccessToken());
		return token.withEntityId(agreementId)
			.withAccountId(Credentials.getInstance().account.id);
	}

	public static List<AgreementApprovalWorkItem> getApprovalWorkItems(final UUID documentId) {
		Permissions.verifyIsDocuSignUser();
		return NegotiateAPI.getInstance().getApprovalWorkItems(documentId);
	}

	public static Boolean resendRequest(final String documentHref, final String resendEmailType) {
		Permissions.verifyIsDocuSignUser();
		return NegotiateAPI.getHistoryAPIInstance().resendRequest(documentHref, resendEmailType);
	}

	public static Boolean cancelApprovalOrExternalReview(final UUID documentId) {
		Permissions.verifyIsDocuSignUser();
		return NegotiateAPI.getInstance().cancelApprovalOrExternalReview(documentId);
	}

	public static Boolean approveOnBehalfOrRecipientResponse(final String comment, final boolean itemResponse, final UUID workItemsId) {
		Permissions.verifyIsDocuSignUser();
		if(itemResponse)
			return NegotiateAPI.getInstance().approveOnBehalfOrRecipientResponse(comment, NegotiateAPI.APPROVE, workItemsId);
		else
			return NegotiateAPI.getInstance().approveOnBehalfOrRecipientResponse(comment, NegotiateAPI.REJECT, workItemsId);
	}

	public static Boolean externalReviewCompleteOnBehalf(final String comments, final Url newVersionUrl, final UUID documentId) {
		Permissions.verifyIsDocuSignUser();
		UUID externalReviewId = NegotiateAPI.getInstance().getDocumentReview(documentId);
		return NegotiateAPI.getInstance().externalReviewCompleteOnBehalf(comments, newVersionUrl, externalReviewId);
	}
}