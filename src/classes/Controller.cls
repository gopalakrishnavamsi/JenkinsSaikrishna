public abstract with sharing class Controller {

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

	public static AuraHandledException wrapException(final Exception ex, final String context) {
		LoggerService.getInstance().exception(ex, context);
		String message = ex.getMessage();
		AuraHandledException ex2 = new AuraHandledException(message);
		ex2.setMessage(message);
		return ex2;
	}
}
