/**
 * Primary interface point for DocuSign Negotiate.
 */
public with sharing class NegotiateService {
	@TestVisible
	private static final NegotiateService.Database DB = new NegotiateService.Database();

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
					// add historyItems
					List<AgreementHistoryItem> agreementHistoryItems = NegotiateAPI.getHistoryAPIInstance().getHistoryItems(agreement.id);
					agreement.withStatus(calculateStatus(agreementHistoryItems)).withHistoryItems(agreementHistoryItems);
					if (agreementHistoryItems != null && !agreementHistoryItems.isEmpty() && agreementHistoryItems.get(0) != null) {
						agreement.withModifiedDate(agreementHistoryItems.get(0).historyDate);
					}
					// add versions
					agreement.withVersions(NegotiateAPI.getInstance().getAgreementVersions(agreement.id));
				}
			}
		}
		return agreements;
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

		else if (historyItemType.equals(AgreementHistoryItem.ApprovalCheckoutCanceled)) {
			return AgreementStatus.APPROVAL_CANCELLED;
		}

		else if (historyItemType.equals(AgreementHistoryItem.DocumentCheckIn)) {
			return AgreementStatus.NEW_VERSION;
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

	public static Boolean renameAgreement(final UUID documentId, final String documentName) {
		Permissions.verifyIsDocuSignUser();
		return NegotiateAPI.getInstance().renameAgreement(documentId, documentName);
	}

	public static Boolean deleteAgreement(final UUID documentId) {
		Permissions.verifyIsDocuSignUser();
		return NegotiateAPI.getInstance().deleteAgreement(documentId);
	}

	public static NegotiateAPI.TaskStatus sendForExternalReview(final List<UUID> documentsIds, final List<String> reviewerIds, final String subject, final String body, final Integer expiresInNumberOfDays) {
		Permissions.verifyIsDocuSignUser(); //TODO check if additional Netgotiate permissions check
		UUID taskId = NegotiateAPI.getInstance().sendForExternalReview(documentsIds, reviewerIds, subject, body, expiresInNumberOfDays);
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

	public static NegotiateAPI.TaskStatus sendForInternalApproval(final List<UUID> documentsIds, final List<String> reviewerIds, final String subject, final String body) {
		Permissions.verifyIsDocuSignUser(); //TODO check if additional Netgotiate permissions check
		UUID taskId = NegotiateAPI.getInstance().sendForApproval(documentsIds, reviewerIds, subject, body);
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

	public static List<AgreementHistoryItem.Actor> getApprovalUsers(final UUID documentId) {
		// use fullName on Actor and accountUrl for the workItemUrl
		Permissions.verifyIsDocuSignUser();
		return NegotiateAPI.getInstance().getApprovalUsers(documentId);
	}
}