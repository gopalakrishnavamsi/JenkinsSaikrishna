public class UnauthorizedException extends Exception {
	public Id userId { get; private set; }
	public RequiredPermissionSet requirement { get; private set; }
	public enum RequiredPermissionSet {
		DocuSignUser,
		DocuSignAdministrator,
		SalesforceAdministrator,
		EnvelopeOwner
	}

	public UnauthorizedException(final String message, final Object details) {
		this(message + (details == null ? '' : '\n' + details));
	}

	public static UnauthorizedException notEnvelopeOwner() {
		final UnauthorizedException ex = new UnauthorizedException(Label.NotEnvelopeOwner);
		ex.userId = UserInfo.getUserId();
		ex.requirement = RequiredPermissionSet.EnvelopeOwner;
		return ex;
	}

	public static UnauthorizedException notSalesforceAdministrator() {
		final UnauthorizedException ex = new UnauthorizedException(Label.MustBeAdministrator);
		ex.userId = UserInfo.getUserId();
		ex.requirement = RequiredPermissionSet.SalesforceAdministrator;
		return ex;
	}

	public static UnauthorizedException notDocuSignAdministrator() {
		final UnauthorizedException ex = new UnauthorizedException(Label.MustBeDocuSignAdministrator);
		ex.userId = UserInfo.getUserId();
		ex.requirement = RequiredPermissionSet.DocuSignAdministrator;
		return ex;
	}

	public static UnauthorizedException notDocuSignUser() {
		final UnauthorizedException ex = new UnauthorizedException(Label.MustBeDocuSignUser);
		ex.userId = UserInfo.getUserId();
		ex.requirement = RequiredPermissionSet.DocuSignUser;
		return ex;
	}

	public static UnauthorizedException mayRequireActivation() {
		final UnauthorizedException ex = new UnauthorizedException(Label.MustBeActivated);
		ex.userId = UserInfo.getUserId();
		ex.requirement = RequiredPermissionSet.DocuSignUser;
		return ex;
	}
}
