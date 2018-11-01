/**
 * The exception thrown when unauthorized access is detected.
 */
global class UnauthorizedException extends Exception {
	/**
	 * The ID of the unauthorized user.
	 */
	global Id userId { get; private set; }
	/**
	 * The access requirement.
	 */
	global AccessRequirement requirement { get; private set; }

	/**
	 * Access requirements:
	 * <ul>
	 *     <li><code>Unspecified</code>: Not specified.</li>
	 *     <li><code>DocuSignSender</code>: Must be assigned the <code>DocuSign Sender</code> permission set.</li>
	 *     <li><code>DocuSignUser</code>: Must be assigned the <code>DocuSign User</code> permission set.</li>
	 *     <li><code>DocuSignAdministrator</code>: Must be assigned the <code>DocuSign Administrator</code> permission
	 *     set.</li>
	 *     <li><code>SalesforceAdministrator</code>: Must be a Salesforce administrator.</li>
	 *     <li><code>EnvelopeOwner</code>: Must be the envelope owner.</li>
	 *     <li><code>ConfigureAccount</code>: DocuSign account is not configured in Salesforce.</li>
	 * </ul>
	 */
	global enum AccessRequirement {
		Unspecified,
		DocuSignUser,
		DocuSignAdministrator,
		DocuSignSender,
		SalesforceAdministrator,
		EnvelopeOwner,
		ConfigureAccount
	}

	/**
	 * Constructs the exception.
	 *
	 * @param message The error message.
	 * @param details Additional error details.
	 */
	public UnauthorizedException(final String message, final Object details) {
		this(message + (details == null ? '' : '\n' + details));

		this.requirement = AccessRequirement.Unspecified;
	}

	/**
	 * Factory method to construct an exception when the user is not the envelope owner.
	 *
	 * @return The new exception.
	 */
	public static UnauthorizedException notEnvelopeOwner() {
		final UnauthorizedException ex = new UnauthorizedException(Label.NotEnvelopeOwner);
		ex.userId = UserInfo.getUserId();
		ex.requirement = AccessRequirement.EnvelopeOwner;
		return ex;
	}

	/**
	 * Factory method to construct an exception when the user is not assigned the <code>DocuSign Adminstrator</code>
	 * permission set.
	 *
	 * @return The new exception.
	 */
	public static UnauthorizedException notSalesforceAdministrator() {
		final UnauthorizedException ex = new UnauthorizedException(Label.MustBeAdministrator);
		ex.userId = UserInfo.getUserId();
		ex.requirement = AccessRequirement.SalesforceAdministrator;
		return ex;
	}

	/**
	 * Factory method to construct an exception when the user is not a Salesforce administrator.
	 *
	 * @return The new exception.
	 */
	public static UnauthorizedException notDocuSignAdministrator() {
		final UnauthorizedException ex = new UnauthorizedException(Label.MustBeDocuSignAdministrator);
		ex.userId = UserInfo.getUserId();
		ex.requirement = AccessRequirement.DocuSignAdministrator;
		return ex;
	}

	/**
	 * Factory method to construct an exception when the user is not assigned the <code>DocuSign User</code>
	 * permission set.
	 *
	 * @return The new exception.
	 */
	public static UnauthorizedException notDocuSignUser() {
		final UnauthorizedException ex = new UnauthorizedException(Label.MustBeDocuSignUser);
		ex.userId = UserInfo.getUserId();
		ex.requirement = AccessRequirement.DocuSignUser;
		return ex;
	}

	/**
	 * Factory method to construct an exception when the user is not assigned the <code>DocuSign Sender</code>
	 * permission set.
	 *
	 * @return The new exception.
	 */
	public static UnauthorizedException notDocuSignSender() {
		final UnauthorizedException ex = new UnauthorizedException(Label.MustBeDocuSignSender);
		ex.userId = UserInfo.getUserId();
		ex.requirement = AccessRequirement.DocuSignSender;
		return ex;
	}

	/**
	 * Factory method to construct an exception when the user is a DocuSign user but may require activation.
	 *
	 * @return The new exception.
	 */
	public static UnauthorizedException mayRequireActivation() {
		final UnauthorizedException ex = new UnauthorizedException(Label.MustBeActivated);
		ex.userId = UserInfo.getUserId();
		ex.requirement = AccessRequirement.DocuSignUser;
		return ex;
	}

	/**
	 * Factory method to construct an exception when Salesforce is not connected to DocuSign.
	 *
	 * @return The new exception.
	 */
	public static UnauthorizedException accountNotConfigured() {
		final UnauthorizedException ex = new UnauthorizedException(Label.AccountNotConfigured);
		ex.userId = UserInfo.getUserId();
		ex.requirement = AccessRequirement.ConfigureAccount;
		return ex;
	}
}