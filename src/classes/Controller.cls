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
}
