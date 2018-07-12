public abstract with sharing class Controller {

	public String namespace {
		get {
			return Application.lightningNamespace;
		}
	}

	public String baseUrl {
		get {
			return Salesforce.baseUrl.toExternalForm();
		}
	}

	public String instanceName {
		get {
			return Salesforce.instanceName;
		}
	}
}
