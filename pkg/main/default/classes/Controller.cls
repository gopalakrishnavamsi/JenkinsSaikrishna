public virtual with sharing class Controller {

	public String namespace {
		get {
			return Application.lightningNamespace;
		}
	}

	public String lightningHost {
		get {
			return Salesforce.getLightningHost();
		}
	}

	public String visualforceHost {
		get {
			return Salesforce.getVisualforceHost();
		}
	}

	public static AuraHandledException wrapException(final String message) {
		LoggerService.getInstance().error(message);
		AuraHandledException ex = new AuraHandledException(message);
		ex.setMessage(message);
		return ex;
	}

	private static String getErrorMessage(final Exception ex) {
		String message = null;
		if (ex instanceof UnauthorizedException) {
			UnauthorizedException uex = (UnauthorizedException)ex;
			if (uex.requirement == null || uex.requirement == UnauthorizedException.AccessRequirement.Unspecified) {
				message = Label.UnauthorizedUser; // Use friendly error message for end-users
			} else {
				message = uex.getMessage();
			}
		} else {
			message = ex.getMessage();
		}
		return message;
	}

	public static AuraHandledException wrapException(final Exception ex, final String context) {
		LoggerService.getInstance().exception(ex, context);
		String message = getErrorMessage(ex);
		AuraHandledException ex2 = new AuraHandledException(message);
		ex2.setMessage(message);
		return ex2;
	}
}
