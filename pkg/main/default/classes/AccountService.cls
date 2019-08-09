/**
 * Primary interface point for DocuSign for Salesforce account management.
 */
global with sharing class AccountService {
	/**
	 * Retrieves a URL that can be used to display the DocuSign console. This URL can only be used once.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set, and must be an active member of the
	 * DocuSign account.
	 *
	 * @return The DocuSign console URL.
	 */
	global static Url getDocuSignUrl() {
		if (!Permissions.isDocuSignUser()) throw new UnauthorizedException(Label.UnauthorizedPageAccess);

		try {
			return AccountAPI.getInstance().getConsoleViewUrl();
		} finally {
			Credentials.save();
		}
	}

	/**
	 * Retrieves DocuSign for Salesforce account settings.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The account settings.
	 */
	public static AccountSettings getSettings() {
		Permissions.verifyIsDocuSignAdministrator();

		return AccountSettings.getInstance();
	}

	/**
	 * Updates DocuSign for Salesforce account settings.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param settings The settings to update.
	 *
	 * @return The updated settings.
	 */
	public static AccountSettings saveSettings(final AccountSettings settings) {
		Permissions.verifyIsDocuSignAdministrator();

		if (settings == null) throw new DocuSignException(Label.UndefinedArgument);

		return AccountSettings.save(settings);
	}

	/**
	 * Runs all post-install scripts again if needed to solve a problem. This is a safe operation as it will not
	 * overwrite current settings if they exist.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The results of the post-install script execution.
	 */
	public static PostInstallResults executePostInstallScripts() {
		Permissions.verifyIsDocuSignAdministrator();

		return new PostInstall(true).execute(
			UserInfo.getOrganizationId(),
			UserInfo.getUserId(),
			null,
			false,
			false);
	}
}
