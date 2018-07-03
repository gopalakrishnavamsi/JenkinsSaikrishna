public with sharing abstract class Controller {

	@AuraEnabled
	public String namespace {
		get {
			return Application.lightningNamespace;
		}
	}
}
