public class AgreementApprovalWorkItem {
	@AuraEnabled
	public String firstName;

	@AuraEnabled
	public String lastName;

	@AuraEnabled
	public String email;

	@AuraEnabled
	public String workItemUrl;

	@AuraEnabled
	public UUID workItemId;

	public AgreementApprovalWorkItem(final String firstName,
		final String lastName,
		final String email,
		final String workItemUrl) {
		this.firstName = firstName;
		this.lastName = lastName;
		this.email = email;
		this.workItemUrl = workItemUrl;
		this.workItemId = UUID.parse(this.workItemUrl.substringAfterLast('/'));
	}
}