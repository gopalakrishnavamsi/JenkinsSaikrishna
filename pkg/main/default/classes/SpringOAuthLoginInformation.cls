public class SpringOAuthLoginInformation {
	@AuraEnabled
	public String status { get; private set; }

	@AuraEnabled
	public String message { get; private set; }

	public SpringOAuthLoginInformation(
		final String status,
		final String message) {

		this.status = status;
		this.message = message;
	}
}
