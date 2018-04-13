public class ValidationResult {

	public List<String> messages { get; private set; }
	public Boolean isValid {
		get {
			return Collection.isEmpty(messages);
		}
	}

	public ValidationResult() {
		this(new List<String>());
	}

	public ValidationResult(final String message) {
		this(String.isNotBlank(message) ? new List<String> { message } : new List<String>());
	}

	public ValidationResult(final List<String> messages) {
		this.messages = messages == null ? new List<String>() : messages;
	}

	override public String toString() {
		return Collection.mkString(this.messages, '\n');
	}

	public ValidationResult add(final String message) {
		if (String.isNotBlank(message)) this.messages.add(message);
		return this;
	}

	public ValidationResult add(final List<String> messages) {
		if (messages != null) this.messages.addAll(messages);
		return this;
	}

	public ValidationResult add(final ValidationResult other) {
		if (other != null && Collection.isNotEmpty(other.messages)) {
			this.messages.addAll(other.messages);
		}
		return this;
	}

	public ValidationResult add(final Permissions.FlsResults flsResults) {
		if (flsResults != null && !flsResults.isAuthorized) {
			this.messages.add(flsResults.getErrorMessage());
		}
		return this;
	}
}
