public class AdminResponse extends RemoteActionResponse {

	public Account account { get; private set; }
	public List<String> availableAccounts { get; private set; }

	private AdminResponse(
		final Boolean success,
		final List<RemoteActionResponse.Message> messages,
		final Account account,
		final List<String> availableAccounts) {

		super(success, messages);

		this.account = account;
		this.availableAccounts = availableAccounts;
	}

	public static AdminResponse loginSuccessful(final Account account) {
		return new AdminResponse(true, null, account, null);
	}

	public static AdminResponse loginMultiple(final String message, final List<String> availableAccounts) {
		return new AdminResponse(true, new List<RemoteActionResponse.Message> {
			new RemoteActionResponse.Message(MessageSeverity.Warning, message)
		}, null, availableAccounts);
	}
}
