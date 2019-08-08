public with sharing class AgreementsController extends Controller {
	public AgreementsController() {
	}

	public AgreementsController(final ApexPages.StandardController c) {
	}

	public static Boolean getIsCurrentUserDocuSignAdmin() {
		return Permissions.isDocuSignAdministrator();
	}

	@AuraEnabled(Cacheable = true)
	public static String getNameSpace() {
		try {
			Permissions.verifyIsDocuSignNegotiator();
			return Application.namespace;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get namespace.');
		}
	}

	@AuraEnabled
	public static List<Agreement> getAgreements(final Id sourceObjectId) {
		try {
			return NegotiateService.getAgreements(sourceObjectId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get Agreements.');
		}

	}

	@AuraEnabled
	public static Agreement getAgreement(final String agreementId) {
		try {
			return NegotiateService.getAgreement(UUID.parse(agreementId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get Agreement.');
		}

	}

	@AuraEnabled
	public static List<Document> getLinkedDocuments(final Id sourceId) {
		try {
			Permissions.verifyIsDocuSignNegotiator();
			return DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), new Set<Id> { sourceId }, false);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get linked documents');
		}
	}

	@AuraEnabled
	public static NegotiateAPI.TaskStatus createAgreementInEOSFolder(final Id sfContentVersionId, final Id sourceObjectId, final String documentName) {
		try {
			return NegotiateService.createAgreementInEOSFolder(sfContentVersionId, sourceObjectId, documentName);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to create Agreement Folder');
		}
	}

	@AuraEnabled
	public static Boolean renameAgreement(final String documentId, final String documentName) {
		try {
			return NegotiateService.renameAgreement(UUID.parse(documentId), documentName);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to Rename Agreement');
		}
	}

	@AuraEnabled
	public static Boolean deleteAgreement(final String documentId) {
		try {
			return NegotiateService.deleteAgreement(UUID.parse(documentId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to Delete Agreement');
		}
	}

	@AuraEnabled
	public static NegotiateService.LimitedAccessToken generateUploadToken(final Id objectId) {
		try {
			return NegotiateService.generateUploadToken(objectId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to generate upload access token.');
		}
	}

	@AuraEnabled
	public static NegotiateService.LimitedAccessToken generateDownloadToken(final String objectId) {
		try {
			return NegotiateService.generateDownloadToken(UUID.parse(objectId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to generate upload access token.');
		}
	}

	@AuraEnabled
	public static NegotiateService.LimitedAccessToken generateUploadNewVersionToken(final String agreementId) {
		try {
			return NegotiateService.generateUploadNewVersionToken(UUID.parse(agreementId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to generate upload new version access token.');
		}
	}

	@AuraEnabled
	public static String generateResourceToken(final String agreementId) {
		try {
			return NegotiateService.getResourceToken(UUID.parse(agreementId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to generate resource access token.');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static Recipient resolveRecipient(final Id sourceId) {
		try {
			Permissions.verifyIsDocuSignNegotiator();
			Recipient result = null;
			if (String.isNotBlank(sourceId)) {
				List<Recipient> rs = RecipientService.getRecipients(sourceId.getSobjectType(), new Set<Id> { sourceId });
				if (Collection.isNotEmpty(rs)) {
					result = rs[0];
				}
			}
			return result;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to resolve recipients');
		}
	}

	@AuraEnabled
	public static String redirectToAgreementPreview(final Id sourceId, final String agreementId) {
		try {
			String result = NegotiateService.getAgreementPreviewLink(sourceId, agreementId, false);
			if (result == null) throw Controller.wrapException('Failed to redirect to Agreement Preview page: undefined parameter');
			return result;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to redirect to Agreement Preview');
		}
	}

	@AuraEnabled
	public static String getAgreementShareLink(final Id sourceId, final String agreementId) {
		try {
			String result = NegotiateService.getAgreementPreviewLink(sourceId, agreementId, true);
			if (result == null) throw Controller.wrapException('Failed to redirect to Agreement Preview page: undefined parameter');
			return result;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to redirect to Agreement Preview');
		}
	}

	@AuraEnabled
	public static NegotiateAPI.TaskStatus sendForExternalReview(final String agreementName, final Id sourceId, final List<String> documentsIds, final String reviewersJson, final String subject, final String body, final Integer expiresInNumberOfDays) {
		try {
			if (String.isBlank(reviewersJson)) throw Controller.wrapException('Failed to send documents for External Review: Invalid Reviewers');
			List<UUID> documentIdList = new List<UUID>();
			List<Recipient> reviewers = (List<Recipient>)JSON.deserialize(reviewersJson, List<Recipient>.class);
			for (String documentId : documentsIds) {
				documentIdList.add(UUID.parse(documentId));
			}
			return NegotiateService.sendForExternalReview(agreementName, sourceId, documentIdList, reviewers, subject, body, expiresInNumberOfDays);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to send documents for External Review');
		}
	}

	@AuraEnabled
	public static NegotiateAPI.TaskStatus internalApproval(final String agreementName, final Id sourceId, final List<String> documentsIds, final String approversJson, final String subject, final String body, final Boolean isSequential) {
		try {
			if (String.isBlank(approversJson)) throw Controller.wrapException('Failed to send documents for Internal Approval: Invalid Approvers');
			List<UUID> documentIdList = new List<UUID>();
			List<Recipient> approvers = (List<Recipient>)JSON.deserialize(approversJson, List<Recipient>.class);
			for (String documentId : documentsIds) {
				documentIdList.add(UUID.parse(documentId));
			}
			return NegotiateService.sendForInternalApproval(agreementName, sourceId, documentIdList, approvers, subject, body, isSequential);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to send documents for Internal Approval');
		}
	}

	@AuraEnabled
	public static Boolean resendRequest(final String documentHref, final String resendEmailType) {
		try {
			return NegotiateService.resendRequest(documentHref, resendEmailType);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to resend Agreement');
		}
	}

	@AuraEnabled
	public static Boolean cancelApprovalOrExternalReview(final String documentId) {
		try {
			return NegotiateService.cancelApprovalOrExternalReview(UUID.parse(documentId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to cancel request');
		}
	}

	@AuraEnabled
	public static List<AgreementApprovalWorkItem> getApprovalWorkItems(final String agreementId) {
		try {
			return NegotiateService.getApprovalWorkItems(UUID.parse(agreementId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get ApprovalWorkItems');
		}
	}

	@AuraEnabled
	public static Boolean approveOnBehalfOrRecipientResponse(final String comment, final boolean itemResponse, final String workItemsId) {
		try {
			return NegotiateService.approveOnBehalfOrRecipientResponse(comment, itemResponse, UUID.parse(workItemsId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get ApprovalWorkItems');
		}
	}

	@AuraEnabled
	public static NegotiateAPI.TaskStatus exportAgreementToSalesforce(final Id sourceId, final String agreementId) {
		try {
			return NegotiateService.exportAgreementToSalesforce(sourceId, UUID.parse(agreementId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to Add Agreement in Salesforce');
		}
	}

}
