public class SpringOAuthLoginInformation {

	@AuraEnabled
	public Boolean success { get; private set; }
	@AuraEnabled
	public String message { get; private set; }

	private SpringOAuthLoginInformation(
		final Boolean success,
		final String message) {

		this.success = success;
		this.message = message;
	}

	public static SpringOAuthLoginInformation success(final String message) {
		return new SpringOAuthLoginInformation(true, message);
	}

	public static SpringOAuthLoginInformation failure(final String message) {
		return new SpringOAuthLoginInformation(false, message);
	}
}
