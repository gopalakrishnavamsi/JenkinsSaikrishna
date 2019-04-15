/**
 * Primary interface point for DocuSign Negotiate.
 */
public with sharing class NegotiateService {

	public static List<Agreement> getAgreements(final UUID folderId, final UUID accountId) {
		List<Agreement> agreements = NegotiateAPI.getInstance().getAgreements(folderId);
		for (Agreement a : agreements) {
			if (a != null) {
				List<AgreementHistoryItem> agreementHistoryItems = NegotiateAPI.getInstance().getHistoryItems(accountId, a.id);
				a.withStatus(calculateStatus(agreementHistoryItems)).withHistoryItems(agreementHistoryItems);
				if (agreementHistoryItems != null && !agreementHistoryItems.isEmpty() && agreementHistoryItems.get(0) != null) {
					a.withModifiedDate(agreementHistoryItems.get(0).historyDate);
				}
			}
		}
		return agreements;
	}

	private static String calculateStatus(final List<AgreementHistoryItem> historyItems) {
		if (historyItems == null || historyItems.isEmpty()) {
			return AgreementStatus.SYSTEM_ERROR;
		}
		if (historyItems.get(0).historyItemType == AgreementHistoryItem.Action.WorkflowApproved) {

			List<AgreementHistoryItem> tempHistoryItems = new List<AgreementHistoryItem>();
			Long numberOfApprovers = 0;
			for (AgreementHistoryItem historyItem : historyItems) {
				if (historyItem.historyItemType != null && historyItem.historyItemType == AgreementHistoryItem.Action.ApprovalCheckout) {
					numberOfApprovers = historyItem.recipients.size();
					break;
				} else if (historyItem.historyItemType != null && historyItem.historyItemType == AgreementHistoryItem.Action.WorkflowApproved) {
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

	private static String statusActionMapping(AgreementHistoryItem.Action historyItemType) {
		switch on historyItemType {
			when DocumentImportedFromSalesforce, TitleChanged {
				return AgreementStatus.NEW_AGREEMENT;
			}
			when ExternalReviewInitiated {
				return AgreementStatus.PENDING_REVIEW;
			}
			when ExternalReviewCompletedDocumentAndComments, ExternalReviewCompletedCheckoutCancelled, ExternalReviewCompletedDocumentCheckin, ExternalReviewCompletedInternally {
				return AgreementStatus.REVIEWED;
			}
			when ExternalReviewCancelled {
				return AgreementStatus.REVIEW_CANCELLED;
			}
			when ExternalReviewErrored {
				return AgreementStatus.SYSTEM_ERROR;
			}
			when ApprovalCheckout {
				return AgreementStatus.PENDING_APPROVAL;
			}
			when WorkflowApproved {
				return AgreementStatus.APPROVED;
			}
			when WorkflowRejected {
				return AgreementStatus.REJECTED;
			}
			when ApprovalCheckoutCanceled {
				return AgreementStatus.APPROVAL_CANCELLED;
			}
			when DocumentCheckIn {
				return AgreementStatus.NEW_VERSION;
			}
			when else {
				return AgreementStatus.SYSTEM_ERROR;
			}
		}
	}
}