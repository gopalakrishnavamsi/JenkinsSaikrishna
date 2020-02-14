/**
 * Primary interface point for DocuSign Negotiate.
 */
public with sharing class NegotiateService {
	@TestVisible
	private static final NegotiateService.Database DB = new NegotiateService.Database();
	public static final String TASK_SUCCESS = 'Success';
	public static final String TASK_WAITING = 'Waiting';
	public static final String TASK_EXECUTING = 'Executing';
	public static final String TASK_PROCESSING = 'Processing';
	public static final String TASK_COMPLETED = 'Completed';

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

	@Future
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
		Permissions.verifyIsDocuSignNegotiator();
		UUID folderId = DB.getFolderId(sourceObjectId);
		List<Agreement> agreements = new List<Agreement>();
		if (folderId == null) {
			String sourceObjectType = sourceObjectId.getSobjectType().getDescribe().getName();
			String sourceObjectName = sourceObjectId; //EOS folder name set as recordID since Name field can vary on all objects.
			folderId = NegotiateAPI.getInstance().createEOSFolder(sourceObjectName, sourceObjectId, sourceObjectType);
			setFolderId(sourceObjectId, folderId.toString());
			return agreements;

		} else {
			agreements = NegotiateAPI.getInstance().getAgreements(folderId);
			for (Agreement agreement : agreements) {
				if (agreement != null) {
					HistoryAPI.getInstance().prepareHistoryItems(agreement.id);
				}
			}
			Map<UUID, List<AgreementHistoryItem>> documentIdToHistoryItems
				= HistoryAPI.getInstance().processHistoryItems();

			for (Agreement agreement : agreements) {
				if (agreement != null) {
					agreement = getAgreementData(agreement, documentIdToHistoryItems);
				}
			}
		}
		return agreements;
	}

	public static Agreement getAgreement(final UUID agreementId) {
		Permissions.verifyIsDocuSignNegotiator();
		return getAgreementData(NegotiateAPI.getInstance().getAgreement(agreementId));
	}

	private static Agreement getAgreementData(Agreement agreement, Map<UUID, List<AgreementHistoryItem>> documentIdToHistoryItems) {
		// add historyItems
		List<AgreementHistoryItem> agreementHistoryItems = documentIdToHistoryItems.get(agreement.id);
		agreement.withStatus(calculateStatus(agreementHistoryItems)).withHistoryItems(agreementHistoryItems);
		if (agreementHistoryItems != null && !agreementHistoryItems.isEmpty() && agreementHistoryItems.get(0) != null) {
			agreement.withModifiedDate(agreementHistoryItems.get(0).historyDate);
		}
		// add versions
		agreement.withVersions(NegotiateAPI.getInstance().getAgreementVersions(agreement.id));
		return agreement;
	}

	private static Agreement getAgreementData(Agreement agreement) {
		// add historyItems
		List<AgreementHistoryItem> agreementHistoryItems = HistoryAPI.getInstance().getHistoryItems(agreement.id);
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

		else if (historyItemType.equals(AgreementHistoryItem.ApprovalCheckout) ||
			historyItemType.equals(AgreementHistoryItem.CompletedHumanActivity)) {
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
		Permissions.verifyIsDocuSignNegotiator();
		UUID folderId = DB.getFolderId(sourceObjectId);
		Boolean isUpdated = false;
		if (folderId == null) {
			String sourceObjectType = sourceObjectId.getSobjectType().getDescribe().getName();
			String sourceObjectName = sourceObjectId;
			folderId = NegotiateAPI.getInstance().createEOSFolder(sourceObjectName, sourceObjectId, sourceObjectType);
			isUpdated = true;
		}
		UUID taskId = NegotiateAPI.getInstance().createAgreementInEOSFolder(sfContentVersionId, folderId, documentName);
		NegotiateAPI.TaskStatus taskStatus = NegotiateAPI.getInstance().getAgreementInEOSFolderStatus(taskId);
		if (taskStatus.status.equals(TASK_SUCCESS)) {
			taskStatus.message = Label.AgreementImportSuccessful;
		} else if (taskStatus.status.equals(TASK_PROCESSING)) {
			taskStatus.message = Label.AgreementImportProcessing;
		} else {
			taskStatus.message = Label.AgreementImportFailed;
		}
		if (isUpdated) {
			setFolderId(sourceObjectId, folderId.toString());
		}
		return taskStatus;
	}

	public static UUID compareAgreements(final String originalDocumentHref, final String compareVersionHref) {
		Permissions.verifyIsDocuSignNegotiator();
		//validate inputs
		if (String.isBlank(originalDocumentHref) || String.isBlank(compareVersionHref)) {
			throw new APIException(Label.InvalidInputsAgreementComparison);
		}
		UUID returnValue;
		UUID taskId = NegotiateAPI.getInstance().compareAgreements(originalDocumentHref, compareVersionHref);
		NegotiateAPI.TaskStatus taskStatus = NegotiateAPI.getInstance().getCompareAgreementsStatus(taskId);
		//successfully processed agreement comparison task
		if (taskStatus.status.equals(TASK_SUCCESS)) {
			returnValue = taskId;
		}
		//throw exception if status is not equal to success
		else {
			throw new APIException(Label.FailedToTriggerDocumentComparisonTask);
		}
		return returnValue;
	}

	public static NegotiateAPI.TaskStatus exportAgreementToSalesforce(final Id sourceObjectId, final UUID documentId) {
		Permissions.verifyIsDocuSignNegotiator();
		UUID taskId = NegotiateAPI.getInstance().exportAgreementToSalesforce(sourceObjectId, documentId);
		NegotiateAPI.TaskStatus taskStatus = NegotiateAPI.getInstance().getExportAgreementToSalesforceStatus(taskId);
		if (taskStatus.status.equals(TASK_SUCCESS)) {
			taskStatus.message = Label.AgreementExportSuccessful;
		} else if (taskStatus.status.equals(TASK_PROCESSING)) {
			taskStatus.message = Label.AgreementExportProcessing;
		} else {
			taskStatus.message = Label.AgreementExportFailed;
		}
		return taskStatus;
	}

	public static String getAgreementPreviewLink(final Id sourceId, final String agreementId, final Boolean isFullUrl) {
		Permissions.verifyIsDocuSignNegotiator();
		if (sourceId == null || agreementId == null) return null;

		UUID agreementUId = UUID.parse(agreementId);
		PageReference agreementView = Page.AgreementPreview;
		agreementView.getParameters().put('sourceId', EncodingUtil.urlEncode(sourceId, StringUtils.ENCODING));
		agreementView.getParameters().put('agreementId', EncodingUtil.urlEncode(agreementUId.value, StringUtils.ENCODING));
		if (isFullUrl) return new Url(Salesforce.baseUrl, agreementView.getUrl()).toExternalForm();
		return agreementView.getUrl();
	}

	public static Boolean renameAgreement(final UUID documentId, final String documentName) {
		Permissions.verifyIsDocuSignNegotiator();
		return NegotiateAPI.getInstance().renameAgreement(documentId, documentName);
	}

	public static Boolean deleteAgreement(final UUID documentId) {
		Permissions.verifyIsDocuSignNegotiator();
		return NegotiateAPI.getInstance().deleteAgreement(documentId);
	}

	public static NegotiateAPI.TaskStatus sendForExternalReview(final String agreementName, final Id sourceId, final List<UUID> documentsIds, final List<Recipient> reviewers, final String subject, final String body, final Integer expiresInNumberOfDays) {
		Permissions.verifyIsDocuSignNegotiator();
		UUID taskId = NegotiateAPI.getInstance().sendForExternalReview(agreementName, sourceId, documentsIds, reviewers, subject, body, expiresInNumberOfDays);
		NegotiateAPI.TaskStatus taskStatus = NegotiateAPI.getInstance().getWorkFlowStatus(taskId);
		if (taskStatus.status.equals(TASK_WAITING) || taskStatus.status.equals(TASK_COMPLETED)) {
			taskStatus.message = Label.ExternalReviewSuccess;
		} else if (taskStatus.status.equals(TASK_EXECUTING)) {
			taskStatus.message = Label.ExternalReviewProcessing;
		} else {
			taskStatus.message = Label.ExternalReviewFailed;
		}
		return taskStatus;
	}

	public static NegotiateAPI.TaskStatus sendForInternalApproval(final String agreementName, final Id sourceId, final List<UUID> documentsIds, final List<Recipient> approvers, final String subject, final String body, final Boolean isSequential) {
		Permissions.verifyIsDocuSignNegotiator();
		UUID taskId = NegotiateAPI.getInstance().sendForApproval(agreementName, sourceId, documentsIds, approvers, subject, body, isSequential);
		NegotiateAPI.TaskStatus taskStatus = NegotiateAPI.getInstance().getWorkFlowStatus(taskId);
		if (taskStatus.status.equals(TASK_WAITING) || taskStatus.status.equals(TASK_COMPLETED)) {
			taskStatus.message = Label.InternalApprovalSuccess;
		} else if (taskStatus.status.equals(TASK_EXECUTING)) {
			taskStatus.message = Label.InternalApprovalProcessing;
		} else {
			taskStatus.message = Label.InternalApprovalFailed;
		}
		return taskStatus;
	}

	public static LimitedAccessToken generateUploadToken(final Id objectId) {
		Permissions.verifyIsDocuSignNegotiator();

		return ScmTokenAPI.getInstance().generateLimitedAccessToken(
			DB.getFolderId(objectId),
			AuthService.getContentAccessToken());
	}

	public static LimitedAccessToken generateDownloadToken(final UUID agreementId) {
		Permissions.verifyIsDocuSignNegotiator();

		return ScmTokenAPI.getInstance().generateLimitedAccessToken(
			agreementId,
			AuthService.getContentAccessToken());
	}

	public static LimitedAccessToken generateUploadNewVersionToken(final UUID agreementId) {
		Permissions.verifyIsDocuSignNegotiator();

		return ScmTokenAPI.getInstance().generateLimitedAccessToken(
			agreementId,
			AuthService.getContentAccessToken());
	}

	public static List<AgreementApprovalWorkItem> getApprovalWorkItems(final UUID documentId) {
		Permissions.verifyIsDocuSignNegotiator();
		return NegotiateAPI.getInstance().getApprovalWorkItems(documentId);
	}

	public static Boolean resendRequest(final String documentHref, final String resendEmailType) {
		Permissions.verifyIsDocuSignNegotiator();
		return HistoryAPI.getInstance().resendRequest(documentHref, resendEmailType);
	}

	public static Boolean cancelApprovalOrExternalReview(final UUID documentId) {
		Permissions.verifyIsDocuSignNegotiator();
		return NegotiateAPI.getInstance().cancelApprovalOrExternalReview(documentId);
	}

	public static Boolean approveOnBehalfOrRecipientResponse(final String comment, final Boolean itemResponse, final UUID workItemsId) {
		Permissions.verifyIsDocuSignNegotiator();
		if (itemResponse) {
			return NegotiateAPI.getInstance().approveOnBehalfOrRecipientResponse(comment, NegotiateAPI.APPROVE, workItemsId);
		} else {
			return NegotiateAPI.getInstance().approveOnBehalfOrRecipientResponse(comment, NegotiateAPI.REJECT, workItemsId);
		}
	}

	public static Boolean externalReviewCompleteOnBehalf(final String comments, final Url newVersionUrl, final UUID documentId) {
		Permissions.verifyIsDocuSignNegotiator();
		UUID externalReviewId = NegotiateAPI.getInstance().getDocumentReview(documentId);
		return NegotiateAPI.getInstance().externalReviewCompleteOnBehalf(comments, newVersionUrl, externalReviewId);
	}

	public static String getResourceToken(final UUID documentID) {
		Permissions.verifyIsDocuSignNegotiator();
		return ScmTokenAPI.getInstance().getResourceToken(documentID).toExternalForm();
	}

	public static Url getCompareUrl(final UUID compareTaskId) {
		Permissions.verifyIsDocuSignNegotiator();
		return ScmTokenAPI.getInstance().getCompareUrl(compareTaskId);
	}

	public static void setRootLevelFolderSecurity() {
		Permissions.verifyIsDocuSignAdministrator();
		Url rootLevelFolderUrl = NegotiateAPI.getInstance().getRootLevelFolderUrl();
		if (rootLevelFolderUrl != null) {
			NegotiateAPI.getInstance().triggerChangeSecurityTask(rootLevelFolderUrl);
		}
	}
}
